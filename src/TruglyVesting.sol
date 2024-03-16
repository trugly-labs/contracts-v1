/// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin Contracts (last updated v5.0.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.23;

import {Owned} from "@solmate/auth/Owned.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {ITruglyVesting} from "./interfaces/ITruglyVesting.sol";

/// @title Vesting contract for MEMERC20 tokens
/// @notice This contract is used to vest MEMERC20 tokens for a specified duration
contract TruglyVesting is ITruglyVesting, Owned {
    using SafeTransferLib for ERC20;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /// @dev Emitted when the vesting of `token` is started by `creator` for `totalAllocation` tokens
    event MEMERC20VestingStarted(
        address indexed token,
        address indexed creator,
        string symbol,
        uint256 totalAllocation,
        uint64 start,
        uint64 duration,
        uint64 cliff
    );
    /// @dev Emitted when `amount` of `token` tokens are released to `creator`
    event MEMERC20Released(address indexed token, address indexed creator, uint256 amount);
    /// @dev Emitted when `memeceptionContract` is authorized or unauthorized
    event MemeceptionAuthorized(address indexed memeception, bool isAuthorized);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Error when the caller is not a memeception
    error NotMemeception();
    /// @dev Error when the vesting of `token` is already started
    error VestingAlreadyStarted();
    /// @dev Error when the `totalAllocation` is zero
    error VestingAmountCannotBeZero();
    /// @dev Error when the `duration` is zero
    error VestingDurationCannotBeZero();
    /// @dev Error when the `creator` is address(0)
    error VestingCreatorCannotBeAddressZero();
    /// @dev Error when the `token` is address(0)
    error VestingTokenCannotBeAddressZero();
    /// @dev Error when the `start` is in the past
    error VestingStartInPast();
    /// @dev Error when the `cliff` is greater than `duration`
    error VestingCliffCannotBeGreaterThanDuration();
    /// @dev Error when the contract does not have enough balance
    error InsufficientBalance();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /// @dev Mapping of token to its vesting information
    mapping(address => VestingInfo) private _vestingInfo;
    /// @dev Mapping of memeception to its authorization status
    mapping(address => bool) private _memeceptionContracts;

    constructor() payable Owned(msg.sender) {}

    /// @inheritdoc ITruglyVesting
    function startVesting(
        address token,
        address creator,
        uint256 totalAllocation,
        uint64 start,
        uint64 duration,
        uint64 cliff
    ) external {
        if (!_memeceptionContracts[msg.sender]) revert NotMemeception();
        if (_vestingInfo[token].start != 0) revert VestingAlreadyStarted();
        if (totalAllocation == 0) revert VestingAmountCannotBeZero();
        if (duration == 0) revert VestingDurationCannotBeZero();
        if (start < block.timestamp) revert VestingStartInPast();
        if (creator == address(0)) revert VestingCreatorCannotBeAddressZero();
        if (token == address(0)) revert VestingTokenCannotBeAddressZero();
        if (cliff > duration) revert VestingCliffCannotBeGreaterThanDuration();
        if (ERC20(token).balanceOf(address(this)) != totalAllocation) revert InsufficientBalance();

        _vestingInfo[token] = VestingInfo({
            totalAllocation: totalAllocation,
            released: 0,
            start: start,
            duration: duration,
            cliff: cliff,
            creator: creator
        });

        emit MEMERC20VestingStarted(token, creator, ERC20(token).symbol(), totalAllocation, start, duration, cliff);
    }

    /// @inheritdoc ITruglyVesting
    function getVestingInfo(address token) public view returns (VestingInfo memory) {
        return _vestingInfo[token];
    }

    /// @inheritdoc ITruglyVesting
    function releasable(address token) public view returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - _vestingInfo[token].released;
    }

    /// @inheritdoc ITruglyVesting
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        _vestingInfo[token].released += amount;
        ERC20(token).safeTransfer(_vestingInfo[token].creator, amount);
        emit MEMERC20Released(token, _vestingInfo[token].creator, amount);
    }

    /// @inheritdoc ITruglyVesting
    function vestedAmount(address token, uint64 timestamp) public view returns (uint256) {
        VestingInfo memory info = _vestingInfo[token];
        uint256 totalAllocation = info.totalAllocation;
        if (timestamp < info.start + info.cliff) {
            return 0;
        } else if (timestamp >= (info.start + info.duration)) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - info.start)) / info.duration;
        }
    }

    /// @inheritdoc ITruglyVesting
    function setMemeception(address memeceptionContract, bool isAuthorized) external onlyOwner {
        _memeceptionContracts[memeceptionContract] = isAuthorized;
        emit MemeceptionAuthorized(memeceptionContract, isAuthorized);
    }
}
