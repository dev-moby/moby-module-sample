// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract AddressBook {
    struct AddressSet {
        address WBTC;
        address WETH;
        address USDC;
        address OPTIONS_AUTHORITY;
        address VAULT_PRICE_FEED;
        address OPTIONS_MARKET;
        address S_VAULT;
        address M_VAULT;
        address L_VAULT;
        address S_VAULT_UTILS;
        address M_VAULT_UTILS;
        address L_VAULT_UTILS;
        address S_USDG;
        address M_USDG;
        address L_USDG;
        address S_OLP;
        address M_OLP;
        address L_OLP;
        address S_OLP_MANAGER;
        address M_OLP_MANAGER;
        address L_OLP_MANAGER;
        address S_REWARD_TRACKER;
        address M_REWARD_TRACKER;
        address L_REWARD_TRACKER;
        address S_REWARD_DISTRIBUTOR;
        address M_REWARD_DISTRIBUTOR;
        address L_REWARD_DISTRIBUTOR;
        address S_REWARD_ROUTER_V2;
        address M_REWARD_ROUTER_V2;
        address L_REWARD_ROUTER_V2;
        address CONTROLLER;
        address POSITION_MANAGER;
        address SETTLE_MANAGER;
        address FEE_DISTRIBUTOR;
        address BTC_OPTIONS_TOKEN;
        address ETH_OPTIONS_TOKEN;
        address FAST_PRICE_EVENTS;
        address FAST_PRICE_FEED;
        address POSITION_VALUE_FEED;
        address SETTLE_PRICE_FEED;
        address SPOT_PRICE_FEED;
        address VIEW_AGGREGATOR;
        address REFERRAL;
    }
    uint256 constant internal _ARBITRUM_ONE_CHAIN_ID = 42161;
    uint256 constant internal _ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant internal _BERACHAIN_BARTIO_CHAIN_ID = 80084;

    mapping(uint256 => AddressSet) public addressBook;
    
    function getAddressBook(uint256 chainId) public pure returns (AddressSet memory) {
        if (chainId == _ARBITRUM_ONE_CHAIN_ID) {
            return AddressSet(
                {
                    WBTC: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
                    WETH: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                    USDC: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
                    OPTIONS_AUTHORITY: 0x1c806266d47F209C23Ed2De9521011521f7aF06e,
                    VAULT_PRICE_FEED: 0x38c0bD72883feCbA5B7552493f64edd87988483c,
                    OPTIONS_MARKET: 0x216309646F9BD99c73eF05bDc5d2e97F5AE34f73,
                    S_VAULT: 0xd4D23332E6256B751E2Da0B9C0b3a70CFe9180C0,
                    M_VAULT: 0x9e34F79E39AddB64f4874203066fFDdD6Ab63a41,
                    L_VAULT: 0x3B22F749f082bC33Af33751cBD53d21215FC71d1,
                    S_VAULT_UTILS: 0x79D4379A407134096BcB982bA00af2372824f666,
                    M_VAULT_UTILS: 0xC104f87c785BF2B37B80355deb6a6569280c50b5,
                    L_VAULT_UTILS: 0xd401FDF32DB28FA1311A0F67bA81Ec96fBA37ab9,
                    S_USDG: 0x983C43F02A42Be6F4C279Ea29E561eC353F24Ab1,
                    M_USDG: 0xE93224a9819cB9E093f3c5B68Cf62eb677e05929,
                    L_USDG: 0x1a2Ba92F072EFD2E3c775330A16a8848aD75099b,
                    S_OLP: 0x07CfB9eBF06511862f3ad60A9513b4a8f33E6FA5,
                    M_OLP: 0xf0C531D488C12B723B41a7DE9B642323bF45771B,
                    L_OLP: 0xCa5d0b01dB5882b9d9729f3755FaF4265a1479a9,
                    S_OLP_MANAGER: 0x986B713fC57d653D29C57f23077E67eBe160a132,
                    M_OLP_MANAGER: 0x870daa37233be5624CEf865f56BE9326256a5b0e,
                    L_OLP_MANAGER: 0xAcd395FEc94D7EDdcA108892cD1FDDEBb8092ec8,
                    S_REWARD_TRACKER: 0xDb6F4AA12Ac37332CFb02df2B795550a38A44b9c,
                    M_REWARD_TRACKER: 0xB6F4c1Fe04D7539F1128c17c3D1FcfA6a169F2Ed,
                    L_REWARD_TRACKER: 0xBCfF6c30DbE7b6Ea198fFb3aE2A4DbE2Fbd5B4D4,
                    S_REWARD_DISTRIBUTOR: 0x11ea09203c42185294AaED6ae1fC5DD4ecfDE766,
                    M_REWARD_DISTRIBUTOR: 0xc0C8239CB08B8EFE2F7b4B2E154Ce334a09062d6,
                    L_REWARD_DISTRIBUTOR: 0xE2f3a0eb2f965B238891eD4b968B3ec864526731,
                    S_REWARD_ROUTER_V2: 0x64e1faFA9e9d5F1a7431B886F5Fbff4052c5925d,
                    M_REWARD_ROUTER_V2: 0x6881E756EA3322AEAadE0267C2a7FcF2A887ee9A,
                    L_REWARD_ROUTER_V2: 0x4D55eC6488B151AB42753A17730106A6D97C4dd3,
                    CONTROLLER: 0x46FA90cAbeCeA5369F5Ca9466655277EcA36b574,
                    POSITION_MANAGER: 0xB03E14Eeb1a4B2F95a7e1CBe400BAec3E78d2a1F,
                    SETTLE_MANAGER: 0xA62027C5edc68Abc52D3a3BbDd213Fa12457320B,
                    FEE_DISTRIBUTOR: 0x6C68831e2598a7C6a2dbedc7423197133364F8c9,
                    BTC_OPTIONS_TOKEN: 0xe8A06f2dD300F81dC4673595BEAd86b1f316ad14,
                    ETH_OPTIONS_TOKEN: 0xAdd22197FC76ac9B7CaE0bc6DA090a4809B2801E,
                    FAST_PRICE_EVENTS: 0x3B261D7b407d542D226e94bca95DB52fAc4695a3,
                    FAST_PRICE_FEED: 0xf77472c99AaBCDCf30412bf5c6E763deCDE49165,
                    POSITION_VALUE_FEED: 0x4c16E62D93Aa82876BC4478C74BAe48EaAEFe6A1,
                    SETTLE_PRICE_FEED: 0x136937B91EA2635b94fecfAD44189aFeDd39f0AE,
                    SPOT_PRICE_FEED: 0xeaa3BE0f53B780654e91e32CAC94c3625C58FE75,
                    VIEW_AGGREGATOR: 0x6D4705507CeEbE28367392b04C43516b119E9864,
                    REFERRAL: 0x501D8F3cCba3D471A71a5c479eAaF42A7aA57ac8
                }
            );
        } else if (chainId == _ARBITRUM_SEPOLIA_CHAIN_ID) {
            return AddressSet(
                {
                    WBTC: 0x7f908D0faC9B8D590178bA073a053493A1D0A5d4,
                    WETH: 0xc556bAe1e86B2aE9c22eA5E036b07E55E7596074,
                    USDC: 0x1459F5c7FC539F42ffd0c63A0e4AD000dfF70919,
                    OPTIONS_AUTHORITY: 0x1cA8a02ad7D36848524F86A0558813B5Be39cF55,
                    VAULT_PRICE_FEED: 0x0f80775eDEC46Cd687d83d7AeABba45106BAC56b,
                    OPTIONS_MARKET: 0xe9135D6F772a22cB6584BC39c8081F40aA3a24B9,
                    S_VAULT: 0x18C34A7Db31Ed648A7665e5Fb9D167967362E8c1,
                    M_VAULT: 0x624a4d0b1bd542c3751040f42dE4beD6Dc3d5329,
                    L_VAULT: 0xbc08aC2f8Fae2f2ccAe93F9a8a31041208A31301,
                    S_VAULT_UTILS: 0xAa262bC7099aFE3eF5F59818981396F200645CF0,
                    M_VAULT_UTILS: 0x8B122e24B8Da75697eCec6BFeDA1888b41bFc465,
                    L_VAULT_UTILS: 0x084E7016D35f474FbD3A981A507b842d9fB5FeEa,
                    S_USDG: 0x4f036BEf9b5103D6497749E5C2378eCbA77C15e9,
                    M_USDG: 0x259500DC6FDb2Ce2cf510867BB3557205575E508,
                    L_USDG: 0x825Dec8FF2c832F5b5B1F6942583f1c422F2BB00,
                    S_OLP: 0xEbFCc94f552f73a21c691860DD586C5033BF59ac,
                    M_OLP: 0x93b29879f0B962d3A655Dbcc788b2b32848F91e3,
                    L_OLP: 0xD2660D4F6E30A4dA739B51CEdD33F6404405C421,
                    S_OLP_MANAGER: 0x2860d641aC5C8447Be9B6aDE6B2A119be36Ac34b,
                    M_OLP_MANAGER: 0xa0C28c7d27979D14928936508CB4707fae6831a8,
                    L_OLP_MANAGER: 0xd9084eD62d86f5E25b62834EaC4EA9a280567DC5,
                    S_REWARD_TRACKER: 0x1710FbCd5F40e39fC42F0740A9337C648661b493,
                    M_REWARD_TRACKER: 0x188534f84DbA45F31110e17152d316A3fcda43ED,
                    L_REWARD_TRACKER: 0x77215cfad85329F06226EF18DFcB47387DbE43db,
                    S_REWARD_DISTRIBUTOR: 0xFC23D2A9Ee57B9bfFaFF83Ad72DFb297AAa59919,
                    M_REWARD_DISTRIBUTOR: 0xcb5176552d17eBA3E0B8efD9C4F31e05Be6e002b,
                    L_REWARD_DISTRIBUTOR: 0x882412Ba5c79b1F0d2fB2225a292071e0C072248,
                    S_REWARD_ROUTER_V2: 0x215A8dec241660534f38E0e0cc1139a9B6Ed9f82,
                    M_REWARD_ROUTER_V2: 0x8473e07325e19D35160f7962B713bAa02cAf6741,
                    L_REWARD_ROUTER_V2: 0x6A513B7Ab3e5c37a1E1BE706d3f095129746B46e,
                    CONTROLLER: 0xEe9A9de1D11d59Ceb61671BeF5830e2AAd69fc57,
                    POSITION_MANAGER: 0xdA3D966384Aac23f4A912A1C77bd91A674666a8F,
                    SETTLE_MANAGER: 0xF5eDC9fFAf45eEFa0808D26097ED7440fEB96C71,
                    FEE_DISTRIBUTOR: 0x141c476c76445cC62e73c0d366Fa217f481939ce,
                    BTC_OPTIONS_TOKEN: 0x7eec5C6Cd2C2b134d39664A910335Da3E9A045Ef,
                    ETH_OPTIONS_TOKEN: 0x87b379Df9bE273B1B8F06870bFC1f162D37683Dc,
                    FAST_PRICE_EVENTS: 0x682b7d4389Cc018a8e9651A1185d6ca0Cc220f21,
                    FAST_PRICE_FEED: 0x6Ff1D50448199e842De9d650CE990ae259F7C7aA,
                    POSITION_VALUE_FEED: 0xAb4Ca38857936F0693354c8b95E3aD933844bb03,
                    SETTLE_PRICE_FEED: 0x0AB1E640c7Fcb371bE1b687e605449D5718a02D1,
                    SPOT_PRICE_FEED: 0xbFe0e9ce401141e5f1898de6fa02ecDE91420585,
                    VIEW_AGGREGATOR: 0x6E1652D70078d2572564be74dA6fEbad389C5927,
                    REFERRAL: 0x87AeD0608bC4f9C71FE0F68B4470d4059229ab42
                }
            );
        } else if (chainId == _BERACHAIN_BARTIO_CHAIN_ID) {
            return AddressSet(
                {
                    WBTC: 0x2577D24a26f8FA19c1058a8b0106E2c7303454a4,
                    WETH: 0xE28AfD8c634946833e89ee3F122C06d7C537E8A8,
                    USDC: 0xd6D83aF58a19Cd14eF3CF6fe848C9A4d21e5727c,
                    OPTIONS_AUTHORITY: 0x428642F2deC312175a5ad564f9A51A0D3736D0f3,
                    VAULT_PRICE_FEED: 0xa65fb1e29B770dA20f2afd7Ac3930EEcc67F132C,
                    OPTIONS_MARKET: 0x798996410c7d14b8D51614A3De13AcD2A579efFb,
                    S_VAULT: 0x7f908D0faC9B8D590178bA073a053493A1D0A5d4,
                    M_VAULT: 0xc556bAe1e86B2aE9c22eA5E036b07E55E7596074,
                    L_VAULT: 0x1459F5c7FC539F42ffd0c63A0e4AD000dfF70919,
                    S_VAULT_UTILS: 0x50599966F4aF26B29a563Ab70b95B7Fb69D49b67,
                    M_VAULT_UTILS: 0x1F2843EF34749824a51F47B57F51C06cd588e7F0,
                    L_VAULT_UTILS: 0x61d75f1f879153e064d11E1bF047802e8af99cab,
                    S_USDG: 0x38E2bD95c9fc0179c36c0798Ac6556bF2b14BB02,
                    M_USDG: 0xCb5212B68776AF5E885fBE0Fb6E93974549d4942,
                    L_USDG: 0x4186F8868048935A7766714804b843B297c223Ea,
                    S_OLP: 0x7B1efA40708DA01c3a70f5d6E836B2A22dF1619b,
                    M_OLP: 0x98b2311DEaAAe72A19e882f9E6b231713533248f,
                    L_OLP: 0x49684cdcb19fCd2B84497108eC01991241464276,
                    S_OLP_MANAGER: 0xB71Be70Bb0EE3c5b20e7205E11497Abddd7c4a72,
                    M_OLP_MANAGER: 0xC91DAA8B41B6389dB4114a4BE1C77143A8708FA8,
                    L_OLP_MANAGER: 0xEC04F69cec0b9E56d50209c19B8bD7ec464fE062,
                    S_REWARD_TRACKER: 0xcFa0Ca5bFf1C13E0631ED0d78074BB60627b6304,
                    M_REWARD_TRACKER: 0xFefBcB29bD747390543aF96b1209249A4D0F05Dd,
                    L_REWARD_TRACKER: 0xe3Df0af7245B3CaA8f67Cc6968AbB9450001e90b,
                    S_REWARD_DISTRIBUTOR: 0x87d2Bc496068d78F3F614c9424334C678311ED31,
                    M_REWARD_DISTRIBUTOR: 0x6e00a72b53Cb52141C49fB13Aa9f3a14a7B1307C,
                    L_REWARD_DISTRIBUTOR: 0xc8635ab7cB28206AA6d33dCDaD876e05DB771a76,
                    S_REWARD_ROUTER_V2: 0x169Fc6c6c7ED89B8100C85E5a22662F7DAe32177,
                    M_REWARD_ROUTER_V2: 0x3772984adD362e92b6AEa095F7bdd9FD9Eb6073F,
                    L_REWARD_ROUTER_V2: 0x4BAb3934C80eaee82Bd78e80f3557d836ECb8Bd8,
                    CONTROLLER: 0x13707339fCaf422Cc60366928DD3ca1eB013b1e2,
                    POSITION_MANAGER: 0x6861dB8E5CF2c33b207B6BDf0c89204A05734930,
                    SETTLE_MANAGER: 0x3E75690B3f36Bb1FAf441C604A029B9EF8B1e1AF,
                    FEE_DISTRIBUTOR: 0xBF2e8DCFaf5E5a47FdED03a20EBC60551f0C6FD3,
                    BTC_OPTIONS_TOKEN: 0x5032ab062a3Ec1510ff327A73b78B8539621fB7B,
                    ETH_OPTIONS_TOKEN: 0xd88457dBAE6B447E66692e3Da741A0260f8622dB,
                    FAST_PRICE_EVENTS: 0x29d99B1F12E55f92D4b15fB5eE8375E586990AAD,
                    FAST_PRICE_FEED: 0x5Dc73DfD1b60f0CF9e8B8c57B09bB796C045EE3E,
                    POSITION_VALUE_FEED: 0x590896a6eFfCa7857696E2E7f027B30C35ca0Ef7,
                    SETTLE_PRICE_FEED: 0x2444Df6311596735770eEB41D15b82A1B4bFDC38,
                    SPOT_PRICE_FEED: 0xb8bBD05803d2d169A88439364CD7F6D7F96eb277,
                    VIEW_AGGREGATOR: 0x10c0D06f474F4cC9f2e1E4467B23A54B9D34E36b,
                    REFERRAL: 0x198864A20Bfb092549B3e7Ee9AA76E4978aAFcd6
                }
            );
        } else {
            return AddressSet(
                {
                    WBTC: address(0),
                    WETH: address(0),
                    USDC: address(0),
                    OPTIONS_AUTHORITY: address(0),
                    VAULT_PRICE_FEED: address(0),
                    OPTIONS_MARKET: address(0),
                    S_VAULT: address(0),
                    M_VAULT: address(0),
                    L_VAULT: address(0),
                    S_VAULT_UTILS: address(0),
                    M_VAULT_UTILS: address(0),
                    L_VAULT_UTILS: address(0),
                    S_USDG: address(0),
                    M_USDG: address(0),
                    L_USDG: address(0),
                    S_OLP: address(0),
                    M_OLP: address(0),
                    L_OLP: address(0),
                    S_OLP_MANAGER: address(0),
                    M_OLP_MANAGER: address(0),
                    L_OLP_MANAGER: address(0),
                    S_REWARD_TRACKER: address(0),
                    M_REWARD_TRACKER: address(0),
                    L_REWARD_TRACKER: address(0),
                    S_REWARD_DISTRIBUTOR: address(0),
                    M_REWARD_DISTRIBUTOR: address(0),
                    L_REWARD_DISTRIBUTOR: address(0),
                    S_REWARD_ROUTER_V2: address(0),
                    M_REWARD_ROUTER_V2: address(0),
                    L_REWARD_ROUTER_V2: address(0),
                    CONTROLLER: address(0),
                    POSITION_MANAGER: address(0),
                    SETTLE_MANAGER: address(0),
                    FEE_DISTRIBUTOR: address(0),
                    BTC_OPTIONS_TOKEN: address(0),
                    ETH_OPTIONS_TOKEN: address(0),
                    FAST_PRICE_EVENTS: address(0),
                    FAST_PRICE_FEED: address(0),
                    POSITION_VALUE_FEED: address(0),
                    SETTLE_PRICE_FEED: address(0),
                    SPOT_PRICE_FEED: address(0),
                    VIEW_AGGREGATOR: address(0),
                    REFERRAL: address(0)
                }
            );
        }
    }
}
