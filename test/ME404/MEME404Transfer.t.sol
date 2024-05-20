/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404TransferTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address SENDER = address(this);
    address RECEIVER = makeAddr("receiver");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
    }

    /// @notice Test Wallet A (1 MEME / ERC1155 #1) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (1 MEME / ERC1155 #1)
    function test_transferTier1_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Tier1_success";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        memeToken.transfer(RECEIVER, getAmountThreshold(TIER));
        vm.stopPrank();

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(TIER), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, getTokenIdForFungibleTier(TIER), 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(TIER, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Test Wallet A (Tier 6 / ERC1155 #6) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 6 / ERC1155 #5)

    /// @notice Test Wallet A (Tier 7 / ERC721 #1) -> All $MEME ->Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 7 / ERC721 #2)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 / ERC721 #1001) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 8 / ERC721 #1002)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: [#1001]

    /// @notice Test Wallet A (2 $MEME / ERC1155 #1) -> 1 $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (1 / ERC1155 #1) -> Wallet B (Tier 1 / ERC1155 #1)

    /// @notice Test Wallet A (Tier 7 * 2 / ERC721 #1 #2) -> Tier 7 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 / ERC721 #1) -> Wallet B (Tier 7 / ERC721 #3)
    /// Expected: Tier 7 Burn: [#2]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 * 2 / ERC721 #1001 #1002) -> Tier 8 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 / ERC721 #1001) -> Wallet B (Tier 8 / ERC721 #1003)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: [#1002]

    /// @notice Test Wallet A (Tier 8 + Tier 7 (MEME) / ERC721 #1001) -> Tier 8 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 / ERC721 #1) -> Wallet B (Tier 8 / ERC721 #1002)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: [#1001]

    /// @notice Test Wallet A (Tier 7 + Tier 6 (MEME) / ERC721 #1) -> Tier 7 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 6 / ERC1155 #6) -> Wallet B (Tier 7 / ERC721 #2)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 7 + Tier 6 (MEME) / ERC721 #1) -> Tier 6 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 / ERC721 #1) -> Wallet B (Tier 6 / ERC1155 #6)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 7 (MEME) / ERC721 #1001) -> Tier 7 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 / ERC721 #1001) -> Wallet B (Tier 7 / ERC721 #1)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 1 / ERC1155 #1) -> Tier 1 * $MEME -> Wallet B (Tier 1 / ERC1155 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 1 * 2 / ERC1155 #1)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 6 / ERC1155 #6) -> Tier 6 * $MEME -> Wallet B (Tier 6 / ERC1155 #6)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 6 * 2 / ERC1155 #6)

    /// @notice Test Wallet A (Tier 7 / ERC721 #1) -> Tier 7 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 7 * 2 / ERC721 #2 #3)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 7 / ERC721 #1001) -> Tier 7 * $MEME -> Wallet B (Tier 7 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 / ERC721 #1001) -> Wallet B (Tier 7 * 2 / ERC721 #1 #2)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 7 - 1 / ERC721 #1001) -> Tier 7 * $MEME -> Wallet B (Tier 7 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 - 1 / ERC721 #2) -> Wallet B (Tier 7 * 2 / ERC721 #1 #3)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: [#1001]

    /// @notice Test Wallet A (Tier 7 + Tier 7 - 1 / ERC721 #1) -> Tier 7 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 - 1 / ERC1155 #6) -> Wallet B (Tier 7 * 2 / ERC721 #2 #3)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 7 + Tier 6 - 1 / ERC721 #1) -> Tier 6 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 - 1 / ERC1155 #6) -> Wallet B (Tier 7 + Tier 6 / ERC721 #2)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 7 + Tier 6 - 1 / ERC721 #1) -> Tier 6 * $MEME -> Wallet B (Tier 7 - 1 / ERC1155 #6)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 - 1 / ERC1155 #6) -> Wallet B (Tier 7 + Tier 6 - 1 / ERC721 #2)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 7 + Tier 6 / ERC721 #1) -> Tier 6 * $MEME -> Wallet B (Tier 7 - 1 / ERC1155 #6)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 / ERC1155 #6) -> Wallet B (Tier 7 + Tier 6 / ERC721 #2)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 6 / ERC721 #1001) -> Tier 6 * $MEME -> Wallet B (Tier 8 - 1 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 /  ERC721 #1001) -> Wallet B (Tier 8 + Tier 6 - 1 / ERC721 #1002)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 6 / ERC721 #1001) -> Tier 6 * $MEME -> Wallet B (Tier 8 - 1 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 /  ERC721 #1001) -> Wallet B (Tier 8 + Tier 6 - 1 / ERC721 #1002)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: []

    /// @notice Test Wallet A (Tier 8 + Tier 6 - 1 / ERC721 #1001) -> Tier 6 * $MEME -> Wallet B (Tier 8 - 1 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 /  ERC721 #2) -> Wallet B (Tier 8 + Tier 6 - 1 / ERC721 #1002)
    /// Expected: Tier 7 Burn: [#1]
    /// Expected: Tier 8 Burn: [#1001]

    /// @notice Test Wallet A (Tier 8 + Tier 7 - 1 / ERC721 #1001) -> Tier 7 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice [ERC721 #5]
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 8 - 1 / ERC721 #3) -> Wallet B (Tier 7 * 2 / ERC721 #2 #4)
    /// Expected: Tier 7 Burn: []
    /// Expected: Tier 8 Burn: [#1001]

    /// @notice Test Wallet A (Tier 8 + Tier 7 / ERC721 #1001) -> Tier 8 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice Burn [ERC721 #5]
    /// @notice Burn [ERC721 #1005]
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 7 / ERC721 #4) -> Wallet B (Tier 8 + Tier 7 / ERC721 #1002)
    /// Expected: Tier 7 Burn: [#5, #2]
    /// Expected: Tier 8 Burn: [#1005, #1001]

    /// @notice Scenario 20: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> Highest Tier * MEME -> Wallet B (2nd HT / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2001) -> Wallet B (HT + 2nd HT / ERC721 #2003)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: [#2002]
    function test_transferScenario20_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "transferScenario20";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        vm.startPrank(SENDER);
        memeToken.transfer(RECEIVER, getAmountThreshold(TIER));
        vm.stopPrank();

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;

        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2003;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory sHTBurnIds = new uint256[](1);
        sHTBurnIds[0] = 1;
        uint256[] memory HTBurnIds = new uint256[](1);
        HTBurnIds[0] = 2002;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, sHTBurnIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTBurnIds, 2004, TEST);
    }

    /// @notice Test Wallet A (Tier 8 + Tier 7 / ERC721 #1001) -> Tier 8 * $MEME -> Wallet B (Tier 7 / ERC721 #2)
    /// @notice Burn [ERC721 #5]
    /// @notice Burn [ERC721 #1005]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 7 / ERC721 #2) -> Wallet B (Tier 8 + Tier 7 / ERC721 #1001)
    /// Expected: Tier 7 Burn: [#5]
    /// Expected: Tier 8 Burn: [#1005]

    /// @notice Test Wallet A (Tier 8 + Tier 7 / ERC721 #1001) -> Tier 7 * $MEME -> Wallet B (Tier 8 - 1 / ERC721 #2)
    /// @notice Burn [ERC721 #5]
    /// @notice Burn [ERC721 #1005]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 8 / ERC721 #1001) -> Wallet B (Tier 8 - 1 + Tier 7 / ERC721 #1005)
    /// Expected: Tier 7 Burn: [#5, #2]
    /// Expected: Tier 8 Burn: []

    // function test_transferFirstTier_success() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[0].amountThreshold, true);
    // }

    // function test_transferFirstTierHaveSelector() public {
    //     ContractWithSelector c = new ContractWithSelector();

    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         memeceptionBaseTest.transfer404(BOB, address(c), tierParams[i].amountThreshold, true);
    //     }
    // }

    // function test_transferFirstTierHaveNoSelector() public {
    //     ContractWithoutSelector c = new ContractWithoutSelector();
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         memeceptionBaseTest.transfer404(BOB, address(c), tierParams[i].amountThreshold, true);
    //     }
    // }

    // function test_transferFirstTierFromHaveSelector() public {
    //     ContractWithSelector c = new ContractWithSelector();

    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         memeceptionBaseTest.transfer404(address(c), BOB, tierParams[i].amountThreshold, true);
    //     }
    // }

    // function test_transferFirstTierFromHaveNoSelector() public {
    //     ContractWithoutSelector c = new ContractWithoutSelector();
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         memeceptionBaseTest.transfer404(address(c), BOB, tierParams[i].amountThreshold, true);
    //     }
    // }

    // function test_transferSecondTier() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[1].amountThreshold, true);
    // }

    // function test_transferThirdTier() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[2].amountThreshold, true);
    // }

    // function test_transferFourthTier() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[3].amountThreshold, true);
    // }

    // function test_transferFifthTier() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[4].amountThreshold, true);
    // }

    // function test_transferSecondHighestTier_success() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, true);
    // }

    // function test_transferHighestTier() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, true);
    // }

    // function test_transferNoBurn_firstTier() public {
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold * 2, false);
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[0].amountThreshold, false);
    // }

    // function test_transferNoBurn_SecondHighestTier() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold * 2, false
    //     );
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, false);
    // }

    // function test_transferNoBurn_HighestTier() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold * 2, false
    //     );
    //     memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, false);
    // }

    // function test_transferZero() public {
    //     memeceptionBaseTest.transfer404(BOB, ALICE, 0, false);
    // }

    // function test_transferNotEnough() public {
    //     memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, 1, false);
    //     vm.expectRevert();
    //     memeceptionBaseTest.transfer404(BOB, ALICE, 2, false);
    // }

    // function test_transferNoUpgradeTier() public {
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         address RECEIVER = makeAddr(i.toString());
    //         memeceptionBaseTest.transfer404(BOB, RECEIVER, tierParams[i].amountThreshold, true);
    //         // No Upgrade 2nd time
    //         uint256 deltaToNexTier = i < tierParams.length - 1
    //             ? tierParams[i + 1].amountThreshold - tierParams[i].amountThreshold - 1
    //             : tierParams[i].amountThreshold;
    //         memeceptionBaseTest.transfer404(BOB, RECEIVER, deltaToNexTier, true);
    //     }
    // }

    // function test_transferNoDownTier() public {
    //     for (uint256 i = 1; i < tierParams.length; i++) {
    //         address RECEIVER = makeAddr(i.toString());
    //         memeceptionBaseTest.transfer404(
    //             address(memeceptionBaseTest), BOB, tierParams[i].amountThreshold + 10, false
    //         );
    //         // No Downgrade 2 times
    //         memeceptionBaseTest.transfer404(BOB, RECEIVER, 1, false);
    //         memeceptionBaseTest.transfer404(BOB, RECEIVER, 9, false);
    //     }
    // }

    // function test_transferFromAllThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         address FROM = makeAddr(i.toString());
    //         memeToken.transfer(FROM, tierParams[i].amountThreshold);
    //         memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold, false);
    //     }
    // }

    // function test_transferFromAllThresholdNoDown() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         address FROM = makeAddr(i.toString());
    //         memeToken.transfer(FROM, tierParams[i].amountThreshold);
    //         memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold, false);
    //     }
    // }

    // function test_transferEdgeCase() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );

    //     address FROM = makeAddr("FROM");
    //     address TO = makeAddr("TO");
    //     memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold);
    //     memeToken.transfer(TO, tierParams[tierParams.length - 1].amountThreshold - 1);

    //     memeceptionBaseTest.transfer404(FROM, TO, 1, false);
    // }

    // function test_transferEdgeCaseTwo() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );

    //     address FROM = makeAddr("FROM");
    //     address TO = makeAddr("TO");
    //     memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
    //     memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold - 1);

    //     memeceptionBaseTest.transfer404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    // }

    // function test_transferEdgeCaseThird() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );

    //     address FROM = makeAddr("FROM");
    //     address TO = makeAddr("TO");
    //     memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
    //     memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold);

    //     memeceptionBaseTest.transfer404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    // }

    // function test_transferToAllThreshold() public {
    //     memeceptionBaseTest.transfer404(
    //         address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
    //     );
    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         for (uint256 j = 0; j < tierParams.length; j++) {
    //             address FROM = makeAddr(string.concat("FROM", i.toString(), j.toString()));
    //             address TO = makeAddr(string.concat("TO", j.toString(), i.toString()));

    //             memeToken.transfer(FROM, tierParams[i].amountThreshold);
    //             if (i >= j) {
    //                 memeceptionBaseTest.transfer404(FROM, TO, tierParams[j].amountThreshold, false);
    //             } else {
    //                 vm.expectRevert();
    //                 memeceptionBaseTest.transfer404(FROM, TO, tierParams[j].amountThreshold, false);
    //             }
    //         }
    //     }
    // }
}
