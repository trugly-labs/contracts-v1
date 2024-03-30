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

    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeceptionClaimed(address indexed memeToken, address indexed og, uint256 amountMeme, uint256 refundETH);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_claim_success_with_refund() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        hoax(makeAddr("alice"), MAX_BID_AMOUNT);
        memeception.bid{value: 5 ether}(address(memeToken));

        initFullBid(MAX_BID_AMOUNT);
        (uint256 ethAuctionBal,) = getAuctionData(createMemeParams.startAt);
        uint256 expectedRefund = MAX_BID_AMOUNT - ethAuctionBal;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(address(memeToken), address(memeceptionBaseTest), 2.22222222177778e27, expectedRefund);

        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_claim_success_no_refund() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        uint256 amount = PoolLiquidity.getETHLiquidity(createMemeParams.startAt);
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(address(memeToken), address(memeceptionBaseTest), Constant.TOKEN_MEMECEPTION_SUPPLY, 0);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_claim_success_two_users() public {
        uint256 ALICE_BID = 5 ether;
        vm.warp(createMemeParams.startAt + 115 minutes);
        address alice = makeAddr("alice");
        hoax(alice, MAX_BID_AMOUNT);
        memeception.bid{value: ALICE_BID}(address(memeToken));

        initFullBid(MAX_BID_AMOUNT);
        (uint256 ethAuctionBal,) = getAuctionData(createMemeParams.startAt);
        uint256 expectedRefund = MAX_BID_AMOUNT - ethAuctionBal + ALICE_BID;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionClaimed(address(memeToken), address(memeceptionBaseTest), 2.22222222177778e27, expectedRefund);

        memeceptionBaseTest.claim(address(memeToken));

        hoax(alice);
        emit MemeceptionClaimed(address(memeToken), alice, 2.22222222222222e27, 0);
        memeception.claim(address(memeToken));
        assertEq(memeToken.balanceOf(alice), 2.22222222222222e27);
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
            address(memeToken), address(memeceptionBaseTest), 4.4246815981502e27, 4.44664041620562e16
        );

        memeceptionBaseTest.claim(address(memeToken));

        hoax(alice);
        emit MemeceptionClaimed(address(memeToken), alice, 1.97628458498024e25, 9.95553359683795e18);
        memeception.claim(address(memeToken));
        assertEq(memeToken.balanceOf(alice), 1.97628458498024e25);
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
        memeception.claim(address(memeToken));
    }

    function test_claim_fail_invalid_meme_address() public {
        vm.expectRevert(MemeNotLaunched.selector);
        memeception.claim(address(2));
    }
}
