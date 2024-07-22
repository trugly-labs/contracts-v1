/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {LibString} from "@solmate/utils/LibString.sol";
import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {ME20BaseTest} from "../base/ME20BaseTest.sol";
import {RouterBaseTest} from "../base/RouterBaseTest.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {MockTruglyFactory} from "../mock/MockTruglyFactory.sol";
import {MockTruglyFactoryNFT} from "../mock/MockTruglyFactoryNFT.sol";
import {Meme20AddressMiner} from "./Meme20AddressMiner.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {IUNCX_LiquidityLocker_UniV3} from "../../src/interfaces/external/IUNCX_LiquidityLocker_UniV3.sol";
import {TruglyStake} from "../../src/TruglyStake.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract DeployersME20 is Test, TestHelpers {
    using LibString for uint256;

    // Global variables
    ME20BaseTest memeceptionBaseTest;
    RouterBaseTest routerBaseTest;
    MEME20 memeToken;
    TruglyVesting vesting;
    TruglyStake truglyStake;
    MockTruglyFactory factory;
    address treasury = address(1);
    TruglyMemeception memeception;
    ISwapRouter swapRouter;
    IUNCX_LiquidityLocker_UniV3 uncxLocker;
    ITruglyMemeception.Memeception memeInfo;

    address public MULTISIG = makeAddr("multisig");
    address MEMECREATOR = makeAddr("creator");

    address WETH9 = Constant.BASE_WETH9;

    // Parameters
    ITruglyMemeception.MemeceptionCreationParams public createMemeParams = ITruglyMemeception.MemeceptionCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: 0,
        swapFeeBps: 80,
        vestingAllocBps: 1000,
        salt: "",
        creator: MEMECREATOR,
        targetETH: 10 ether,
        maxBuyETH: 1 ether
    });

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("base");
        vm.createSelectFork(rpc, 12490712);
        deployVesting();
        deployFactory();
        deployMemeception();
        deployUniversalRouter();

        memeception = memeceptionBaseTest.memeceptionContract();
        deployStake();
        // Base
        swapRouter = ISwapRouter(Constant.UNISWAP_BASE_SWAP_ROUTER);

        uncxLocker = IUNCX_LiquidityLocker_UniV3(Constant.UNCX_BASE_V3_LOCKERS);
    }

    function deployVesting() public virtual {
        vesting = new TruglyVesting();
    }

    function deployFactory() public virtual {
        MockTruglyFactoryNFT factoryNFT = new MockTruglyFactoryNFT();
        factory = new MockTruglyFactory(address(factoryNFT));
    }

    function deployMemeception() public virtual {
        memeceptionBaseTest = new ME20BaseTest(address(vesting), treasury, address(factory));
        vesting.setMemeception(address(memeceptionBaseTest.memeceptionContract()), true);
    }

    function deployStake() public virtual {
        truglyStake = new TruglyStake(address(memeception), MULTISIG);
    }

    function initCreateMeme() public virtual {
        address meme = createMeme(createMemeParams.symbol);
        memeToken = MEME20(meme);
    }

    function createMeme(string memory symbol) public virtual returns (address meme) {
        (address mineAddress, bytes32 salt) = Meme20AddressMiner.find(
            address(factory), Constant.BASE_WETH9, createMemeParams.name, symbol, address(memeception), MEMECREATOR
        );
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;
        createMemeParams.creator = MEMECREATOR;

        (meme,) = memeceptionBaseTest.createMeme(createMemeParams);
        assertEq(meme, mineAddress, "mine memeAddress");
        memeToken = MEME20(meme);
        memeInfo = memeception.getMemeception(meme);
    }

    function initBuyMemecoin(uint256 amount) public virtual {
        memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
    }

    function initBuyMemecoinFullCap() public virtual {
        uint256 buyAmountPerTx = createMemeParams.maxBuyETH;
        for (uint256 i = 0; i < 10; i++) {
            startHoax(makeAddr(i.toString()), buyAmountPerTx);
            initBuyMemecoin(buyAmountPerTx);
            vm.stopPrank();
        }
    }

    function deployUniversalRouter() public virtual {
        routerBaseTest = new RouterBaseTest();
    }

    /// @dev From this TX: https://basescan.org/tx/0x76967c6c9f233537748b1869fbcd42af3f21a214c0c789c2cc321efaec4b3f97
    function initSwapParams()
        public
        virtual
        returns (
            bytes memory commands,
            bytes[] memory inputs,
            uint256 deadline,
            uint256 amount,
            RouterBaseTest.ExpectedBalances memory expectedBalances
        )
    {
        commands = hex"0b000604";
        inputs = new bytes[](4);
        inputs[0] =
            hex"00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000060ea6ef2800";
        inputs[1] =
            hex"00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000060ea6ef28000000000000000000000000000000000000000000009f146bedda4cca154b7f7200000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002b4200000000000000000000000000000000000006000bb85dc3675d79c7d6291ac51ceda9f9a85aee0a060b000000000000000000000000000000000000000000";
        inputs[2] =
            hex"0000000000000000000000005dc3675d79c7d6291ac51ceda9f9a85aee0a060b0000000000000000000000000d37fc458b1c02649ed99c7238cd91ea797f34fd0000000000000000000000000000000000000000000000000000000000000064";
        inputs[3] =
            hex"0000000000000000000000005dc3675d79c7d6291ac51ceda9f9a85aee0a060b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000009f146bedda4cca154b7f72";
        deadline = 1811771053;

        amount = 0.00000666 ether;

        expectedBalances = RouterBaseTest.ExpectedBalances({
            token0: address(0),
            token1: 0x5Dc3675d79C7D6291aC51CeDa9F9a85Aee0a060B,
            creator: 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD,
            userDelta0: -int256(amount),
            userDelta1: 192_486_804.511889375963190096 ether,
            treasuryDelta0: 0,
            treasuryDelta1: 388_862.231337150254471091 ether,
            creatorDelta0: 0,
            creatorDelta1: 1_555_448.925348601017884364 ether
        });
    }

    function initSwapUniversalRouter() public {
        (
            bytes memory commands,
            bytes[] memory inputs,
            uint256 deadline,
            uint256 amount,
            RouterBaseTest.ExpectedBalances memory expectedBalances
        ) = initSwapParams();
        routerBaseTest.execute{value: amount}(commands, inputs, deadline, expectedBalances);
    }

    function initSwapFromSwapRouter(uint256 amountIn, address recipient) public {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: Constant.BASE_WETH9,
            tokenOut: address(memeToken),
            fee: Constant.UNI_LP_SWAPFEE,
            recipient: recipient,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // SqrtPrice for Auction step 24 (assuming we ended the auction at step 23)
            sqrtPriceLimitX96: 0
        });
        hoax(recipient, amountIn);
        swapRouter.exactInputSingle{value: amountIn}(params);
    }

    /// @notice receive native tokens
    receive() external payable {}
}
