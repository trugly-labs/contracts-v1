/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";

contract MEME20Transfers is DeployersME20 {
    address ALICE;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(10 ether);

        ALICE = makeAddr("Alice");
    }

    function test_transfer_exempt() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        hoax(memeceptionAddr, 10 ether);
        memeToken.transfer(ALICE, 10 ether);
        address BOB = makeAddr("bob");
        hoax(ALICE, 10 ether);
        memeToken.transfer(BOB, 5 ether);

        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 5 ether, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 5 ether, "bobBalance");
    }

    function test_transfer_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        hoax(memeceptionAddr, 10 ether);
        memeToken.transfer(ALICE, 10 ether);
        assertEq(memeToken.balanceOf(memeceptionAddr), initialBalance - 10 ether, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 10 ether, "aliceBalance");
    }

    function test_transfer_from_exempt() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        hoax(memeceptionAddr, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);
        memeToken.transferFrom(memeceptionAddr, ALICE, 10 ether);
        address BOB = makeAddr("bob");
        hoax(ALICE, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);
        memeToken.transferFrom(ALICE, BOB, 5 ether);

        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 5 ether, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 5 ether, "bobBalance");
    }

    function test_transfer_from_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        hoax(memeceptionAddr, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);

        memeToken.transferFrom(memeceptionAddr, ALICE, 10 ether);

        assertEq(memeToken.balanceOf(memeceptionAddr), initialBalance - 10 ether, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 10 ether, "aliceBalance");
    }

    function test_transfer_fail_no_balance() public {
        vm.expectRevert();
        memeToken.transfer(ALICE, 10 ether);
    }

    function test_transferFrom_fail_no_approval() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);
        vm.expectRevert();
        memeToken.transferFrom(ALICE, makeAddr("bob"), 1);
    }
}
