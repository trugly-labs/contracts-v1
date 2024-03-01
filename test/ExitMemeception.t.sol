/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract ExitMemeceptionTest is Deployers {
    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed backer, uint256 amount);

    uint256 internal constant depositAmount = 50 ether;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initDepositMemeception(depositAmount);

        vm.warp(block.timestamp + 7 days);
    }

    function test_exitMemeception_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeceptionExit(address(memeToken), address(launchpadBaseTest), depositAmount);

        launchpadBaseTest.exitMemeception(address(memeToken));
    }
}
