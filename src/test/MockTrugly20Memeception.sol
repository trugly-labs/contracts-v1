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

    // /// @dev Lock the UniV3 liquidity in the UNCX Locker
    // /// @param lpTokenId The UniV3 LP Token ID
    // /// @return lockId The UNCX lock ID
    function _lockLiquidity(uint256 lpTokenId, uint256 lockFee) internal override returns (uint256 lockId) {
        if (bypassLock) {
            return 42;
        }
        super._lockLiquidity(lpTokenId, lockFee);
    }
}
