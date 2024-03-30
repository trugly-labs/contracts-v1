/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract ExitTest is Deployers {
    error InvalidMemeceptionDate();
    error MemeLaunched();

    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBid(MAX_BID_AMOUNT);
    }

    function test_exit_success() public {
        vm.warp(createMemeParams.startAt + 1 days);
        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT);

        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_success_two_users() public {
        startHoax(makeAddr("alice"), MAX_BID_AMOUNT - 1);
        memeception.bid{value: MAX_BID_AMOUNT}(address(memeToken));

        vm.warp(createMemeParams.startAt + 3 hours);

        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT - 1);
        memeception.exit(address(memeToken));

        vm.stopPrank();

        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT);

        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_success_no_bid() public {
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), 0);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_memeception_not_ended() public {
        vm.warp(createMemeParams.startAt + 3 hours);
        vm.expectRevert(InvalidMemeceptionDate.selector);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_meme_launched() public {
        initFullBid(MAX_BID_AMOUNT);
        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.exit(address(memeToken));
    }

    function test_exit_fail_invalid_meme_address() public {
        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.exit(address(1));
    }
}
