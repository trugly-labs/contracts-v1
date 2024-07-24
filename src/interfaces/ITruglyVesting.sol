/// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin Contracts (last updated v5.0.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.23;

/// @title Vesting contract for MEMERC20 tokens
/// @notice This contract is used to vest MEMERC20 tokens for a specified duration
interface ITruglyVesting {
    /// @dev Store information about the vesting of a single token
    struct VestingInfo {
        uint256 totalAllocation;
        uint256 released;
        uint64 start;
        uint64 duration;
        uint64 cliff;
        address creator;
    }

    /// @dev Start vesting for a token
    /// @param token The token to vest
    /// @param creator The creator of the token, who will receive the vested tokens
    /// @param duration The duration of the vesting
    /// @param cliff The cliff time of the vesting
    function startVesting(address token, address creator, uint64 duration, uint64 cliff) external;

    /// @dev Get the vesting information for a token
    /// @param token The token to get the vesting information for
    /// @return The vesting information for the token
    function getVestingInfo(address token) external view returns (VestingInfo memory);

    /// @dev Get the amount of tokens that can be released
    /// @param token The token to get the releasable amount for
    /// @return The amount of tokens that can be released
    function releasable(address token) external view returns (uint256);

    /// @dev Release claimable vested tokens
    /// @param token The token to release vested tokens for
    function release(address token) external;

    /// @dev Get the amount of tokens that are vested (claimed + unclaimed)
    /// @param token The token to get the vested amount for
    /// @param timestamp The timestamp to get the vested amount for
    /// @return The amount of tokens that are vested
    function vestedAmount(address token, uint64 timestamp) external view returns (uint256);

    /// @dev Authorize or unauthorize a memeception contract
    /// @param memeceptionContract The memeception contract to authorize or unauthorize
    /// @param isAuthorized Whether the memeception contract is authorized or not
    function setMemeception(address memeceptionContract, bool isAuthorized) external;

    /// @dev Transfer the creator of a token
    /// @param token The token to transfer the creator of
    /// @param _newCreator The new creator of the token
    function transferCreator(address token, address _newCreator) external;
}
