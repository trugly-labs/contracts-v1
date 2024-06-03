/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404FlowTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address CHARLIE = makeAddr("charlie");
    address JANET = makeAddr("janet");
    address SENDER = address(this);
    address RECEIVER = makeAddr("receiver");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initializeToken();

        vm.startPrank(BOB);
        meme721.setApprovalForAll(address(this), true);
        meme1155.setApprovalForAll(address(this), true);
        memeToken.approve(address(this), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(ALICE);
        meme721.setApprovalForAll(address(this), true);
        meme1155.setApprovalForAll(address(this), true);
        memeToken.approve(address(this), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(JANET);
        meme721.setApprovalForAll(address(this), true);
        meme1155.setApprovalForAll(address(this), true);
        memeToken.approve(address(this), type(uint256).max);
        vm.stopPrank();
    }

    /// @notice Flow #0
    /// Wallet BOB: Tier 1 * 10 MEME / ERC1155 #1
    /// Wallet ALICE: Tier #2 + Tier 1/ ERC1155 #2
    /// Wallet CHARLIE: TIer 3 + Tier 2 / ERC #1
    /// Wallet JANET: TIer 4 / ERC #2001
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// @notice Actions:
    /// - Janet (Tier 4 - 1 ether / #2 #3 .. #20) -> 1 Ether -> Charlie (Tier 3 + Tier 2 + 1 ether / ERC721 #1)
    /// - Charlie (Tier 2 + 1 ether / ERC1155 #2) -> ERC721 #1 -> ALICE (Tier 3 + Tier 2 + Tier 1 / ERC721 #1)
    /// - Charlie (Tier 2 / ERC1155 #2) -> 1 ether -> JANET (Tier 4 / ERC721 #2002)
    /// - Charlie (0 / 0) -> ERC1155 #2 -> JANET (Tier 4 + Tier2 / ERC721 #2002)
    /// - BACK AND FORTH: Janet -> ERC721 #2002 -> BOB
    /// - Burn Through all unminted for Tier 4 : Janet -> Tier 4 * MEME -> BOB
    /// - Mint Tier 4 * 2 -> BOB (Tier 1 * 10 + Tier 4 * 2)
    /// - Mint Tier 4 * 2 -> ALICE (Tier 4 * 2 + Tier 3 + Tier 2 + Tier 1)
    function test_flow_0_success() public {
        initWalletWithTokens(BOB, getAmountThreshold(1) * 10);
        initWalletWithTokens(ALICE, getAmountThreshold(2) + getAmountThreshold(1));
        initWalletWithTokens(CHARLIE, getAmountThreshold(3) + getAmountThreshold(2));
        initWalletWithTokens(JANET, getAmountThreshold(4));

        /// - Janet (Tier 4 - 1 ether / #2 #3 .. #21) -> 1 Ether -> Charlie (Tier 3 + Tier 2 + 1 ether / ERC721 #1)
        string memory TEST = "Flow #0 - Janet -> Charlie";
        vm.startPrank(JANET);
        memeToken.transfer(CHARLIE, 1 ether);
        vm.stopPrank();

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](19);
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            senderTokenIds[i] = i + 2;
        }
        assertMEME404(JANET, getAmountThreshold(4) - 1 ether, TEST);
        assertMEME1155(JANET, 1, 0, TEST);
        assertMEME721(JANET, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(CHARLIE, getAmountThreshold(3) + getAmountThreshold(2) + 1 ether, TEST);
        assertMEME1155(CHARLIE, 1, 0, TEST);
        assertMEME721(CHARLIE, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2002, TEST);

        /// - Charlie (Tier 2 + 1 ether / ERC1155 #2) -> ERC721 #1 -> ALICE (Tier 3 + Tier 2 + Tier 1 / ERC721 #1)
        TEST = "Flow #0 - Charlie -> Alice";

        vm.expectRevert();
        meme721.transferFrom(CHARLIE, ALICE, 1);
        vm.startPrank(CHARLIE);
        meme721.setApprovalForAll(address(this), true);
        vm.stopPrank();
        meme721.transferFrom(CHARLIE, ALICE, 1);

        // Assert Sender
        assertMEME404(JANET, getAmountThreshold(4) - 1 ether, TEST);
        assertMEME404(CHARLIE, getAmountThreshold(2) + 1 ether, TEST);
        assertMEME1155(CHARLIE, 2, 1, TEST);
        assertMEME721(CHARLIE, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(ALICE, getAmountThreshold(3) + getAmountThreshold(2) + getAmountThreshold(1), TEST);
        assertMEME1155(ALICE, 1, 0, TEST);
        assertMEME721(ALICE, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2002, TEST);

        /// - Charlie (Tier 2 / ERC1155 #2) -> 1 ether -> JANET (Tier 4 / ERC721 #2002)
        TEST = "Flow #0 - Charlie -> Janet";

        vm.expectRevert();
        memeToken.transferFrom(CHARLIE, JANET, 1 ether);

        hoax(CHARLIE);
        memeToken.approve(address(this), 1 ether);
        memeToken.transferFrom(CHARLIE, JANET, 1 ether);

        // Assert SENDER
        assertMEME404(CHARLIE, getAmountThreshold(2), TEST);
        assertMEME1155(CHARLIE, 2, 1, TEST);
        assertMEME721(CHARLIE, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(JANET, getAmountThreshold(4), TEST);
        assertMEME1155(JANET, 2, 0, TEST);
        assertMEME721(JANET, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        burnTokenIds = new uint256[](19);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length + 1 - i;
        }
        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);

        /// - Charlie (0 / 0) -> ERC1155 #2 -> JANET (Tier 4 + Tier2 / ERC721 #2002)
        TEST = "Flow #0 - Charlie -> Janet #2";

        vm.expectRevert();
        meme1155.safeTransferFrom(CHARLIE, JANET, 2, 1, "");
        hoax(CHARLIE);
        meme1155.setApprovalForAll(address(this), true);

        meme1155.safeTransferFrom(CHARLIE, JANET, 2, 1, "");

        // Assert SENDER
        assertMEME404(CHARLIE, 0, TEST);
        assertMEME1155(CHARLIE, 2, 0, TEST);
        assertMEME721(CHARLIE, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(JANET, getAmountThreshold(4) + getAmountThreshold(2), TEST);
        assertMEME1155(JANET, 2, 0, TEST);
        assertMEME721(JANET, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        burnTokenIds = new uint256[](19);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length + 1 - i;
        }
        HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);

        /// - BACK AND FORTH: Janet -> ERC721 #2002 -> BOB (Tier 1 * 10)
        TEST = "Flow #0 - BACK AND FORTH: Janet -> ERC721 #2002 -> BOB (Tier 1 * 10";
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            meme721.transferFrom(JANET, BOB, 2002);
            // Assert SENDER
            assertMEME404(JANET, getAmountThreshold(2), TEST);
            assertMEME1155(JANET, 2, 1, TEST);
            assertMEME721(JANET, EMPTY_UINT_ARRAY, TEST);

            // Assert RECEIVER
            receiverTokenIds = new uint256[](1);
            receiverTokenIds[0] = 2002;
            assertMEME404(BOB, getAmountThreshold(4) + getAmountThreshold(1) * 10, TEST);
            assertMEME1155(BOB, 2, 0, TEST);
            assertMEME721(BOB, receiverTokenIds, TEST);

            // Assert MEME404 Burn and Unminted
            assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
            assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
            assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
            assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);

            meme721.transferFrom(BOB, JANET, 2002);
            // Assert SENDER
            assertMEME404(BOB, getAmountThreshold(1) * 10, TEST);
            assertMEME1155(BOB, 1, 1, TEST);
            assertMEME721(BOB, EMPTY_UINT_ARRAY, TEST);

            // Assert RECEIVER
            receiverTokenIds = new uint256[](1);
            receiverTokenIds[0] = 2002;
            assertMEME404(JANET, getAmountThreshold(4) + getAmountThreshold(2), TEST);
            assertMEME1155(JANET, 2, 0, TEST);
            assertMEME721(JANET, receiverTokenIds, TEST);

            // Assert MEME404 Burn and Unminted
            assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
            assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
            assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
            assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);
        }

        /// - Burn Through all unminted for Tier 4 : Janet -> Tier 4 * MEME -> BOB
        TEST = "Flow #0 -Burn Through all unminted for Tier 4 : Janet -> Tier 4 * MEME -> BOB";
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            memeToken.transferFrom(JANET, BOB, getAmountThreshold(4));
            memeToken.transferFrom(BOB, JANET, getAmountThreshold(4));
        }

        // Assert SENDER
        senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2100;
        assertMEME404(JANET, getAmountThreshold(2) + getAmountThreshold(4), TEST);
        assertMEME1155(JANET, 2, 0, TEST);
        assertMEME721(JANET, senderTokenIds, TEST);

        // Assert RECEIVER
        assertMEME404(BOB, getAmountThreshold(1) * 10, TEST);
        assertMEME1155(BOB, 1, 1, TEST);
        assertMEME721(BOB, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 1);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);

        /// - Mint Tier 4 * 2 -> BOB (Tier 1 * 10 + Tier 4 * 2)
        TEST = "Flow #0: Mint Tier 4 * 2 -> BOB (Tier 1 * 10 + Tier 4 * 2)";
        initWalletWithTokens(BOB, getAmountThreshold(4) * 2);
        // Assert RECEIVER
        receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2099;
        receiverTokenIds[1] = 2098;
        assertMEME404(BOB, getAmountThreshold(1) * 10 + getAmountThreshold(4) * 2, TEST);
        assertMEME1155(BOB, 1, 0, TEST);
        assertMEME721(BOB, receiverTokenIds, TEST);

        HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 3);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);

        /// - Mint Tier 4 * 2 -> ALICE (Tier 4 * 2 + Tier 3 + Tier 2 + Tier 1)
        TEST = "Flow #0: Mint Tier 4 * 2 -> ALICE (Tier 4 * 2 + Tier 3 + Tier 2 + Tier 1)";
        initWalletWithTokens(ALICE, getAmountThreshold(4) * 2);
        // Assert RECEIVER
        receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2097;
        receiverTokenIds[1] = 2096;
        assertMEME404(
            ALICE,
            getAmountThreshold(3) + getAmountThreshold(1) + getAmountThreshold(2) + getAmountThreshold(4) * 2,
            TEST
        );
        assertMEME1155(ALICE, 1, 0, TEST);
        assertMEME721(ALICE, receiverTokenIds, TEST);

        burnTokenIds = new uint256[](20);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i;
        }
        HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 5);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 21, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);
    }
}
