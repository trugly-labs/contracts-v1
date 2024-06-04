/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Meme20AddressMiner} from "../utils/Meme20AddressMiner.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract CreateMemeTest is DeployersME20 {
    error InvalidMemeAddress();
    error MemeSwapFeeTooHigh();
    error VestingAllocTooHigh();
    error ZeroAmount();
    error MaxTargetETH();
    error Paused();

    string constant symbol = "MEME";

    function setUp() public override {
        super.setUp();

        uint40 startAt = 0;
        (, bytes32 salt) = Meme20AddressMiner.find(
            address(factory), WETH9, createMemeParams.name, symbol, address(memeception), address(memeceptionBaseTest)
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;
    }

    function test_createMeme_success_simple() public {
        createMeme("MEME");
    }

    function test_createMeme_success_future() public {
        createMemeParams.startAt = uint40(block.timestamp + 10 days);
        createMeme("MEME");
    }

    function test_createMeme_success_past() public {
        createMemeParams.startAt = uint40(block.timestamp - 10 days);
        createMeme("MEME");
    }

    function test_createMeme_success_zero_swap() public {
        createMemeParams.swapFeeBps = 0;
        createMeme("MEME");
    }

    function test_createMeme_success_zero_vesting() public {
        createMemeParams.vestingAllocBps = 0;
        createMeme("MEME");
    }

    function test_createMeme_success_max_vesting() public {
        createMemeParams.vestingAllocBps = 1000;
        createMeme("MEME");
    }

    function test_createMemeSymbolExist_success() public {
        createMeme("MEME");

        createMemeParams.salt = bytes32("6");
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMemeSameSymbolAndSalt_collision_revert() public {
        createMeme("MEME");

        vm.expectRevert();
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMeme_fail_swapFee() public {
        createMemeParams.swapFeeBps = 81;
        vm.expectRevert(MemeSwapFeeTooHigh.selector);
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMeme_fail_vestingAlloc() public {
        createMemeParams.vestingAllocBps = 1001;
        vm.expectRevert(VestingAllocTooHigh.selector);
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMeme_fail_targetETH() public {
        createMemeParams.targetETH = 0;
        vm.expectRevert(ZeroAmount.selector);
        memeception.createMeme(createMemeParams);
    }

    function test_createMeme_fail_max_targetETH() public {
        createMemeParams.targetETH = Constant.MAX_TARGET_ETH + 1;
        vm.expectRevert(MaxTargetETH.selector);
        memeception.createMeme(createMemeParams);
    }

    function test_createMeme_fail_paused() public {
        vm.startPrank(memeceptionBaseTest.MULTISIG());
        memeception.setPaused(true);
        vm.stopPrank();

        vm.expectRevert(Paused.selector);
        memeception.createMeme(createMemeParams);
    }
}
