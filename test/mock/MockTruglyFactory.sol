/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MockMEME404} from "./MockMEME404.sol";
import {TruglyFactory} from "../../src/TruglyFactory.sol";

/// @title Trugly's Factory to create memecoins
contract MockTruglyFactory is TruglyFactory {
    constructor(address _factoryNFT) TruglyFactory(_factoryNFT) {}

    function createMeme404(string memory name, string memory symbol, address creator, bytes32 salt)
        external
        override
        returns (address)
    {
        MockMEME404 meme404 = new MockMEME404{salt: salt}(name, symbol, msg.sender, creator, _factoryNFT);
        return address(meme404);
    }
}
