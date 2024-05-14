/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

import {MEME404} from "../../src/types/MEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";

contract MEME404RawTransferFromTest is DeployersME404 {
    /// @dev Only NFT collection can call this function
    error OnlyNFT();

    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initFullBid(10 ether);
        vm.warp(block.timestamp + 1 minutes);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_transferFromNFT1155() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        vm.startPrank(address(meme1155));
        memeToken.transferFromNFT(BOB, ALICE, 1);

        vm.stopPrank();
        assertEq(meme1155.balanceOf(BOB, 1), 1);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme721.balanceOf(ALICE), 0);
        assertEq(meme721.balanceOf(BOB), 0);
        assertEq(memeToken.balanceOf(BOB), 0);
        assertEq(memeToken.balanceOf(ALICE), 1);
    }

    function test_transferFromNFT721() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold, false
        );
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(BOB, ALICE, 1);

        vm.stopPrank();
        assertEq(meme1155.balanceOf(BOB, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme721.balanceOf(BOB), 1);
        assertEq(meme721.balanceOf(ALICE), 0);
        assertEq(memeToken.balanceOf(BOB), 0);
        assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 2].amountThreshold);
    }

    function test_transferFromNFT721HighestTier() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold, false
        );
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(BOB, ALICE, 2001);

        vm.stopPrank();
        assertEq(meme1155.balanceOf(BOB, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme721.balanceOf(BOB), 1);
        assertEq(meme721.balanceOf(ALICE), 0);
        assertEq(memeToken.balanceOf(BOB), 0);
        assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 1].amountThreshold);
    }

    function test_transferFromNFT1155_notNFT_revert() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(BOB, ALICE, 1);
    }

    function test_transferFromNFT721_revert_notNFT() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold, false
        );
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(BOB, ALICE, 1);
    }

    function test_transferFromNFT721WrongTokenId_revert() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold, false
        );
        vm.expectRevert(OnlyNFT.selector);
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(BOB, ALICE, 2102);

        vm.stopPrank();
    }

    function test_transferFromNFT1155WrongTokenId_revert() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold, false
        );
        vm.expectRevert(OnlyNFT.selector);
        vm.startPrank(address(meme1155));
        memeToken.transferFromNFT(BOB, ALICE, 7);

        vm.stopPrank();
    }
}
