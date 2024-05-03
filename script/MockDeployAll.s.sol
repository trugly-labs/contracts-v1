// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {MockDeploymentsFn} from "./utils/MockDeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";

contract MockDeployAll is Script, MockDeploymentsFn {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        console2.log("Deployer Address: ", 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD);
        deployMemeception(
            0x5E5571147F71E7f58484c2AfA0AB859dc80E8251, treasury, 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD
        );
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
