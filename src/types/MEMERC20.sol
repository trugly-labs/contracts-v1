/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {MEMERC20Constant} from "../libraries/MEMERC20Constant.sol";

contract MEMERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, MEMERC20Constant.TOKEN_DECIMALS) {
        _mint(msg.sender, MEMERC20Constant.TOKEN_TOTAL_SUPPLY);
    }
}
