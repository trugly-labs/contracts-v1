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
        address multisig = deployMultisig();
        deployMemeception(0x5E5571147F71E7f58484c2AfA0AB859dc80E8251, treasury, multisig);
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
