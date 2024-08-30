// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;
import "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "./libraries/Utils.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/ISettleManager.sol";
import "./interfaces/IOptionsToken.sol";
import "./interfaces/IOptionsMarket.sol";
import "./interfaces/IERC1155Receiver.sol";

contract MobyRouter is Ownable2StepUpgradeable, IERC1155Receiver {
    using SafeERC20 for IERC20;

    address public positionManager;
    address public settleManager;
    address public controller;
    address public optionsMarket;
    mapping(bytes32 => address) public requestKeyOwner; // every createOpenPosition or createClosePosition will have a requestKey. This mapping identifies the owner of the request
    mapping(bytes32 => bool) public isClaimed;
    mapping(bytes32 => bool) public isOpen;
    mapping(bytes32 => address) public receivingToken; // refund token when request is canceled or payout token when request for closePosition is executed
    mapping(address => uint256) public requestKeyLength;
    mapping(address => mapping (uint256 => bytes32)) public requestKeyOf; // requestKeyOf(user, index)

    event OpenPositionCreated(address indexed owner, bytes32 requestKey);
    event ClosePositionCreated(address indexed owner, bytes32 requestKey);
    event Claimed(address indexed account, bytes32 requestKey);
    event PositionSettled(address indexed account, uint256 indexed optionTokenId, uint256 size);

    /*
    * @dev initialize MobyRouter
    * @param _positionManager address of PositionManager of Moby
    * @param _settleManager address of SettleManager of Moby
    */
    function initilize(address _positionManager, address _settleManager) external initializer {
        __Ownable2Step_init();
        positionManager = _positionManager;
        settleManager = _settleManager;
        controller = IPositionManager(positionManager).controller();
        optionsMarket = IPositionManager(positionManager).optionsMarket();
    }

    /**
     * @dev execuctionFee in PositionManager. Should send as msg.value when createOpenPosition or createClosePosition.
     */
    function executionFee() public view returns (uint256) {
        return IPositionManager(positionManager).executionFee();
    }

    /*
    * @dev information about open position request
    * @param _requestKey request key recieved from createOpenPosition
    * @return _underlyingAssetIndex underlying asset index
    * @return _expiry expiry of the option
    * @return optionTokenId ID of the option token
    * @return _minSize minimum quantity of option tokens (variable value)
    * @return _amountIn amount of payment token (fixed value)
    * @return _minOutWhenSwap minimum quantity of tokens desired when swapping
    * @return _isDepositedInETH whether the payment token is ETH
    * @return _blockTime block time at the moment of request
    * @return _status request status
    * @return _sizeOut quantity of the executed option token
    * @return _executionPrice price of the executed option token
    * @return _processBlockTime block time at the moment of execution
    * @return _amountOut quantity of the premium when sold option
    */
    function getOpenPositionRequests(bytes32 _requestKey) public view returns (
        uint16 _underlyingAssetIndex,
        uint40 _expiry,
        uint256 optionTokenId,
        uint256 _minSize,
        uint256 _amountIn,
        uint256 _minOutWhenSwap,
        bool _isDepositedInETH,
        uint40 _blockTime,
        IPositionManager.RequestStatus _status,
        uint256 _sizeOut,
        uint256 _executionPrice,
        uint40 _processBlockTime,
        uint256 _amountOut
    ) {
        (
            ,
            _underlyingAssetIndex,
            _expiry,
            optionTokenId,
            _minSize,
            _amountIn,
            _minOutWhenSwap,
            _isDepositedInETH,
            _blockTime,
            _status,
            _sizeOut,
            _executionPrice,
            _processBlockTime,
            _amountOut
        ) =  IPositionManager(positionManager).openPositionRequests(_requestKey);
    }

    /*
    * @dev information about close position request
    * @param _requestKey request key recieved from createClosePosition
    * @return _underlyingAssetIndex underlying asset index
    * @return _expiry expiry of the option
    * @return _optionTokenId ID of the option token
    * @return _size quantity of the option token (fixed value)
    * @return _minAmountOut minimum quantity of payout token (variable value)
    * @return _minOutWhenSwap minimum quantity of tokens desired when swapping
    * @return _withdrawETH whether the payout token is ETH
    * @return _blockTime block time at the moment of request
    * @return _status request status
    * @return _amountOut quantity of the payout token
    * @return _executionPrice price of the executed option token
    * @return _processBlockTime block time at the moment of execution
    */
    function getClosePositionRequests(bytes32 _requestKey) public view returns (
        uint16 _underlyingAssetIndex,
        uint40 _expiry,
        uint256 _optionTokenId,
        uint256 _size,
        uint256 _minAmountOut,
        uint256 _minOutWhenSwap,
        bool _withdrawETH,
        uint40 _blockTime,
        IPositionManager.RequestStatus _status,
        uint256 _amountOut,
        uint256 _executionPrice,
        uint40 _processBlockTime
    ) {
        (
        ,
        _underlyingAssetIndex,
        _expiry,
        _optionTokenId,
        _size,
        _minAmountOut,
        _minOutWhenSwap,
        _withdrawETH,
        _blockTime,
        _status,
        _amountOut,
        _executionPrice,
        _processBlockTime
        ) = IPositionManager(positionManager).closePositionRequests(_requestKey);
    }

    /*
    * @dev get information about optionToken by id
    */
    function parseOptionTokenId(uint256 optionTokenId) public pure returns (
        uint16 underlyingAssetIndex, // 16 bits
        uint40 expiry, // 40 bits
        Utils.Strategy strategy, // 4 bits
        uint8 length, // 2 bit
        bool[4] memory isBuys, // 1 bit each
        uint48[4] memory strikePrices, // 46 bits each
        bool[4] memory isCalls, // 1 bit each
        uint8 sourceVaultIndex // 2 bits
    ) {
        return Utils.parseOptionTokenId(optionTokenId);
    }

    /*
    * @dev requests to open a position, which will be executed in another transaction.
    * Can check the status of this request using the getOpenPositionRequests function.
    * After the request is executed, you can call the claim function to receive tokens based on the result.
    */
    function createOpenPosition(
        uint16 _underlyingAssetIndex,
        uint8 _length,
        bool[4] memory _isBuys,
        bytes32[4] memory _optionIds,
        bool[4] memory _isCalls,
        uint256 _minSize,
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOutWhenSwap,
        address _leadTrader
    ) external payable returns (bytes32 _requestKey) {
        require(msg.value == IPositionManager(positionManager).executionFee(), "MobyRouter: Invalid fee");
        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(_path[0]).approve(controller, _amountIn);
        _requestKey = IPositionManager(positionManager).createOpenPosition{value: msg.value} (
            _underlyingAssetIndex,
            _length,
            _isBuys,
            _optionIds,
            _isCalls,
            _minSize,
            _path,
            _amountIn,
            _minOutWhenSwap,
            _leadTrader
        );

        requestKeyOwner[_requestKey] = msg.sender;
        requestKeyOf[msg.sender][requestKeyLength[msg.sender]] = _requestKey;
        requestKeyLength[msg.sender] += 1;
        isOpen[_requestKey] = true;
        receivingToken[_requestKey] = _path[0]; // refund
        emit OpenPositionCreated(msg.sender, _requestKey);
    }

    /*
    * @dev requests to close a position, which will be executed in another transaction.
    * Can check the status of this request using the getClosePositionRequests function.
    * After the request is executed, you can call the claim function to receive tokens based on the result.
    */
    function createClosePosition(
        uint16 _underlyingAssetIndex,
        uint256 _optionTokenId,
        uint256 _size,
        address[] memory _path,
        uint256 _minAmountOut,
        uint256 _minOutWhenSwap,
        bool _withdrawETH
    ) external payable returns (bytes32 _requestKey) {
        require(msg.value == IPositionManager(positionManager).executionFee(), "MobyRouter: Invalid fee");
        address optionsToken = IOptionsMarket(optionsMarket).getOptionsTokenByIndex(_underlyingAssetIndex);
        IOptionsToken(optionsToken).safeTransferFrom(msg.sender, address(this), _optionTokenId, _size, "");

        _requestKey =  IPositionManager(positionManager).createClosePosition{value: msg.value} (
            _underlyingAssetIndex,
            _optionTokenId,
            _size,
            _path,
            _minAmountOut,
            _minOutWhenSwap,
            _withdrawETH
        );
        requestKeyOwner[_requestKey] = msg.sender;
        requestKeyOf[msg.sender][requestKeyLength[msg.sender]] = _requestKey;
        requestKeyLength[msg.sender] += 1;
        isOpen[_requestKey] = false;
        receivingToken[_requestKey] = _path[_path.length - 1]; // payout
        emit ClosePositionCreated(msg.sender, _requestKey);
    }

    /*
    * @dev settle position after expiration
    */
    function settlePosition(
        address[] memory _path,
        uint16 _underlyingAssetIndex,
        uint256 _optionTokenId,
        uint256 _minOutWhenSwap,
        bool _withdrawETH
    ) external payable returns (uint256 _amountOut) {
        address optionsToken = IOptionsMarket(optionsMarket).getOptionsTokenByIndex(_underlyingAssetIndex);
        uint256 size = IERC1155Base(optionsToken).balanceOf(msg.sender, _optionTokenId);
        IOptionsToken(optionsToken).safeTransferFrom(msg.sender, address(this), _optionTokenId, size, "");

        _amountOut =  ISettleManager(settleManager).settlePosition(
            _path,
            _underlyingAssetIndex,
            _optionTokenId,
            _minOutWhenSwap,
            _withdrawETH
        );
        IERC20(_path[_path.length - 1]).safeTransfer(msg.sender, _amountOut);
        emit PositionSettled(msg.sender, _optionTokenId, size);
    }

    /*
    * @dev claim tokens after the request is executed
    * If the request is cancelled, the tokens that were paid will be refunded.
    * If the request is executed, the OptionToken(ERC1155) will be transferred to the user.
    * If the request for selling option is executed, the premium will be transferred to the user.
    * @param _requestKey request key recieved from createOpenPosition or createClosePosition
    * @return _isExecuted whether the request is executed (return false if the request is cancelled)
    */
    function claim(bytes32 _requestKey) external returns (bool _isExecuted) {
        if (isOpen[_requestKey]) {
            (
                uint16 underlyingAssetIndex,
                /* uint40 expiry */,
                uint256 optionTokenId,
                /* uint256 minSize */,
                uint256 amountIn,
                /* uint256 minOutWhenSwap */,
                /* bool isDepositedInETH */,
                /* uint40 blockTime */,
                IPositionManager.RequestStatus status,
                uint256 sizeOut,
                /* uint256 executionPrice */,
                /* uint40 processBlockTime */,
                uint256 amountOut
            ) = getOpenPositionRequests(_requestKey);
            require(requestKeyOwner[_requestKey] == msg.sender, "MobyRouter: Not owner");
            require(isClaimed[_requestKey] == false, "MobyRouter: Already claimed");
            if (status == IPositionManager.RequestStatus.Cancelled) {
                IERC20(receivingToken[_requestKey]).safeTransfer(msg.sender, amountIn); // If Cancelled, the tokens that were paid will be refunded.
                _isExecuted = false;
            } else if (status == IPositionManager.RequestStatus.Pending) {
                revert("MobyRouter: Not executed"); 
            } else {
                address optionsToken = IOptionsMarket(optionsMarket).getOptionsTokenByIndex(underlyingAssetIndex);
                IOptionsToken(optionsToken).safeTransferFrom(address(this), msg.sender, optionTokenId, sizeOut, "");
                address mainStableAsset = IOptionsMarket(optionsMarket).mainStableAsset();
                IERC20(mainStableAsset).safeTransfer(msg.sender, amountOut);
                _isExecuted = true;
            }
        } else {
            (
                uint16 underlyingAssetIndex,
                /* uint40 expiry */,
                uint256 optionTokenId,
                uint256 size,
                /* uint256 minAmountOut */,
                /* uint256 minOutWhenSwap */,
                /* bool withdrawETH */,
                /* uint40 blockTime */,
                IPositionManager.RequestStatus status,
                uint256 amountOut,
                /* uint256 executionPrice */,
                /* uint40 processBlockTime */
            ) = getClosePositionRequests(_requestKey);
            require(requestKeyOwner[_requestKey] == msg.sender, "MobyRouter: Not owner");
            require(isClaimed[_requestKey] == false, "MobyRouter: Already claimed");
            if (status == IPositionManager.RequestStatus.Cancelled) {
                address optionsToken = IOptionsMarket(optionsMarket).getOptionsTokenByIndex(underlyingAssetIndex);
                IOptionsToken(optionsToken).safeTransferFrom(address(this), msg.sender, optionTokenId, size, "");
                _isExecuted = false;
            } else if (status == IPositionManager.RequestStatus.Pending) {
                revert("MobyRouter: Not executed"); 
            } else {
                IERC20(receivingToken[_requestKey]).safeTransfer(msg.sender, amountOut);
                _isExecuted = true;
            }
        }            
        isClaimed[_requestKey] = true;
        emit Claimed(msg.sender, _requestKey);
    }



    /*
    * @dev Implement this functions to receive ERC1155 tokens.
    */
    function onERC1155Received(address /* operator */, address /* from */, uint256 /* id */, uint256 /* value */, bytes calldata /* data */) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address /* operator */, address /* from */, uint256[] calldata /* ids */, uint256[] calldata /* values */, bytes calldata /* data */) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
    
}
