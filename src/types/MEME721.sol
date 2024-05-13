/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {MEME404} from "./MEME404.sol";

import {MEME20Constant} from "../libraries/MEME20Constant.sol";

/// @title Trugly's MEME404
/// @notice Contract automatically generated by https://www.trugly.meme
contract MEME721 is ERC721 {
    using LibString for uint256;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    // @dev Only memecoin can call this function
    error OnlyMemecoin();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    address public creator;
    address public memecoin;
    string public baseURI;

    mapping(address => uint256) internal _ownerToId;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       IMPLEMENTATION              */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    modifier onlyMemecoin() {
        if (msg.sender != memecoin) revert OnlyMemecoin();
        _;
    }

    constructor(string memory name, string memory _symbol, address _creator, string memory _baseURI)
        ERC721(name, _symbol)
    {
        creator = _creator;
        memecoin = msg.sender;
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, id.toString()) : "";
    }

    function transferFrom(address from, address to, uint256 id) public override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );

        MEME404(memecoin).rawTransferFrom(from, to, id);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function mint(address account, uint256 id) external onlyMemecoin {
        _ownerToId[account] = id;
        _mint(account, id);
    }

    function burn(uint256 id) external onlyMemecoin {
        address curOwner = _ownerOf[id];
        _ownerToId[curOwner] = 0;
        _burn(id);
    }

    function tokenIdByOwner(address account) external view returns (uint256) {
        return _ownerToId[account];
    }
}
