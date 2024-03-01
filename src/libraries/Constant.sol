/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Total supply of the Meme token
    uint256 internal constant TOKEN_TOTAL_SUPPLY = 10_000_000_000_000 ether;

    /// @dev Supply dedicated for the memeceptions - unscaled (55%)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 5_500_000_000_000;

    /// @dev Token decimals
    uint8 internal constant TOKEN_DECIMALS = 18;

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
    // @dev Auction target price (20 ETH Total scaled by 1e18)
    int256 internal constant AUCTION_TARGET_PRICE = 0.00000364e18;
    // @dev Auction min price (5 ETH Total scaled by 1e18)
    int256 internal constant AUCTION_MIN_PRICE = 0.0000909e18;
    /// @dev Auction time unit per actions
    uint256 internal constant AUCTION_TIME_UNIT = 5 minutes;
    /// @dev Auction price decay percentage per time unit (10% scaled by 1e18)
    int256 internal constant AUCTION_PRICE_DECAY_PCT = 0.1e18;
    /// @dev Auction expected token sold per time unit
    int256 internal constant AUCTION_TOKEN_PER_TIME_UNIT = 500_000_000_000 ether;
    /// @dev Auction duration
    uint64 internal constant AUCTION_DURATION = 3 hours;
    uint256 internal constant AUCTION_MAX_BID = 100 ether;
}
