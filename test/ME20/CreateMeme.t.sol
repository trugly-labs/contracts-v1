/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Meme20AddressMiner} from "../utils/Meme20AddressMiner.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract CreateMemeTest is DeployersME20 {
    error InvalidMemeAddress();
    error MemeSymbolExist();
    error InvalidMemeceptionDate();
    error MemeSwapFeeTooHigh();
    error VestingAllocTooHigh();

    string constant symbol = "MEME";

    function setUp() public override {
        super.setUp();

        uint40 startAt = uint40(block.timestamp + 3 days);
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

    function test_createMeme_success() public {
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

    function test_createMeme_fail_symbolExist() public {
        createMeme("MEME");

        vm.expectRevert(MemeSymbolExist.selector);
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMeme_fail_minStartAt() public {
        createMemeParams.startAt = uint40(block.timestamp + Constant.MEMECEPTION_MIN_START_AT - 1);
        vm.expectRevert(InvalidMemeceptionDate.selector);
        memeceptionBaseTest.createMeme(createMemeParams);
    }

    function test_createMeme_fail_maxStartAt() public {
        createMemeParams.startAt = uint40(block.timestamp + Constant.MEMECEPTION_MAX_START_AT + 1);
        vm.expectRevert(InvalidMemeceptionDate.selector);
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
}
