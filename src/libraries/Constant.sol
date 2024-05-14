/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Supply dedicated for the memeceptions (50%)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 4_444_444_444 ether;

    /// @dev Memeception minimum start at (now + 30 minutes)
    uint64 internal constant MEMECEPTION_MIN_START_AT = 10 minutes;

    /// @dev Memeception maximum start at (now + 30 day)
    uint64 internal constant MEMECEPTION_MAX_START_AT = 30 days;

    /// @dev Maximum creator swap fee (in bps)
    uint16 internal constant CREATOR_MAX_FEE_BPS = 80;

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

    /// @dev Auction time unit per actions
    uint256 internal constant AUCTION_PRICE_DECAY_PERIOD = 1.5 minutes;
    uint256 internal constant MAX_AUCTION_PRICE_DECAY_PERIOD = 5 minutes;
    uint256 internal constant MIN_AUCTION_PRICE_DECAY_PERIOD = 1 minutes;
    /// @dev Auction duration
    uint40 internal constant MAX_AUCTION_DURATION = 54 minutes;

    uint40 internal constant MIN_AUCTION_DURATION = 36 minutes;
    /// @dev Auction duration
    uint256 internal constant AUCTION_MAX_BID = 10 ether;

    uint256 internal constant AUCTION_CLAIM_COOLDOWN = 1 minutes;

    uint256 internal constant MAX_LOCKER_FLAT_FEE = 0.1 ether;
    uint256 internal constant MAX_LOCKER_LP_FEE = 150;
    uint256 internal constant MAX_LOCKER_COLLECT_FEE = 200;

    uint256 internal constant MAX_AUCTION_PRICE = 1e12;
    uint256 internal constant MIN_AUCTION_PRICE = 0.1e9;

    uint256 internal constant MIN_AUCTION_PRICES_TIERS = 10;
}
