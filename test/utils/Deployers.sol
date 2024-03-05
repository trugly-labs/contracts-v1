/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {MemeceptionBaseTest} from "../../src/test/MemeceptionBaseTest.sol";
import {RouterBaseTest} from "../../src/test/RouterBaseTest.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {DeploymentAddresses} from "../../src/test/DeploymentAddresses.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {MemeAddressMiner} from "./MemeAddressMiner.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Deployers is Test, TestHelpers, DeploymentAddresses {
    // Global variables
    MemeceptionBaseTest memeceptionBaseTest;
    RouterBaseTest routerBaseTest;
    MEMERC20 memeToken;
    TruglyVesting vesting;

    // Parameters
    ITruglyMemeception.MemeceptionCreationParams public createMemeParams = ITruglyMemeception.MemeceptionCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: uint40(block.timestamp + 3 days),
        swapFeeBps: 100,
        vestingAllocBps: 500,
        salt: ""
    });

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpc, 19287957);
        deployVesting();
        deployMemeception();
        deployUniversalRouter();
    }

    function deployVesting() public virtual {
        vesting = new TruglyVesting();
    }

    function deployMemeception() public virtual {
        memeceptionBaseTest = new MemeceptionBaseTest(address(vesting));
        vesting.setMemeception(address(memeceptionBaseTest.memeceptionContract()), true);
    }

    function initCreateMeme() public virtual {
        address meme = createMeme(createMemeParams.symbol);
        memeToken = MEMERC20(meme);
    }

    function createMeme(string memory symbol) public virtual returns (address meme) {
        uint40 startAt = uint40(block.timestamp + 3 days);
        (, bytes32 salt) = MemeAddressMiner.find(
            address(memeceptionBaseTest.memeceptionContract()), WETH9, createMemeParams.name, symbol
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;

        (meme,) = memeceptionBaseTest.createMeme(createMemeParams);
        memeToken = MEMERC20(meme);
    }

    function initBid(uint256 amount) public virtual {
        vm.warp(block.timestamp + 4 days);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function deployUniversalRouter() public virtual {
        routerBaseTest = new RouterBaseTest();
    }
}
