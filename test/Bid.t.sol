/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";
import {MEMERC20Constant} from "../src/libraries/MEMERC20Constant.sol";
import {AuctionTestData} from "./utils/AuctionTestData.sol";
import {TruglyMemeception} from "../src/TruglyMemeception.sol";
import {LibString} from "@solady/utils/LibString.sol";

contract BidTest is Deployers, AuctionTestData {
    error MemeLaunched();
    error DuplicateOG();
    error ZeroAmount();
    error BidAmountTooHigh();
    error MemeceptionEnded();
    error MemeceptionNotStarted();

    event MemeceptionBid(address indexed memeToken, address indexed og, uint256 amountETH, uint256 amountMeme);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        vm.warp(createMemeParams.startAt + 1 seconds);
    }

    function test_bid_success() public {
        uint256 amount = 1 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, 1976284584980237154150197);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_capReached_success() public {
        vm.warp(createMemeParams.startAt + 115 minutes);

        uint256 amount = 9.999999999 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, Constant.TOKEN_MEMECEPTION_SUPPLY);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_capReached_over_success() public {
        vm.warp(createMemeParams.startAt + 110 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeceptionBaseTest.memeceptionContract().bid{value: MAX_BID_AMOUNT}(address(memeToken));

        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT, 4.44444444e26);

        memeceptionBaseTest.bid{value: MAX_BID_AMOUNT}(address(memeToken));
    }

    function test_bid_all_auction_success() public {
        memeceptionBaseTest.setAuctionDuration(Constant.MAX_AUCTION_DURATION);
        for (uint256 i = 0; i <= 35; i++) {
            console2.log("i", i);
            address memeToken = createMeme(LibString.toString(i));
            uint256 timeNow = memeceptionBaseTest.memeceptionContract().getMemeception(memeToken).startAt
                + i * Constant.AUCTION_PRICE_DECAY_PERIOD;
            vm.warp(timeNow);
            (uint256 ethAuctionBal, uint256 numberMaxBids) =
                getAuctionData(memeceptionBaseTest.memeceptionContract().getMemeception(memeToken).startAt);

            // Loop to bid max-1 times
            while (numberMaxBids-- > 1) {
                startHoax(makeAddr(LibString.toString(i * 100 + numberMaxBids)), MAX_BID_AMOUNT);
                memeceptionBaseTest.memeceptionContract().bid{value: MAX_BID_AMOUNT}(memeToken);
                vm.stopPrank();
            }

            // Final bid triggering the launch of the LP
            uint256 amount = MAX_BID_AMOUNT;
            vm.expectEmit(true, true, false, false);
            emit MemeceptionBid(memeToken, address(memeceptionBaseTest), amount, 0);

            memeceptionBaseTest.bid{value: amount}(memeToken);

            assertApproxEqLow(
                ethAuctionBal,
                ERC20(WETH9).balanceOf(memeceptionBaseTest.memeceptionContract().getMemeception(memeToken).pool),
                0.00000001e18,
                "Liquidity Added must not be greater than auction balance (WETH)"
            );

            assertApproxEqLow(
                MEMERC20Constant.TOKEN_TOTAL_SUPPLY * (10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS) / 10000
                    - Constant.TOKEN_MEMECEPTION_SUPPLY,
                ERC20(memeToken).balanceOf(memeceptionBaseTest.memeceptionContract().getMemeception(memeToken).pool),
                0.00000001e18,
                "Liquidity Added must be equal to auction balance (MEMERC20)"
            );
        }
    }

    function test_bid_fail_zero_amount() public {
        vm.expectRevert(ZeroAmount.selector);
        memeceptionBaseTest.bid{value: 0}(address(memeToken));
    }

    function test_bid_fail_max_bid() public {
        vm.expectRevert(BidAmountTooHigh.selector);
        memeceptionBaseTest.bid{value: MAX_BID_AMOUNT + 1}(address(memeToken));
    }

    function test_bid_fail_memeception_not_started() public {
        vm.warp(createMemeParams.startAt - 1 seconds);
        vm.expectRevert(MemeceptionNotStarted.selector);
        memeception.bid{value: 1 ether}(address(memeToken));
    }

    function test_bid_fail_memeception_ended() public {
        vm.warp(createMemeParams.startAt + 120 minutes);
        vm.expectRevert(MemeceptionEnded.selector);
        memeception.bid{value: 1 ether}(address(memeToken));
    }

    function test_bid_fail_duplicate_og() public {
        memeceptionBaseTest.bid{value: 1 ether}(address(memeToken));
        vm.expectRevert(DuplicateOG.selector);
        memeceptionBaseTest.bid{value: 1 ether}(address(memeToken));
    }

    function test_bid_fail_meme_launched() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeceptionBaseTest.bid{value: MAX_BID_AMOUNT}(address(memeToken));

        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.bid{value: 1 ether}(address(memeToken));
    }

    function test_bid_fail_unknown_meme() public {
        vm.expectRevert();
        memeceptionBaseTest.bid{value: 1 ether}(address(1));
    }
}
