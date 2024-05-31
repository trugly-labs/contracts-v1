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

    function _lockLiquidity(uint256 lpTokenId, uint256 lockFee) internal override returns (uint256) {
        if (bypassLock) return lpTokenId;
        return super._lockLiquidity(lpTokenId, lockFee);
    }

    function _getUncxLockerFee() internal view override returns (uint256) {
        if (bypassLock) return 0;
        return super._getUncxLockerFee();
    }
}
