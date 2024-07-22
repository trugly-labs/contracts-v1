/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Constant {
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       CONSTANTS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Supply dedicated for the fair launch (45% of total supply)
    uint256 internal constant TOKEN_MEMECEPTION_SUPPLY = 4_500_000_000 ether;

    /// @dev Maximum creator vesting allocation (in bps)
    uint16 internal constant CREATOR_MAX_VESTED_ALLOC_BPS = 5000;

    /// @dev UniswapV3 Pool's fee (3%)
    uint24 internal constant UNI_LP_SWAPFEE = 3000;

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant TICK_LOWER = -887220;

    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant TICK_UPPER = -TICK_LOWER;

    /// ~~~~~~~ VESTING / AUCTION ~~~~~~~
    //// @dev Vesting duration
    uint64 internal constant VESTING_DURATION = 1 * 365 days;
    /// @dev Vesting cliff
    uint64 internal constant VESTING_CLIFF = 365 days / 12;

    /// UNCX Locker
    uint256 internal constant MAX_LOCKER_FLAT_FEE = 0.1 ether;
    uint256 internal constant MAX_LOCKER_LP_FEE = 150;
    uint256 internal constant MAX_LOCKER_COLLECT_FEE = 200;

    uint256 internal constant MAX_TARGET_ETH = 100_000 ether;

    address internal constant UNISWAP_BASE_STAKER_ADDRESS = 0x42bE4D6527829FeFA1493e1fb9F3676d2425C3C1;
    address internal constant UNISWAP_BASE_FEE_COLLECTOR = 0x5d64D14D2CF4fe5fe4e65B1c7E3D11e18D493091;

    address internal constant UNISWAP_BASE_UNIVERSAL_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address internal constant UNISWAP_BASE_SWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
    address internal constant UNCX_BASE_V3_LOCKERS = 0x231278eDd38B00B07fBd52120CEf685B9BaEBCC1;

    address internal constant UNISWAP_BASE_V3_FACTORY = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    address internal constant UNISWAP_BASE_V3_POSITION_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;

    address internal constant BASE_WETH9 = 0x4200000000000000000000000000000000000006;

    address internal constant TRUGLY_BASE_UNIVERSAL_ROUTER = 0xe22dDaFcE4A76DC48BBE590F3237E741e2F58Be7;
}
