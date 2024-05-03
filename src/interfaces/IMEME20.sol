/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IMEME20 {
    function creator() external view returns (address);

    function feeBps() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function isPoolOrRouter(address account) external view returns (bool);

    function isExempt(address account) external view returns (bool);

    function addPoolOrRouter(address _contract) external;

    function addExempt(address _contract) external;

    function setCreatorFeeBps(uint256 _newFeeBps) external;

    function setCreatorAddress(address _creator) external;

    function recovery(address _stuckToken) external;

    function setProtocolFeeBps(uint256 _newFeeBps) external;

    function setProtocolAddress(address _protocolAddress) external;

    function setTreasuryAddress(address _treasury) external;
}
