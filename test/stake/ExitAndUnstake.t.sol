/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyStake} from "../../src/TruglyStake.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";

contract ExitAndUnstakeTest is DeployersME20 {
    error ZeroAmount();

    address ALICE = makeAddr("alice");
    uint256 buyAmount = 1 ether;

    function setUp() public override {
        super.setUp();

        createMemeParams.maxBuyETH = createMemeParams.targetETH * 2;
        initCreateMeme();
        payable(ALICE).transfer(10 ether);

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));
    }

    function test_exitAndUnstake_success() public {
        uint256 beforeBalETH = address(this).balance;
        truglyStake.exitAndUnstake(address(memeToken));
        uint256 afterBalETH = address(this).balance;

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), 0);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, 0);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
        assertEq(afterBalETH, beforeBalETH + buyAmount);
        assertEq(address(truglyStake).balance, 0);
    }

    function test_exitAndUnstake_two_users_success() public {
        uint256 expectedMemeAmount = buyAmount * memeception.getPricePerETH(address(memeToken));

        vm.startPrank(ALICE);
        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));
        vm.stopPrank();

        uint256 beforeBalETH = address(this).balance;
        truglyStake.exitAndUnstake(address(memeToken));
        uint256 afterBalETH = address(this).balance;

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), 0);
        assertEq(truglyStake.getStakedBalance(address(memeToken), ALICE), expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
        assertEq(afterBalETH, beforeBalETH + buyAmount);
        assertEq(address(truglyStake).balance, 0);
    }

    function test_exitAndUnstake_cap_reached_revert() public {
        truglyStake.buyAndStake{value: 10 ether}(address(memeToken));
        vm.expectRevert();
        truglyStake.exitAndUnstake(address(memeToken));
    }

    function test_exitAndUnstake_zero_amount_reverts() public {
        vm.startPrank(ALICE);
        vm.expectRevert(ZeroAmount.selector);
        truglyStake.exitAndUnstake(address(memeToken));
        vm.stopPrank();
    }
}
