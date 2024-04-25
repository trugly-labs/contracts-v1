/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {MemeceptionBaseTest} from "../../src/test/MemeceptionBaseTest.sol";
import {RouterBaseTest} from "../../src/test/RouterBaseTest.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {MemeAddressMiner} from "./MemeAddressMiner.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SqrtPriceX96} from "../../src/libraries/SqrtPriceX96.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Deployers is Test, TestHelpers, BaseParameters {
    // Global variables
    MemeceptionBaseTest memeceptionBaseTest;
    RouterBaseTest routerBaseTest;
    MEMERC20 memeToken;
    TruglyVesting vesting;
    address treasury = address(1);
    TruglyMemeception memeception;
    ISwapRouter swapRouter;

    uint256 public constant MAX_BID_AMOUNT = 10 ether;

    // Parameters
    ITruglyMemeception.MemeceptionCreationParams public createMemeParams = ITruglyMemeception.MemeceptionCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: uint40(block.timestamp + 3 days),
        swapFeeBps: 80,
        vestingAllocBps: 500,
        salt: "",
        creator: address(this)
    });

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("base");
        vm.createSelectFork(rpc, 12490712);
        deployVesting();
        deployMemeception();
        deployUniversalRouter();

        memeception = memeceptionBaseTest.memeceptionContract();
        // Base
        swapRouter = ISwapRouter(0x2626664c2603336E57B271c5C0b26F421741e481);
    }

    function deployVesting() public virtual {
        vesting = new TruglyVesting();
    }

    function deployMemeception() public virtual {
        memeceptionBaseTest = new MemeceptionBaseTest(address(vesting), treasury);
        vesting.setMemeception(address(memeceptionBaseTest.memeceptionContract()), true);
    }

    function initCreateMeme() public virtual {
        address meme = createMeme(createMemeParams.symbol);
        memeToken = MEMERC20(meme);
    }

    function createMeme(string memory symbol) public virtual returns (address meme) {
        uint40 startAt = uint40(block.timestamp + 3 days);
        (, bytes32 salt) = MemeAddressMiner.find(
            address(memeceptionBaseTest.memeceptionContract()),
            WETH9,
            createMemeParams.name,
            symbol,
            address(memeceptionBaseTest)
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;

        (meme,) = memeceptionBaseTest.createMeme(createMemeParams);
        memeToken = MEMERC20(meme);
    }

    function initBid(uint256 amount) public virtual {
        vm.warp(createMemeParams.startAt);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function initFullBid(uint256 lastBidAmount) public virtual {
        vm.warp(createMemeParams.startAt + Constant.MIN_AUCTION_DURATION - 1.5 minutes);

        memeceptionBaseTest.bid{value: lastBidAmount}(address(memeToken));
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

    function initSwapFromSwapRouter() public {
        uint256 amountIn = 0.01 ether;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: address(memeToken),
            fee: Constant.UNI_LP_SWAPFEE,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: 0,
            // SqrtPrice for Auction step 24 (assuming we ended the auction at step 23)
            sqrtPriceLimitX96: 0
        });
        swapRouter.exactInputSingle{value: amountIn}(params);
    }
}
