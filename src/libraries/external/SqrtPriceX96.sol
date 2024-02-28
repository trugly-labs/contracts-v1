/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {FullMath} from "./FullMath.sol";

library SqrtPriceX96 {
    using FullMath for uint256;

    function calcSqrtPriceX96(uint256 supplyA, uint256 supplyB) public pure returns (uint160) {
        // Calculate the price ratio (supplyB / supplyA)
        uint256 priceRatio = supplyB.mulDiv(1e18, supplyA);

        // Calculate the square root of the price ratio
        uint256 sqrtRatio = FixedPointMathLib.sqrt(priceRatio);

        // Convert to Q64.96 format
        return uint160(sqrtRatio.mulDiv(2 ** 96, FixedPointMathLib.sqrt(1e18)));
    }
}
