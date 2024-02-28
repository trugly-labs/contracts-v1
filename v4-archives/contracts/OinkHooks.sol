/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

import {IOinkHooks} from "./interfaces/IOinkHooks.sol";
import {BaseHook} from "./external/BaseHook.sol";

contract OinkHooks is IOinkHooks, BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using FullMath for uint256;

    error OnlyFarmer();
    error OnlyCreator();
    error MemeSwapFeeTooHigh();

    event CreatorChanged(address indexed oldCreator, address indexed newCreator);
    event CreatorFeeBpsChanged(uint256 oldSwapFee, uint256 newSwapFee);

    address private creator;

    address public immutable oink;
    uint256 public creatorFeeBps;

    uint256 private constant OINK_SWAPFEE_BPS = 30;
    uint256 private constant BIPS_DENOMINATOR = 1e4;
    uint256 private constant CREATOR_MAX_FEE_BPS = 100;

    constructor(IPoolManager _poolManager, address _oink, address _creator, uint256 _creatorFeeBps)
        BaseHook(_poolManager)
    {
        creator = _creator;
        oink = _oink;
        creatorFeeBps = _creatorFeeBps;
    }

    function getHooksCalls() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            noOp: false,
            accessLock: true
        });
    }

    function beforeSwap(
        address,
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams,
        bytes calldata hookData
    ) external override returns (bytes4) {
        if (swapParams.zeroForOne) _settleHookFee(poolKey, swapParams);

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        if (!swapParams.zeroForOne) _settleHookFee(poolKey, swapParams);

        return BaseHook.afterSwap.selector;
    }

    function _settleHookFee(PoolKey calldata poolKey, IPoolManager.SwapParams calldata swapParams) internal {
        (uint256 creatorFee, uint256 protocolFee) = getHookFees(poolKey, swapParams);
        if (protocolFee > 0) poolManager.mint(address(oink), poolKey.currency0.toId(), protocolFee);
        if (creatorFee > 0) poolManager.mint(creator, poolKey.currency0.toId(), creatorFee);
    }

    function getHookFees(PoolKey calldata poolKey, IPoolManager.SwapParams calldata swapParams)
        public
        view
        returns (uint256 creatorFee, uint256 protocolFee)
    {
        if (swapParams.zeroForOne) {
            if (swapParams.amountSpecified > 0) {
                uint256 amountSpecified = uint256(swapParams.amountSpecified);
                /// exact input
                protocolFee = amountSpecified.mulDiv(OINK_SWAPFEE_BPS, BIPS_DENOMINATOR);
                if (creatorFeeBps > 0) creatorFee = amountSpecified.mulDiv(creatorFeeBps, BIPS_DENOMINATOR);
            } else {
                /// exact output
                PoolId poolId = poolKey.toId();
                (uint160 sqrtPriceX96,,) = poolManager.getSlot0(poolId);
                uint128 liquidity = poolManager.getLiquidity(poolId);
                uint256 amountIn =
                    SqrtPriceMath.getAmount0Delta(swapParams.sqrtPriceLimitX96, sqrtPriceX96, liquidity, true);
                protocolFee = amountIn.mulDiv(OINK_SWAPFEE_BPS, BIPS_DENOMINATOR);
                if (creatorFeeBps > 0) creatorFee = amountIn.mulDiv(creatorFeeBps, BIPS_DENOMINATOR);
            }
        } else {
            /// One for Zero
            if (swapParams.amountSpecified > 0) {
                /// exact Meme input
                PoolId poolId = poolKey.toId();
                (uint160 sqrtPriceX96,,) = poolManager.getSlot0(poolId);
                uint128 liquidity = poolManager.getLiquidity(poolId);
                uint256 amountOut =
                    SqrtPriceMath.getAmount0Delta(sqrtPriceX96, swapParams.sqrtPriceLimitX96, liquidity, false);
                protocolFee = amountOut * OINK_SWAPFEE_BPS / BIPS_DENOMINATOR;
                if (creatorFeeBps > 0) creatorFee = amountOut * creatorFeeBps / BIPS_DENOMINATOR;
            } else {
                /// exact ETH output
                uint256 amountSpecified = uint256(-swapParams.amountSpecified);
                protocolFee = amountSpecified.mulDiv(OINK_SWAPFEE_BPS, BIPS_DENOMINATOR);
                if (creatorFeeBps > 0) creatorFee = amountSpecified.mulDiv(creatorFeeBps, BIPS_DENOMINATOR);
            }
        }
    }

    function transferCreator(address _newCreator) external {
        if (creator != msg.sender) revert OnlyCreator();

        emit CreatorChanged(creator, _newCreator);
        creator = _newCreator;
    }

    function changeCreatorSwapFee(uint256 _newSwapFee) external {
        if (creator != msg.sender) revert OnlyCreator();
        if (_newSwapFee > CREATOR_MAX_FEE_BPS) revert MemeSwapFeeTooHigh();

        emit CreatorFeeBpsChanged(creatorFeeBps, _newSwapFee);
        creatorFeeBps = _newSwapFee;
    }
}
