// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {UniversalRouter} from "@trugly-labs/universal-router-fork/UniversalRouter.sol";
import {RouterParameters} from "@trugly-labs/universal-router-fork/base/RouterImmutables.sol";

/// @title The Trugly UniversalRouter
/// @notice Dispatching swaps to UniV2 or UniV3
/// @notice This contract inherit UniswapLabs's UniversalRouter (https://github.com/Uniswap/universal-router)

contract TruglyUniversalRouter is UniversalRouter, Owned {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Emited when the treasury is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    event SwapFee(address indexed token, address indexed creator, uint256 creatorFee, uint256 protocolFee);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Thrown when address is address(0)
    error ZeroAddress();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    address internal treasury;
    uint256 constant BIPS_TREASURY = 20;
    uint256 constant MAX_BIPS = 150;

    constructor(RouterParameters memory params, address _treasury) UniversalRouter(params) Owned(msg.sender) {
        treasury = _treasury;

        emit TreasuryUpdated(address(0), treasury);
    }

    /// @notice Override UniversalRouter.Payments.payPortion
    /// @dev Add the treasury fee + creator fee
    function payPortion(address token, address recipient, uint256 bips) internal override {
        if (bips < BIPS_TREASURY || bips > MAX_BIPS) revert InvalidBips();
        uint256 bipsCreator = bips - BIPS_TREASURY;

        if (token == address(0)) {
            uint256 balance = address(this).balance;
            uint256 amountTreasury = (balance * BIPS_TREASURY) / FEE_BIPS_BASE;
            uint256 amountCreator = (balance * bipsCreator) / FEE_BIPS_BASE;
            treasury.safeTransferETH(amountTreasury);
            if (amountCreator > 0) recipient.safeTransferETH(amountCreator);
            emit SwapFee(token, recipient, amountCreator, amountTreasury);
        } else {
            uint256 balance = ERC20(token).balanceOf(address(this));
            uint256 amountTreasury = (balance * BIPS_TREASURY) / FEE_BIPS_BASE;
            uint256 amountCreator = (balance * bipsCreator) / FEE_BIPS_BASE;
            ERC20(token).safeTransfer(treasury, amountTreasury);
            if (amountCreator > 0) ERC20(token).safeTransfer(recipient, amountCreator);
            emit SwapFee(token, recipient, amountCreator, amountTreasury);
        }
    }

    /// @notice Only the owner can call this function
    /// @dev Update the treasury address
    /// @param _newTreasury The new treasury address
    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, _newTreasury);
        treasury = _newTreasury;
    }
}
