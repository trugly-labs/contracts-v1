/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";

contract SetAuctionDuration is Deployers {
    error InvalidAuctionDuration();
    /// @dev Emited when the treasury is updated

    /// @dev Emited when the auction duration is updated
    event AuctionDurationUpdated(uint256 oldDuration, uint256 newDuration);

    function test_setAuctionDuration_success() public {
        vm.expectEmit(true, true, false, true);
        emit AuctionDurationUpdated(Constant.MIN_AUCTION_DURATION, Constant.MIN_AUCTION_DURATION + 1);
        memeceptionBaseTest.setAuctionDuration(Constant.MIN_AUCTION_DURATION + 1);
    }

    function test_setAuctionDuration_fail_not_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        hoax(makeAddr("alice"));
        memeception.setAuctionDuration(Constant.MIN_AUCTION_DURATION + 1);
    }

    function test_setAuctionDuration_fail_zero() public {
        vm.expectRevert(InvalidAuctionDuration.selector);
        memeceptionBaseTest.setAuctionDuration(0);
    }

    function test_setAuctionDuration_fail_below_min() public {
        vm.expectRevert(InvalidAuctionDuration.selector);
        memeceptionBaseTest.setAuctionDuration(Constant.MIN_AUCTION_DURATION - 1);
    }

    function test_setAuctionDuration_fail_above_max() public {
        vm.expectRevert(InvalidAuctionDuration.selector);
        memeceptionBaseTest.setAuctionDuration(Constant.MAX_AUCTION_DURATION + 1);
    }
}
