/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract ClaimMemeceptionTest is Deployers {
    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeClaimed(address indexed memeToken, address indexed claimer, uint256 amountMeme);

    uint256 internal constant depositAmount = 100 ether;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initDepositMemeception(depositAmount);
    }

    function test_claimMemeception_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeClaimed(address(memeToken), address(launchpadBaseTest), TOKEN_MEMECEPTION_SUPPLY);

        launchpadBaseTest.claimMemeception(address(memeToken));
    }
}
