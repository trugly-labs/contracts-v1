/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {MEME404} from "../../src/types/MEME404.sol";
// import {MEME1155} from "../../src/types/MEME1155.sol";
// import {MockMEME721} from "./MockMEME721.sol";

contract MockMEME404 is MEME404 {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       IMPLEMENTATION              */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    constructor(string memory _name, string memory _symbol, address _memeception, address _creator, address _factory)
        MEME404(_name, _symbol, _memeception, _creator, _factory)
    {}

    function tiersCount() external view returns (uint256) {
        return _tierCount;
    }

    function exemptNFTMint(address _exempt) external view returns (bool) {
        return _exemptNFTMint[_exempt];
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }

    function getBurnedTokenAtIndex(uint256 _tierId, uint256 _index) external view returns (uint256) {
        return _get(_tiers[_tierId].burnIds, _index);
    }

    function getBurnedLengthForTier(uint256 _tierId) external view returns (uint256) {
        return _tiers[_tierId].burnLength;
    }

    function nextBurnId(uint256 tierId) public view returns (uint256) {
        return _tiers[tierId].burnLength > 0 ? _get(_tiers[tierId].burnIds, _tiers[tierId].burnLength) : 0;
    }
}
