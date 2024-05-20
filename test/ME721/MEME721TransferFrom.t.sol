/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {MEME404} from "../../src/types/MEME404.sol";

contract MEME721TansferFromTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address SENDER = address(this);
    address RECEIVER = makeAddr("receiver");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        // initFullBid(10 ether);
        // vm.warp(block.timestamp + 1 minutes);
        // memeceptionBaseTest.claim(address(memeToken));

        // hoax(BOB);
        // meme721.setApprovalForAll(address(this), true);

        // assertEq(meme721.isApprovedForAll(BOB, address(this)), true, "isApprovedForAll");
    }

    /// TODO: Test Transfer to self

    /// @notice Scenario 20: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> #2002 -> Wallet B (2nd HT / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2001) -> Wallet B (HT + 2nd HT / ERC721 #2002)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: []
    function test_721transferFromScenario20_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "transferScenario20";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        meme721.transferFrom(SENDER, RECEIVER, 2002);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;

        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory sHTBurnIds = new uint256[](1);
        sHTBurnIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, sHTBurnIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    // function test_721transferFromNotApproval() public {
    //     address NO_APPROVAL = makeAddr("NO_APPROVAL");
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), NO_APPROVAL, tierParams[tierParams.length - 1].amountThreshold, false
    //     );
    //     vm.expectRevert("NOT_AUTHORIZED");
    //     meme721.transferFrom(NO_APPROVAL, ALICE, tierParams[tierParams.length].lowerId);
    // }

    // function test_721transferFrom_success() public {
    //     for (uint256 i = tierParams.length - 2; i < tierParams.length; i++) {
    //         uint256 tokenId = tierParams[i].lowerId;
    //         memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[i].amountThreshold, false);
    //         RECEIVER = makeAddr(i.toString());
    //         meme721.transferFrom(BOB, RECEIVER, tokenId);
    //         assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
    //         assertEq(meme721.balanceOf(RECEIVER), 1, "ALICE 721 balance +1");
    //         assertEq(meme721.nextOwnedTokenId(RECEIVER), tokenId, "ALICE 721 balance");
    //         assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //         assertEq(memeToken.balanceOf(RECEIVER), tierParams[i].amountThreshold, "ALICE MEME balance");
    //         assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //         assertEq(meme1155.balanceOf(RECEIVER, 1), 0, "ALICE 1155balance");
    //     }
    // }

    // function test_721transferFromToHaveSelector() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold, false
    //     );
    //     ContractWithSelector c = new ContractWithSelector();

    //     uint256 tokenId = tierParams[tierParams.length - 1].lowerId;
    //     meme721.transferFrom(BOB, address(c), tokenId);
    //     assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance - 1");
    //     assertEq(meme721.balanceOf(address(c)), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(address(c)), tokenId, "ALICE 721 balance");
    //     assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //     assertEq(
    //         memeToken.balanceOf(address(c)), tierParams[tierParams.length - 1].amountThreshold, "ALICE MEME balance"
    //     );
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 721 balance");
    //     assertEq(meme1155.balanceOf(address(c), 1), 0, "ALICE 721 balance");
    // }

    // function test_721transferFromToHaveNoSelector() public {
    //     uint256 tokenId = tierParams[tierParams.length - 1].lowerId;
    //     uint256 amountThreshold = tierParams[tierParams.length - 1].amountThreshold;
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, amountThreshold, false);
    //     ContractWithoutSelector c = new ContractWithoutSelector();

    //     vm.expectRevert();
    //     meme721.transferFrom(BOB, address(c), tokenId);
    // }

    // function test_721transferFromFromHaveSelector() public {
    //     uint256 tokenId = tierParams[tierParams.length - 1].lowerId;
    //     uint256 amountThreshold = tierParams[tierParams.length - 1].amountThreshold;
    //     ContractWithSelector c = new ContractWithSelector();
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), address(c), amountThreshold, false);
    //     SENDER = address(c);

    //     hoax(SENDER);
    //     meme721.setApprovalForAll(address(this), true);

    //     meme721.transferFrom(address(c), ALICE, tokenId);

    //     assertEq(meme721.balanceOf(address(c)), 0, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), tokenId, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(SENDER), 0, "ALICE 721 balance");
    //     assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //     assertEq(memeToken.balanceOf(ALICE), amountThreshold, "ALICE MEME balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 721 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 721 balance");
    // }

    // function test_721transferFromNotTokenId() public {
    //     uint256 tokenId = tierParams[tierParams.length - 1].lowerId;
    //     uint256 amountThreshold = tierParams[tierParams.length - 1].amountThreshold;
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, amountThreshold, false);
    //     vm.expectRevert();
    //     meme721.transferFrom(BOB, ALICE, tokenId + 1);
    // }

    // function test_721transferFromRecipientCrossingHighestNoFungibleTierThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold, false
    //     );
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), ALICE, tierParams[tierParams.length - 1].amountThreshold - 1, false
    //     );
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 1, "ALICE 721 balance");
    //     meme721.transferFrom(BOB, ALICE, 1);

    //     assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
    //     assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
    //     assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //     assertEq(
    //         memeToken.balanceOf(ALICE),
    //         tierParams[tierParams.length - 2].amountThreshold - 1 + tierParams[tierParams.length - 2].amountThreshold,
    //         "ALICE MEME balance"
    //     );
    //     assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 2001, "ALICE 721 balance");

    //     MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
    //     MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
    //     assertEq(highestTier.nextUnmintedId, 2002, "highestTiernextUnmintedId");
    //     assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

    //     assertEq(secondHighestTier.nextUnmintedId, 2, "secondHighestTier.nextUnmintedId");
    //     assertEq(secondHighestTier.burnLength, 1, "secondHighestTier - burnLength");
    //     assertEq(memeToken.nextBurnId(tierParams.length - 1), 1, "secondHighestTier - burnIds");
    // }

    // function test_721transferFromRecipientCrossingSecondHighestNoFungibleTierThreshold() public {
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[1].amountThreshold, false);
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), ALICE, tierParams[tierParams.length - 3].amountThreshold - 1, false
    //     );
    //     assertEq(meme721.balanceOf(ALICE), 0, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 0, "ALICE 721 balance");
    //     meme721.transferFrom(BOB, ALICE, tierParams[1].lowerId);

    //     assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
    //     assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
    //     assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //     assertEq(
    //         memeToken.balanceOf(ALICE),
    //         tierParams[tierParams.length - 3].amountThreshold - 1 + tierParams[1].amountThreshold,
    //         "ALICE MEME balance"
    //     );
    //     assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 1, "ALICE 721 balance");

    //     MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
    //     MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
    //     assertEq(highestTier.nextUnmintedId, 2001, "highestTiernextUnmintedId");
    //     assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

    //     assertEq(secondHighestTier.nextUnmintedId, 2, "secondHighestTier.nextUnmintedId");
    //     assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    // }

    // function test_721transferFromRecipientNotCrossingHighestNoFungibleTierThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold, false
    //     );
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), ALICE, tierParams[tierParams.length - 2].amountThreshold, false
    //     );
    //     assertEq(meme721.nextOwnedTokenId(BOB), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 2, "ALICE 721 balance");
    //     meme721.transferFrom(BOB, ALICE, 1);

    //     assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
    //     assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
    //     assertEq(memeToken.balanceOf(BOB), 0, "BOB MEME balance");
    //     assertEq(
    //         memeToken.balanceOf(ALICE), tierParams[tierParams.length - 2].amountThreshold * 2, "ALICE MEME balance"
    //     );
    //     assertEq(meme721.balanceOf(BOB), 0, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 1, "ALICE 721 balance");

    //     MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
    //     MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
    //     assertEq(highestTier.nextUnmintedId, 2001, "highestTiernextUnmintedId");
    //     assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

    //     assertEq(secondHighestTier.nextUnmintedId, 1, "secondHighestTier.nextUnmintedId");
    //     assertEq(secondHighestTier.burnLength, 1, "secondHighestTier - burnLength");
    //     assertEq(memeToken.nextBurnId(tierParams.length - 1), 2, "secondHighestTier - burnLength");
    // }

    // function test_721transferFromSenderNotCrossingNoFungibleTierThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold * 2, false
    //     );
    //     assertEq(meme721.nextOwnedTokenId(BOB), 2001, "BOB tokenIdByowner");
    //     meme721.transferFrom(BOB, ALICE, tierParams[tierParams.length - 1].lowerId);

    //     assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
    //     assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
    //     assertEq(memeToken.balanceOf(BOB), tierParams[tierParams.length - 1].amountThreshold, "BOB MEME balance");
    //     assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 1].amountThreshold, "ALICE MEME balance");
    //     assertEq(meme721.balanceOf(BOB), 1, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(BOB), 2001, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 2002, "ALICE 721 balance");

    //     MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
    //     MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
    //     assertEq(highestTier.nextUnmintedId, 2003, "highestTiernextUnmintedId");
    //     assertEq(highestTier.burnLength, 0, "highestTier.burnLength");

    //     assertEq(secondHighestTier.nextUnmintedId, 0, "secondHighestTier.nextUnmintedId");
    //     assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    // }

    // function test_721transferFromSenderCrossingNoFungibleTierThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest),
    //         BOB,
    //         tierParams[tierParams.length - 1].amountThreshold + tierParams[tierParams.length - 2].amountThreshold,
    //         false
    //     );
    //     assertEq(meme721.nextOwnedTokenId(BOB), 2001, "BOB tokenIByOwner");
    //     meme721.transferFrom(BOB, ALICE, tierParams[tierParams.length - 1].lowerId);

    //     assertEq(meme1155.balanceOf(BOB, 0), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 1), 0, "BOB 1155 balance");
    //     assertEq(meme1155.balanceOf(BOB, 6), 0, "BOB 1155 balance +1");
    //     assertEq(meme1155.balanceOf(ALICE, 0), 0, "ALICE 1155 balance -1");
    //     assertEq(meme1155.balanceOf(ALICE, 1), 0, "ALICE 1155 balance");
    //     assertEq(meme1155.balanceOf(ALICE, 6), 0, "ALICE 1155 balance +1");
    //     assertEq(memeToken.balanceOf(BOB), tierParams[tierParams.length - 21].amountThreshold, "BOB MEME balance");
    //     assertEq(memeToken.balanceOf(ALICE), tierParams[tierParams.length - 1].amountThreshold, "ALICE MEME balance");
    //     assertEq(meme721.balanceOf(BOB), 1, "BOB 721 balance");
    //     assertEq(meme721.balanceOf(ALICE), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(BOB), 1, "ALICE 721 balance");
    //     assertEq(meme721.nextOwnedTokenId(ALICE), 2002, "ALICE 721 balance");

    //     MEME404.Tier memory highestTier = memeToken.getTier(tierParams.length);
    //     MEME404.Tier memory secondHighestTier = memeToken.getTier(tierParams.length - 1);
    //     assertEq(highestTier.nextUnmintedId, 2003, "highestTiernextUnmintedId");
    //     assertEq(highestTier.burnLength, 1, "highestTier.burnLength");
    //     assertEq(memeToken.nextBurnId(tierParams.length), 2002, "highestTier.burnLength");

    //     assertEq(secondHighestTier.nextUnmintedId, 0, "secondHighestTier.nextUnmintedId");
    //     assertEq(secondHighestTier.burnLength, 0, "secondHighestTier - burnLength");
    // }
}
