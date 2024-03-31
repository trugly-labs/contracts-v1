// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {MockDeploymentsFn} from "./utils/MockDeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";

contract MockDeployAll is Script, MockDeploymentsFn {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        deployMemeception(address(vesting), treasury);
        // deployMemeception(0xa8951e7a48B9e2E09e99585944411aD4A2D4Ce9d, treasury);
        deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
