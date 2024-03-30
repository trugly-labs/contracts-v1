// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.23;

import {MEMERC20} from "../../src/types/MEMERC20.sol";

library MemeAddressMiner {
    uint256 public constant MAX_LOOP = 200;

    function find(address deployer, address _WETH9, string memory _name, string memory _symbol, address _creator)
        external
        pure
        returns (address, bytes32)
    {
        address memeAddress;
        bytes memory creationCodeWithArgs =
            abi.encodePacked(type(MEMERC20).creationCode, abi.encode(_name, _symbol, _creator));

        uint256 salt;
        for (salt; salt < MAX_LOOP; salt++) {
            memeAddress = computeAddress(deployer, salt, creationCodeWithArgs);
            if (memeAddress > _WETH9) {
                return (memeAddress, bytes32(salt));
            }
        }
        revert("MemeAddressMiner: could not find salt");
    }

    /// @notice Precompute a contract address deployed via CREATE2
    /// @param deployer The address that will deploy the hook. In `forge test`, this will be the test contract `address(this)` or the pranking address
    ///                 In `forge script`, this should be `0x4e59b44847b379578588920cA78FbF26c0B4956C` (CREATE2 Deployer Proxy)
    /// @param salt The salt used to deploy the hook
    /// @param creationCode The creation code of a hook contract
    function computeAddress(address deployer, uint256 salt, bytes memory creationCode)
        public
        pure
        returns (address contractAddress)
    {
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xFF), deployer, salt, keccak256(creationCode)))))
        );
    }
}
