/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.23;

import "./INonfungiblePositionManager.sol";

/**
 * @dev Interface of the UNCX UniswapV3 Liquidity Locker
 */
interface ILiquidityLocker {
    struct LockParams {
        INonfungiblePositionManager nftPositionManager;
        uint256 nft_id;
        address dustRecipient;
        address owner;
        address additionalCollector;
        address collectAddress;
        uint256 unlockDate;
        uint16 countryCode;
        string feeName;
        bytes[] r;
    }

    struct FeeStruct {
        string name;
        uint256 lpFee;
        uint256 collectFee;
        uint256 flatFee;
        address flatFeeToken;
    }

    function lock(LockParams calldata params) external payable returns (uint256 lockId);
    function collect(uint256 lockId, address recipient, uint128 amount0Max, uint128 amount1Max)
        external
        returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    function getFee(string memory name) external view returns (FeeStruct memory);
}
