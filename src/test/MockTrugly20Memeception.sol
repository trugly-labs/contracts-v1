/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {WETH} from "@solmate/tokens/WETH.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Trugly20Memeception} from "../Trugly20Memeception.sol";
import {Constant} from "../libraries/Constant.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {ILiquidityLocker} from "../interfaces/external/ILiquidityLocker.sol";
import {INonfungiblePositionManager} from "../interfaces/external/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEME20} from "../types/MEME20.sol";

contract MockTrugly20Memeception is Trugly20Memeception {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEME20;

    uint256 public scaleDownFactor = 1e7;
    bool public bypassLock = true;

    address public testAdmin;

    constructor(
        address _v3Factory,
        address _v3PositionManager,
        address _uncxLockers,
        address _WETH9,
        address _vesting,
        address _treasury,
        address _multisig
    ) Trugly20Memeception(_v3Factory, _v3PositionManager, _uncxLockers, _WETH9, _vesting, _treasury, _multisig) {
        testAdmin = msg.sender;
    }

    /// Bypass verification
    function _verifyCreateMeme(MemeceptionCreationParams calldata params) internal view override {}

    function _getAuctionPriceScaled(Memeception memory memeception) internal view override returns (uint256) {
        uint256 price = super._getAuctionPriceScaled(memeception);
        return price / scaleDownFactor;
    }

    function setScaleDownFactor(uint256 _scaleDownFactor) external {
        if (msg.sender != testAdmin) {
            revert("Only test admin can call this function");
        }
        scaleDownFactor = _scaleDownFactor;
    }

    function setBypassLock(bool _bypassLock) external {
        if (msg.sender != testAdmin) {
            revert("Only test admin can call this function");
        }
        bypassLock = _bypassLock;
    }

    function byPass() external {
        if (msg.sender != testAdmin) {
            revert("Only test admin can call this function");
        }
        bypassLock = true;
        scaleDownFactor = 1e7;
    }

    function noBypass() external {
        if (msg.sender != testAdmin) {
            revert("Only test admin can call this function");
        }
        bypassLock = false;
        scaleDownFactor = 1e4;
    }

    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal override {
        if (!bypassLock) {
            _addLiquidityToUniV3Pool(memeToken, amountETH, amountMeme);
            return;
        }

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
}
