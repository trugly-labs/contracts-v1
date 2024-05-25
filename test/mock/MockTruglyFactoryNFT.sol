/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MockMEME721} from "./MockMEME721.sol";
import {TruglyFactoryNFT} from "../../src/TruglyFactoryNFT.sol";

/// @title Trugly's Factory to create memecoins
contract MockTruglyFactoryNFT is TruglyFactoryNFT {
    constructor() TruglyFactoryNFT() {}

    function createMeme721(
        string memory name,
        string memory symbol,
        address meme404,
        address creator,
        string memory baseURI
    ) external override returns (address) {
        MockMEME721 meme721 = new MockMEME721(name, symbol, meme404, creator, baseURI);
        return address(meme721);
    }
}
