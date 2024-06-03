/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404TansferFromTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address SENDER = makeAddr("SENDER");
    address RECEIVER = makeAddr("receiver");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initializeToken();

        vm.startPrank(SENDER);
        memeToken.approve(address(this), type(uint256).max);
        vm.stopPrank();
    }

    function test_404transferFromNotApproval() public {
        address NO_APPROVAL = makeAddr("NO_APPROVAL");
        initWalletWithTokens(NO_APPROVAL, 1);

        vm.expectRevert();
        memeToken.transferFrom(NO_APPROVAL, ALICE, 1);
    }

    function test_404transferFromNotEnoughApproval() public {
        address NOT_ENOUGH_APPROVAL = makeAddr("NOT_ENOUGH_APPROVAL");
        initWalletWithTokens(NOT_ENOUGH_APPROVAL, 1);

        hoax(NOT_ENOUGH_APPROVAL);
        memeToken.approve(address(this), 1);

        vm.expectRevert();
        memeToken.transferFrom(NOT_ENOUGH_APPROVAL, ALICE, 2);
    }

    /// @notice Scenario #1 Test Wallet A (1 MEME / ERC1155 #1) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (1 MEME / ERC1155 #1)
    function test_404transferFromScenario1_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(TIER, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #2: Test Wallet A (Tier 2 / ERC1155 #2) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 2 / ERC1155 #2)
    function test_404transferFromScenario2_success() public {
        // Init Test
        uint256 TIER = 2;
        string memory TEST = "Scenario #2";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 2, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(TIER, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #3: Test Wallet A (Tier 3 / ERC721 #1) -> All $MEME ->Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 / ERC721 #2)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario3_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #3";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #4: Test Wallet A (Tier 4 / ERC721 #2001) -> All $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 / ERC721 #2002)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario4_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #4";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2003, TEST);
    }

    /// @notice Scenario 5: Test Wallet A (2 $MEME / ERC1155 #1) -> 1 $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (1 / ERC1155 #1) -> Wallet B (Tier 1 / ERC1155 #1)
    function test_404transferFromScenario5_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #5";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario 6: Test Wallet A (Tier 3 * 2 / ERC721 #1 #2) -> Tier 3 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1) -> Wallet B (Tier 3 / ERC721 #3)
    /// Expected: Tier 3 Burn: [#2]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario6_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #6";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 3;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario 7: Test Wallet A (Tier 4 * 2 / ERC721 #2001 #2002) -> Tier 4 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 / ERC721 #2001) -> Wallet B (Tier 4 / ERC721 #2003)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: [#2002]
    function test_404transferFromScenario7_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #7";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2003;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2002;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2004, TEST);
    }

    /// @notice Scenario #8: Test Wallet A (Tier 4 + Tier 3 (MEME) / ERC721 #2001) -> Tier 4 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1) -> Wallet B (Tier 4 / ERC721 #2002)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario8_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #8";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2003, TEST);
    }

    /// @notice Scenario #9: Test Wallet A (Tier 1 + Tier 3 (MEME) / ERC721 #1) -> Tier 3 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 1 / ERC1155 #1) -> Wallet B (Tier 3 / ERC721 #2)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario9_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #9";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(1));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(1), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #10: Test Wallet A (Tier 2 + Tier 3 (MEME) / ERC721 #1) -> Tier 2 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1) -> Wallet B (Tier 2 / ERC1155 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario10_success() public {
        // Init Test
        uint256 TIER = 2;
        string memory TEST = "Scenario #10";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(1), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 2, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #11: Test Wallet A (Tier 4 + Tier 3 (MEME) / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 / ERC721 #2001) -> Wallet B (Tier 3 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario11_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #11";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(1), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #12: Test Wallet A (Tier 1 / ERC1155 #1) -> Tier 1 * $MEME -> Wallet B (Tier 1 / ERC1155 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 1 * 2 / ERC1155 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario12_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #12";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #14: Test Wallet A (Tier 3 / ERC721 #1) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 * 2 / ERC721 #2 #3)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario14_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #14";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2;
        receiverTokenIds[1] = 3;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #16: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 / ERC721 #2001) -> Wallet B (Tier 3 * 2 / ERC721 #1 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario16_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #16";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1;
        receiverTokenIds[1] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #17: Test Wallet A (Tier 4 + Tier 3 - 1 / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 - 1 / ERC721 #2 #3 #4 #5 .... #20) -> Wallet B (Tier 3 * 2 / ERC721 #1 #21)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario17_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #17";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256 expectedSenderTokenLength = (getAmountThreshold(4) - 1) / getAmountThreshold(3);
        uint256[] memory senderTokenIds = new uint256[](expectedSenderTokenLength);
        for (uint256 i = 0; i < expectedSenderTokenLength; i++) {
            senderTokenIds[i] = 2 + i;
        }
        assertMEME404(SENDER, getAmountThreshold(4) - 1, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1;
        receiverTokenIds[1] = 21;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 22, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2002, TEST);
    }

    /// @notice Scenario #18: Test Wallet A (Tier 3 + Tier 3 - 1 / ERC721 #1) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 - 1 / ERC1155 #2) -> Wallet B (Tier 3 * 2 / ERC721 #2 #3)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario18_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #18";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2 - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER) + 1);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(3) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2;
        receiverTokenIds[1] = 3;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2 + 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #19: Test Wallet A (Tier 3 + Tier 2 - 1 / ERC721 #1) -> Tier 2 * $MEME -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 - 1 / ERC1155 #2) -> Wallet B (Tier 3 + Tier 2 / ERC721 #2)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario19_success() public {
        // Init Test
        string memory TEST = "Scenario #19";
        uint256 TIER = 2;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(3) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #20: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> Highest Tier * MEME -> Wallet B (2nd HT / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2001) -> Wallet B (HT + 2nd HT / ERC721 #2003)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: [#2002]
    function test_404transferFromScenario20_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "transferScenario20";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

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

    /// @notice Scenario #21: Test Wallet A (Tier 3 + Tier 2 - 1 / ERC721 #1) -> Tier 2 * $MEME -> Wallet B (Tier 3 - 1 / ERC1155 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 - 1 / ERC1155 #2) -> Wallet B (Tier 3 + Tier 2 - 1 / ERC721 #2)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario21_success() public {
        // Init Test
        string memory TEST = "Scenario #21";
        uint256 TIER = 2;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3) - 1);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(3) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3) - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #23: Test Wallet A (Tier 4 + Tier 2 / ERC721 #2001) -> Tier 2 * $MEME -> Wallet B (Tier 4 - 1 / ERC721 #1 #2, .., #19)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 /  ERC721 #2001) -> Wallet B (Tier 4 + Tier 2 - 1 / ERC721 #2002)
    /// Expected: Tier 3 Burn: [#19, ...., #2, #1]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario23_success() public {
        // Init Test
        string memory TEST = "Scenario #23";
        uint256 TIER = 2;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256 expectedBurnLenth = (getAmountThreshold(4) - 1) / getAmountThreshold(3);
        uint256[] memory burnTokenIds = new uint256[](expectedBurnLenth);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, expectedBurnLenth + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #25: Test Wallet A (Tier 4 + Tier 3 - 1 / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (Tier 4 - 1 / ERC721 #1 #2 ... #19)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 /  ERC721 #20 #21 .. #38) -> Wallet B (Tier 4 + Tier 3 - 1 / ERC721 #2002)
    /// Expected: Tier 3 Burn: [#19, .. #2, #1]
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario25_success() public {
        // Init Test
        string memory TEST = "Scenario #25";
        uint256 TIER = 3;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](19);
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            senderTokenIds[i] = 20 + i;
        }
        assertMEME404(SENDER, getAmountThreshold(4) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](19);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i;
        }
        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 39, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);
    }

    /// @notice Scenario #26: Test Wallet A (Tier 4 + Tier 3 - 1 / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #3)
    /// @notice Burn List [ERC721 #1]
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 - 1 / ERC721 #4 .. #21 #22) -> Wallet B (Tier 3 * 2 / ERC721 #3 #23)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario26_success() public {
        // Init Test
        string memory TEST = "Scenario #26";
        uint256 TIER = 3;
        initWalletWithTokens(BOB, getAmountThreshold(TIER));
        vm.startPrank(BOB);
        memeToken.transfer(ALICE, getAmountThreshold(TIER));
        vm.stopPrank();
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](19);
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            senderTokenIds[i] = 4 + i;
        }
        assertMEME404(SENDER, getAmountThreshold(4) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 3;
        receiverTokenIds[1] = 23;
        assertMEME404(RECEIVER, getAmountThreshold(3) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;

        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 24, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2002, TEST);
    }

    /// @notice Scenario #27: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2003) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn [ERC721 #1]
    /// @notice Burn [ERC721 #2001]
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #3) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2004)
    /// Expected: Tier 3 Burn: [#1, #2]
    /// Expected: Tier 4 Burn: [#2001, #2003]
    function test_404transferFromScenario27_success() public {
        // Init Test
        string memory TEST = "Scenario #27";
        uint256 TIER = 4;
        initWalletWithTokens(BOB, getAmountThreshold(TIER));
        vm.startPrank(BOB);
        memeToken.transfer(ALICE, getAmountThreshold(TIER));
        vm.stopPrank();
        initWalletWithTokens(BOB, getAmountThreshold(3));
        vm.startPrank(BOB);
        memeToken.transfer(ALICE, getAmountThreshold(3));
        vm.stopPrank();

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 3;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2004;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(4), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](2);
        burnTokenIds[0] = 1;
        burnTokenIds[1] = 2;

        uint256[] memory HTburnTokenIds = new uint256[](2);
        HTburnTokenIds[0] = 2001;
        HTburnTokenIds[1] = 2003;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2005, TEST);
    }

    /// -------------- SCENARIOS WHERE UNLIMTED TOKENS ARE NO LONGER AVAILABLE --------------- ///

    /// @notice Scenario #28: Test Wallet A (Tier 4 / ERC721 #2099) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice sHTBurn []
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2097 #2099]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2097]
    function test_404transferFromScenario28_success() public {
        // Init Test
        string memory TEST = "Scenario #28";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[TIER - 1].upperId - tierParams[TIER - 1].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(TIER));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(TIER));
            vm.stopPrank();
        }
        // Safety Check
        assertEq(memeToken.getTier(TIER).nextUnmintedId, tierParams[TIER - 1].upperId + 1);
        assertEq(
            memeToken.getBurnedLengthForTier(TIER),
            (tierParams[TIER - 1].upperId - tierParams[TIER - 1].lowerId + 1) / 2
        );
        assertEq(memeToken.nextBurnId(TIER), tierParams[TIER - 1].upperId - 1);

        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2099;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;

        uint256[] memory HTburnTokenIds =
            new uint256[]((tierParams[TIER - 1].upperId - tierParams[TIER - 1].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);
    }

    /// @notice Scenario #29: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2099) -> Tier 3 * $MEME -> Wallet B (Tier 4 + Tier 4 - Tier 3/ ERC721 #2097)
    /// @notice sHTBurn []
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2093 #2095]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 4 / #2099) -> Wallet B (Tier 4 * 2 / ERC721 #2097 #2095)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2093]
    function test_404transferFromScenario29_success() public {
        // Init Test
        string memory TEST = "Scenario #29";
        uint256 TIER = 3;
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(4));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(4));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) * 2 - getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2099;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2097;
        receiverTokenIds[1] = 2095;
        assertMEME404(RECEIVER, getAmountThreshold(4) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) / 2 - 3);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);
    }

    /// @notice Scenario #30: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2099) -> Tier 4 * $MEME -> Wallet B (0 / 0)
    /// @notice sHTBurn [#1]
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2093 #2095 #2097]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / #3) -> Wallet B (Tier 4 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2093, #2095, #2097]
    function test_404transferFromScenario30_success() public {
        // Init Test
        string memory TEST = "Scenario #30";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(4));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(4));
            vm.stopPrank();
        }
        initWalletWithTokens(BOB, getAmountThreshold(3));
        vm.startPrank(BOB);
        memeToken.transfer(ALICE, getAmountThreshold(3));
        vm.stopPrank();

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 3;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2099;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        uint256[] memory HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);
    }

    /// @notice Scenario #31: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #3 .. #1997]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2002)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995 #1997]
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario31_success() public {
        // Init Test
        string memory TEST = "Scenario #31";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }
        // Safety Check
        assertEq(memeToken.getTier(3).nextUnmintedId, tierParams[2].upperId + 1);
        assertEq(memeToken.getBurnedLengthForTier(3), (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2);
        assertEq(memeToken.nextBurnId(3), tierParams[2].upperId - 1);

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1999;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(3), 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;

        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2003, TEST);
    }

    /// @notice Scenario #32: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> Tier 4 * $MEME -> Wallet B (Tier 4 / ERC721 #2002)
    /// @notice sHTBurn [#1 #3 .. #1997 #1999]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2003)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995 #1997]
    /// Expected: Tier 4 Burn: [#2001]
    function test_404transferFromScenario32_success() public {
        // Init Test
        string memory TEST = "Scenario #32";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }
        // Safety Check
        assertEq(memeToken.getTier(3).nextUnmintedId, tierParams[2].upperId + 1);
        assertEq(memeToken.getBurnedLengthForTier(3), (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2);
        assertEq(memeToken.nextBurnId(3), tierParams[2].upperId - 1);

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1999;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(4) * 2, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2002;
        receiverTokenIds[1] = 2003;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;

        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2004, TEST);
    }

    /// @notice Scenario #33: Test Wallet A (Tier 3 * 3 / ERC721 #1999 #1997 #1995) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #1993)
    /// @notice sHTBurn [#1 #3 .. #1991]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999 #1997) -> Wallet B (Tier 3 * 2 / ERC721 #1993 #1995)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1991]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario33_success() public {
        // Init Test
        string memory TEST = "Scenario #33";
        uint256 TIER = 3;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 3);
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](2);
        senderTokenIds[0] = 1999;
        senderTokenIds[1] = 1997;
        assertMEME404(SENDER, getAmountThreshold(3) * 2, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(4) * 2, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1993;
        receiverTokenIds[1] = 1995;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 4);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #34: Test Wallet A (Tier 4 + tier 3 / ERC721 #2001) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #3 .. #1997]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 4 / ERC721 #2001) -> Wallet B (Tier 3 * 2 / ERC721 #1999 #1997)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario34_success() public {
        // Init Test
        string memory TEST = "Scenario #34";
        uint256 TIER = 3;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(4) + getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(4) * 2, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1999;
        receiverTokenIds[1] = 1997;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 2);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #35: Test Wallet A (tier 3 + tier 2 / ERC721 #1999) -> Tier 3 * $MEME -> Wallet B (Tier 3 / ERC721 #1997)
    /// @notice sHTBurn [#1 #3 .. #1995]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 2 / ERC1155 #2) -> Wallet B (Tier 3 * 2 / ERC721 #1997 #1999)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995]
    /// Expected: Tier 4 Burn: []
    function test_404transferFromScenario35_success() public {
        // Init Test
        string memory TEST = "Scenario #35";
        uint256 TIER = 3;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(2) + getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(2), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1997;
        receiverTokenIds[1] = 1999;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 2);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #36: Test Wallet A (Tier 4 + tier 3 / ERC721 #2099) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #2 .. #1997 #1998]
    /// @notice HTBurn [#2001 #2002 ... #2098]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1 #2 .. #1998]
    /// Expected: Tier 4 Burn: [#2001 #2002 ... #2098]
    function test_404transferFromScenario36_success() public {
        // Init Test
        string memory TEST = "Scenario #36";
        uint256 TIER = 4;

        initWalletWithTokens(BOB, getAmountThreshold(3));
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            vm.startPrank(BOB);
            memeToken.transfer(ALICE, getAmountThreshold(3));
            vm.stopPrank();
            vm.startPrank(ALICE);
            memeToken.transfer(BOB, getAmountThreshold(3));
            vm.stopPrank();
        }

        address BOB2 = makeAddr("BOB2");
        initWalletWithTokens(BOB2, getAmountThreshold(4));
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            vm.startPrank(BOB2);
            memeToken.transfer(ALICE, getAmountThreshold(4));
            vm.stopPrank();
            vm.startPrank(ALICE);
            memeToken.transfer(BOB2, getAmountThreshold(4));
            vm.stopPrank();
        }

        // Safety Check
        assertEq(memeToken.getTier(3).nextUnmintedId, tierParams[2].upperId + 1, "Tier 3 - nextUnmintedId");
        assertEq(
            memeToken.getBurnedLengthForTier(3), tierParams[2].upperId - tierParams[2].lowerId, "Tier 3 - BurnedLength"
        );
        assertEq(memeToken.nextBurnId(3), tierParams[2].upperId - 1, "Tier 3 - nextBurnId");

        assertEq(memeToken.getTier(4).nextUnmintedId, tierParams[3].upperId + 1, "Tier 4 - nextUnmintedId");
        assertEq(
            memeToken.getBurnedLengthForTier(4), tierParams[3].upperId - tierParams[3].lowerId, "Tier 4 - BurnedLength"
        );
        assertEq(memeToken.nextBurnId(4), tierParams[3].upperId - 1, "Tier 4 - nextBurnId");

        initWalletWithTokens(SENDER, getAmountThreshold(3) + getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1999;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2099;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) - 2);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i;
        }
        uint256[] memory HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 2);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = tierParams[3].lowerId + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, tierParams[3].upperId + 1, TEST);
    }

    /// @notice Scenario #37: Test Wallet A (Tier 4 + tier 4 / ERC721 #2099 #2098) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #2 .. #1997 #1998]
    /// @notice HTBurn [#2001 #2002 ... #2097]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 4 / ERC721 #2099) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2098)
    /// Expected: Tier 3 Burn: [#1 #2 .. #1998 #1999]
    /// Expected: Tier 4 Burn: [#2001 #2002 ... #2097]
    function test_404transferFromScenario37_success() public {
        // Init Test
        string memory TEST = "Scenario #37";
        uint256 TIER = 4;

        initWalletWithTokens(BOB, getAmountThreshold(3));
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            vm.startPrank(BOB);
            memeToken.transfer(ALICE, getAmountThreshold(3));
            vm.stopPrank();
            vm.startPrank(ALICE);
            memeToken.transfer(BOB, getAmountThreshold(3));
            vm.stopPrank();
        }

        address BOB2 = makeAddr("BOB2");
        initWalletWithTokens(BOB2, getAmountThreshold(4));
        for (uint256 i = 0; i < (tierParams[3].upperId - tierParams[3].lowerId + 1) / 2; i++) {
            vm.startPrank(BOB2);
            memeToken.transfer(ALICE, getAmountThreshold(4));
            vm.stopPrank();
            vm.startPrank(ALICE);
            memeToken.transfer(BOB2, getAmountThreshold(4));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2099;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2098;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) - 1);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i;
        }
        uint256[] memory HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 3);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = tierParams[3].lowerId + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, tierParams[3].upperId + 1, TEST);
    }

    /// @notice Scenario #38 Test Wallet A (1 MEME / ERC1155 #1) -> All $MEME -> Treasury (EXEMPT) (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (1 MEME / 0)
    function test_404transferFromScenario38_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #38";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        RECEIVER = treasury;

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #39 Test Wallet A (Tier 3 MEME / ERC722 #1) -> All $MEME -> Treasury (EXEMPT) (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 MEME / 0)
    function test_404transferFromScenario39_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #39";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        RECEIVER = treasury;

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #40 Test Wallet A (Tier 3 MEME / ERC722 #1) -> ERC721 #1 -> Treasury (EXEMPT) (Tier 3 MEME / ERC721 #1)
    /// @notice Treasury  (Tier 3 / ERC721 #1) -> Tier 2 MEME -> Wallet A (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 2 MEME / ERC1155 #2) -> Treasury (Tier 3 MEME / 0)
    function test_404transferFromScenario40_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #40";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        RECEIVER = treasury;

        vm.startPrank(SENDER);
        meme721.setApprovalForAll(address(this), true);
        vm.stopPrank();
        meme721.transferFrom(SENDER, RECEIVER, 1);

        vm.startPrank(treasury);
        memeToken.approve(address(this), getAmountThreshold(2));
        vm.stopPrank();
        memeToken.transferFrom(RECEIVER, SENDER, getAmountThreshold(2));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(2), TEST);
        assertMEME1155(SENDER, 2, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(treasury, getAmountThreshold(TIER) - getAmountThreshold(2), TEST);
        assertMEME1155(treasury, 2, 0, TEST);
        assertMEME721(treasury, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #41 Test Wallet A (Tier 4 MEME / ERC722 #2001) -> ERC721 #2001 -> Treasury (EXEMPT) (Tier 4 MEME / ERC721 #2001)
    /// @notice Treasury  (Tier 4 MEME / ERC721 #2001) -> Tier 3 MEME -> Wallet A (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 MEME / ERC721 #1) -> Treasury (Tier 4 - Tier 3 MEME / 0)
    function test_404transferFromScenario41_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #41";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        RECEIVER = treasury;

        vm.startPrank(SENDER);
        meme721.setApprovalForAll(address(this), true);
        vm.stopPrank();
        meme721.transferFrom(SENDER, RECEIVER, 2001);

        vm.startPrank(treasury);
        memeToken.approve(address(this), getAmountThreshold(3));
        vm.stopPrank();
        memeToken.transferFrom(RECEIVER, SENDER, getAmountThreshold(3));

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 2, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        assertMEME404(treasury, getAmountThreshold(TIER) - getAmountThreshold(3), TEST);
        assertMEME1155(treasury, 2, 0, TEST);
        assertMEME721(treasury, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, burnTokenIds, 2002, TEST);
    }

    /// @notice Scenario #42 Test Wallet A (Tier 2 MEME / ERC1155 #2) -> ERC1155#2 -> Treasury (EXEMPT) (0 / 0)
    /// @notice Treasury  (Tier 2 MEME / ERC1155 #2) -> Tier 1 MEME -> Wallet A (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 1 MEME / ERC1155 #1) -> Treasury (Tier 2 - Tier 1 MEME / 0)
    function test_404transferFromScenario42_success() public {
        // Init Test
        uint256 TIER = 2;
        string memory TEST = "Scenario #42";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        RECEIVER = treasury;

        vm.startPrank(SENDER);
        meme1155.setApprovalForAll(address(this), true);
        vm.stopPrank();
        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        vm.startPrank(treasury);
        memeToken.approve(address(this), getAmountThreshold(1));
        vm.stopPrank();
        memeToken.transferFrom(RECEIVER, SENDER, getAmountThreshold(1));

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(treasury, getAmountThreshold(TIER) - getAmountThreshold(1), TEST);
        assertMEME1155(treasury, 1, 0, TEST);
        assertMEME721(treasury, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    function test_transferFirstTierHaveSelector() public {
        string memory TEST = "FirstTierHaveSelector";
        uint256 TIER = 1;
        ContractWithSelector c = new ContractWithSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(1));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(1));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, tierParams[2].lowerId, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFromFirstTierFromHaveSelector() public {
        string memory TEST = "FirstTierFromHaveSelector";
        uint256 TIER = 1;
        ContractWithSelector c = new ContractWithSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        memeToken.approve(address(this), getAmountThreshold(TIER));
        vm.stopPrank();

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, tierParams[2].lowerId, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFrom2HTHaveSelector() public {
        string memory TEST = "2HTHaveSelector";
        uint256 TIER = 3;
        ContractWithSelector c = new ContractWithSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFrom2HTFromHaveSelector() public {
        string memory TEST = "2HTFromHaveSelector";
        uint256 TIER = 3;
        ContractWithSelector c = new ContractWithSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        memeToken.approve(address(this), getAmountThreshold(TIER));
        vm.stopPrank();

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_transferFirstTierNoSelector() public {
        string memory TEST = "FirstTierNoSelector";
        uint256 TIER = 1;
        ContractWithoutSelector c = new ContractWithoutSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, tierParams[2].lowerId, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFromFirstTierFromNoSelector() public {
        string memory TEST = "FirstTierFromNOSelector";
        uint256 TIER = 1;
        ContractWithoutSelector c = new ContractWithoutSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        memeToken.approve(address(this), getAmountThreshold(TIER));
        vm.stopPrank();

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, tierParams[2].lowerId, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFrom2HTNoSelector() public {
        string memory TEST = "2HTNoSelector";
        uint256 TIER = 3;
        ContractWithoutSelector c = new ContractWithoutSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFrom2HTFromNoSelector() public {
        string memory TEST = "2HTFromNoSelector";
        uint256 TIER = 3;
        ContractWithoutSelector c = new ContractWithoutSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        memeToken.approve(address(this), getAmountThreshold(TIER));
        vm.stopPrank();

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(TIER));

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFromZero() public {
        string memory TEST = "404transferFromZero";
        uint256 TIER = 1;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, ALICE, 0);

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, 0, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_404transferFromZero2HT() public {
        string memory TEST = "404transferFromZero2HT";
        uint256 TIER = 3;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        memeToken.transferFrom(SENDER, ALICE, 0);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, 0, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_transferNotEnough() public {
        vm.expectRevert();
        memeToken.transferFrom(makeAddr("NEW WALLET"), ALICE, 1);
    }

    function test_404transferFromMaxGas() public {
        initWalletWithTokens(SENDER, getAmountThreshold(4) * 50);
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);
        uint256 gasBefore = gasleft();

        memeToken.transferFrom(SENDER, RECEIVER, getAmountThreshold(4) * 49 + 1);

        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas used for MEME404.transferFrom:", gasUsed);
    }
}
