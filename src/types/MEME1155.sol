/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC1155} from "@solmate/tokens/ERC1155.sol";
import {LibString} from "@solmate/utils/LibString.sol";

import {MEME20Constant} from "../libraries/MEME20Constant.sol";

/// @title Trugly's MEME404
/// @notice Contract automatically generated by https://www.trugly.meme
contract MEME1155 is ERC1155 {
    using LibString for uint256;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    // @dev Only memecoin can call this function
    error OnlyMemecoin();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    string public name;
    string public symbol;
    address public creator;
    address public memecoin;
    string public baseURI;
    uint256 public nftId;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       IMPLEMENTATION              */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    modifier onlyMemecoin() {
        if (msg.sender != memecoin) revert OnlyMemecoin();
        _;
    }

    constructor(string memory _name, string memory _symbol, address _creator, string memory _baseURI, uint256 _nftId) {
        name = _name;
        symbol = _symbol;
        creator = _creator;
        memecoin = msg.sender;
        baseURI = _baseURI;
        nftId = _nftId;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, id.toString()) : "";
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyMemecoin {
        _mint(account, id, amount, data);
    }

    function burn(address account, uint256 id, uint256 amount) external onlyMemecoin {
        _burn(account, id, amount);
    }
}
