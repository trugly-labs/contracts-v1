/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {IMEME404} from "../../src/interfaces/IMEME404.sol";

contract MEME1155TansferFromTest is DeployersME404 {
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
        meme1155.setApprovalForAll(address(this), true);
        vm.stopPrank();
        assertEq(meme1155.isApprovedForAll(SENDER, address(this)), true, "isApprovedForAll");
    }

    function test_1155safeTransferFromSelf() public {
        string memory TEST = "TransferFromSelf";
        initWalletWithTokens(SENDER, getAmountThreshold(1));

        RECEIVER = SENDER;
        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(1), TEST);
        assertMEME1155(RECEIVER, 1, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    function test_1155safeTransferFromNotApproval() public {
        address NO_APPROVAL = makeAddr("NO_APPROVAL");
        initWalletWithTokens(NO_APPROVAL, 1);

        vm.expectRevert();
        meme1155.safeTransferFrom(NO_APPROVAL, ALICE, 1, 1, "");
    }

    /// @notice Scenario #1 Test Wallet A (1 MEME / ERC1155 #1) -> ERC1155 #1 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (1 MEME / ERC1155 #1)
    function test_1155safeTransferFromScenario1_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #1";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

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

    /// @notice Scenario #2: Test Wallet A (Tier 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 2 / ERC1155 #2)
    function test_1155safeTransferFromScenario2_success() public {
        // Init Test
        uint256 TIER = 2;
        string memory TEST = "Scenario #2";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

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

    /// @notice Scenario 5: Test Wallet A (2 $MEME / ERC1155 #1) -> ERC1155 #1 -> Wallet B (0 / 0)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (1 / ERC1155 #1) -> Wallet B (Tier 1 / ERC1155 #1)
    function test_1155safeTransferFromScenario5_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #5";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER) * 2);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

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

    /// @notice Scenario #12: Test Wallet A (Tier 1 / ERC1155 #1) -> ERC1155 #1 -> Wallet B (Tier 1 / ERC1155 #1)
    /// @notice Burn list empty
    /// @notice Available unminted tokens
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 1 * 2 / ERC1155 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_1155safeTransferFromScenario12_success() public {
        // Init Test
        uint256 TIER = 1;
        string memory TEST = "Scenario #12";
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));
        initWalletWithTokens(RECEIVER, getAmountThreshold(TIER));

        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

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

    /// @notice Scenario #13: Test Wallet A (Tier 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 4 - 1 / ERC721 #1 ... #19)
    /// @notice sHTBurn []
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 - 1 + Tier 2 / ERC721 #2001)
    /// Expected: Tier 3 Burn: [#19 .. #1]
    /// Expected: Tier 4 Burn: []
    function test_1155safeTransferFromScenario13_success() public {
        // Init Test
        string memory TEST = "Scenario #13";
        initWalletWithTokens(SENDER, getAmountThreshold(2));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(4) + getAmountThreshold(2) - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256 expectedBurnLength = (getAmountThreshold(4) - 1) / getAmountThreshold(3);
        uint256[] memory burnTokenIds = new uint256[](expectedBurnLength);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, expectedBurnLength + 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// @notice Scenario #14: Test Wallet A (Tier 2 * 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 3 - 1 / ERC1155 #2)
    /// @notice sHTBurn []
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (Tier 2 / ERC1155 #2) -> Wallet B (Tier 3 - 1 + Tier 2 / ERC721 #1)
    /// Expected: Tier 3 Burn: []
    /// Expected: Tier 4 Burn: []
    function test_1155safeTransferFromScenario14_success() public {
        // Init Test
        string memory TEST = "Scenario #14";
        initWalletWithTokens(SENDER, getAmountThreshold(2) * 2);
        initWalletWithTokens(RECEIVER, getAmountThreshold(3) - 1);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(2), TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(2) - 1, TEST);
        assertMEME1155(RECEIVER, 2, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 2, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #15: An additioanl fungible Tier 3 that is super close to Tier 2 + 10
    /// @notice Test Wallet A (Tier 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 1 + 10 / ERC1155 #1)
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 2 + Tier 1 + 10 / ERC1155 #3)
    function test_1155safeTransferFromScenario15_success() public {
        // Init Test
        string memory TEST = "Scenario #15";
        tierParams[2] = IMEME404.TierCreateParam({
            baseURL: "https://normal.com/",
            nftName: "Normal NFT",
            nftSymbol: "Normal",
            amountThreshold: getAmountThreshold(2) + 10,
            nftId: 1,
            lowerId: 3,
            upperId: 3,
            isFungible: true
        });
        createMemeParams.symbol = "CUSTOMMEME404";
        initCreateMeme404();

        initWalletWithTokens(SENDER, getAmountThreshold(2));
        initWalletWithTokens(RECEIVER, getAmountThreshold(1) + 10);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, 1, 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(1) + getAmountThreshold(2) + 10, TEST);
        assertMEME1155(RECEIVER, 3, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #16: An additioanl fungible Tier 3 that is super close to Tier 2 + 10
    /// @notice Test Wallet A (Tier 2 + Tier 1 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 1 + 10 / ERC1155 #1)
    /// Expected: Wallet A (Tier 1 / ERC1155 #1) -> Wallet B (Tier 2 + Tier 1 + 10 / ERC1155 #3)
    function test_1155safeTransferFromScenario16_success() public {
        // Init Test
        string memory TEST = "Scenario #16";
        tierParams[2] = IMEME404.TierCreateParam({
            baseURL: "https://normal.com/",
            nftName: "Normal NFT",
            nftSymbol: "Normal",
            amountThreshold: getAmountThreshold(2) + 10,
            nftId: 1,
            lowerId: 3,
            upperId: 3,
            isFungible: true
        });
        createMemeParams.symbol = "CUSTOMMEME404";
        initCreateMeme404();

        initWalletWithTokens(SENDER, getAmountThreshold(2) + getAmountThreshold(1));
        initWalletWithTokens(RECEIVER, getAmountThreshold(1) + 10);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, getAmountThreshold(1) + getAmountThreshold(2) + 10, TEST);
        assertMEME1155(RECEIVER, 3, 1, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    /// @notice Scenario #17: An additioanl fungible Tier 3 that is super close to Tier 2 + 10 AND Tier 4 that is super close to Tier 3
    /// @notice Test Wallet A (Tier 3 + Tier 1 / ERC1155 #3) -> ERC1155 #3 -> Wallet B (Tier 2 + 10 / ERC1155 #1)
    /// Expected: Wallet A (Tier 1 / #1) -> Wallet B (Tier 2 + Tier 2 + Tier 3+  10 / ERC721 #2001)
    function test_1155safeTransferFromScenario17_success() public {
        // Init Test
        string memory TEST = "Scenario #17";
        tierParams[2] = IMEME404.TierCreateParam({
            baseURL: "https://normal.com/",
            nftName: "Normal NFT",
            nftSymbol: "Normal",
            amountThreshold: getAmountThreshold(2) + 10,
            nftId: 1,
            lowerId: 3,
            upperId: 3,
            isFungible: true
        });
        tierParams[3] = IMEME404.TierCreateParam({
            baseURL: "https://elite.com/",
            nftName: "Elite NFT",
            nftSymbol: "Elite",
            amountThreshold: getAmountThreshold(2) + 20,
            nftId: 2,
            lowerId: 2001,
            upperId: type(uint32).max - 1,
            isFungible: false
        });
        createMemeParams.symbol = "CUSTOMMEME404";
        initCreateMeme404();

        initWalletWithTokens(SENDER, getAmountThreshold(3) + getAmountThreshold(1));
        initWalletWithTokens(RECEIVER, getAmountThreshold(2) + 10);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 3, 1, "");

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(1), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2001;
        assertMEME404(RECEIVER, getAmountThreshold(2) + getAmountThreshold(3) + 10, TEST);
        assertMEME1155(RECEIVER, 3, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2002, TEST);
    }

    /// -------------- SCENARIOS WHERE UNLIMTED TOKENS ARE NO LONGER AVAILABLE --------------- ///
    /// @notice Scenario #27: Test Wallet A (Tier 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 3 - 1 / #ERC1155 #2)
    /// @notice sHTBurn [#1 #3 .. #1997 #1999]
    /// @notice HTBurn []
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 3 - 1 + Tier 2 / ERC721 #1999)
    /// Expected: Tier 3 Burn: [#1 #3 .. #1997]
    /// Expected: Tier 4 Burn: []
    function test_1155safeTransferFromScenario27_success() public {
        // Init Test
        string memory TEST = "Scenario #27";
        for (uint256 i = 0; i < (tierParams[2].upperId - tierParams[2].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(3));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(3));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(2));
        initWalletWithTokens(RECEIVER, getAmountThreshold(3) - 1);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 1999;
        assertMEME404(RECEIVER, getAmountThreshold(3) + getAmountThreshold(2) - 1, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256[] memory burnTokenIds = new uint256[]((tierParams[2].upperId - tierParams[2].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = 1 + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, 2001, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }
    /// @notice Scenario #28: Test Wallet A (Tier 2 / ERC1155 #2) -> ERC1155 #2 -> Wallet B (Tier 4 - 1 / ERC721 #1 .. #19)
    /// @notice sHTBurn []
    /// @notice HTBurn [ERC721 #2001 #2003 .. #2097 #2099]
    /// @notice Unminted.length = 0
    /// Expected: Wallet A (0 / 0) -> Wallet B (Tier 4 - 1 + Tier 2 / ERC721 #2099)
    /// Expected: Tier 3 Burn: [#19 .. #1]
    /// Expected: Tier 4 Burn: [#2001, #2003 .. #2097]

    function test_1155safeTransferFromScenario28_success() public {
        // Init Test
        string memory TEST = "Scenario #28";
        uint256 TIER = 4;
        for (uint256 i = 0; i < (tierParams[TIER - 1].upperId - tierParams[TIER - 1].lowerId + 1) / 2; i++) {
            initWalletWithTokens(BOB, getAmountThreshold(TIER));
            vm.startPrank(BOB);
            memeToken.transfer(makeAddr(i.toString()), getAmountThreshold(TIER));
            vm.stopPrank();
        }

        initWalletWithTokens(SENDER, getAmountThreshold(2));
        initWalletWithTokens(RECEIVER, getAmountThreshold(4) - 1);

        meme1155.safeTransferFrom(SENDER, RECEIVER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, 0, TEST);
        assertMEME1155(SENDER, getTokenIdForFungibleTier(2), 0, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        uint256[] memory receiverTokenIds = new uint256[](1);
        receiverTokenIds[0] = 2099;
        assertMEME404(RECEIVER, getAmountThreshold(4) - 1 + getAmountThreshold(2), TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, receiverTokenIds, TEST);

        // Assert MEME404 Burn and Unminted
        uint256 expectedBurnLength = (getAmountThreshold(4) - 1) / getAmountThreshold(3);
        uint256[] memory burnTokenIds = new uint256[](expectedBurnLength);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            burnTokenIds[i] = burnTokenIds.length - i;
        }

        uint256[] memory HTburnTokenIds =
            new uint256[]((tierParams[TIER - 1].upperId - tierParams[TIER - 1].lowerId + 1) / 2 - 1);
        for (uint256 i = 0; i < HTburnTokenIds.length; i++) {
            HTburnTokenIds[i] = 2001 + i * 2;
        }
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, burnTokenIds, expectedBurnLength+1, TEST);
        assertMEME404BurnAndUmintedForTier(4, HTburnTokenIds, 2101, TEST);
    }

    /// @notice Scenario 29: To and From an exemptyNFT wallet
    /// @notice Wallet A (Tier 2 / #2) -> ERC1155 #2 -> Treasury (EXEMPT) (Tier 1, 0)
    /// @notice Treasury (Tier 1 + Tier 2 / ERC1155 #2) -> #2 -> Wallet A (0 / 0 )
    /// Expected: Wallet A (Tier 2 / ERC1155 #2) -> Treasury (Tier 1 / 0)
    /// Expect Tier 3 Burn: []
    /// Expect Tier 4 Burn: []
    function test_1155transferFromScenario29_success() public {
        string memory TEST = "Scenario 29";
        initWalletWithTokens(SENDER, getAmountThreshold(2));
        initWalletWithTokens(treasury, getAmountThreshold(1));

        meme1155.safeTransferFrom(SENDER, treasury, 2, 1, "");

        vm.startPrank(treasury);
        meme1155.setApprovalForAll(address(this), true);
        vm.stopPrank();

        meme1155.safeTransferFrom(treasury, SENDER, 2, 1, "");

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(2), TEST);
        assertMEME1155(SENDER, 2, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(treasury, getAmountThreshold(1), TEST);
        assertMEME1155(treasury, 1, 0, TEST);
        assertMEME721(treasury, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, 1, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, 2001, TEST);
    }

    function test_1155transferFirstTierHaveSelector() public {
        string memory TEST = "FirstTierHaveSelector";
        uint256 TIER = 1;
        ContractWithSelector c = new ContractWithSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(1));

        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

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

    function test_1155safeTransferFromFirstTierFromHaveSelector() public {
        string memory TEST = "FirstTierFromHaveSelector";
        uint256 TIER = 1;
        ContractWithSelector c = new ContractWithSelector();
        SENDER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.startPrank(SENDER);
        meme1155.setApprovalForAll(address(this), true);
        vm.stopPrank();

        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

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

    function test_1155transferFromFirstTierNoSelector() public {
        string memory TEST = "FirstTierNoSelector";
        uint256 TIER = 1;
        ContractWithoutSelector c = new ContractWithoutSelector();
        RECEIVER = address(c);
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        vm.expectRevert();
        meme1155.safeTransferFrom(SENDER, RECEIVER, 1, 1, "");

        // Assert Sender
        assertMEME404(SENDER, getAmountThreshold(TIER), TEST);
        assertMEME1155(SENDER, 1, 1, TEST);
        assertMEME721(SENDER, EMPTY_UINT_ARRAY, TEST);

        // Assert RECEIVER
        assertMEME404(RECEIVER, 0, TEST);
        assertMEME1155(RECEIVER, 1, 0, TEST);
        assertMEME721(RECEIVER, EMPTY_UINT_ARRAY, TEST);

        // Assert MEME404 Burn and Unminted
        assertMEME404BurnAndUmintedForTier(1, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(2, EMPTY_UINT_ARRAY, 0, TEST);
        assertMEME404BurnAndUmintedForTier(3, EMPTY_UINT_ARRAY, tierParams[2].lowerId, TEST);
        assertMEME404BurnAndUmintedForTier(4, EMPTY_UINT_ARRAY, tierParams[3].lowerId, TEST);
    }

    function test_1155safeTransferFromZero() public {
        string memory TEST = "404safeTransferFromZero";
        uint256 TIER = 1;
        initWalletWithTokens(SENDER, getAmountThreshold(TIER));

        meme1155.safeTransferFrom(SENDER, ALICE, 1, 0, "");

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

    function test_1155transferNotEnough() public {
        vm.expectRevert();
        meme1155.safeTransferFrom(makeAddr("NEW WALLET"), ALICE, 1, 1, "");
    }

    function test_1155transferNotTooHighAmount() public {
        initWalletWithTokens(SENDER, getAmountThreshold(1) * 2);
        vm.expectRevert();
        meme1155.safeTransferFrom(SENDER, ALICE, 1, 2, "");
    }
}
