/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MEME404} from "../../src/types/MEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {DeployersMEME404} from "../utils/DeployersMEME404.sol";

contract MEME404ConstructorTest is DeployersMEME404 {
    function test_constructor() public {
        address nftNormalTier = getNormalNFTCollection();
        address nftEliteTier = getEliteNFTCollection();

        for (uint256 i = 0; i < params.length; i++) {
            address nftTier = meme404.getTier(i).nft;
            if (i < params.length - 2) {
                assertEq(nftTier, nftNormalTier, "constructor: nftNormalTier");
            } else {
                assertEq(nftTier, nftEliteTier, "constructor: nftEliteTier");
            }
        }

        assertEq(meme404.tiersCount(), params.length, "constructor: tiersCount");

        assertEq(meme404.nftIdToAddress(0), nftNormalTier, "constructor: nftIdToAddress normal");
        assertEq(meme404.nftIdToAddress(1), nftEliteTier, "constructor: nftIdToAddress elite");
        assertEq(meme404.nftIdToAddress(2), address(0), "constructor: nftIdToAddress over");

        for (uint256 i = 0; i < params.length; i++) {
            MEME404.Tier memory tier = meme404.getTier(i);
            assertEq(tier.baseURL, params[i].baseURL, "constructor: baseURL");
            assertEq(tier.lowerId, params[i].lowerId, "constructor: lowerId");
            assertEq(tier.upperId, params[i].upperId, "constructor: upperId");
            assertEq(tier.amountThreshold, params[i].amountThreshold, "constructor: amountThreshold");
            assertEq(tier.isFungible, params[i].isFungible, "constructor: isFungible");
            assertEq(tier.curIndex, params[i].lowerId, "constructor: curIndex");
            assertEq(tier.burnIds, new uint256[](0), "constructor: burnIds");

            if (i < params.length - 2) {
                assertEq(tier.nft, nftNormalTier, "constructor: nft normal");
            } else {
                assertEq(tier.nft, nftEliteTier, "constructor: nft elite");
            }
        }

        MEME404.Tier memory overTier = meme404.getTier(params.length);
        assertEq(overTier.nft, address(0), "constructor: nft over");

        /// Assert NFT collection
        MEME1155 meme1155 = MEME1155(nftNormalTier);
        assertEq(meme1155.name(), params[0].nftName, "MEME1155: name");
        assertEq(meme1155.symbol(), params[0].nftSymbol, "MEME1155: symbol");
        assertEq(meme1155.creator(), CREATOR, "MEME1155: creator");
        assertEq(meme1155.memecoin(), address(meme404), "MEME1155: memecoin");
        assertEq(meme1155.nftId(), params[0].nftId, "MEME1155: nftId");
        assertEq(meme1155.uri(1), "https://nft.com/1", "MEME1155: uri(1)");
        assertEq(meme1155.uri(2), "https://nft.com/2", "MEME1155: uri(2)");

        MEME721 meme721 = MEME721(nftEliteTier);
        assertEq(meme721.name(), params[params.length - 1].nftName, "MEME721: name");
        assertEq(meme721.symbol(), params[params.length - 1].nftSymbol, "MEME721: symbol");
        assertEq(meme721.creator(), CREATOR, "MEME721: creator");
        assertEq(meme721.memecoin(), address(meme404), "MEME721: memecoin");
        assertEq(meme721.baseURI(), "https://elite.com/", "MEME721: baseURI");
        assertEq(meme721.nftId(), params[params.length - 1].nftId, "MEME721: nftId");
        assertEq(meme721.tokenURI(1), "https://elite.com/1", "MEME721: tokenURI(1)");
        assertEq(meme721.tokenURI(2), "https://elite.com/2", "MEME721: tokenURI(2)");
    }
}
