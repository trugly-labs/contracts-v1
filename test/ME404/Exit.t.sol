/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME404} from "../utils/DeployersME404.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract ExitMemecoin404Test is DeployersME404 {
    error InvalidMemeceptionDate();
    error MemeLaunched();
    error InvalidMemeAddress();

    /// @dev Emitted when a user exits the fair launch and claims a refund
    event MemecoinExit(address indexed memeToken, address indexed user, uint256 refundETH, uint256 amountMeme);

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
    }

    function test_404exitMemecoin_success_single() public {
        initBuyMemecoin(createMemeParams.targetETH / 2);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken), address(this), createMemeParams.targetETH / 2, memeToken.balanceOf(address(this))
        );

        memeceptionBaseTest.exitMemecoin(address(memeToken), memeToken.balanceOf(address(this)));
    }

    function test_404exitMemecoin_success_partial() public {
        initBuyMemecoin(createMemeParams.targetETH / 2);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken), address(this), createMemeParams.targetETH / 4, memeToken.balanceOf(address(this)) / 2
        );

        memeceptionBaseTest.exitMemecoin(address(memeToken), memeToken.balanceOf(address(this)) / 2);
    }

    function test_404exitMemecoin_success_two_users() public {
        initBuyMemecoin(createMemeParams.targetETH / 4 * 3);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken),
            address(this),
            createMemeParams.targetETH / 4 * 3,
            Constant.TOKEN_MEMECEPTION_SUPPLY / 4 * 3
        );
        memeceptionBaseTest.exitMemecoin(address(memeToken), Constant.TOKEN_MEMECEPTION_SUPPLY / 4 * 3);

        address ALICE = makeAddr("alice");
        startHoax(ALICE, createMemeParams.targetETH / 4);
        memeception.buyMemecoin{value: createMemeParams.targetETH / 4}(address(memeToken));
        memeToken.approve(address(memeception), memeToken.balanceOf(ALICE));

        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken),
            address(makeAddr("alice")),
            createMemeParams.targetETH / 4,
            Constant.TOKEN_MEMECEPTION_SUPPLY / 4
        );
        assertApproxEq(
            memeToken.balanceOf(address(memeception)),
            Constant.TOKEN_MEMECEPTION_SUPPLY + Constant.TOKEN_MEMECEPTION_SUPPLY / 4 * 3,
            0.01e18,
            "#1"
        );
        assertEq(address(memeception).balance, createMemeParams.targetETH / 4, "#2");
        memeception.exitMemecoin(address(memeToken), memeToken.balanceOf(ALICE));
        vm.stopPrank();

        assertEq(memeToken.balanceOf(address(ALICE)), 0, "#3");
        assertApproxEq(memeToken.balanceOf(address(memeception)), Constant.TOKEN_MEMECEPTION_SUPPLY * 2, 0.01e18, "#4");
        assertEq(address(memeception).balance, 0, "#5");
        assertEq(ALICE.balance, createMemeParams.targetETH / 4, "#6");
    }

    function test_404exitMemecoin_success_no_bid() public {
        emit MemecoinExit(address(memeToken), address(this), 0, 0);
        memeceptionBaseTest.exitMemecoin(address(memeToken), 0);
    }

    function test_404exitMemecoin_success_no_bid_2() public {
        initBuyMemecoin(createMemeParams.targetETH / 4 * 3);
        emit MemecoinExit(address(memeToken), address(this), 0, 0);
        memeceptionBaseTest.exitMemecoin(address(memeToken), 0);
    }

    function test_404exitMemecoin_fail_meme_launched() public {
        initBuyMemecoin(createMemeParams.targetETH / 2);
        hoax(makeAddr("alice"), createMemeParams.targetETH);
        memeception.buyMemecoin{value: createMemeParams.targetETH / 2}(address(memeToken));

        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.exitMemecoin(address(memeToken), Constant.TOKEN_MEMECEPTION_SUPPLY / 2);
    }

    function test_404exitMemecoin_fail_invalid_meme_address() public {
        initBuyMemecoin(createMemeParams.targetETH / 2);
        memeToken.approve(address(memeception), Constant.TOKEN_MEMECEPTION_SUPPLY / 2);
        vm.expectRevert(InvalidMemeAddress.selector);
        memeception.exitMemecoin(address(1), Constant.TOKEN_MEMECEPTION_SUPPLY / 2);
    }

    function test_404exitMemecoin_fail_unapproved() public {
        initBuyMemecoin(createMemeParams.targetETH / 2);
        memeToken.approve(address(memeception), Constant.TOKEN_MEMECEPTION_SUPPLY / 2 - 1);
        vm.expectRevert();
        memeception.exitMemecoin(address(memeToken), Constant.TOKEN_MEMECEPTION_SUPPLY / 2);
    }
}
