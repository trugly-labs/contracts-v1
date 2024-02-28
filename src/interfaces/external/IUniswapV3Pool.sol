// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

/// @author Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol)
interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);

    function initialize(uint160 sqrtPriceX96) external;
}
