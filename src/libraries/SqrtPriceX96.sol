/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {Constant} from "./Constant.sol";

library SqrtPriceX96 {
    using FixedPointMathLib for uint256;

    error AuctionOutOfRange();

    uint160 private constant SQRT_PRICE_0 = 9.9620638014409013576665500134366e31;
    uint160 private constant SQRT_PRICE_01 = 1.4088485737223794521680377483428e32;
    uint160 private constant SQRT_PRICE_02 = 1.82362737790643434215160709805482e32;
    uint160 private constant SQRT_PRICE_03 = 2.18690505124291044800996032480766e32;
    uint160 private constant SQRT_PRICE_04 = 2.61385148314342471623782117882802e32;
    uint160 private constant SQRT_PRICE_05 = 3.12566923209442619738216347268162e32;
    uint160 private constant SQRT_PRICE_06 = 3.74004952386637585900988618606868e32;
    uint160 private constant SQRT_PRICE_07 = 4.47288483623316197307592818547738e32;
    uint160 private constant SQRT_PRICE_08 = 5.01082896750095862372827603139212e32;
    uint160 private constant SQRT_PRICE_09 = 5.60227709747861399187319382274581e32;
    uint160 private constant SQRT_PRICE_10 = 6.26353620937619827966034503924015e32;
    uint160 private constant SQRT_PRICE_11 = 7.01656400766222794661335211947389e32;
    uint160 private constant SQRT_PRICE_12 = 7.84475704480554846956081104400211e32;
    uint160 private constant SQRT_PRICE_13 = 8.77608416065665349822957349799227e32;
    uint160 private constant SQRT_PRICE_14 = 9.2571173506391380438700740303897e32;
    uint160 private constant SQRT_PRICE_15 = 9.7615609348314673869497186272117e32;
    uint160 private constant SQRT_PRICE_16 = 1.029284437475773524677208730204788e33;
    uint160 private constant SQRT_PRICE_17 = 1.085724849103095756140328693349724e33;
    uint160 private constant SQRT_PRICE_18 = 1.145051948872197182170980975817298e33;
    uint160 private constant SQRT_PRICE_19 = 1.208218151350457264229254757417478e33;
    uint160 private constant SQRT_PRICE_20 = 1.274809635932793620597993085167618e33;
    uint160 private constant SQRT_PRICE_21 = 1.344009007269693266194936117742324e33;
    uint160 private constant SQRT_PRICE_22 = 1.417276456914365682368813729285808e33;
    uint160 private constant SQRT_PRICE_23 = 1.493940559327630397832851686065551e33;
    uint160 private constant SQRT_PRICE_24 = 1.57669936427387949526019089948247e33;
    uint160 private constant SQRT_PRICE_25 = 1.66565590888416773239749174532807e33;
    uint160 private constant SQRT_PRICE_26 = 1.76062583365031861318986556302222e33;
    uint160 private constant SQRT_PRICE_27 = 1.8609751593349162631242332096384e33;
    uint160 private constant SQRT_PRICE_28 = 1.96540882188949032818435859689197e33;
    uint160 private constant SQRT_PRICE_29 = 2.0717228035196628260459834247092e33;
    uint160 private constant SQRT_PRICE_30 = 2.18690505124291044800996032480766e33;
    uint160 private constant SQRT_PRICE_31 = 2.31132305030739515210613901046113e33;
    uint160 private constant SQRT_PRICE_32 = 2.44503417745840435635508912864654e33;
    uint160 private constant SQRT_PRICE_33 = 2.5875809522433224700453035772294e33;
    uint160 private constant SQRT_PRICE_34 = 2.73770832051606666489469598972311e33;
    uint160 private constant SQRT_PRICE_35 = 2.89300345324985299295434785749435e33;

    function sqrtPriceX96(uint256 startAt) internal view returns (uint160) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        if (step >= 12) {
            if (step <= 23) {
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
            } else {
                if (step == 35) return SQRT_PRICE_35;
                if (step == 34) return SQRT_PRICE_34;
                if (step == 33) return SQRT_PRICE_33;
                if (step == 32) return SQRT_PRICE_32;
                if (step == 31) return SQRT_PRICE_31;
                if (step == 30) return SQRT_PRICE_30;
                if (step == 29) return SQRT_PRICE_29;
                if (step == 28) return SQRT_PRICE_28;
                if (step == 27) return SQRT_PRICE_27;
                if (step == 26) return SQRT_PRICE_26;
                if (step == 25) return SQRT_PRICE_25;
                if (step == 24) return SQRT_PRICE_24;
            }
        } else {
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
        }

        revert AuctionOutOfRange();
    }

    function calcSqrtPriceX96(uint256 supplyA, uint256 supplyB) internal pure returns (uint160) {
        uint256 priceRatio = FixedPointMathLib.rawDiv(supplyB, supplyA);
        uint256 sqrtRatio = FixedPointMathLib.sqrt(priceRatio);
        // Convert to Q64.96 format
        return uint160(FixedPointMathLib.rawMul(sqrtRatio, 2 ** 96));
    }
}
