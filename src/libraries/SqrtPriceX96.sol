/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {Constant} from "./Constant.sol";

library SqrtPriceX96 {
    using FixedPointMathLib for uint256;

    error AuctionOutOfRange();

    uint160 private constant SQRT_PRICE_0 = 929032555196893304771571;
    uint160 private constant SQRT_PRICE_01 = 656925219722788800000000;
    uint160 private constant SQRT_PRICE_02 = 464516277598447000000000;
    uint160 private constant SQRT_PRICE_03 = 379655038948275600000000;
    uint160 private constant SQRT_PRICE_04 = 328462609861394400000000;
    uint160 private constant SQRT_PRICE_05 = 293785889486828200000000;
    uint160 private constant SQRT_PRICE_06 = 267651683265957600000000;
    uint160 private constant SQRT_PRICE_07 = 247548390606185300000000;
    uint160 private constant SQRT_PRICE_08 = 232258138799223300000000;
    uint160 private constant SQRT_PRICE_09 = 218865558318730500000000;
    uint160 private constant SQRT_PRICE_10 = 207737994673057900000000;
    uint160 private constant SQRT_PRICE_11 = 197951528367808700000000;
    uint160 private constant SQRT_PRICE_12 = 189258320233352600000000;
    uint160 private constant SQRT_PRICE_13 = 182052457173315000000000;
    uint160 private constant SQRT_PRICE_14 = 175535532424576000000000;
    uint160 private constant SQRT_PRICE_15 = 169532532485366300000000;
    uint160 private constant SQRT_PRICE_16 = 164099867290649800000000;
    uint160 private constant SQRT_PRICE_17 = 159295900026650600000000;
    uint160 private constant SQRT_PRICE_18 = 154621832981808000000000;
    uint160 private constant SQRT_PRICE_19 = 150663761902430000000000;
    uint160 private constant SQRT_PRICE_20 = 146892944743414000000000;
    uint160 private constant SQRT_PRICE_21 = 143324162055994000000000;
    uint160 private constant SQRT_PRICE_22 = 139972868055119000000000;
    uint160 private constant SQRT_PRICE_23 = 136855041204042000000000;

    function sqrtPriceX96(uint256 startAt) internal view returns (uint160) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        if (step == 23) return SQRT_PRICE_23;
        if (step == 22) return SQRT_PRICE_22;
        if (step == 21) return SQRT_PRICE_21;
        if (step == 20) return SQRT_PRICE_20;
        if (step == 19) return SQRT_PRICE_19;
        if (step == 18) return SQRT_PRICE_18;
        if (step == 17) return SQRT_PRICE_17;
        if (step == 16) return SQRT_PRICE_16;
        if (step == 15) return SQRT_PRICE_15;
        if (step == 14) return SQRT_PRICE_14;
        if (step == 13) return SQRT_PRICE_13;
        if (step == 12) return SQRT_PRICE_12;
        if (step == 11) return SQRT_PRICE_11;
        if (step == 10) return SQRT_PRICE_10;
        if (step == 9) return SQRT_PRICE_09;
        if (step == 8) return SQRT_PRICE_08;
        if (step == 7) return SQRT_PRICE_07;
        if (step == 6) return SQRT_PRICE_06;
        if (step == 5) return SQRT_PRICE_05;
        if (step == 4) return SQRT_PRICE_04;
        if (step == 3) return SQRT_PRICE_03;
        if (step == 2) return SQRT_PRICE_02;
        if (step == 1) return SQRT_PRICE_01;
        if (step == 0) return SQRT_PRICE_0;

        revert AuctionOutOfRange();
    }

    // function calcSqrtPriceX96(uint256 supplyA, uint256 supplyB) internal pure returns (uint160) {
    //     console2.log("supplyA: ", supplyA);
    //     console2.log("supplyB: ", supplyB);
    //     // Calculate the price ratio (supplyB / supplyA)
    //     uint256 priceRatio = FixedPointMathLib.mulDiv(supplyB, 1e32, supplyA);
    //     console2.log("priceRatio: ", priceRatio);

    //     // Calculate the square root of the price ratio
    //     uint256 sqrtRatio = FixedPointMathLib.sqrt(priceRatio);
    //     console2.log("sqrtRatio: ", sqrtRatio);
    //     console2.log("sqrtPriceX96", FixedPointMathLib.fullMulDiv(sqrtRatio, 2 ** 96, FixedPointMathLib.sqrt(1e32)));

    //     // Convert to Q64.96 format
    //     return uint160(FixedPointMathLib.fullMulDiv(sqrtRatio, 2 ** 96, FixedPointMathLib.sqrt(1e32)));
    // }
}
// supplyA:  4000000000000000000000000000000
// supplyB:  11956521500000000000
// priceRatio:  2989130
// sqrtRatio:  1728
// sqrtPriceX96 136906264824648775361643
// poolWETH Balance (Cap reached)
// Error: a ~= b not satisfied [uint]
//   Expected: 11956521500000000000
//     Actual: 11943935999999624311
//  Max Delta: 100000000
//      Delta: 12585500000375689
