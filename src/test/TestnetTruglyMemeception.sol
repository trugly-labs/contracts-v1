/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {TruglyMemeception} from "../TruglyMemeception.sol";
import {Constant} from "../libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {IMEME20} from "../interfaces/IMEME20.sol";
import {IWETH9} from "./../interfaces/external/IWETH9.sol";
import {ILiquidityLocker} from "../interfaces/external/ILiquidityLocker.sol";
import {INonfungiblePositionManager} from "../interfaces/external/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEME20Constant} from "../libraries/MEME20Constant.sol";

contract TestnetTruglyMemeception is TruglyMemeception {
    using FixedPointMathLib for uint256;

    bool public bypassLock = true;

    address public testAdmin;

    constructor(address _vesting, address _treasury, address _multisig, address _factory)
        TruglyMemeception(_vesting, _treasury, _multisig, _factory)
    {
        testAdmin = msg.sender;
    }

    function setBypassLock(bool _bypassLock) external {
        if (msg.sender != testAdmin) {
            revert("Only test admin can call this function");
        }
        bypassLock = _bypassLock;
    }

    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal override {
        if (!bypassLock) {
            _addLiquidityToUniV3Pool(memeToken, amountETH, amountMeme);
            return;
        }

        uint256 amountETHMinusLockFee = amountETH;

        IMEME20(memeToken).initialize(
            owner,
            treasury,
            MEME20Constant.MAX_PROTOCOL_FEE_BPS,
            memeceptions[memeToken].swapFeeBps,
            memeceptions[memeToken].pool,
            SWAP_ROUTERS,
            EXEMPT_FEES
        );
        uint160 sqrtPriceX96 = _calcSqrtPriceX96(amountETHMinusLockFee, amountMeme);
        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(sqrtPriceX96);

        WETH9.deposit{value: amountETHMinusLockFee}();
        WETH9.approve(address(v3PositionManager), amountETHMinusLockFee);
        IMEME20(memeToken).approve(address(v3PositionManager), amountMeme);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(WETH9),
            token1: memeToken,
            fee: Constant.UNI_LP_SWAPFEE,
            tickLower: Constant.TICK_LOWER,
            tickUpper: Constant.TICK_UPPER,
            amount0Desired: amountETHMinusLockFee,
            amount1Desired: amountMeme,
            amount0Min: amountETHMinusLockFee.mulDiv(99, 100),
            amount1Min: amountMeme.mulDiv(99, 100),
            recipient: address(this),
            deadline: block.timestamp + 30 minutes
        });

        (uint256 tokenId,,,) = v3PositionManager.mint(params);
        memeceptions[memeToken].tokenId = tokenId;

        emit MemeLiquidityAdded(memeToken, memeceptions[memeToken].pool, amountMeme, amountETHMinusLockFee);
    }
}
