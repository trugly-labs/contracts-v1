/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME404} from "../utils/DeployersME404.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract Exit404Test is DeployersME404 {
    error InvalidMemeceptionDate();
    error MemeLaunched();
    error InvalidMemeAddress();

    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initBid(MAX_BID_AMOUNT);
    }

    function test_exit_success() public {
        vm.warp(createMemeParams.startAt + memeception.auctionDuration());
        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT);

        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_success_two_users() public {
        startHoax(makeAddr("alice"), MAX_BID_AMOUNT - 1);
        memeception.bid{value: MAX_BID_AMOUNT - 1}(address(memeToken));

        vm.warp(createMemeParams.startAt + memeception.auctionDuration());

        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(makeAddr("alice")), MAX_BID_AMOUNT - 1);
        memeception.exit(address(memeToken));

        vm.stopPrank();

        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT);

        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_success_no_bid() public {
        vm.warp(createMemeParams.startAt + memeception.auctionDuration());
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), 0);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_memeception_not_ended() public {
        vm.warp(createMemeParams.startAt + memeception.auctionDuration() - 1);
        vm.expectRevert(InvalidMemeceptionDate.selector);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_meme_launched() public {
        vm.warp(createMemeParams.startAt + memeception.auctionDuration() - 1);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeception.bid{value: MAX_BID_AMOUNT}(address(memeToken));

        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_invalid_meme_address() public {
        vm.expectRevert(InvalidMemeAddress.selector);
        memeception.exit(address(1));
    }
}
