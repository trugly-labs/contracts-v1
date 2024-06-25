/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyStake} from "../../src/TruglyStake.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";

contract WithdrawTest is DeployersME20 {
    error ZeroAmount();

    event Withdrawn(address indexed user, uint256 amount);

    address ALICE = makeAddr("alice");
    uint256 buyAmount = 1 ether;
    uint256 rewardsAmount = 10000 ether;

    function setUp() public override {
        super.setUp();

        createMemeParams.maxBuyETH = createMemeParams.targetETH * 2;
        initCreateMeme();
        payable(ALICE).transfer(10 ether);
        payable(MULTISIG).transfer(10 ether);

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        vm.startPrank(MULTISIG);
        memeception.buyMemecoin{value: 1 ether}(address(memeToken));
        memeToken.approve(address(truglyStake), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(ALICE);
        truglyStake.buyAndStake{value: 9 ether}(address(memeToken));
        memeToken.approve(address(truglyStake), type(uint256).max);
        vm.stopPrank();
    }

    function test_withdraw_withoutRewards_success() public {
        uint256 expectedMemeAmount = buyAmount * memeception.getPricePerETH(address(memeToken));
        uint256 expectedAliceMemeAmount = 8 ether * memeception.getPricePerETH(address(memeToken));

        uint256 beforeBal = memeToken.balanceOf(address(truglyStake));
        uint256 beforeBalUser = memeToken.balanceOf(address(this));

        truglyStake.withdraw(address(memeToken));
        uint256 afterBal = memeToken.balanceOf(address(truglyStake));
        uint256 afterBalUser = memeToken.balanceOf(address(this));

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), 0);
        assertEq(truglyStake.getStakedBalance(address(memeToken), ALICE), expectedAliceMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedAliceMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
        assertEq(address(truglyStake).balance, 0);
        assertEq(afterBal, beforeBal - expectedMemeAmount);
        assertEq(afterBalUser, beforeBalUser + expectedMemeAmount);
    }

    function test_withdraw_withRewards_success() public {
        vm.startPrank(MULTISIG);
        truglyStake.depositRewards(address(memeToken), rewardsAmount);
        vm.stopPrank();

        uint256 expectedMemeAmount = buyAmount * memeception.getPricePerETH(address(memeToken));
        uint256 expectedAliceMemeAmount = 8 ether * memeception.getPricePerETH(address(memeToken));

        uint256 expectedRewardAmount = rewardsAmount / 9;
        uint256 expectedAliceRewardAmount = rewardsAmount - expectedRewardAmount;

        uint256 beforeBal = memeToken.balanceOf(address(truglyStake));
        uint256 beforeBalUser = memeToken.balanceOf(address(this));

        truglyStake.withdraw(address(memeToken));
        uint256 afterBal = memeToken.balanceOf(address(truglyStake));
        uint256 afterBalUser = memeToken.balanceOf(address(this));

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), 0, "staked balance");
        assertEq(
            truglyStake.getStakedBalance(address(memeToken), ALICE), expectedAliceMemeAmount, "alice staked balance"
        );
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedAliceMemeAmount, "total staked");
        assertApproxEq(
            truglyStake.getStakeInfo(address(memeToken)).claimableRewards,
            rewardsAmount - expectedRewardAmount,
            10000,
            "claimable rewards"
        );
        assertEq(address(truglyStake).balance, 0, "contract balance (ETH)");
        assertApproxEq(afterBal, beforeBal - expectedMemeAmount - expectedRewardAmount, 10000, "contract meme balance");
        assertApproxEq(
            afterBalUser, beforeBalUser + expectedMemeAmount + expectedRewardAmount, 10000, "user meme balance"
        );

        beforeBal = memeToken.balanceOf(address(truglyStake));
        beforeBalUser = memeToken.balanceOf(ALICE);
        vm.startPrank(ALICE);

        truglyStake.withdraw(address(memeToken));
        vm.stopPrank();
        afterBal = memeToken.balanceOf(address(truglyStake));
        afterBalUser = memeToken.balanceOf(ALICE);

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), 0, "staked balance #2");
        assertEq(truglyStake.getStakedBalance(address(memeToken), ALICE), 0, "alice staked balance #2");
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, 0, "total staked #2");
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0, "claimable rewards #2");
        assertEq(address(truglyStake).balance, 0, "contract balance (ETH) #2");
        assertApproxEq(
            afterBal, beforeBal - expectedAliceMemeAmount - expectedAliceRewardAmount, 10000, "contract meme balance #2"
        );
        assertApproxEq(
            afterBalUser,
            beforeBalUser + expectedAliceRewardAmount + expectedAliceMemeAmount,
            10000,
            "user meme balance #2"
        );
    }

    function test_withdraw_zeroAmount_revert() public {
        vm.startPrank(makeAddr("bob"));
        vm.expectRevert(ZeroAmount.selector);

        truglyStake.withdraw(address(memeToken));
        vm.stopPrank();
    }

    function test_withdraw_twice_revert() public {
        truglyStake.withdraw(address(memeToken));
        vm.expectRevert(ZeroAmount.selector);
        truglyStake.withdraw(address(memeToken));
    }
}
