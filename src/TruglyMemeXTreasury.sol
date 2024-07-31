/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import { Owned } from "@solmate/auth/Owned.sol";

contract TruglyMemeXTreasury is Owned {
    using SafeTransferLib for address;

    constructor(address _owner) Owned(_owner) {}

    mapping(address => uint256) public treasuryBalances;

    event Deposited(address indexed memeToken, uint256 amount);
    event TransferToXOwner(address indexed memeToken, address accountOwner, uint256 amount);

    function deposit(address memeToken) onlyOwner external payable {
        treasuryBalances[memeToken] += msg.value;
        emit Deposited(memeToken, msg.value);
    }

    function transferToXAccountOwner(address memeToken, address accountOwner) onlyOwner external {
        uint256 amount = treasuryBalances[memeToken];
        treasuryBalances[memeToken] = 0;
        accountOwner.safeTransferETH(amount);
        emit TransferToXOwner(memeToken, accountOwner, amount);
    }
}
