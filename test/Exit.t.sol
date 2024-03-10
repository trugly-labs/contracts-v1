/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract ExitTest is Deployers {
    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 amount);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBid(MAX_BID_AMOUNT);

        vm.warp(createMemeParams.startAt + 4 days);
    }

    function test_exit_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), MAX_BID_AMOUNT);

        memeceptionBaseTest.exit(address(memeToken));
    }
}
