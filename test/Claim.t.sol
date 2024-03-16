/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";

contract ClaimTest is Deployers {
    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeceptionClaimed(address indexed memeToken, address indexed og, uint256 amountMeme, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(MAX_BID_AMOUNT);
    }

    function test_claim_success() public {
        uint256 expectedRefund = 8.065 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(
            address(memeToken), address(memeceptionBaseTest), 891705069124423963133640552996, expectedRefund
        );

        memeceptionBaseTest.claim(address(memeToken));
    }
}
