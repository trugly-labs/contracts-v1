// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {TestnetDeploymentsFn} from "./utils/TestnetDeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";
import {TruglyFactory} from "../src/TruglyFactory.sol";

contract TestnetDeployAll is Script, TestnetDeploymentsFn {
    address public constant TESTNET_DEPLOYER = 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD;

    function run() external {
        /// REMEMBER TO SET THE MNEMONIC_FIRST_ACC_PRIV_KEY TO THE TESTNET DEPLOYER
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        TruglyFactory factory = deployFactory();
        console2.log("Deployer Address: ", 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD);
        deployMemeception(
            address(vesting), // Vesting
            treasury,
            TESTNET_DEPLOYER, // Owner
            address(factory) // Factory
        );
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
