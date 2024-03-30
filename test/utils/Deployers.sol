/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {MemeceptionBaseTest} from "../../src/test/MemeceptionBaseTest.sol";
import {RouterBaseTest} from "../../src/test/RouterBaseTest.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {TruglyVesting} from "../../src/TruglyVesting.sol";
import {MemeAddressMiner} from "./MemeAddressMiner.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract Deployers is Test, TestHelpers, BaseParameters {
    // Global variables
    MemeceptionBaseTest memeceptionBaseTest;
    RouterBaseTest routerBaseTest;
    MEMERC20 memeToken;
    TruglyVesting vesting;
    address treasury = address(1);
    TruglyMemeception memeception;

    uint256 public constant MAX_BID_AMOUNT = 10 ether;

    // Parameters
    ITruglyMemeception.MemeceptionCreationParams public createMemeParams = ITruglyMemeception.MemeceptionCreationParams({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: uint40(block.timestamp + 3 days),
        swapFeeBps: 80,
        vestingAllocBps: 500,
        salt: ""
    });

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("base");
        vm.createSelectFork(rpc, 12490712);
        deployVesting();
        deployMemeception();
        deployUniversalRouter();

        memeception = memeceptionBaseTest.memeceptionContract();
    }

    function deployVesting() public virtual {
        vesting = new TruglyVesting();
    }

    function deployMemeception() public virtual {
        memeceptionBaseTest = new MemeceptionBaseTest(address(vesting), treasury);
        vesting.setMemeception(address(memeceptionBaseTest.memeceptionContract()), true);
    }

    function initCreateMeme() public virtual {
        address meme = createMeme(createMemeParams.symbol);
        memeToken = MEMERC20(meme);
    }

    function createMeme(string memory symbol) public virtual returns (address meme) {
        uint40 startAt = uint40(block.timestamp + 3 days);
        (, bytes32 salt) = MemeAddressMiner.find(
            address(memeceptionBaseTest.memeceptionContract()),
            WETH9,
            createMemeParams.name,
            symbol,
            address(memeceptionBaseTest)
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;

        (meme,) = memeceptionBaseTest.createMeme(createMemeParams);
        memeToken = MEMERC20(meme);
    }

    function initBid(uint256 amount) public virtual {
        vm.warp(createMemeParams.startAt);
        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function initFullBid(uint256 lastBidAmount) public virtual {
        vm.warp(createMemeParams.startAt + 115 minutes);

        memeceptionBaseTest.bid{value: lastBidAmount}(address(memeToken));
    }

    function deployUniversalRouter() public virtual {
        routerBaseTest = new RouterBaseTest();
    }
}
