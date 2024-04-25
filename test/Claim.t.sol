/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {PoolLiquidity} from "../src/test/PoolLiquidity.sol";
import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";
import {AuctionTestData} from "./utils/AuctionTestData.sol";

contract ClaimTest is Deployers, AuctionTestData {
    error ZeroAmount();
    /// @dev Thrown when the Meme pool is not launched
    error MemeNotLaunched();

    error ClaimCooldownPeriod();

    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeceptionClaimed(address indexed memeToken, address indexed og, uint256 amountMeme, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_claim_success_with_refund() public {
        uint256 ALICE_BID = 5 ether;
        vm.warp(createMemeParams.startAt + Constant.MIN_AUCTION_DURATION - 1.5 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeception.bid{value: ALICE_BID}(address(memeToken));

        initFullBid(MAX_BID_AMOUNT);
        (uint256 ethAuctionBal,) = getAuctionData(createMemeParams.startAt);
        uint256 expectedRefund = MAX_BID_AMOUNT - ethAuctionBal + ALICE_BID - 1;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(
            address(memeToken), address(memeceptionBaseTest), 2222222221777777777777777778, expectedRefund
        );

        vm.warp(block.timestamp + Constant.AUCTION_CLAIM_COOLDOWN);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_claim_success_no_refund() public {
        vm.warp(createMemeParams.startAt + Constant.MIN_AUCTION_DURATION - 1.5 minutes);
        uint256 amount = PoolLiquidity.getETHLiquidity(createMemeParams.startAt);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));

        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(address(memeToken), address(memeceptionBaseTest), Constant.TOKEN_MEMECEPTION_SUPPLY, 0);

        vm.warp(createMemeParams.startAt + Constant.MAX_AUCTION_DURATION + Constant.AUCTION_CLAIM_COOLDOWN);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_claim_success_two_users() public {
        uint256 ALICE_BID = 5 ether;
        vm.warp(createMemeParams.startAt + Constant.MIN_AUCTION_DURATION - 1.5 minutes);
        address alice = makeAddr("alice");
        hoax(alice, MAX_BID_AMOUNT);
        memeception.bid{value: ALICE_BID}(address(memeToken));

        initFullBid(MAX_BID_AMOUNT);
        (uint256 ethAuctionBal,) = getAuctionData(createMemeParams.startAt);
        uint256 expectedRefund = MAX_BID_AMOUNT - ethAuctionBal + ALICE_BID - 1;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(
            address(memeToken), address(memeceptionBaseTest), 2222222221777777777777777778, expectedRefund
        );
        vm.warp(createMemeParams.startAt + Constant.MAX_AUCTION_DURATION + Constant.AUCTION_CLAIM_COOLDOWN);

        memeceptionBaseTest.claim(address(memeToken));

        hoax(alice, MAX_BID_AMOUNT);
        emit MemeceptionClaimed(address(memeToken), alice, 2222222222222222222222222222, 0);
        memeception.claim(address(memeToken));
        assertEq(memeToken.balanceOf(alice), 2222222222222222222222222222);
    }

    function test_claim_success_different_price() public {
        vm.warp(createMemeParams.startAt + 1);
        address alice = makeAddr("alice");
        hoax(alice, MAX_BID_AMOUNT);
        memeception.bid{value: MAX_BID_AMOUNT}(address(memeToken));

        vm.warp(createMemeParams.startAt + 115);
        initFullBid(MAX_BID_AMOUNT);
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(
            address(memeToken), address(memeceptionBaseTest), 4424681598150197628458498024, 44466404162055335
        );

        vm.warp(createMemeParams.startAt + Constant.MAX_AUCTION_DURATION + Constant.AUCTION_CLAIM_COOLDOWN);
        memeceptionBaseTest.claim(address(memeToken));

        hoax(alice, MAX_BID_AMOUNT);
        emit MemeceptionClaimed(address(memeToken), alice, 19762845849802371541501976, 9955533596837944664);

        memeception.claim(address(memeToken));
        assertEq(memeToken.balanceOf(alice), 19762845849802371541501976);
    }

    function test_claim_fail_meme_not_launched() public {
        vm.warp(createMemeParams.startAt + 1);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeception.bid{value: MAX_BID_AMOUNT}(address(memeToken));
        vm.expectRevert(MemeNotLaunched.selector);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_claim_fail_memeception_not_started() public {
        vm.warp(createMemeParams.startAt - 1);
        vm.expectRevert(MemeNotLaunched.selector);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_claim_fail_no_bid() public {
        initFullBid(MAX_BID_AMOUNT);
        hoax(makeAddr("alice"));
        vm.expectRevert(ZeroAmount.selector);
        vm.warp(createMemeParams.startAt + Constant.MAX_AUCTION_DURATION + Constant.AUCTION_CLAIM_COOLDOWN);
        memeception.claim(address(memeToken));
    }

    function test_claim_fail_invalid_meme_address() public {
        vm.expectRevert(MemeNotLaunched.selector);
        memeception.claim(address(2));
    }

    function test_claim_fail_before_cooldown() public {
        initFullBid(MAX_BID_AMOUNT);

        vm.warp(block.timestamp + Constant.AUCTION_CLAIM_COOLDOWN - 1);
        vm.expectRevert(ClaimCooldownPeriod.selector);
        memeceptionBaseTest.claim(address(memeToken));
    }
}
