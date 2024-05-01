// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {DeploymentsFn} from "./utils/DeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";

contract DeployAll is Script, DeploymentsFn {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        deployMemeception(0xD309DcF90f6A4eAd4D0fddD7760f33fAc511c71d, treasury);
        // deployUniversalRouter(treasury);
        vm.stopBroadcast();
    }
}
