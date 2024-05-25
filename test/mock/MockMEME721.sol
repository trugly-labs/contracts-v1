/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MEME721} from "../../src/types/MEME721.sol";

contract MockMEME721 is MEME721 {
    constructor(string memory name, string memory _symbol, address meme404, address _creator, string memory _baseURI)
        MEME721(name, _symbol, meme404, _creator, _baseURI)
    {}

    function getTokenAtIndex(address _owner, uint256 _index) external view returns (uint256) {
        return _get(_owners[_owner].ids, _index);
    }

    function getIndexForToken(uint256 _tokenId) external view returns (uint256) {
        return _uint32MapIndex[_tokenId];
    }
}
