/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Constant} from "../../src/libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

library PoolLiquidity {
    error AuctionOutOfRange();

    using FixedPointMathLib for uint256;

    function getETHLiquidity(uint256 startAt) public view returns (uint256) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        if (step == 0) return 2.2488888886640000e21;
        if (step == 1) return 1.1244444443320000e21;
        if (step == 2) return 6.7111111104400000e20;
        if (step == 3) return 4.6666666662000000e20;
        if (step == 4) return 3.2666666663400000e20;
        if (step == 5) return 2.2844444442160000e20;
        if (step == 6) return 1.5955555553960000e20;
        if (step == 7) return 1.1155555554440000e20;
        if (step == 8) return 8.8888888880000000e19;
        if (step == 9) return 7.1111111104000000e19;
        if (step == 10) return 5.6888888883200000e19;
        if (step == 11) return 4.5333333328800000e19;
        if (step == 12) return 3.6266666663040000e19;
        if (step == 13) return 2.8977777774880000e19;
        if (step == 14) return 2.6044444441840000e19;
        if (step == 15) return 2.3422222219880000e19;
        if (step == 16) return 2.1066666664560000e19;
        if (step == 17) return 1.8933333331440000e19;
        if (step == 18) return 1.7022222220520000e19;
        if (step == 19) return 1.5288888887360000e19;
        if (step == 20) return 1.3733333331960000e19;
        if (step == 21) return 1.2355555554320000e19;
        if (step == 22) return 1.111111111e19;
        if (step == 23) return 9.999999999e18;
        revert AuctionOutOfRange();
    }
}
