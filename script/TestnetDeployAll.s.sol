// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {TestnetDeploymentsFn} from "./utils/TestnetDeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";
import {TruglyFactory} from "../src/TruglyFactory.sol";

contract TestnetDeployAll is Script, TestnetDeploymentsFn {
    function run() external {
        /// REMEMBER TO SET THE MNEMONIC_FIRST_ACC_PRIV_KEY TO THE TESTNET DEPLOYER
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        // TruglyFactory factory = deployFactory();
        console2.log("Deployer Address: ", 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD);
        deployMemeception(
            0x5E5571147F71E7f58484c2AfA0AB859dc80E8251, // Vesting
            treasury,
            0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD, // Owner
            0x69366Ff75E4b46445926BB08CD7268f6278D8D1d // Factory
        );
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
