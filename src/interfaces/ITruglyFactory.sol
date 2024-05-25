/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/// @title Trugly's Manager to create memecoins
interface ITruglyFactory {
    function createMeme20(string memory name, string memory symbol, address creator, bytes32 salt)
        external
        returns (address);

    function createMeme404(string memory name, string memory symbol, address creator, bytes32 salt)
        external
        returns (address);
}
