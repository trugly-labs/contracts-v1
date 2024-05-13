/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {ME404BaseTest} from "../../src/test/ME404BaseTest.sol";
import {RouterBaseTest} from "../../src/test/RouterBaseTest.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {Meme404AddressMiner} from "./Meme404AddressMiner.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {IUNCX_LiquidityLocker_UniV3} from "../../src/interfaces/external/IUNCX_LiquidityLocker_UniV3.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract DeployersME404 is Test, TestHelpers, BaseParameters {
    // Global variables
    ME404BaseTest memeceptionBaseTest;
    RouterBaseTest routerBaseTest;
    MEME404 memeToken;
    TruglyVesting vesting;
    address treasury = address(1);
    TruglyMemeception memeception;
    ISwapRouter swapRouter;
    IUNCX_LiquidityLocker_UniV3 uncxLocker;

    address MEMECREATOR = makeAddr("creator");
    uint256 public constant MAX_BID_AMOUNT = 10 ether;

    // Parameters
    ITruglyMemeception.MemeceptionCreationParams public createMemeParams = ITruglyMemeception.MemeceptionCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: uint40(block.timestamp + 3 days),
        swapFeeBps: 80,
        vestingAllocBps: 100,
        salt: "",
        creator: MEMECREATOR
    });

    // Tier Parameters
    MEME404.TierCreateParam[] public tierParams;

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("base");
        vm.createSelectFork(rpc, 12490712);

        _initTierParams();
        deployVesting();
        deployMemeception();
        deployUniversalRouter();

        memeception = memeceptionBaseTest.memeceptionContract();
        // Base
        swapRouter = ISwapRouter(SWAP_ROUTER);

        uncxLocker = IUNCX_LiquidityLocker_UniV3(UNCX_V3_LOCKERS);
    }

    function deployVesting() public virtual {
        vesting = new TruglyVesting();
    }

    function deployMemeception() public virtual {
        memeceptionBaseTest = new ME404BaseTest(address(vesting), treasury);
        vesting.setMemeception(address(memeceptionBaseTest.memeceptionContract()), true);
    }

    function initCreateMeme404() public virtual {
        address meme = createMeme404(createMemeParams.symbol);
        memeToken = MEME404(meme);
    }

    function createMeme404(string memory symbol) public virtual returns (address meme) {
        uint40 startAt = uint40(block.timestamp + 3 days);
        (address mineAddress, bytes32 salt) = Meme404AddressMiner.find(
            address(memeceptionBaseTest.memeceptionContract()), WETH9, createMemeParams.name, symbol, MEMECREATOR
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;
        createMemeParams.creator = MEMECREATOR;

        (meme,) = memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
        assertEq(meme, mineAddress, "mine memeAddress");
        memeToken = MEME404(meme);
    }

    function initBid(uint256 amount) public virtual {
        vm.warp(createMemeParams.startAt);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function initFullBid(uint256 lastBidAmount) public virtual {
        vm.warp(createMemeParams.startAt + memeception.auctionDuration() - 1);

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

    function initSwapFromSwapRouter(uint256 amountIn, address recipient) public {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
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

    function getNormalNFTCollection() public view returns (address) {
        return memeToken.getTier(0).nft;
    }

    function getEliteNFTCollection() public view returns (address) {
        return memeToken.getTier(tierParams.length - 1).nft;
    }

    function _initTierParams() internal {
        /// Fungible Tiers
        tierParams.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 1, 0, 1, 1, true));
        tierParams.push(
            MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 222222 ether, 0, 2, 2, true)
        );
        tierParams.push(
            MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 444444 ether, 0, 3, 3, true)
        );
        tierParams.push(
            MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 666666 ether, 0, 4, 4, true)
        );
        tierParams.push(
            MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 888888 ether, 0, 5, 5, true)
        );
        tierParams.push(
            MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 2222222 ether, 0, 6, 6, true)
        );

        /// Non Fungible Tiers
        tierParams.push(
            MEME404.TierCreateParam("https://elite.com/", "Elite NFT", "ELITE", 4444444 ether, 1, 1, 2000, false)
        );
        tierParams.push(
            MEME404.TierCreateParam("https://elite.com/", "Elite NFT", "ELITE", 88888888 ether, 1, 2001, 2101, false)
        );
    }
}
