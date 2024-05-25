/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/// @title Trugly's Manager to create memecoins
interface ITruglyFactoryNFT {
    function createMeme1155(
        string memory name,
        string memory symbol,
        address meme404,
        address creator,
        string memory baseURI
    ) external returns (address);

    function createMeme721(
        string memory name,
        string memory symbol,
        address meme404,
        address creator,
        string memory baseURI
    ) external returns (address);
}
