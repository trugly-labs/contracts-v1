/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Constant} from "../libraries/Constant.sol";

contract MEMERC20 is ERC20, Constant {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, TOKEN_DECIMALS) {
        _mint(msg.sender, TOKEN_TOTAL_SUPPLY);
    }
}
