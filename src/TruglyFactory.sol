/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MEME404} from "./types/MEME404.sol";
import {MEME20} from "./types/MEME20.sol";
import {ITruglyFactory} from "./interfaces/ITruglyFactory.sol";

/// @title Trugly's Factory to create memecoins
contract TruglyFactory is ITruglyFactory {
    address internal _factoryNFT;

    constructor(address factoryNFT) {
        _factoryNFT = factoryNFT;
    }

    function createMeme20(string memory name, string memory symbol, address creator, bytes32 salt)
        external
        returns (address)
    {
        MEME20 meme20 = new MEME20{salt: salt}(name, symbol, msg.sender, creator);
        return address(meme20);
    }

    function createMeme404(string memory name, string memory symbol, address creator, bytes32 salt)
        external
        virtual
        returns (address)
    {
        MEME404 meme404 = new MEME404{salt: salt}(name, symbol, msg.sender, creator, _factoryNFT);
        return address(meme404);
    }
}
