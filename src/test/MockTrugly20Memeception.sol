/// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {WETH} from "@solmate/tokens/WETH.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Trugly20Memeception} from "../Trugly20Memeception.sol";
import {Constant} from "../libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {INonfungiblePositionManager} from "../interfaces/external/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEME20} from "../types/MEME20.sol";

contract MockTrugly20Memeception is Trugly20Memeception {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEME20;

    constructor(
        address _v3Factory,
        address _v3PositionManager,
        address _WETH9,
        address _vesting,
        address _treasury,
        address _multisig
    ) Trugly20Memeception(_v3Factory, _v3PositionManager, _WETH9, _vesting, _treasury, _multisig) {}

    /// Bypass verification
    function _verifyCreateMeme(MemeceptionCreationParams calldata params) internal view override {}

    function _getAuctionPriceScaled(Memeception memory memeception) internal view override returns (uint256) {
        uint256 price = super._getAuctionPriceScaled(memeception);
        return price / 1e7;
    }

    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal override {
        uint160 sqrtPriceX96 = _calcSqrtPriceX96(amountETH, amountMeme);

        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(sqrtPriceX96);

        WETH9.deposit{value: amountETH}();
        WETH9.safeApprove(address(v3PositionManager), amountETH);
        MEME20(memeToken).safeApprove(address(v3PositionManager), amountMeme);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(WETH9),
            token1: memeToken,
            fee: Constant.UNI_LP_SWAPFEE,
            tickLower: Constant.TICK_LOWER,
            tickUpper: Constant.TICK_UPPER,
            amount0Desired: amountETH,
            amount1Desired: amountMeme,
            amount0Min: amountETH.mulDiv(99, 100),
            amount1Min: amountMeme.mulDiv(99, 100),
            recipient: address(this),
            deadline: block.timestamp + 30 minutes
        });

        (uint256 tokenId,,,) = v3PositionManager.mint(params);
        memeceptions[memeToken].tokenId = tokenId;

        emit MemeLiquidityAdded(memeToken, memeceptions[memeToken].pool, amountMeme, amountETH);
    }

    function _calcSqrtPriceX96(uint256 supplyA, uint256 supplyB) internal pure returns (uint160) {
        // Calculate the price ratio (supplyB / supplyA)
        uint256 priceRatio = FixedPointMathLib.divWad(supplyB, supplyA);

        // Calculate the square root of the price ratio
        uint256 sqrtRatio = FixedPointMathLib.sqrt(priceRatio);

        // Convert to Q64.96 format
        return uint160(FixedPointMathLib.fullMulDiv(sqrtRatio, 2 ** 96, FixedPointMathLib.sqrt(1e18)));
    }
}
