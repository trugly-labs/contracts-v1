/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract ExitMemecoinTest is DeployersME20 {
    error InvalidMemeceptionDate();
    error MemeLaunched();
    error InvalidMemeAddress();

    /// @dev Emitted when a user exits the fair launch and claims a refund
    event MemecoinExit(address indexed memeToken, address indexed user, uint256 refundETH, uint256 amountMeme);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_exitMemecoin_success_single() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken), address(this), createMemeParams.targetETH / 10, memeToken.balanceOf(address(this))
        );

        memeceptionBaseTest.exitMemecoin(address(memeToken), memeToken.balanceOf(address(this)));
    }

    function test_exitMemecoin_success_partial() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken), address(this), createMemeParams.targetETH / 20, memeToken.balanceOf(address(this)) / 2
        );

        memeceptionBaseTest.exitMemecoin(address(memeToken), memeToken.balanceOf(address(this)) / 2);
    }

    function test_exitMemecoin_success_two_users() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken), address(this), createMemeParams.targetETH / 10, memeInfo.memeceptionSupply / 10
        );
        memeceptionBaseTest.exitMemecoin(address(memeToken), memeInfo.memeceptionSupply / 10);

        address ALICE = makeAddr("alice");
        startHoax(ALICE, createMemeParams.targetETH / 20);
        memeception.buyMemecoin{value: createMemeParams.targetETH / 20}(address(memeToken));
        memeToken.approve(address(memeception), memeToken.balanceOf(ALICE));

        assertApproxEq(
            memeToken.balanceOf(address(memeception)),
            memeInfo.memeceptionSupply * 2 - memeInfo.memeceptionSupply / 20,
            0.01e18,
            "#1"
        );
        assertEq(address(memeception).balance, createMemeParams.targetETH / 20, "#2");

        vm.expectEmit(true, true, false, true);
        emit MemecoinExit(
            address(memeToken),
            address(makeAddr("alice")),
            createMemeParams.targetETH / 20,
            memeInfo.memeceptionSupply / 20
        );
        memeception.exitMemecoin(address(memeToken), memeToken.balanceOf(ALICE));
        vm.stopPrank();

        assertEq(memeToken.balanceOf(address(ALICE)), 0, "#3");
        assertApproxEq(memeToken.balanceOf(address(memeception)), memeInfo.memeceptionSupply * 2, 0.01e18, "#4");
        assertEq(address(memeception).balance, 0, "#5");
        assertEq(ALICE.balance, createMemeParams.targetETH / 20, "#6");
    }

    function test_exitMemecoin_success_no_bid() public {
        emit MemecoinExit(address(memeToken), address(this), 0, 0);
        memeceptionBaseTest.exitMemecoin(address(memeToken), 0);
    }

    function test_exitMemecoin_success_no_bid_2() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        emit MemecoinExit(address(memeToken), address(this), 0, 0);
        memeceptionBaseTest.exitMemecoin(address(memeToken), 0);
    }

    function test_exitMemecoin_fail_meme_launched() public {
        initBuyMemecoinFullCap();

        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.exitMemecoin(address(memeToken), memeInfo.memeceptionSupply / 10);
    }

    function test_exitMemecoin_fail_invalid_meme_address() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        memeToken.approve(address(memeception), memeInfo.memeceptionSupply / 10);
        vm.expectRevert(InvalidMemeAddress.selector);
        memeception.exitMemecoin(address(1), memeInfo.memeceptionSupply / 10);
    }

    function test_exitMemecoin_fail_unapproved() public {
        initBuyMemecoin(createMemeParams.targetETH / 10);
        memeToken.approve(address(memeception), memeInfo.memeceptionSupply / 10 - 1);
        vm.expectRevert();
        memeception.exitMemecoin(address(memeToken), memeInfo.memeceptionSupply / 10);
    }
}
