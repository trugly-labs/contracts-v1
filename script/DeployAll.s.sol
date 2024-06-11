// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {DeploymentsFn} from "./utils/DeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";

import {TruglyFactory} from "../src/TruglyFactory.sol";

contract DeployAll is Script, DeploymentsFn {
    /// REMEMBER TO SET THE MNEMONIC_FIRST_ACC_PRIV_KEY TO THE DEPLOYER
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        address multisig = deployMultisig();
        // TruglyFactory factory = deployFactory();
        deployMemeception(
            address(vesting), //Vesting
            treasury,
            multisig,
            0x4f773Bfa7249BE81107e0E1944b99dfA26482270 // Factory
                // address(factory)
        );
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
