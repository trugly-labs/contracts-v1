/// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

import {IERC721Receiver} from "./external/IERC721Receiver.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MemeRC20 and their Memeception
interface ITruglyLaunchpad is IERC721Receiver {
    /// @dev Struct containing information about the Memeception and the UniV3 Pool
    struct Memeception {
        /// @dev Address of the UniV3 Pool
        address pool;
        /// @dev Address of the creator of the Memeception
        address creator;
        /// @dev Total Amount contributed to the Memeception
        uint80 balance;
        /// @dev Cap to reach before the Memeception ends
        uint80 cap;
        /// @dev Date when the Memeception will/has started
        uint64 startAt;
        /// @dev Swap Fee of the UniV3 Pool (in bps)
        uint16 swapFeeBps;
    }

    /// @dev Containing the parameters to create a MemeRC20
    struct MemeCreationParams {
        /// @dev Name of the MemeRC20
        string name;
        /// @dev Symbol of the MemeRC20
        string symbol;
        /// @dev Date when the Memeception will start
        uint64 startAt;
        /// @dev Cap to reach before the Memeception ends
        uint80 cap;
        /// @dev Swap Fee of the UniV3 Pool (in bps)
        uint16 swapFeeBps;
        /// @dev Amount of the MEMERC20 allocated to the team and vested (in bps)
        uint16 vestingAllocBps;
    }

    /// @dev Create a MemeRC20, its UniV3 Pool and setup the Memeception
    /// @param memeCreation Parameters to create the MemeRC20 and its Memeception
    /// @return memeToken Address of the MemeRC20
    /// @return pool Address of the UniV3 Pool
    function createMeme(MemeCreationParams calldata memeCreation) external returns (address memeToken, address pool);

    /// @dev Deposit ETH to the Memeception
    /// @param memeToken Address of the MemeRC20
    /// @param sig Signature to authorize the deposit
    function depositMemeception(address memeToken, bytes calldata sig) external payable;

    /// @notice Exit the Memeception
    /// @dev Only possible after deadline is reached & cap not reached
    /// @param memeToken Address of the MemeRC20
    function exitMemeception(address memeToken) external;

    /// @notice Claim the MemeRC20 from the Memeception
    /// @dev Only possible after the cap is reached
    /// @param memeToken Address of the MemeRC20
    function claimMemeception(address memeToken) external;

    /// @notice Set the signer address in charge of signing Memeception participation
    /// @dev Only the admin can call this function
    /// @param _memeSigner Address of the new signer
    function setMemeSigner(address _memeSigner) external;

    /// @dev Get the Memeception information for a given MemeRC20
    /// @param memeToken Address of the MemeRC20
    /// @return memeception Memeception information
    function getMemeception(address memeToken) external view returns (Memeception memory);

    /// @dev Get the ETH balance of a given OG address in a Memeception
    /// @param memeToken Address of the MemeRC20
    /// @param og Address of the OG
    /// @return balanceOG ETH balance of the OG
    function getBalanceOG(address memeToken, address og) external view returns (uint256 balanceOG);
}
