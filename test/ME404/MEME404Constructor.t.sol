/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MEME404} from "../../src/types/MEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract memeTokenConstructorTest is DeployersME404 {
    function setUp() public override {
        super.setUp();
        initCreateMeme404();
    }

    function test_constructor() public {
        address nftNormalTier = getNormalNFTCollection();
        address nftEliteTier = getEliteNFTCollection();

        for (uint256 i = 0; i < tierParams.length; i++) {
            address nftTier = memeToken.getTier(i).nft;
            if (i < tierParams.length - 2) {
                assertEq(nftTier, nftNormalTier, "constructor: nftNormalTier");
            } else {
                assertEq(nftTier, nftEliteTier, "constructor: nftEliteTier");
            }
        }

        assertEq(memeToken.tiersCount(), tierParams.length, "constructor: tiersCount");

        assertEq(memeToken.nftIdToAddress(0), nftNormalTier, "constructor: nftIdToAddress normal");
        assertEq(memeToken.nftIdToAddress(1), nftEliteTier, "constructor: nftIdToAddress elite");
        assertEq(memeToken.nftIdToAddress(2), address(0), "constructor: nftIdToAddress over");

        for (uint256 i = 0; i < tierParams.length; i++) {
            MEME404.Tier memory tier = memeToken.getTier(i);
            assertEq(tier.baseURL, tierParams[i].baseURL, "constructor: baseURL");
            assertEq(tier.lowerId, tierParams[i].lowerId, "constructor: lowerId");
            assertEq(tier.upperId, tierParams[i].upperId, "constructor: upperId");
            assertEq(tier.amountThreshold, tierParams[i].amountThreshold, "constructor: amountThreshold");
            assertEq(tier.isFungible, tierParams[i].isFungible, "constructor: isFungible");

            if (createMemeParams.vestingAllocBps >= 100 && i == tierParams.length - 1) {
                assertEq(tier.curIndex, tierParams[i].lowerId + 1, "constructor: curIndex");
            } else {
                assertEq(tier.curIndex, tierParams[i].lowerId, "constructor: curIndex");
            }
            assertEq(tier.burnIds, new uint256[](0), "constructor: burnIds");

            if (i < tierParams.length - 2) {
                assertEq(tier.nft, nftNormalTier, "constructor: nft normal");
            } else {
                assertEq(tier.nft, nftEliteTier, "constructor: nft elite");
            }
        }

        MEME404.Tier memory overTier = memeToken.getTier(tierParams.length);
        assertEq(overTier.nft, address(0), "constructor: nft over");

        /// Assert NFT collection
        MEME1155 meme1155 = MEME1155(nftNormalTier);
        assertEq(meme1155.name(), tierParams[0].nftName, "MEME1155: name");
        assertEq(meme1155.symbol(), tierParams[0].nftSymbol, "MEME1155: symbol");
        assertEq(meme1155.creator(), MEMECREATOR, "MEME1155: creator");
        assertEq(meme1155.memecoin(), address(memeToken), "MEME1155: memecoin");
        assertEq(meme1155.nftId(), tierParams[0].nftId, "MEME1155: nftId");
        assertEq(meme1155.uri(1), "https://nft.com/1", "MEME1155: uri(1)");
        assertEq(meme1155.uri(2), "https://nft.com/2", "MEME1155: uri(2)");

        MEME721 meme721 = MEME721(nftEliteTier);
        assertEq(meme721.name(), tierParams[tierParams.length - 1].nftName, "MEME721: name");
        assertEq(meme721.symbol(), tierParams[tierParams.length - 1].nftSymbol, "MEME721: symbol");
        assertEq(meme721.creator(), MEMECREATOR, "MEME721: creator");
        assertEq(meme721.memecoin(), address(memeToken), "MEME721: memecoin");
        assertEq(meme721.baseURI(), "https://elite.com/", "MEME721: baseURI");
        assertEq(meme721.nftId(), tierParams[tierParams.length - 1].nftId, "MEME721: nftId");
        assertEq(meme721.tokenURI(1), "https://elite.com/1", "MEME721: tokenURI(1)");
        assertEq(meme721.tokenURI(2), "https://elite.com/2", "MEME721: tokenURI(2)");
    }
}
