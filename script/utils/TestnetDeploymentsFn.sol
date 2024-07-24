// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";

import {Constant} from "../../src/libraries/Constant.sol";
import {RouterParameters} from "@trugly-labs/universal-router-fork/base/RouterImmutables.sol";
import {TruglyUniversalRouter} from "../../src/TruglyUniversalRouter.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {TruglyStake} from "../../src/TruglyStake.sol";
import {TruglyFactory} from "../../src/TruglyFactory.sol";
import {TruglyFactoryNFT} from "../../src/TruglyFactoryNFT.sol";
import {TestnetTruglyMemeception} from "../../src/test/TestnetTruglyMemeception.sol";

contract TestnetDeploymentsFn {
    address public constant UNSUPPORTED_PROTOCOL = address(0);
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address public constant TREASURY = 0x2f5417Dee5bF31fe270Bb9e7F48962dDDA77b755;
    address public constant ADMIN = 0xb2660C551AB31FAc6D01a75f628Af2d200FfD1F2;

    function deployUniversalRouter(address treasury) public returns (TruglyUniversalRouter router) {
        console2.log("Deploying TruglyUniversalRouter..");
        RouterParameters memory params = RouterParameters({
            permit2: PERMIT2,
            weth9: Constant.BASE_WETH9,
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
            v2Factory: UNSUPPORTED_PROTOCOL,
            v3Factory: Constant.UNISWAP_BASE_V3_FACTORY,
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

    function deployFactory() public returns (TruglyFactory factory) {
        console2.log("Deploying TruglyFactoryNFT..");
        TruglyFactoryNFT factoryNFT = new TruglyFactoryNFT();
        console2.log("TruglyFactoryNFT Deployed:", address(factoryNFT));

        console2.log("Deploying TruglyFactory..");
        factory = new TruglyFactory(address(factoryNFT));
        console2.log("TruglyFactory Deployed:", address(factory));
    }

    function deployMemeception(address vesting, address treasury, address multisig, address factory)
        public
        returns (TestnetTruglyMemeception memeception)
    {
        console2.log("Deploying TruglyMemeception..");
        memeception = new TestnetTruglyMemeception(vesting, treasury, multisig, factory);
        TruglyVesting(vesting).setMemeception(address(memeception), true);
        console2.log("TruglyMemeception Deployed:", address(memeception));
    }

    function deployStake(address memeception, address multisig) public returns (TruglyStake stake) {
        console2.log("Deploying TruglyStake..");
        stake = new TruglyStake(memeception, multisig);
        console2.log("TruglyStake Deployed:", address(stake));
    }
}
