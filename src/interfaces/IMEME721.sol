/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IMEME721 {
    function mint(address account, uint256 id) external;
    function burn(uint256 id) external;

    function nextOwnedTokenId(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
