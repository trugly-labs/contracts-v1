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

    address SENDER = makeAddr("bob");
    address RECEIVER = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
    }

    function test_transferFromNFT1155_notNFT_revert() public {
        initWalletWithTokens(SENDER, getAmountThreshold(1));
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(SENDER, RECEIVER, 1);
    }

    function test_transferFromNFT11552Tier_notNFT_revert() public {
        initWalletWithTokens(SENDER, getAmountThreshold(2));
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(SENDER, RECEIVER, 2);
    }

    function test_transferFromNFT721_revert_notNFT() public {
        initWalletWithTokens(SENDER, getAmountThreshold(3));
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(SENDER, RECEIVER, 1);
    }

    function test_transferFromNFT721_HT_revert_notNFT() public {
        initWalletWithTokens(SENDER, getAmountThreshold(4));
        vm.expectRevert(OnlyNFT.selector);
        memeToken.transferFromNFT(SENDER, RECEIVER, 2001);
    }

    function test_transferFromNFT721WrongTokenId_revert() public {
        initWalletWithTokens(SENDER, getAmountThreshold(3));
        vm.expectRevert();
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(SENDER, RECEIVER, 2001);
        vm.stopPrank();
    }

    function test_transferFromNFT721WrongTokenId() public {
        initWalletWithTokens(SENDER, getAmountThreshold(4));
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(SENDER, RECEIVER, 1);
        vm.stopPrank();
    }

    function test_transferFromNFTWrongCollection_revert() public {
        initWalletWithTokens(SENDER, getAmountThreshold(1));
        vm.expectRevert();
        vm.startPrank(address(meme721));
        memeToken.transferFromNFT(SENDER, RECEIVER, 1);
        vm.stopPrank();
    }
}
