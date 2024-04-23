// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {TruglyMOLS} from "../src/TruglyMOLS.sol";
import {BaseParameters} from "./parameters/Base.sol";

contract DeployTruglyMOLS is Script, BaseParameters {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Deploying TruglyMOLS...");
        TruglyMOLS mols = new TruglyMOLS(0x2f5417Dee5bF31fe270Bb9e7F48962dDDA77b755);

        console2.log("TruglyMOLS deployed at: ", address(mols));
    }
}
