// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

library OinkMath {
    function calculateSqrtPriceX96(uint256 supplyA, uint256 supplyB) public pure returns (uint160) {
        // Calculate the price ratio (supplyB / supplyA)
        uint256 priceRatio = supplyB / supplyA;

        // Calculate the square root of the price ratio
        uint256 sqrtRatio = FixedPointMathLib.sqrt(priceRatio);

        // Convert to Q64.96 format
        return uint160(sqrtRatio * (2 ** 96));
    }
}
