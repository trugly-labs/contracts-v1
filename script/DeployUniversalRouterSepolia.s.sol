// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {DeploymentsFn} from "./utils/DeploymentsFn.sol";

contract DeployUniversalRouterSepolia is Script, DeploymentsFn {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address treasury = deployTreasury();
        deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
