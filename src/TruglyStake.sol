/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {ITruglyMemeception} from "./interfaces/ITruglyMemeception.sol";
import {MEME20} from "./types/MEME20.sol";

contract TruglyStake is Owned, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @dev Thrown when the amount is 0
    error ZeroAmount();

    event Withdrawn(address indexed user, uint256 amount);
    event DepositRewards(address indexed memeToken, uint256 amount);

    ITruglyMemeception public memeception;

    struct StakeInfo {
        uint256 totalStaked;
        uint256 claimableRewards;
    }

    mapping(address => StakeInfo) internal _stakeInfo;
    mapping(address => mapping(address => uint256)) internal _stakedBalances;

    constructor(address _memeception, address _owner) Owned(_owner) {
        memeception = ITruglyMemeception(_memeception);
    }

    function buyAndStake(address memeToken) external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        uint256 beforeBal = MEME20(memeToken).balanceOf(address(this));
        uint256 beforeBalETH = address(this).balance - msg.value;
        memeception.buyMemecoin{value: msg.value}(memeToken);
        uint256 afterBal = MEME20(memeToken).balanceOf(address(this));
        uint256 afterBalETH = address(this).balance;

        uint256 amount = afterBal - beforeBal;
        if (afterBalETH > beforeBalETH) {
            msg.sender.safeTransferETH(afterBalETH - beforeBalETH);
        }
        _stakedBalances[memeToken][msg.sender] += amount;
        _stakeInfo[memeToken].totalStaked += amount;
    }

    function exitAndUnstake(address memeToken) external nonReentrant {
        uint256 amount = _stakedBalances[memeToken][msg.sender];
        if (amount == 0) revert ZeroAmount();
        if (MEME20(memeToken).allowance(address(this), address(memeception)) < amount) {
            MEME20(memeToken).approve(address(memeception), type(uint256).max);
        }

        _stakeInfo[memeToken].totalStaked -= amount;
        _stakedBalances[memeToken][msg.sender] = 0;

        uint256 beforeBal = address(this).balance;
        memeception.exitMemecoin(memeToken, amount);
        uint256 afterBal = address(this).balance;

        payable(msg.sender).transfer(afterBal - beforeBal);
    }

    function withdraw(address memeToken) external nonReentrant {
        StakeInfo storage info = _stakeInfo[memeToken];
        uint256 amount = _stakedBalances[memeToken][msg.sender];
        if (amount == 0) revert ZeroAmount();

        if (info.claimableRewards > 0) {
            uint256 pctScaled = amount.divWad(info.totalStaked);
            uint256 reward = info.claimableRewards.mulWad(pctScaled);
            info.claimableRewards -= reward;
            info.totalStaked -= amount;
            amount += reward;
        } else {
            info.totalStaked -= amount;
        }

        _stakedBalances[memeToken][msg.sender] = 0;
        MEME20(memeToken).transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function depositRewards(address memeToken, uint256 amount) external onlyOwner {
        MEME20(memeToken).transferFrom(msg.sender, address(this), amount);
        _stakeInfo[memeToken].claimableRewards += amount;

        emit DepositRewards(memeToken, amount);
    }

    function getStakedBalance(address memeToken, address user) external view returns (uint256) {
        return _stakedBalances[memeToken][user];
    }

    function getStakeInfo(address memeToken) external view returns (StakeInfo memory) {
        return _stakeInfo[memeToken];
    }

    /// @notice receive native tokens
    receive() external payable {}
}
