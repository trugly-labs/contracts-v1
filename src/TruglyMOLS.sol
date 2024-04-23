// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import {ERC721} from "@solmate/tokens/ERC721.sol";

import {Owned} from "@solmate/auth/Owned.sol";

contract TruglyMOLS is ERC721, Owned {
    error NonExistingToken();

    constructor(address _owner) ERC721("Trugly MOLs", "TRUGLYMOLS") Owned(_owner) {}

    // Mapping from token ID to token URIs
    mapping(uint256 => string) private _tokenURIs;

    function mint(address to, uint256 tokenId, string memory tokenURI_) external onlyOwner {
        _mint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf[tokenId] == address(0)) revert NonExistingToken();
        return _tokenURIs[tokenId];
    }
}
