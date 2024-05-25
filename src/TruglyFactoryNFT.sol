/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MEME1155} from "./types/MEME1155.sol";
import {MEME721} from "./types/MEME721.sol";
import {ITruglyFactoryNFT} from "./interfaces/ITruglyFactoryNFT.sol";

/// @title Trugly's Factory to create memecoins
contract TruglyFactoryNFT is ITruglyFactoryNFT {
    constructor() {}

    function createMeme1155(
        string memory name,
        string memory symbol,
        address meme404,
        address creator,
        string memory baseURI
    ) external returns (address) {
        MEME1155 meme1155 = new MEME1155(name, symbol, meme404, creator, baseURI);
        return address(meme1155);
    }

    function createMeme721(
        string memory name,
        string memory symbol,
        address meme404,
        address creator,
        string memory baseURI
    ) external virtual returns (address) {
        MEME721 meme721 = new MEME721(name, symbol, meme404, creator, baseURI);
        return address(meme721);
    }
}
