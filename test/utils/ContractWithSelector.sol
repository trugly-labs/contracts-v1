/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract ContractWithSelector {
    constructor() {}
    /// @dev receive ERC721 tokens for Univ3 LP Positions

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev receive ERC1155 tokens for Univ3 LP Positions
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev receive ERC1155 tokens for Univ3 LP Positions
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
