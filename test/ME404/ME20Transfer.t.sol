/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME20Transfers is DeployersME404 {
    error PoolNotInitialized();

    address ALICE;
    uint256 initTreasuryBal;
    uint256 initCreatorBal;

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initBuyMemecoin(createMemeParams.targetETH);

        ALICE = makeAddr("Alice");
        initTreasuryBal = memeToken.balanceOf(treasury);
        initCreatorBal = memeToken.balanceOf(MEMECREATOR);

        memeToken.transfer(address(memeception), 10 ether);
    }

    function test_404transfer_exempt() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        hoax(memeceptionAddr, 10 ether);
        memeToken.transfer(ALICE, 10 ether);
        address BOB = makeAddr("bob");
        hoax(ALICE, 10 ether);
        memeToken.transfer(BOB, 5 ether);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 5 ether, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 5 ether, "bobBalance");
    }

    function test_404transfer_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        hoax(memeceptionAddr, 10 ether);
        memeToken.transfer(ALICE, 10 ether);
        assertEq(memeToken.balanceOf(memeceptionAddr), initialBalance - 10 ether, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 10 ether, "aliceBalance");
    }

    function test_404transfer_from_exempt() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        hoax(memeceptionAddr, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);
        memeToken.transferFrom(memeceptionAddr, ALICE, 10 ether);
        address BOB = makeAddr("bob");
        hoax(ALICE, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);
        memeToken.transferFrom(ALICE, BOB, 5 ether);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 5 ether, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 5 ether, "bobBalance");
    }

    function test_404transfer_from_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        hoax(memeceptionAddr, 10 ether);
        MEME20(memeToken).approve(address(this), 10 ether);

        memeToken.transferFrom(memeceptionAddr, ALICE, 10 ether);
        assertEq(memeToken.balanceOf(memeceptionAddr), initialBalance - 10 ether, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 10 ether, "aliceBalance");
    }

    function test_404transfer_fail_no_balance() public {
        vm.expectRevert();

        vm.startPrank(makeAddr("NOBALANCE"));
        memeToken.transfer(ALICE, 10 ether);
        vm.stopPrank();
    }

    function test_404transferFrom_fail_no_approval() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);
        vm.expectRevert();
        memeToken.transferFrom(ALICE, makeAddr("bob"), 1);
    }

    function test_404transfer_not_initialized_error() public {
        MEME404 m = new MEME404("MEME", "MEME", address(this));
        m.transfer(ALICE, 1);

        vm.expectRevert(PoolNotInitialized.selector);
        vm.startPrank(ALICE);
        m.transfer(address(this), 1);
    }
}
