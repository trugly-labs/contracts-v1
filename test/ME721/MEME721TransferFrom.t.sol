/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {IMEME404} from "../../src/interfaces/IMEME404.sol";

contract MEME721TansferFromTest is DeployersME404 {
    error PoolNotInitialized();

    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address SENDER = address(this);
    address RECEIVER = makeAddr("receiver");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initializeToken();

        vm.startPrank(SENDER);
        meme721.setApprovalForAll(address(this), true);
        vm.stopPrank();
        assertEq(meme721.isApprovedForAll(SENDER, address(this)), true, "isApprovedForAll");
    }

    function test_721transferFromNotApproval() public {
        address NO_APPROVAL = makeAddr("NO_APPROVAL");
        initWalletWithTokens(NO_APPROVAL, getAmountThreshold(3));

        uint256 nextOwnedTokenId = meme721.nextOwnedTokenId(NO_APPROVAL);
        vm.expectRevert();
        meme721.transferFrom(NO_APPROVAL, RECEIVER, nextOwnedTokenId);
    }

    function test_721transferFromApprovalWrongId() public {
        address NOT_ENOUGH_APPROVAL = makeAddr("NOT_ENOUGH_APPROVAL");
        initWalletWithTokens(NOT_ENOUGH_APPROVAL, getAmountThreshold(4) * 2);

        hoax(NOT_ENOUGH_APPROVAL);
        meme721.approve(address(this), 2001);

        vm.expectRevert();
        meme721.transferFrom(NOT_ENOUGH_APPROVAL, RECEIVER, 2002);
    }

    function test_721transferFromSingleApprove() public {
        address SINGLE_APPROVE = makeAddr("SINGLE_APPROVE");
        string memory TEST = "SingleApprove";
        initWalletWithTokens(SINGLE_APPROVE, getAmountThreshold(4));

        hoax(SINGLE_APPROVE);
        meme721.approve(address(this), 2001);

        meme721.transferFrom(SINGLE_APPROVE, RECEIVER, 2001);
        SENDER = SINGLE_APPROVE;

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(1), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;

        assertMEME404(RECEIVER, getAmountThreshold(4), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #1: Test Wallet A (Tier 3 / ERC721 #1) -> ERC721 #1 ->Wallet A (Tier 3 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario1_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, SENDER, 1);
        RECEIVER = SENDER;
        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #2: Test Wallet A (Tier 3 * 2 / ERC721 #1 #2) -> ERC721 #2 ->Wallet A
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 * 2 / ERC721 #1 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario2_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #2";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, SENDER, 2);
        RECEIVER = SENDER;
        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1;
        receiverTokenIds[1] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #2.1: Test Wallet A (Tier 3 * 2 / ERC721 #1 #2) -> ERC721 #1 ->Wallet A
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 * 2 / ERC721 #2 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario2_1_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #2.1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, SENDER, 1);
        RECEIVER = SENDER;
        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1;
        receiverTokenIds[1] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #0: Test Wallet A (Tier 4 * 2 / ERC721 #2001 #2002) -> ERC721 #2002 ->Wallet A
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 * 2 / ERC721 #2001 #2002)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario0_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #0";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, SENDER, 2002);
        RECEIVER = SENDER;
        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2001;
        receiverTokenIds[1] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #0.1: Test Wallet A (Tier 4 * 2 / ERC721 #2001 #2002) -> ERC721 #2001 ->Wallet A
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 * 2 / ERC721 #2002 #2001)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario0_1_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #0.1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, SENDER, 2001);
        RECEIVER = SENDER;
        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2001;
        receiverTokenIds[1] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #3: Test Wallet A (Tier 3 / ERC721 #1) -> ERC721 #1 ->Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario3_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #3";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 1);

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
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #4: Test Wallet A (Tier 4 / ERC721 #2001) -> ERC721 #2001 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 / ERC721 #2001)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario4_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #4";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario 6: Test Wallet A (Tier 3 * 2 / ERC721 #1 #2) -> ERC #1 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #2) -> Wallet B (Tier 3 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario6_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #6";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, RECEIVER, 1);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
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
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario 6.1: Test Wallet A (Tier 3 * 2 / ERC721 #1 #2) -> ERC #2 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1) -> Wallet B (Tier 3 / ERC721 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario6_1_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #6.1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, RECEIVER, 2);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario 7: Test Wallet A (Tier 4 * 2 / ERC721 #2001 #2002) -> ERC #2002 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 / ERC721 #2001) -> Wallet B (Tier 4 / ERC721 #2002)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario7_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #7";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

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
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #8: Test Wallet A (Tier 4 + Tier 3 (MEME) / ERC721 #2001) -> #2001 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #1) -> Wallet B (Tier 4 / ERC721 #2001)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario8_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #8";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #9: Test Wallet A (Tier 1 + Tier 3 (MEME) / ERC721 #1) -> ERC721 #1 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 1 / ERC1155 #1) -> Wallet B (Tier 3 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario9_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #9";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(1));

        meme721.transferFrom(SENDER, RECEIVER, 1);

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(1), 1, TEST);
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
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #14: Test Wallet A (Tier 3 / ERC721 #1) -> ERC721 #1 -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 * 2 / ERC721 #1 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario14_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #14";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 1);

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

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
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #16: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> Tier 4 * $MEME -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #2) -> Wallet B (Tier 3 + Tier 4 / ERC721 #2001)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario16_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #16";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #17: Test Wallet A (Tier 4 + Tier 4 - 1 / ERC721 #2001) -> #2001 -> Wallet B (Tier 4 / ERC721 #2002)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 - 1 / ERC721 #1 #3 #4 #5 .... #19) -> Wallet B (Tier 4 * 2 / ERC721 #2001 #2002)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario17_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #17";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(4) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](19);
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            senderTokenIds[i] = 1 + i;
        }
        assertMEME404(SENDER, getAmountThreshold(4) - 1, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2001;
        receiverTokenIds[1] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 20, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #18: Test Wallet A (Tier 3 + Tier 3 - 1 / ERC721 #1) -> ERC721 #1 -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 - 1 / ERC1155 #2) -> Wallet B (Tier 3 * 2 / ERC721 #1 #2)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario18_success() public {
        // Init Test
        uint256 TIER = 3;
        string memory TEST = "Scenario #18";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2 - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER) + 1);

        meme721.transferFrom(SENDER, RECEIVER, 1);

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(3) - 1, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1;
        receiverTokenIds[1] = 2;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2 + 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #20: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> #2001 -> Wallet B (2nd HT / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2002) -> Wallet B (HT + 2nd HT / ERC721 #2001)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: []
    function test_721transferFromScenario20_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "transferScenario20";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2002;

        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory sHTBurnIds = new uint256[](1);
        sHTBurnIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, sHTBurnIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #25: Test Wallet A (Tier 4 + Tier 4 - 1 / ERC721 #2001) -> ERC721 #2001 -> Wallet B (Tier 4 - 1 / ERC721 #1 #2 ... #19)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 4 - 1 /  ERC721 #20 #21 .. #38) -> Wallet B (Tier 4 * 2 - 1 / ERC721 #2001)
    /// Expected: Tier 3 Burn: [#1,#19, .. #2]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario25_success() public {
        // Init Test
        string memory TEST = "Scenario #25";
        initWalletWithTokens(SENDER, getAmountThreshold(4) + getAmountThreshold(4) - 1);
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](19);
        for (uint256 i = 0; i < senderTokenIds.length; i++) {
            senderTokenIds[i] = 20 + i;
        }
        assertMEME404(SENDER, getAmountThreshold(4) - 1, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(4) * 2 - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](19);
        burnTokenIds[0] = 1;
        for (uint256 i = 1; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i + 1;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 39, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #27: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2003) -> ERC721 #2003 -> Wallet B (Tier 3 / ERC721 #2)
    /// @notice Burn [ERC721 #1]
    /// @notice Burn [ERC721 #2001]
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #3) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2003)
    /// Expected: Tier 3 Burn: [#1, #2]
    /// Expected: Tier 4 Burn: [#2001]
    function test_721transferFromScenario27_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2003);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 3;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2003;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(4), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](2);
        burnTokenIds[0] = 1;
        burnTokenIds[1] = 2;

        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 4, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2004, TEST);
    }

    /// -------------- SCENARIOS WHERE UNLIMTED TOKENS ARE NO LONGER AVAILABLE --------------- ///

    /// @notice Scenario #28: Test Wallet A (Tier 4 / ERC721 #2099) -> #2099 -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice sHTBurn []
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2097 #2099]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2097]
    function test_721transferFromScenario28_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2099);

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 2, 0, TEST);
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

    /// @notice Scenario #30: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2099) -> ERC721 #2099 -> Wallet B (0 / 0)
    /// @notice sHTBurn [#1]
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2093 #2095 #2097]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / #3) -> Wallet B (Tier 4 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1]
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2093, #2095, #2097]
    function test_721transferFromScenario30_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2099);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 3;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 2, 0, TEST);
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

    /// @notice Scenario #31: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> #2001  -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #3 .. #1997]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1997) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2001)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995 #1999]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario31_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1997;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(TIER), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < burnTokenIds.length - 1; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }
        burnTokenIds[burnTokenIds.length - 1] = 1999;

        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #32: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> #2001 -> Wallet B (Tier 4 / ERC721 #2002)
    /// @notice sHTBurn [#1 #3 .. #1997 #1999]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999) -> Wallet B (Tier 4 *2 / ERC721 #2001 #2002)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995 #1997]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario32_success() public {
        // Init Test
        string memory TEST = "Scenario #32";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1999;
        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 2001;
        receiverTokenIds[1] = 2002;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = tierParams[2].lowerId + i * 2;
        }

        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario #33: Test Wallet A (Tier 3 * 3 / ERC721 #1999 #1997 #1995) -> #1997 -> Wallet B (Tier 3 / ERC721 #1993)
    /// @notice sHTBurn [#1 #3 .. #1991]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1999 #1995) -> Wallet B (Tier 3 * 2 / ERC721 #1997 #1993)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1991]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario33_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 1997);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](2);
        senderTokenIds[0] = 1999;
        senderTokenIds[1] = 1995;
        assertMEME404(SENDER, getAmountThreshold(3) * 2, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](2);
        receiverTokenIds[0] = 1997;
        receiverTokenIds[1] = 1993;
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

    /// @notice Scenario #34: Test Wallet A (tier 3 / ERC721 #1999) -> #1999 -> Wallet B (Tier 3 / ERC721 #1997)
    /// @notice sHTBurn [#1 #3 .. #1995]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 * 2 / ERC721 #1999 #1997)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario34_success() public {
        // Init Test
        string memory TEST = "Scenario #34";
        uint256 TIER = 3;
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 1999);

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

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
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #35: Test Wallet A (tier 3 + tier 2 / ERC721 #1999) -> #1999 -> Wallet B (Tier 3 / ERC721 #1997)
    /// @notice sHTBurn [#1 #3 .. #1995]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 2 / ERC1155 #2) -> Wallet B (Tier 3 * 2 / ERC721 #1999 #1997)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1995]
    /// Expected: Tier 4 Burn: []
    function test_721transferFromScenario35_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 1999);

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(2), TEST);
        assertMEME1155(SENDER, 2, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

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
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #36: Test Wallet A (Tier 4 + tier 3 / ERC721 #2099) -> #2099 -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #2 .. #1997 #1998]
    /// @notice HTBurn [#2001 #2002 ... #2098]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 3 / ERC721 #1998) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#1 #2 .. #1997 #1999]
    /// Expected: Tier 4 Burn: [#2001 #2002 ... #2098]
    function test_721transferFromScenario36_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2099);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 1998;
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
        burnTokenIds[burnTokenIds.length - 1] = 1999;
        uint256[] memory HTburnTokenIds = new uint256[]((tierParams[3].upperId - tierParams[3].lowerId + 1) - 2);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = tierParams[3].lowerId + i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, tierParams[2].upperId + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, tierParams[3].upperId + 1, TEST);
    }

    /// @notice Scenario #37: Test Wallet A (Tier 4 + tier 4 / ERC721 #2099 #2098) -> #2098 -> Wallet B (Tier 3 / ERC721 #1999)
    /// @notice sHTBurn [#1 #2 .. #1997 #1998]
    /// @notice HTBurn [#2001 #2002 ... #2097]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 4 / ERC721 #2099) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2098)
    /// Expected: Tier 3 Burn: [#1 #2 .. #1998 #1999]
    /// Expected: Tier 4 Burn: [#2001 #2002 ... #2097]
    function test_721transferFromScenario37_success() public {
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

        meme721.transferFrom(SENDER, RECEIVER, 2098);

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

    /// @notice Scenario #39: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> #2002 -> Wallet A
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2001 #2002)
    /// Expected: 2nd HT Burn: []
    /// Expected: HT Burn: []
    function test_721transferFromScenario39_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #39";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme721.transferFrom(SENDER, SENDER, 2002);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](2);
        senderTokenIds[0] = 2001;
        senderTokenIds[1] = 2002;

        assertMEME404(SENDER, getAmountThreshold(TIER) * 2, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2003, TEST);
    }

    /// @notice Scenario 40: Test Wallet A (HT * 2 / ERC721 #2001 #2002) -> #2002 -> Wallet B (2nd HT / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (HT / ERC721 #2001) -> Wallet B (HT + 2nd HT / ERC721 #2002)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: []
    function test_721transferFromScenario40_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #40";
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

    /// @notice Scenario 41: Test Wallet A (Tier 4 + Tier 3 / ERC721 #2001) -> #2001 -> Wallet B (Tier 3 / ERC721 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (Tier 3 / ERC721 #2) -> Wallet B (Tier 4 + Tier 3 / ERC721 #2001)
    /// Expected: 2nd HT Burn: [#1]
    /// Expected: HT Burn: []
    function test_721transferFromScenario41_success() public {
        // Init Test
        uint256 TIER = 4;
        string memory TEST = "Scenario #41";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3));

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        uint256[] memory senderTokenIds = new uint256[](1);
        senderTokenIds[0] = 2;

        assertMEME404(SENDER, getAmountThreshold(3), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, senderTokenIds, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(TIER) + getAmountThreshold(3), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 3, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario 42: Tier 5 that is Tier 4 threshold + 10
    /// @notice Wallet A (Tier 4, ERC721 #2001)-> #2001 -> Wallet B (Tier 3 + 10, ERC721 #1)
    /// Expected: Wallet A ( / 0) -> Wallet B (Tier 4 + Tier 3 + 10 / ERC721 #3001)
    /// Expect Tier 3 Burn: [#1]
    /// Expect Tier 4 Burn: [#2001]
    function test_721transferFromScenario42_success() public {
        string memory TEST = "Scenario 42";
        tierParams.push(
            IMEME404.TierCreateParam({
                baseURL: "https://elite.com/",
                nftName: "Elite NFT",
                nftSymbol: "ELITE",
                amountThreshold: 100_000_010 ether,
                nftId: 2,
                lowerId: 3001,
                upperId: 3100,
                isFungible: false
            })
        );
        createMemeParams.symbol = "CUSTOMMEME404";
        initCreateMeme404();

        initWalletWithTokens(SENDER, getAmountThreshold(4));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3) + 10 ether);

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 3001;
        assertMEME404(RECEIVER, getAmountThreshold(4) + getAmountThreshold(3) + 10 ether, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[](1);
        burnTokenIds[0] = 1;

        uint256[] memory HTburnTokenIds = new uint256[](1);
        HTburnTokenIds[0] = 2001;
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2002, TEST);
        assertMEME404BurnAndUmintedForTier(5, EMPTY_UINT_ARRAY, 3002, TEST);
    }

    /// @notice Scenario 43: To and From an exemptyNFT wallet
    /// @notice Wallet A (Tier 4 / #2001) -> #2001 -> Treasury (EXEMPT) (Tier 3, 0)
    /// @notice Treasury (Tier 3 + Tier 4 / #2001) -> #2001 -> Wallet A (0 / 0 )
    /// Expected: Wallet A (Tier 4 / #2001) -> Treasury (Tier 3 / 0)
    /// Expect Tier 3 Burn: []
    /// Expect Tier 4 Burn: []
    function test_721transferFromScenario43_success() public {
        string memory TEST = "Scenario 43";
        initWalletWithTokens(SENDER, getAmountThreshold(4));
        initWalletWithTokens(treasury, getAmountThreshold(3));

        meme721.transferFrom(SENDER, treasury, 2001);

        vm.startPrank(treasury);
        meme721.setApprovalForAll(address(this), true);
        vm.stopPrank();

        meme721.transferFrom(treasury, SENDER, 2001);

        // Assert Sender
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2001;
        assertMEME404(SENDER, getAmountThreshold(4), TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, tokenIds, TEST);

        // Assert RECEIVER
        assertMEME404(treasury, getAmountThreshold(3), TEST);
        assertMEME1155(treasury, 1, 0, TEST);
        assertMEME721(treasury, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    function test_721transferFrom2HTHaveSelector() public {
        string memory TEST = "2HTHaveSelector";
        uint256 TIER = 3;
        ContractWithSelector c = new ContractWithSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 1);

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

    function test_721transferFrom2HTFromHaveSelector() public {
        string memory TEST = "2HTFromHaveSelector";
        uint256 TIER = 3;
        ContractWithSelector c = new ContractWithSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        meme721.approve(address(this), 1);
        vm.stopPrank();

        meme721.transferFrom(SENDER, RECEIVER, 1);

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

    function test_721transferFrom2HTNoSelector() public {
        string memory TEST = "2HTNoSelector";
        uint256 TIER = 3;
        ContractWithoutSelector c = new ContractWithoutSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme721.transferFrom(SENDER, RECEIVER, 1);

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

    function test_721transferFrom2HTFromNoSelector() public {
        string memory TEST = "2HTFromNoSelector";
        uint256 TIER = 3;
        ContractWithoutSelector c = new ContractWithoutSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        meme721.approve(address(this), 1);
        vm.stopPrank();

        meme721.transferFrom(SENDER, RECEIVER, 1);

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

    function test_transferNotEnough() public {
        initWalletWithTokens(SENDER, getAmountThreshold(3));
        vm.expectRevert();
        meme721.transferFrom(SENDER, ALICE, 2);
    }

    function test_721transferFromMaxGas() public {
        initWalletWithTokens(SENDER, getAmountThreshold(4) + getAmountThreshold(3));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);
        uint256 gasBefore = gasleft();

        meme721.transferFrom(SENDER, RECEIVER, 2001);

        uint256 gasAfter = gasleft();

        uint256 gasUsed = gasBefore - gasAfter;
        emit log_named_uint("Gas used for MEME721.transferFrom:", gasUsed);
    }
}
