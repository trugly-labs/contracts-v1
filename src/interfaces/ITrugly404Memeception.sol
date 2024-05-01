/// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

import {IERC721Receiver} from "./external/IERC721Receiver.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MemeRC20 and their Memeception
interface ITrugly404Memeception is IERC721Receiver {
    /// @dev Struct containing information about the Memeception and the UniV3 Pool
    struct Memeception {
        /// @dev LP Token ID
        uint256 tokenId;
        /// @dev Address of the UniV3 Pool
        address pool;
        /// @dev Auction final price (0 is not finished or auction ended without selling all tokens) scaled by 18
        uint64 auctionFinalPriceScaled;
        /// @dev Swap Fee of the UniV3 Pool (in bps)
        uint16 swapFeeBps;
        /// @dev Address of the creator of the Memeception
        address creator;
        /// @dev Date when the Memeception will/has started
        uint40 startAt;
        /// @dev Amount of token currently sold in the Memeception Auction
        uint112 auctionTokenSold;
        uint256 auctionEndedAt;
    }

    struct Bid {
        /// @dev Amount deposited by the bidder
        /// enough to store <10,000 ether
        uint80 amountETH;
        uint112 amountMeme;
    }

    /// @dev Containing the parameters to create a MemeRC20
    struct MemeceptionCreationParams {
        /// @dev Name of the MemeRC20
        string name;
        /// @dev Symbol of the MemeRC20
        string symbol;
        /// @dev Date when the Memeception will start
        uint40 startAt;
        /// @dev Swap Fee of the UniV3 Pool (in bps)
        uint16 swapFeeBps;
        /// @dev Amount of the MEMERC20 allocated to the team and vested (in bps)
        uint16 vestingAllocBps;
        /// @dev Salt to create the MEMERC20 with an address lower than WETH9
        bytes32 salt;
        address creator;
    }

    /// @dev Create a MemeRC20, its UniV3 Pool and setup the Memeception
    /// @param params Parameters to create the MemeRC20 and its Memeception
    /// @return memeToken Address of the MemeRC20
    /// @return pool Address of the UniV3 Pool
    function createMeme(MemeceptionCreationParams calldata params) external returns (address memeToken, address pool);

    /// @dev Place a bid to the Memeception
    /// @param memeToken Address of the MemeRC20
    function bid(address memeToken) external payable;

    /// @notice Exit the Memeception
    /// @dev Only possible after deadline is reached & cap not reached
    /// @param memeToken Address of the MemeRC20
    function exit(address memeToken) external;

    /// @notice Claim the MemeRC20 from the Memeception
    /// @dev Only possible after the cap is reached
    /// @param memeToken Address of the MemeRC20
    function claim(address memeToken) external;

    /// @dev Get the Memeception information for a given MemeRC20
    /// @param memeToken Address of the MemeRC20
    /// @return memeception Memeception information
    function getMemeception(address memeToken) external view returns (Memeception memory);

    /// @dev Get the ETH balance of a given OG address in a Memeception
    /// @param memeToken Address of the MemeRC20
    /// @param og Address of the OG
    /// @return balanceOG ETH balance of the OG
    function getBid(address memeToken, address og) external view returns (Bid memory);

    /// @dev Get the current Auction price for a given MemeRC20's memeception
    /// @param memeToken Address of the MemeRC20
    /// @return priceScaled Current Auction price (scaled by 1e25)
    function getAuctionPriceScaled(address memeToken) external view returns (uint256 priceScaled);
}
