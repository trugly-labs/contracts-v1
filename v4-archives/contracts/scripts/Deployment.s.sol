/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";

import {OinkOink} from "../contracts/OinkOink.sol";
import {OinkSwap} from "../contracts/OinkSwap.sol";

contract DeploymentScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IPoolManager manager = deployPoolManager();

        OinkOink oink = new OinkOink(IPoolManager(manager), address(this));
        OinkSwap oinkSwap = new OinkSwap(IPoolManager(manager));

        vm.stopBroadcast();
    }

    // -----------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------
    function deployPoolManager() internal returns (IPoolManager) {
        return IPoolManager(address(new PoolManager(500000)));
    }
}
