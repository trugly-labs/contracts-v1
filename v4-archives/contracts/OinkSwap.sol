/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20Minimal} from "@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol";

import {IOinkSwap} from "./interfaces/IOinkSwap.sol";
import {IOinkHooks} from "./interfaces/IOinkHooks.sol";

contract OinkSwap is IOinkSwap {
    using CurrencyLibrary for Currency;

    bytes constant ZERO_BYTES = new bytes(0);
    IPoolManager public poolManager;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    function memeSwap(PoolKey memory poolKey, IPoolManager.SwapParams memory params) external payable {
        BalanceDelta delta = abi.decode(poolManager.lock(address(this), abi.encode(poolKey, params)), (BalanceDelta));

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);

        emit MemeSwap(Currency.unwrap(poolKey.currency1), msg.sender, delta.amount0(), delta.amount1());
    }

    function lockAcquired(address lockCaller, bytes calldata data) external override returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        if (lockCaller != address(this)) revert OnlyOinkSwap();

        //     if (block.timestamp > deadline) {
        //         revert SwapExpired();
        //     }

        (PoolKey memory poolKey, IPoolManager.SwapParams memory params) =
            abi.decode(data, (PoolKey, IPoolManager.SwapParams));

        BalanceDelta delta = poolManager.swap(poolKey, params, ZERO_BYTES);
        (uint256 creatorFee, uint256 protocolFee) = IOinkHooks(address(poolKey.hooks)).getHookFees(poolKey, params);

        /// Include Hook Fees (exclusively Native currency)
        int128 deltaAmount0 = delta.amount0() + int128(int256(creatorFee)) + int128(int256(protocolFee));

        _settleCurrencyBalance(poolKey.currency0, deltaAmount0);
        _settleCurrencyBalance(poolKey.currency1, delta.amount1());

        return abi.encode(delta);
    }

    function _settleCurrencyBalance(Currency currency, int128 deltaAmount) private {
        if (deltaAmount < 0) {
            poolManager.take(currency, msg.sender, uint128(-deltaAmount));
            return;
        }
        if (deltaAmount > 0) {
            if (currency.isNative()) {
                poolManager.settle{value: uint128(deltaAmount)}(currency);
                return;
            }
            IERC20Minimal(Currency.unwrap(currency)).transferFrom(
                msg.sender, address(poolManager), uint128(deltaAmount)
            );
            poolManager.settle(currency);
        }
    }
}
