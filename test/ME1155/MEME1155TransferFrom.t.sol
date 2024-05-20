/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {MEME404} from "../../src/types/MEME404.sol";

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

    /// TODO: Test Transfer to self

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

    function test_1155transferFromRecipientCrossingFungibleTierThreshold() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold, false);
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), ALICE, tierParams[1].amountThreshold - tierParams[0].amountThreshold, false
        );
        meme1155.safeTransferFrom(BOB, ALICE, 1, 1, "");

        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 2), 0, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 2), 1, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
        assertEq(memeToken.balanceOf(ALICE), tierParams[1].amountThreshold, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 0, "ALICE 721 balance");

        MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
        MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
        assertEq(highestTier.nextUnmintedId, 2001, "highestTiernextUnmintedId");
        assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

        assertEq(secondHighestTier.nextUnmintedId, 1, "secondHighestTier.nextUnmintedId");
        assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    }

    function test_1155transferFromRecipientCrossingNoFungibleTierThreshold() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[1].amountThreshold, false);
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), ALICE, tierParams[tierParams.length - 2].amountThreshold - 1, false
        );
        meme1155.safeTransferFrom(BOB, ALICE, 2, 1, "");

        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 2), 0, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(ALICE, 2), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(ALICE, 5), 0, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
        assertEq(
            memeToken.balanceOf(ALICE),
            tierParams[tierParams.length - 2].amountThreshold - 1 + tierParams[1].amountThreshold,
            "ALICE MEME balance"
        );
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(ALICE), 1, "ALICE 721 balance");

        MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
        MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
        assertEq(highestTier.nextUnmintedId, 2001, "highestTiernextUnmintedId");
        assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

        assertEq(secondHighestTier.nextUnmintedId, 2, "secondHighestTier.nextUnmintedId");
        assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    }

    function test_1155transferFromRecipientCrossingHighestNoFungibleTierThreshold() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[1].amountThreshold, false);
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), ALICE, tierParams[tierParams.length - 1].amountThreshold - 1, false
        );
        assertEq(meme721.nextOwnedTokenId(BOB), 2001, "BOB nextOwnedTokenId");
        assertEq(meme721.balanceOf(BOB), 1, "BOB 721 balance");
        meme1155.safeTransferFrom(BOB, ALICE, 2, 1, "");

        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 2), 0, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(ALICE, 2), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(ALICE, 5), 0, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
        assertEq(
            memeToken.balanceOf(ALICE),
            tierParams[tierParams.length - 1].amountThreshold - 1 + tierParams[1].amountThreshold,
            "ALICE MEME balance"
        );
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(ALICE), 2001, "ALICE 721 balance");

        MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
        MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
        assertEq(highestTier.nextUnmintedId, 2002, "highestTiernextUnmintedId");
        assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

        assertEq(secondHighestTier.nextUnmintedId, 1, "secondHighestTier.nextUnmintedId");
        assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    }

    function test_1155transferFromSenderNotCrossingNoFungibleTierThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 3].amountThreshold * 2, false
        );
        assertEq(meme1155.balanceOf(BOB, 6), 1, "BOB balanceOf MEME1155");
        assertEq(meme1155.balanceOf(BOB, 5), 0, "BOB balanceOf MEME1155");
        meme1155.safeTransferFrom(BOB, ALICE, tierParams[tierParams.length - 3].lowerId, 1, "");

        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 5), 0, "BOB balanceOf MEME1155");
        assertEq(meme1155.balanceOf(BOB, 6), 1, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 6), 1, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), tierParams[tierParams.length - 3].amountThreshold, "BOB MEME balance");
        assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 3].amountThreshold, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 0, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(BOB), 0, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(ALICE), 0, "ALICE 721 balance");

        MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
        MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
        assertEq(highestTier.nextUnmintedId, 2001, "highestTiernextUnmintedId");
        assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

        assertEq(secondHighestTier.nextUnmintedId, 1, "secondHighestTier.nextUnmintedId");
        assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    }

    function test_721transferFromSenderCrossingNoFungibleTierThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest),
            BOB,
            tierParams[tierParams.length - 1].amountThreshold + tierParams[tierParams.length - 2].amountThreshold,
            false
        );
        assertEq(meme721.nextOwnedTokenId(BOB), 2001, "BOB tokenIByOwner");
        meme721.transferFrom(BOB, ALICE, tierParams[tierParams.length - 1].lowerId);

        assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
        assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
        assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
        assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
        assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
        assertEq(memeToken.balanceOf(BOB), tierParams[tierParams.length - 21].amountThreshold, "BOB MEME balance");
        assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 1].amountThreshold, "ALICE MEME balance");
        assertEq(meme721.balanceOf(BOB), 1, "BOB 721 balance");
        assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(BOB), 1, "ALICE 721 balance");
        assertEq(meme721.nextOwnedTokenId(ALICE), 2002, "ALICE 721 balance");

        MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
        MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
        assertEq(highestTier.nextUnmintedId, 2003, "highestTiernextUnmintedId");
        assertEq(highestTier.burnLength, 1, "highestTier.burnLength");
        assertEq(memeToken.nextBurnId(tierParams.length), 2002, "highestTier.burnLength");

        assertEq(secondHighestTier.nextUnmintedId, 0, "secondHighestTier.nextUnmintedId");
        assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
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
