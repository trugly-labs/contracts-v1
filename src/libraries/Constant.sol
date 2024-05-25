/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Supply dedicated for the fair launch (45% of total supply)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 4_000_000_000 ether;

    /// @dev Maximum creator vesting allocation (in bps)
    uint16 internal constant CREATOR_MAX_VESTED_ALLOC_BPS = 1000;

    /// @dev UniswapV3 Pool's fee (3%)
    uint24 internal constant UNI_LP_SWAPFEE = 3000;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant TICK_LOWER = -887220;

    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant TICK_UPPER = -TICK_LOWER;

    /// ~~~~~~~ VESTING / AUCTION ~~~~~~~
    //// @dev Vesting duration
    uint64 internal constant VESTING_DURATION = 2 * 365 days;
    /// @dev Vesting cliff
    uint64 internal constant VESTING_CLIFF = 91.25 days;

    /// UNCX Locker
    uint256 internal constant MAX_LOCKER_FLAT_FEE = 0.1 ether;
    uint256 internal constant MAX_LOCKER_LP_FEE = 150;
    uint256 internal constant MAX_LOCKER_COLLECT_FEE = 200;

    address internal constant UNCX_TREASURY = 0x04bDa42de3bc32Abb00df46004204424d4Cf8287;
}
