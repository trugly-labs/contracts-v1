/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract ExitTest is Deployers {
    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 amount);

    uint256 internal constant bidAmount = 50 ether;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBid(bidAmount);

        vm.warp(block.timestamp + 7 days);
    }

    function test_exit_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(memeceptionBaseTest), bidAmount);

        memeceptionBaseTest.exit(address(memeToken));
    }
}
