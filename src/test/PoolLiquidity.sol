/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Constant} from "../../src/libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

library PoolLiquidity {
    error AuctionOutOfRange();

    using FixedPointMathLib for uint256;

    function getETHLiquidity(uint256 startAt) public view returns (uint256) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        if (step == 0) return 2.248888888664e21;
        if (step == 1) return 1.124444444332e21;
        if (step == 2) return 6.71111111044e20;
        if (step == 3) return 4.6666666662e20;
        if (step == 4) return 3.26666666634e20;
        if (step == 5) return 2.284444444216e20;
        if (step == 6) return 1.595555555396e20;
        if (step == 7) return 1.115555555444e20;
        if (step == 8) return 8.888888888e19;
        if (step == 9) return 7.1111111104e19;
        if (step == 10) return 5.68888888832e19;
        if (step == 11) return 4.53333333288e19;
        if (step == 12) return 3.626666666304e19;
        if (step == 13) return 2.897777777488e19;
        if (step == 14) return 2.604444444184e19;
        if (step == 15) return 2.342222221988e19;
        if (step == 16) return 2.106666666456e19;
        if (step == 17) return 1.893333333144e19;
        if (step == 18) return 1.702222222052e19;
        if (step == 19) return 1.528888888736e19;
        if (step == 20) return 1.373333333196e19;
        if (step == 21) return 1.235555555432e19;
        if (step == 22) return 1.111111111e19;
        if (step == 23) return 9.999999999e18;
        if (step == 24) return 8.97777777688e18;
        if (step == 25) return 8.04444444364e18;
        if (step == 26) return 7.19999999928e18;
        if (step == 27) return 6.4444444438e18;
        if (step == 28) return 5.7777777772e18;
        if (step == 29) return 5.19999999948e18;
        if (step == 30) return 4.6666666662e18;
        if (step == 31) return 4.17777777736e18;
        if (step == 32) return 3.73333333296e18;
        if (step == 33) return 3.333333333e18;
        if (step == 34) return 2.97777777748e18;
        if (step == 35) return 2.6666666664e18;
        revert AuctionOutOfRange();
    }
}
