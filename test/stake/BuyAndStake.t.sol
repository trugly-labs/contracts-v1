/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyStake} from "../../src/TruglyStake.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";

contract BuyAndStakeTest is DeployersME20 {
    error ZeroAmount();

    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();

        createMemeParams.maxBuyETH = createMemeParams.targetETH * 2;
        initCreateMeme();
        payable(ALICE).transfer(10 ether);
    }

    function test_buyAndStake_success() public {
        uint256 buyAmount = 1 ether;
        uint256 pricePerETH = memeception.getPricePerETH(address(memeToken));
        uint256 expectedMemeAmount = buyAmount * pricePerETH;

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
    }

    function test_buyAndStake_two_users_success() public {
        uint256 buyAmount = 1 ether;
        uint256 pricePerETH = memeception.getPricePerETH(address(memeToken));
        uint256 expectedMemeAmount = buyAmount * pricePerETH;

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        vm.startPrank(ALICE);
        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));
        vm.stopPrank();

        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), expectedMemeAmount);
        assertEq(truglyStake.getStakedBalance(address(memeToken), ALICE), expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedMemeAmount * 2);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
    }

    function test_buyAndStake_capReached_success() public {
        uint256 buyAmount = 10 ether;
        uint256 pricePerETH = memeception.getPricePerETH(address(memeToken));
        uint256 expectedMemeAmount = buyAmount * pricePerETH;

        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        assertNotEq(memeception.getMemeception(address(memeToken)).endedAt, 0);
        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
    }

    function test_buyAndStake_capReachedOver_success() public {
        uint256 buyAmount = 11 ether;
        uint256 pricePerETH = memeception.getPricePerETH(address(memeToken));
        uint256 expectedMemeAmount = 10 ether * pricePerETH;

        uint256 initialBalance = address(this).balance;
        truglyStake.buyAndStake{value: buyAmount}(address(memeToken));

        assertNotEq(memeception.getMemeception(address(memeToken)).endedAt, 0);
        assertEq(truglyStake.getStakedBalance(address(memeToken), address(this)), expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).totalStaked, expectedMemeAmount);
        assertEq(truglyStake.getStakeInfo(address(memeToken)).claimableRewards, 0);
        assertEq(address(this).balance, initialBalance - 10 ether);
        assertEq(address(truglyStake).balance, 0);
    }

    function test_buyAndStake_cap_reached_revert() public {
        truglyStake.buyAndStake{value: 10 ether}(address(memeToken));
        vm.expectRevert();
        truglyStake.buyAndStake{value: 1}(address(memeToken));
    }

    function test_buyAndStake_zero_amount_reverts() public {
        vm.expectRevert(ZeroAmount.selector);
        truglyStake.buyAndStake{value: 0}(address(memeToken));
    }
}
