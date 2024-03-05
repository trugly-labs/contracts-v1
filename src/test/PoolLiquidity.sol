/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Constant} from "../../src/libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

library PoolLiquidity {
    error AuctionOutOfRange();

    using FixedPointMathLib for uint256;

    function getETHLiquidity(uint256 startAt) public view returns (uint256) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        if (step == 0) return 5.5e20;
        if (step == 1) return 2.75e20;
        if (step == 2) return 1.375e20;
        if (step == 3) return 9.185e19;
        if (step == 4) return 6.875e19;
        if (step == 5) return 5.5e19;
        if (step == 6) return 4.565e19;
        if (step == 7) return 3.905e19;
        if (step == 8) return 3.4375e19;
        if (step == 9) return 3.0525e19;
        if (step == 10) return 2.75e19;
        if (step == 11) return 2.497e19;
        if (step == 12) return 2.2825e19;
        if (step == 13) return 2.112e19;
        if (step == 14) return 1.9635e19;
        if (step == 15) return 1.8315e19;
        if (step == 16) return 1.716e19;
        if (step == 17) return 1.617e19;
        if (step == 18) return 1.5235e19;
        if (step == 19) return 1.4465e19;
        if (step == 20) return 1.375e19;
        if (step == 21) return 1.309e19;
        if (step == 22) return 1.2485e19;
        if (step == 23) return 1.1935e19;
        revert AuctionOutOfRange();
    }
}
