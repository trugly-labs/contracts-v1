/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyStake} from "../../src/TruglyStake.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";

contract DepositRewardsTest is DeployersME20 {
    error ZeroAmount();

    event DepositRewards(address indexed memeToken, uint256 amount);

    address ALICE = makeAddr("alice");
    uint256 buyAmount = 1 ether;

    function setUp() public override {
        super.setUp();

        createMemeParams.maxBuyETH = createMemeParams.targetETH * 2;
        initCreateMeme();
        payable(ALICE).transfer(10 ether);
        payable(MULTISIG).transfer(10 ether);

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        vm.startPrank(MULTISIG);
        memeceptionBaseTest.buyMemecoin{value: 1 ether}(address(memeToken));
        vm.stopPrank();

        vm.startPrank(ALICE);
        truglyStake.buyAndStake{value: 9 ether}(address(memeToken));
        vm.stopPrank();
    }

    function test_depositRewards_success() public {
        uint256 expectedMemeAmount = buyAmount * memeception.getPricePerETH(address(memeToken));
        uint256 expectedAliceMemeAmount = 8 ether * memeception.getPricePerETH(address(memeToken));

        uint256 beforeBal = memeToken.balanceOf(address(truglyStake));

        vm.startPrank(MULTISIG);
        memeToken.approve(address(truglyStake), type(uint256).max);

        vm.expectEmit(true, false, false, true);
        emit DepositRewards(address(memeToken), 10000 ether);
        truglyStake.depositRewards(address(memeToken), 10000 ether);
        vm.stopPrank();

        uint256 afterBal = memeToken.balanceOf(address(truglyStake));

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), expectedMemeAmount);
        assertEq(truglyStake.getStakedBalance(address(memeToken), ALICE), expectedAliceMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedAliceMemeAmount + expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 10000 ether);
        assertEq(address(truglyStake).balance, 0);
        assertEq(afterBal, beforeBal + 10000 ether);
    }

    function test_depositRewards_notApproved_revert() public {
        vm.startPrank(MULTISIG);
        vm.expectRevert();
        truglyStake.depositRewards(address(memeToken), 10000 ether);
        vm.stopPrank();
    }

    function test_depositRewards_notOwner_reverts() public {
        memeToken.approve(address(truglyStake), type(uint256).max);
        vm.expectRevert("UNAUTHORIZED");
        truglyStake.depositRewards(address(memeToken), 10000 ether);
    }
}
