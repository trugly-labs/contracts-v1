/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Constant} from "./Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

library Auction {
    using FixedPointMathLib for uint256;

    error AuctionOutOfRange();

    uint256 private constant AUCTION_PRICE_0 = 1e8;
    uint256 private constant AUCTION_PRICE_1 = 5e7;
    uint256 private constant AUCTION_PRICE_2 = 2.5e7;
    uint256 private constant AUCTION_PRICE_3 = 1.67e7;
    uint256 private constant AUCTION_PRICE_4 = 1.25e7;
    uint256 private constant AUCTION_PRICE_5 = 1.0e7;
    uint256 private constant AUCTION_PRICE_6 = 8.3e6;
    uint256 private constant AUCTION_PRICE_7 = 7.1e6;
    uint256 private constant AUCTION_PRICE_8 = 6.25e6;
    uint256 private constant AUCTION_PRICE_9 = 5.55e6;
    uint256 private constant AUCTION_PRICE_10 = 5.0e6;
    uint256 private constant AUCTION_PRICE_11 = 4.54e6;
    uint256 private constant AUCTION_PRICE_12 = 4.15e6;
    uint256 private constant AUCTION_PRICE_13 = 3.84e6;
    uint256 private constant AUCTION_PRICE_14 = 3.57e6;
    uint256 private constant AUCTION_PRICE_15 = 3.33e6;
    uint256 private constant AUCTION_PRICE_16 = 3.12e6;
    uint256 private constant AUCTION_PRICE_17 = 2.94e6;
    uint256 private constant AUCTION_PRICE_18 = 2.77e6;
    uint256 private constant AUCTION_PRICE_19 = 2.63e6;
    uint256 private constant AUCTION_PRICE_20 = 2.5e6;
    uint256 private constant AUCTION_PRICE_21 = 2.38e6;
    uint256 private constant AUCTION_PRICE_22 = 2.27e6;
    uint256 private constant AUCTION_PRICE_23 = 2.17e6;

    function price(uint256 startAt) internal view returns (uint256) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
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

        revert AuctionOutOfRange();
    }
}
