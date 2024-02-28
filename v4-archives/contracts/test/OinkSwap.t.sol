/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

import {OinkDeployers} from "./utils/OinkDeployers.sol";

contract OinkSwapTest is OinkDeployers {
    using CurrencyLibrary for Currency;

    event Swap(address indexed sender, address indexed recipient, int128 amount0, int128 amount1);

    function setUp() public override {
        super.setUp();
        initializeMemeToken();
        backMeme(MEME_CREATION.backersETHCap);
    }

    function test_swap_success() public {
        uint256 swapAmount = 10 ether;
        swap(swapAmount);
    }
}
