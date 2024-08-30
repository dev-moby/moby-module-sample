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
    mapping(bytes32 => address) public requestKeyOwner;
    mapping(bytes32 => bool) public isClaimed;
    mapping(bytes32 => bool) public isOpen;
    mapping(bytes32 => address) public receivingToken;
    mapping(address => uint256) public requestKeyLength; // check user's request index
    mapping(address => mapping (uint256 => bytes32)) public requestKeyOf; // requestKeyOf(user, index)

    event OpenPositionCreated(address indexed owner, bytes32 requestKey);
    event ClosePositionCreated(address indexed owner, bytes32 requestKey);
    event Claimed(address indexed account, bytes32 requestKey);
    event PositionSettled(address indexed account, uint256 indexed optionTokenId, uint256 size);

    function initilize(address _positionManager, address _settleManager) external initializer {
        __Ownable2Step_init();
        positionManager = _positionManager;
        settleManager = _settleManager;
        controller = IPositionManager(positionManager).controller();
        optionsMarket = IPositionManager(positionManager).optionsMarket();
    }

    function executionFee() public view returns (uint256) {
        return IPositionManager(positionManager).executionFee();
    }

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
        receivingToken[_requestKey] = _path[_path.length - 1];
        emit ClosePositionCreated(msg.sender, _requestKey);
    }

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

    function claim(bytes32 _requestKey) external returns (bool _isExecuted){
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
                IERC20(receivingToken[_requestKey]).safeTransfer(msg.sender, amountIn);
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



    // IERC1155Receiver
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
