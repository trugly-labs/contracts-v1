// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";

import {RouterParameters} from "@trugly-labs/universal-router-fork/base/RouterImmutables.sol";
import {BaseParameters} from "../parameters/Base.sol";
import {TruglyUniversalRouter} from "../../src/TruglyUniversalRouter.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {MockTruglyMemeception} from "../../src/test/MockTruglyMemeception.sol";

contract MockDeploymentsFn is BaseParameters {
    function deployUniversalRouter(address treasury) public returns (TruglyUniversalRouter router) {
        console2.log("Deploying TruglyUniversalRouter..");
        RouterParameters memory params = RouterParameters({
            permit2: PERMIT2,
            weth9: WETH9,
            seaportV1_5: UNSUPPORTED_PROTOCOL,
            seaportV1_4: UNSUPPORTED_PROTOCOL,
            openseaConduit: UNSUPPORTED_PROTOCOL,
            nftxZap: UNSUPPORTED_PROTOCOL,
            x2y2: UNSUPPORTED_PROTOCOL,
            foundation: UNSUPPORTED_PROTOCOL,
            sudoswap: UNSUPPORTED_PROTOCOL,
            elementMarket: UNSUPPORTED_PROTOCOL,
            nft20Zap: UNSUPPORTED_PROTOCOL,
            cryptopunks: UNSUPPORTED_PROTOCOL,
            looksRareV2: UNSUPPORTED_PROTOCOL,
            routerRewardsDistributor: UNSUPPORTED_PROTOCOL,
            looksRareRewardsDistributor: UNSUPPORTED_PROTOCOL,
            looksRareToken: UNSUPPORTED_PROTOCOL,
            v2Factory: V2_FACTORY,
            v3Factory: V3_FACTORY,
            pairInitCodeHash: ROUTER_PAIR_INIT_CODE_HASH,
            poolInitCodeHash: POOL_INIT_CODE_HASH
        });

        router = new TruglyUniversalRouter(params, treasury);
        console2.log("Universal Router Deployed:", address(router));
    }

    function deployVesting() public returns (TruglyVesting vesting) {
        console2.log("Deploying TruglyVesting..");
        vesting = new TruglyVesting();
        console2.log("TruglyVesting Deployed:", address(vesting));
    }

    function deployTreasury() public pure returns (address) {
        console2.log("Deploying Treasury..");
        console2.log("Treasury Deployed:", TREASURY);
        return TREASURY;
    }

    function deployMemeception(address vesting, address treasury) public returns (MockTruglyMemeception memeception) {
        console2.log("Deploying TruglyMemeception..");
        memeception = new MockTruglyMemeception(V3_FACTORY, V3_POSITION_MANAGER, WETH9, vesting, treasury);
        TruglyVesting(vesting).setMemeception(address(memeception), true);
        console2.log("TruglyMemeception Deployed:", address(memeception));
    }
}
