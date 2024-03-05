/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Supply dedicated for the memeceptions (55%)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 5_500_000_000_000 ether;

    /// @dev Memeception minimum start at (now + 1 day)
    uint64 internal constant MEMECEPTION_MIN_START_AT = 1 days;

    /// @dev Memeception maximum start at (now + 30 day)
    uint64 internal constant MEMECEPTION_MAX_START_AT = 30 days;

    /// @dev Maximum creator swap fee (in bps)
    uint16 internal constant CREATOR_MAX_FEE_BPS = 100;

    /// @dev Maximum creator vesting allocation(in bps)
    uint16 internal constant CREATOR_MAX_VESTED_ALLOC_BPS = 500;

    /// @dev UniswapV3 Pool's fee (3%)
    uint24 internal constant UNI_LP_SWAPFEE = 3000;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant TICK_LOWER = -887220;

    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant TICK_UPPER = -TICK_LOWER;

    /// ~~~~~~~ VESTING / AUCTION ~~~~~~~
    //// @dev Vesting duration
    uint64 internal constant VESTING_DURATION = 4 * 365 days;
    /// @dev Vesting cliff
    uint64 internal constant VESTING_CLIFF = 365 days;
    // @dev Auction starting price (500 ETH) - scaled by 1e18
    uint256 internal constant AUCTION_STARTING_PRICE = 1e8;
    /// @dev Auction time unit per actions
    uint256 internal constant AUCTION_PRICE_DECAY_PERIOD = 5 minutes;
    /// @dev Auction duration
    uint40 internal constant AUCTION_DURATION = 2 hours;
    /// @dev Auction duration
    uint256 internal constant AUCTION_MAX_BID = 10 ether;
}
