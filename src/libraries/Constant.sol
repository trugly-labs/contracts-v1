/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Supply dedicated for the memeceptions (60%)
    uint256 internal constant TOKEN_TOTAL_SUPPLY = 10_000_000_000_000 ether;

    /// @dev Supply dedicated for the memeceptions (60%)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 6_000_000_000_000 ether;

    /// @dev Supply dedicated for the UniV4 Pool (40%)
    uint256 internal constant TOKEN_LP_SUPPLY = 4_000_000_000_000 ether;

    /// @dev Memeception minimum Cap
    uint256 internal constant MEMECEPTION_MIN_ETHCAP = 10 ether;

    /// @dev Memeception maximum Cap
    uint256 internal constant MEMECEPTION_MAX_ETHCAP = 1000 ether;

    /// @dev Memeception minimum start at (now + 1 day)
    uint256 internal constant MEMECEPTION_MIN_START_AT = 1 days;

    /// @dev Memeception maximum start at (now + 30 day)
    uint256 internal constant MEMECEPTION_MAX_START_AT = 30 days;

    /// @dev Memeception deadline (startAt + 3 days)
    uint256 internal constant MEMECEPTION_DEADLINE = 3 days;

    /// @dev Memeception maximum creator swap fee (in bps)
    uint256 internal constant CREATOR_MAX_FEE_BPS = 100;

    /// @dev UniswapV3 Pool's fee (3%)
    uint24 internal constant UNI_LP_SWAPFEE = 3000;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant TICK_LOWER = -887220;

    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant TICK_UPPER = -TICK_LOWER;
}
