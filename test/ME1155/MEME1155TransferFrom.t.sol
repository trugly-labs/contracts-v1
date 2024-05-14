/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME1155TansferFromTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initFullBid(10 ether);
        vm.warp(block.timestamp + 1 minutes);
        memeceptionBaseTest.claim(address(memeToken));

        hoax(BOB);
        meme1155.setApprovalForAll(address(this), true);

        assertEq(meme1155.isApprovedForAll(BOB, address(this)), true, "isApprovedForAll");
    }

    function test_1155transferFromNotApproval() public {
        address NO_APPROVAL = makeAddr("NO_APPROVAL");
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), NO_APPROVAL, tierParams[0].amountThreshold, false);
        vm.expectRevert("NOT_AUTHORIZED");
        meme1155.safeTransferFrom(NO_APPROVAL, ALICE, 1, 1, "");
    }

    function test_1155transferFrom_success() public {
        for (uint256 i = 0; i < tierParams.length - 2; i++) {
            uint256 tokenId = i + 1;
            memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[i].amountThreshold, false);
            address RECEIVER = makeAddr(i.toString());
            meme1155.safeTransferFrom(BOB, RECEIVER, tokenId, 1, "");

            assertEq(meme1155.balanceOf(BOB, tokenId - 1), 0, "BOB 1155 balance - 1");
            assertEq(meme1155.balanceOf(BOB, tokenId), 0, "BOB 1155 balance");
            assertEq(meme1155.balanceOf(BOB, tokenId + 1), 0, "BOB 1155 balance +1");
            assertEq(meme1155.balanceOf(RECEIVER, tokenId - 1), 0, "ALICE 1155 balance -1");
            assertEq(meme1155.balanceOf(RECEIVER, tokenId), 1, "ALICE 1155 balance");
            assertEq(meme1155.balanceOf(RECEIVER, tokenId + 1), 0, "ALICE 1155 balance +1");
            assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
            assertEq(memeToken.balanceOf(RECEIVER), tierParams[i].amountThreshold, "ALICE MEME balance");
            assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
            assertEq(meme721.balanceOf(RECEIVER), 0, "ALICE 721 balance");
        }
    }

    function test_1155transferFromToHaveSelector() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        ContractWithSelector c = new ContractWithSelector();

        meme1155.safeTransferFrom(BOB, address(c), 1, 1, "");
        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance - 1");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 2), 0, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(address(c), 0), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(address(c), 1), 1, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(address(c), 2), 0, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
        assertEq(memeToken.balanceOf(address(c)), 1, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(address(c)), 0, "ALICE 721 balance");
    }

    function test_1155transferFromToHaveNoSelector() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        ContractWithoutSelector c = new ContractWithoutSelector();

        vm.expectRevert();
        meme1155.safeTransferFrom(BOB, address(c), 1, 1, "");
    }

    function test_1155transferFromFromHaveSelector() public {
        ContractWithSelector c = new ContractWithSelector();
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), address(c), tierParams[0].amountThreshold, false);
        address SENDER = address(c);

        hoax(SENDER);
        meme1155.setApprovalForAll(address(this), true);

        meme1155.safeTransferFrom(address(c), ALICE, 1, 1, "");

        assertEq(meme1155.balanceOf(address(c), 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 1), 1, "ALICE 1155 balance");
        assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
        assertEq(memeToken.balanceOf(ALICE), tierParams[0].amountThreshold, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 0, "ALICE 721 balance");
    }

    function test_1155transferFromZero() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        meme1155.safeTransferFrom(BOB, ALICE, 1, 0, "");
        assertEq(meme1155.balanceOf(BOB, 1), 1, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
        assertEq(memeToken.balanceOf(BOB), tierParams[0].amountThreshold, "BOB MEME balance");
        assertEq(memeToken.balanceOf(ALICE), 0, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 0, "ALICE 721 balance");
    }

    function test_1155transferFromNotEnoughBal() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        vm.expectRevert();
        meme1155.safeTransferFrom(BOB, ALICE, 1, 2, "");
    }
}
