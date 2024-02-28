/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {ITruglyLaunchpad} from "../../src/interfaces/ITruglyLaunchpad.sol";
import {LaunchpadBaseTest} from "../../src/test/LaunchpadBaseTest.sol";
import {RouterBaseTest} from "../../src/test/RouterBaseTest.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {DeploymentAddresses} from "../../src/test/DeploymentAddresses.sol";

contract Deployers is Test, Constant, DeploymentAddresses {
    // Global variables
    LaunchpadBaseTest launchpadBaseTest;
    RouterBaseTest routerBaseTest;
    MEMERC20 memeToken;

    // Parameters
    ITruglyLaunchpad.MemeCreationParams public createMemeParams = ITruglyLaunchpad.MemeCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: block.timestamp + 3 days,
        cap: 100 ether,
        swapFeeBps: 100
    });

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpc, 19287957);
        deployLaunchpad();
        deployUniversalRouter();
    }

    function deployLaunchpad() public virtual {
        address signer = address(this);
        launchpadBaseTest = new LaunchpadBaseTest(signer);
    }

    function initCreateMeme() public virtual {
        createMemeParams.startAt = block.timestamp + 3 days;
        (address meme,) = launchpadBaseTest.createMeme(createMemeParams);
        memeToken = MEMERC20(meme);
    }

    function initDepositMemeception(uint256 amount) public virtual {
        vm.warp(block.timestamp + 4 days);
        launchpadBaseTest.depositMemeception{value: amount}(address(memeToken));
    }

    function deployUniversalRouter() public virtual {
        routerBaseTest = new RouterBaseTest();
    }
}
