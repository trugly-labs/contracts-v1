// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

/// @author Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol)
interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function initialize(uint160 sqrtPriceX96) external;
}
