// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {DeploymentsFn} from "./utils/DeploymentsFn.sol";
import {TruglyVesting} from "../src/TruglyVesting.sol";
import {BaseParameters} from "./parameters/Base.sol";
import {MEME20} from "../src/types/MEME20.sol";

contract DeployMEME20 is Script, BaseParameters {
    address[] internal SWAP_ROUTERS = [
        0x2626664c2603336E57B271c5C0b26F421741e481, // SwapRouter02
        0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD // UniswapRouter
    ];

    address[] internal EXEMPT_UNISWAP = [
        0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1, // LP Positions
        0x42bE4D6527829FeFA1493e1fb9F3676d2425C3C1, // Staker Address
        0x067170777BA8027cED27E034102D54074d062d71 // Fee Collector
    ];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MNEMONIC_FIRST_ACC_PRIV_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console2.log("Deploying MEME20 contract...");
        MEME20 meme20 = new MEME20("TestFoo", "FOOTEST", msg.sender);
        meme20.initializeFirst(TREASURY, 20, 80, SWAP_ROUTERS, EXEMPT_UNISWAP);
        console2.log("MEME20 deployed: ", address(meme20));
        vm.stopBroadcast();
    }
}
