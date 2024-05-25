/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IMEME1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}
