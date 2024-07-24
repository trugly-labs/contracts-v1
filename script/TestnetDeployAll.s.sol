// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {TestnetTruglyMemeception} from "../src/test/TestnetTruglyMemeception.sol";
import {TestnetDeploymentsFn} from "./utils/TestnetDeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";
import {TruglyStake} from "../src/TruglyStake.sol";
import {TruglyFactory} from "../src/TruglyFactory.sol";

contract TestnetDeployAll is Script, TestnetDeploymentsFn {
    address public constant TESTNET_DEPLOYER = 0x19a2b9B38790BE0061c859Bee6324251DF03EC8B;

    function run() external {
        /// REMEMBER TO SET THE MNEMONIC_FIRST_ACC_PRIV_KEY TO THE TESTNET DEPLOYER
        uint256 deployerPrivateKey = vm.envUint("TESTNET_MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TruglyVesting vesting = deployVesting();
        address treasury = deployTreasury();
        // TruglyFactory factory = deployFactory();
        console2.log("Deployer Address: ", TESTNET_DEPLOYER);
        TestnetTruglyMemeception memeception = deployMemeception(
            address(vesting), // Vesting
            treasury,
            TESTNET_DEPLOYER, // Owner
            0xFee41B9d16426913F95AC1f6AF1FA6Aa8Ac48220 // Factory
        );
        // deployUniversalRouter(treasury);
        TruglyStake stake = deployStake(
            address(memeception), // TestnetTruglyMemeception
            TESTNET_DEPLOYER
        );
        vm.stopBroadcast();
    }
}
