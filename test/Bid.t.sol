/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";
import {MEMERC20Constant} from "../src/libraries/MEMERC20Constant.sol";
import {AuctionTestData} from "./utils/AuctionTestData.sol";
import {LibString} from "@solady/utils/LibString.sol";

contract BidTest is Deployers, AuctionTestData {
    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionBid(address indexed memeToken, address indexed og, uint256 amountETH, uint256 amountMeme);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_bid_success() public {
        vm.warp(createMemeParams.startAt + 1 seconds);
        uint256 amount = 1 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, 1e28);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_capReached_success() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeceptionBaseTest.memeceptionContract().bid{value: MAX_BID_AMOUNT}(address(memeToken));

        uint256 amount = 1.9535 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, 891705069124423963133640552996);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_capReached_over_success() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeceptionBaseTest.memeceptionContract().bid{value: MAX_BID_AMOUNT}(address(memeToken));

        uint256 amount = MAX_BID_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, 891705069124423963133640552996);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_all_auction_success() public {
        for (uint256 i = 0; i <= 23; i++) {
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
                MEMERC20Constant.TOKEN_TOTAL_SUPPLY * 9500 / 10000 - Constant.TOKEN_MEMECEPTION_SUPPLY,
                ERC20(memeToken).balanceOf(memeceptionBaseTest.memeceptionContract().getMemeception(memeToken).pool),
                0.00000001e18,
                "Liquidity Added must be equal to auction balance (MEMERC20)"
            );
        }
    }
}
