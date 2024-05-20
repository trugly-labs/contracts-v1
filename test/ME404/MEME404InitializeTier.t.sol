/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {MockMEME404} from "../mock/MockMEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404InitializerTest is DeployersME404 {
    /// @dev No tiers are provided
    error NoTiers();
    /// @dev Too many tiers are provided
    error MaxTiers();
    /// @dev When a fungible sequence has upperId that is not equal to lowerId
    error InvalidTierSequenceFungibleThreshold();
    /// @dev When a prev tier has a higher amount threshold than the current tier
    error InvalidTierSequenceAmountThreshold();
    /// @dev When a non-fungible sequence has incorrect upperId and lowerId
    error InvalidTierSequenceNonFungibleIds();

    /// @dev tokenId is 0
    error InvalidTierSequenceZeroId();

    /// @dev When the contract is already initialized
    error TiersAlreadyInitialized();

    /// @dev When there's not enough NFTS based on amount threshold
    error InvalidTierSequenceNotEnoughNFTs();

    /// @dev When a NFT sequence is followed by a fungible one
    error InvalidTierSequenceFungibleAfterNonFungible();

    MockMEME404 meme404;

    address[] public exemptAddresses;

    function setUp() public override {
        _initTierParams();
        meme404 = new MockMEME404("HELLO", "WORLD", MEMECREATOR);

        exemptAddresses = new address[](0);
    }

    function test_initializeTiers_success() public {
        address[] memory _exemptAddresses = new address[](2);
        _exemptAddresses[0] = address(42);
        _exemptAddresses[1] = address(43);

        meme404.initializeTiers(tierParams, _exemptAddresses);
        address nftNormalTier = meme404.getTier(1).nft;
        address nftEliteTier = meme404.getTier(tierParams.length).nft;

        for (uint256 i = 1; i <= tierParams.length; i++) {
            address nftTier = meme404.getTier(i).nft;
            if (i < tierParams.length - 1) {
                assertEq(nftTier, nftNormalTier, "constructor: nftNormalTier");
            } else {
                assertEq(nftTier, nftEliteTier, "constructor: nftEliteTier");
            }
        }

        assertEq(meme404.tiersCount(), tierParams.length, "constructor: tiersCount");

        assertEq(meme404.nftIdToAddress(0), nftNormalTier, "constructor: nftIdToAddress normal");
        assertEq(meme404.nftIdToAddress(1), nftEliteTier, "constructor: nftIdToAddress elite");
        assertEq(meme404.nftIdToAddress(2), address(0), "constructor: nftIdToAddress over");
        assertEq(meme404.exemptNFTMint(address(42)), true, "constructor: exemptNFTMint #1");
        assertEq(meme404.exemptNFTMint(address(43)), true, "constructor: exemptNFTMint #2");
        assertEq(meme404.initialized(), true, "constructor: initialized");

        for (uint256 i = 1; i <= tierParams.length; i++) {
            MEME404.Tier memory tier = meme404.getTier(i);
            assertEq(tier.baseURL, tierParams[i].baseURL, "constructor: baseURL");
            assertEq(tier.lowerId, tierParams[i].lowerId, "constructor: lowerId");
            assertEq(tier.upperId, tierParams[i].upperId, "constructor: upperId");
            assertEq(tier.amountThreshold, tierParams[i].amountThreshold, "constructor: amountThreshold");
            assertEq(tier.isFungible, tierParams[i].isFungible, "constructor: isFungible");

            assertEq(tier.nextUnmintedId, tierParams[i].lowerId, "constructor: nextUnmintedId");
            assertEq(tier.burnLength, 0, "constructor: burnIds");
            assertEq(meme404.nextBurnId(i), 0, "constructor: nextBurnId");

            if (i < tierParams.length - 2) {
                assertEq(tier.nft, nftNormalTier, "constructor: nft normal");
            } else {
                assertEq(tier.nft, nftEliteTier, "constructor: nft elite");
            }
        }

        MEME404.Tier memory overTier = meme404.getTier(tierParams.length);
        assertEq(overTier.nft, address(0), "constructor: nft over");

        /// Assert NFT collection
        MEME1155 meme1155 = MEME1155(nftNormalTier);
        assertEq(meme1155.name(), tierParams[0].nftName, "MEME1155: name");
        assertEq(meme1155.symbol(), tierParams[0].nftSymbol, "MEME1155: symbol");
        assertEq(meme1155.creator(), MEMECREATOR, "MEME1155: creator");
        assertEq(meme1155.memecoin(), address(meme404), "MEME1155: memecoin");
        assertEq(meme1155.uri(1), "https://nft.com/1", "MEME1155: uri(1)");
        assertEq(meme1155.uri(2), "https://nft.com/2", "MEME1155: uri(2)");

        MEME721 meme721 = MEME721(nftEliteTier);
        assertEq(meme721.name(), tierParams[tierParams.length - 1].nftName, "MEME721: name");
        assertEq(meme721.symbol(), tierParams[tierParams.length - 1].nftSymbol, "MEME721: symbol");
        assertEq(meme721.creator(), MEMECREATOR, "MEME721: creator");
        assertEq(meme721.memecoin(), address(meme404), "MEME721: memecoin");
        assertEq(meme721.baseURI(), "https://elite.com/", "MEME721: baseURI");
        assertEq(meme721.tokenURI(1), "https://elite.com/1", "MEME721: tokenURI(1)");
        assertEq(meme721.tokenURI(2), "https://elite.com/2", "MEME721: tokenURI(2)");
    }

    function test_initializeTiersAlreadyInitialized_revert() public {
        meme404.initializeTiers(tierParams, exemptAddresses);
        vm.expectRevert(TiersAlreadyInitialized.selector);
        meme404.initializeTiers(tierParams, exemptAddresses);
    }

    function test_initializeTiersNoTiers_revert() public {
        vm.expectRevert(NoTiers.selector);
        meme404.initializeTiers(new MEME404.TierCreateParam[](0), exemptAddresses);
    }

    function test_initializeTiersMaxTiers_revert() public {
        vm.expectRevert(MaxTiers.selector);
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](11);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersFungibleThreshold_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam("https://nft.com/", "NAME", "SYMBOL", 1, 1, 1, 42, true);
        vm.expectRevert(InvalidTierSequenceFungibleThreshold.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersAmountThreshold_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](2);
        _tierParams[0] = MEME404.TierCreateParam("https://nft.com/", "NAME", "SYMBOL", 10, 1, 1, 1, true);
        _tierParams[1] = MEME404.TierCreateParam("https://nft.com/", "NAME", "SYMBOL", 9, 1, 1, 1, true);
        vm.expectRevert(InvalidTierSequenceAmountThreshold.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersAmountThresholdZero_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam("https://nft.com/", "NAME", "SYMBOL", 0, 1, 1, 1, true);
        vm.expectRevert(InvalidTierSequenceAmountThreshold.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersAmountThresholdAboveSupply_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY + 1, 1, 1, 1, true
        );
        vm.expectRevert(InvalidTierSequenceAmountThreshold.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersNonFungibleIds_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 10, 1, 11, 1, false
        );
        vm.expectRevert(InvalidTierSequenceNonFungibleIds.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersNonFungibleIds_betweenTiers_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](2);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 100, 1, 11, 150, false
        );
        _tierParams[1] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 10, 1, 1, 10, false
        );
        vm.expectRevert(InvalidTierSequenceNonFungibleIds.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersZeroId_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 10, 1, 0, 15, false
        );
        vm.expectRevert(InvalidTierSequenceZeroId.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersNotEnoughNFT_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](1);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 10, 1, 1, 9, false
        );
        vm.expectRevert(InvalidTierSequenceNotEnoughNFTs.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    function test_initializeTiersFungibleAfterNFT_revert() public {
        MEME404.TierCreateParam[] memory _tierParams = new MEME404.TierCreateParam[](2);
        _tierParams[0] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 10, 1, 1, 10, false
        );
        _tierParams[1] = MEME404.TierCreateParam(
            "https://nft.com/", "NAME", "SYMBOL", MEME20Constant.TOKEN_TOTAL_SUPPLY / 5, 2, 1, 1, true
        );
        vm.expectRevert(InvalidTierSequenceFungibleAfterNonFungible.selector);
        meme404.initializeTiers(_tierParams, exemptAddresses);
    }

    // function test_initializeTiers() public {
    //     address nftNormalTier = getNormalNFTCollection();
    //     address nftEliteTier = getEliteNFTCollection();

    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         address nftTier = meme404.getTier(i).nft;
    //         if (i < tierParams.length - 2) {
    //             assertEq(nftTier, nftNormalTier, "constructor: nftNormalTier");
    //         } else {
    //             assertEq(nftTier, nftEliteTier, "constructor: nftEliteTier");
    //         }
    //     }

    //     assertEq(meme404.tiersCount(), tierParams.length, "constructor: tiersCount");

    //     assertEq(meme404.nftIdToAddress(0), nftNormalTier, "constructor: nftIdToAddress normal");
    //     assertEq(meme404.nftIdToAddress(1), nftEliteTier, "constructor: nftIdToAddress elite");
    //     assertEq(meme404.nftIdToAddress(2), address(0), "constructor: nftIdToAddress over");

    //     for (uint256 i = 0; i < tierParams.length; i++) {
    //         MEME404.Tier memory tier = meme404.getTier(i);
    //         assertEq(tier.baseURL, tierParams[i].baseURL, "constructor: baseURL");
    //         assertEq(tier.lowerId, tierParams[i].lowerId, "constructor: lowerId");
    //         assertEq(tier.upperId, tierParams[i].upperId, "constructor: upperId");
    //         assertEq(tier.amountThreshold, tierParams[i].amountThreshold, "constructor: amountThreshold");
    //         assertEq(tier.isFungible, tierParams[i].isFungible, "constructor: isFungible");

    //         if (createMemeParams.vestingAllocBps >= 100 && i == tierParams.length - 1) {
    //             assertEq(tier.nextUnmintedId, tierParams[i].lowerId + 1, "constructor: nextUnmintedId");
    //         } else {
    //             assertEq(tier.nextUnmintedId, tierParams[i].lowerId, "constructor: nextUnmintedId");
    //         }
    //         assertEq(tier.burnIds, new uint256[](0), "constructor: burnIds");

    //         if (i < tierParams.length - 2) {
    //             assertEq(tier.nft, nftNormalTier, "constructor: nft normal");
    //         } else {
    //             assertEq(tier.nft, nftEliteTier, "constructor: nft elite");
    //         }
    //     }

    //     MEME404.Tier memory overTier = meme404.getTier(tierParams.length);
    //     assertEq(overTier.nft, address(0), "constructor: nft over");

    //     /// Assert NFT collection
    //     MEME1155 meme1155 = MEME1155(nftNormalTier);
    //     assertEq(meme1155.name(), tierParams[0].nftName, "MEME1155: name");
    //     assertEq(meme1155.symbol(), tierParams[0].nftSymbol, "MEME1155: symbol");
    //     assertEq(meme1155.creator(), MEMECREATOR, "MEME1155: creator");
    //     assertEq(meme1155.memecoin(), address(meme404), "MEME1155: memecoin");
    //     assertEq(meme1155.nftId(), tierParams[0].nftId, "MEME1155: nftId");
    //     assertEq(meme1155.uri(1), "https://nft.com/1", "MEME1155: uri(1)");
    //     assertEq(meme1155.uri(2), "https://nft.com/2", "MEME1155: uri(2)");

    //     MEME721 meme721 = MEME721(nftEliteTier);
    //     assertEq(meme721.name(), tierParams[tierParams.length - 1].nftName, "MEME721: name");
    //     assertEq(meme721.symbol(), tierParams[tierParams.length - 1].nftSymbol, "MEME721: symbol");
    //     assertEq(meme721.creator(), MEMECREATOR, "MEME721: creator");
    //     assertEq(meme721.memecoin(), address(meme404), "MEME721: memecoin");
    //     assertEq(meme721.baseURI(), "https://elite.com/", "MEME721: baseURI");
    //     assertEq(meme721.nftId(), tierParams[tierParams.length - 1].nftId, "MEME721: nftId");
    //     assertEq(meme721.tokenURI(1), "https://elite.com/1", "MEME721: tokenURI(1)");
    //     assertEq(meme721.tokenURI(2), "https://elite.com/2", "MEME721: tokenURI(2)");
    // }
}
