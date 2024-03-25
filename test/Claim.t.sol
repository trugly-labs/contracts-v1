/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";
import {AuctionTestData} from "./utils/AuctionTestData.sol";

contract ClaimTest is Deployers, AuctionTestData {
    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeceptionClaimed(address indexed memeToken, address indexed og, uint256 amountMeme, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(MAX_BID_AMOUNT);
    }

    function test_claim_success() public {
        (uint256 ethAuctionBal,) = getAuctionData(createMemeParams.startAt);
        uint256 expectedRefund = MAX_BID_AMOUNT - ethAuctionBal;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(
            address(memeToken), address(memeceptionBaseTest), Constant.TOKEN_MEMECEPTION_SUPPLY, expectedRefund
        );

        memeceptionBaseTest.claim(address(memeToken));
    }
}
