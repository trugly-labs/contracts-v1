/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";

contract ClaimTest is Deployers {
    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeClaimed(address indexed memeToken, address indexed claimer, uint256 amountMeme, uint256 refundETH);

    uint256 internal constant bidAmount = 100 ether;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBid(bidAmount);
    }

    function test_claim_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeClaimed(address(memeToken), address(memeceptionBaseTest), Constant.TOKEN_MEMECEPTION_SUPPLY, 0);

        memeceptionBaseTest.claim(address(memeToken));
    }
}
