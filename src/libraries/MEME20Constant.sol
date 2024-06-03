/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MEME20Constant {
    /// @dev Total supply of the Meme token
    uint256 internal constant TOKEN_TOTAL_SUPPLY = 10_000_000_000 ether;

    /// @dev Token decimals
    uint8 internal constant TOKEN_DECIMALS = 18;

    uint256 internal constant MAX_CREATOR_FEE_BPS = 80;

    uint256 internal constant MAX_PROTOCOL_FEE_BPS = 50;
}
