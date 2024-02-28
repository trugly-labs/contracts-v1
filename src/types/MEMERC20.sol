/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract MEMERC20 is ERC20 {
    uint8 public constant MEME_DECIMALS = 18;
    uint256 public constant MEME_TOTAL_SUPPLY = 10_000_000_000_000 ether;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, MEME_DECIMALS) {
        _mint(msg.sender, MEME_TOTAL_SUPPLY);
    }
}
