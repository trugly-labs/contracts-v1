/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Constant} from "./Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

library Auction {
    using FixedPointMathLib for uint256;

    /// @dev Thrown when the auction time is out of range
    error AuctionOutOfRange();

    uint256 private constant AUCTION_PRICE_0 = 5.06e11;
    uint256 private constant AUCTION_PRICE_1 = 2.53e11;
    uint256 private constant AUCTION_PRICE_2 = 1.51e11;
    uint256 private constant AUCTION_PRICE_3 = 1.05e11;
    uint256 private constant AUCTION_PRICE_4 = 7.35e10;
    uint256 private constant AUCTION_PRICE_5 = 5.14e10;
    uint256 private constant AUCTION_PRICE_6 = 3.59e10;
    uint256 private constant AUCTION_PRICE_7 = 2.51e10;
    uint256 private constant AUCTION_PRICE_8 = 2.0e10;
    uint256 private constant AUCTION_PRICE_9 = 1.6e10;
    uint256 private constant AUCTION_PRICE_10 = 1.28e10;
    uint256 private constant AUCTION_PRICE_11 = 1.02e10;
    uint256 private constant AUCTION_PRICE_12 = 8.16e9;
    uint256 private constant AUCTION_PRICE_13 = 6.52e9;
    uint256 private constant AUCTION_PRICE_14 = 5.86e9;
    uint256 private constant AUCTION_PRICE_15 = 5.27e9;
    uint256 private constant AUCTION_PRICE_16 = 4.74e9;
    uint256 private constant AUCTION_PRICE_17 = 4.26e9;
    uint256 private constant AUCTION_PRICE_18 = 3.83e9;
    uint256 private constant AUCTION_PRICE_19 = 3.44e9;
    uint256 private constant AUCTION_PRICE_20 = 3.09e9;
    uint256 private constant AUCTION_PRICE_21 = 2.78e9;
    uint256 private constant AUCTION_PRICE_22 = 2.5e9;
    uint256 private constant AUCTION_PRICE_23 = 2.25e9;
    uint256 private constant AUCTION_PRICE_24 = 2.02e9;
    uint256 private constant AUCTION_PRICE_25 = 1.81e9;
    uint256 private constant AUCTION_PRICE_26 = 1.62e9;
    uint256 private constant AUCTION_PRICE_27 = 1.45e9;
    uint256 private constant AUCTION_PRICE_28 = 1.3e9;
    uint256 private constant AUCTION_PRICE_29 = 1.17e9;
    uint256 private constant AUCTION_PRICE_30 = 1.05e9;
    uint256 private constant AUCTION_PRICE_31 = 0.94e9;
    uint256 private constant AUCTION_PRICE_32 = 0.84e9;
    uint256 private constant AUCTION_PRICE_33 = 0.75e9;
    uint256 private constant AUCTION_PRICE_34 = 0.67e9;
    uint256 private constant AUCTION_PRICE_35 = 0.6e9;

    function price(uint256 step) internal pure returns (uint256) {
        if (step >= 12) {
            if (step <= 23) {
                if (step == 23) return AUCTION_PRICE_23;
                if (step == 22) return AUCTION_PRICE_22;
                if (step == 21) return AUCTION_PRICE_21;
                if (step == 20) return AUCTION_PRICE_20;
                if (step == 19) return AUCTION_PRICE_19;
                if (step == 18) return AUCTION_PRICE_18;
                if (step == 17) return AUCTION_PRICE_17;
                if (step == 16) return AUCTION_PRICE_16;
                if (step == 15) return AUCTION_PRICE_15;
                if (step == 14) return AUCTION_PRICE_14;
                if (step == 13) return AUCTION_PRICE_13;
                if (step == 12) return AUCTION_PRICE_12;
            } else {
                if (step == 35) return AUCTION_PRICE_35;
                if (step == 34) return AUCTION_PRICE_34;
                if (step == 33) return AUCTION_PRICE_33;
                if (step == 32) return AUCTION_PRICE_32;
                if (step == 31) return AUCTION_PRICE_31;
                if (step == 30) return AUCTION_PRICE_30;
                if (step == 29) return AUCTION_PRICE_29;
                if (step == 28) return AUCTION_PRICE_28;
                if (step == 27) return AUCTION_PRICE_27;
                if (step == 26) return AUCTION_PRICE_26;
                if (step == 25) return AUCTION_PRICE_25;
                if (step == 24) return AUCTION_PRICE_24;
            }
        } else {
            if (step == 11) return AUCTION_PRICE_11;
            if (step == 10) return AUCTION_PRICE_10;
            if (step == 9) return AUCTION_PRICE_9;
            if (step == 8) return AUCTION_PRICE_8;
            if (step == 7) return AUCTION_PRICE_7;
            if (step == 6) return AUCTION_PRICE_6;
            if (step == 5) return AUCTION_PRICE_5;
            if (step == 4) return AUCTION_PRICE_4;
            if (step == 3) return AUCTION_PRICE_3;
            if (step == 2) return AUCTION_PRICE_2;
            if (step == 1) return AUCTION_PRICE_1;
            if (step == 0) return AUCTION_PRICE_0;
        }
        revert AuctionOutOfRange();
    }
}
