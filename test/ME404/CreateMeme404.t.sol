/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME404} from "../utils/DeployersME404.sol";
import {Meme20AddressMiner} from "../utils/Meme20AddressMiner.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract CreateMeme404Test is DeployersME404 {
    error InvalidMemeAddress();
    error InvalidMemeceptionDate();
    error MemeSwapFeeTooHigh();
    error VestingAllocTooHigh();
    error TargetETHTooLow();

    string constant symbol = "MEME";

    function setUp() public override {
        super.setUp();

        uint40 startAt = 0;
        (, bytes32 salt) = Meme20AddressMiner.find(
            address(memeceptionBaseTest.memeceptionContract()),
            WETH9,
            createMemeParams.name,
            symbol,
            address(memeceptionBaseTest)
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;
    }

    function test_404createMeme_success_simple() public {
        createMeme404("MEME");
    }

    function test_404createMeme_success_zero_swap() public {
        createMemeParams.swapFeeBps = 0;
        createMeme404("MEME");
    }

    function test_404createMeme_success_zero_vesting() public {
        createMemeParams.vestingAllocBps = 0;
        createMeme404("MEME");
    }

    function test_404createMeme_success_max_vesting() public {
        createMemeParams.vestingAllocBps = 1000;
        createMeme404("MEME");
    }

    function test_404createMemeSymbolExist_success() public {
        createMeme404("MEME");

        createMemeParams.salt = bytes32("4");
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMemeSameSymbolAndSalt_collision_revert() public {
        createMeme404("MEME");

        vm.expectRevert();
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_success_future() public {
        createMemeParams.startAt = uint40(block.timestamp + Constant.MEMECEPTION_MAX_START_AT);
        createMeme404("MEME");
    }

    function test_404createMeme_fail_maxStartAt() public {
        createMemeParams.startAt = uint40(block.timestamp + Constant.MEMECEPTION_MAX_START_AT + 1);
        vm.expectRevert(InvalidMemeceptionDate.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_swapFee() public {
        createMemeParams.swapFeeBps = 81;
        vm.expectRevert(MemeSwapFeeTooHigh.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_vestingAlloc() public {
        createMemeParams.vestingAllocBps = 1001;
        vm.expectRevert(VestingAllocTooHigh.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_targetETH() public {
        createMemeParams.targetETH = Constant.MIN_TARGET_ETH - 1;
        vm.expectRevert(TargetETHTooLow.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }
}
