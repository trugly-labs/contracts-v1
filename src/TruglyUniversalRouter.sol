// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {UniversalRouter} from "@trugly-labs/universal-router-fork/UniversalRouter.sol";
import {RouterParameters} from "@trugly-labs/universal-router-fork/base/RouterImmutables.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

/// @title The Trugly UniversalRouter
/// @notice Dispatching swaps to UniV2 or UniV3
/// @notice This contract inherit UniswapLabs's UniversalRouter (https://github.com/Uniswap/universal-router)

contract TruglyUniversalRouter is UniversalRouter {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Emitted when the admin is updated
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    /// @dev Emited when the treasury is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /// @dev Thrown when the caller is not the admin
    error OnlyAdmin();

    /// @dev Thrown when address is address(0)
    error ZeroAddress();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    address private admin;
    address internal treasury;
    uint256 constant BIPS_TREASURY = 20;
    uint256 constant MAX_BIPS = 150;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       MODIFIERS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        if (admin != msg.sender) revert OnlyAdmin();
        _;
    }

    constructor(RouterParameters memory params, address _treasury) UniversalRouter(params) {
        treasury = _treasury;
        admin = msg.sender;

        emit AdminUpdated(address(0), admin);
        emit TreasuryUpdated(address(0), treasury);
    }

    /// @notice Pays a proportion of the contract's ETH or ERC20 to a recipient
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param bips Portion in bips of whole balance of the contract
    function payPortion(address token, address recipient, uint256 bips) internal override {
        if (bips > MAX_BIPS) revert InvalidBips();
        if (recipient == treasury) {
            super.payPortion(token, recipient, bips);
            return;
        }
        if (bips < BIPS_TREASURY) revert InvalidBips();
        uint256 bipsCreator = bips - BIPS_TREASURY;

        if (token == address(0)) {
            uint256 balance = address(this).balance;
            uint256 amountTreasury = (balance * BIPS_TREASURY) / FEE_BIPS_BASE;
            uint256 amountCreator = (balance * bipsCreator) / FEE_BIPS_BASE;
            treasury.safeTransferETH(amountTreasury);
            recipient.safeTransferETH(amountCreator);
        } else {
            uint256 balance = ERC20(token).balanceOf(address(this));
            uint256 amountTreasury = (balance * BIPS_TREASURY) / FEE_BIPS_BASE;
            uint256 amountCreator = (balance * bipsCreator) / FEE_BIPS_BASE;
            ERC20(token).safeTransfer(treasury, amountTreasury);
            ERC20(token).safeTransfer(recipient, amountCreator);
        }
    }

    /// @notice Transfer the admin role to a new account
    /// @dev Only the current admin can call this function
    /// @param _newAdmin Address of the new admin
    function transferAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert ZeroAddress();
        emit AdminUpdated(admin, _newAdmin);
        admin = _newAdmin;
    }

    function setTreasury(address _newTreasury) external onlyAdmin {
        if (_newTreasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, _newTreasury);
        treasury = _newTreasury;
    }
}
