/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {Meme20AddressMiner} from "../utils/Meme20AddressMiner.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract CreateMeme404Test is DeployersME404 {
    using FixedPointMathLib for uint256;

    error InvalidMemeAddress();
    error MemeSwapFeeTooHigh();
    error VestingAllocTooHigh();
    error ZeroAmount();
    error MaxTargetETH();
    error Paused();
    error MaxBuyETHTooLow();

    string constant symbol = "MEME";

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

        createMemeParams.salt = bytes32("1");
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMemeSameSymbolAndSalt_collision_revert() public {
        createMeme404("MEME");

        vm.expectRevert();
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_swapFee() public {
        createMemeParams.swapFeeBps = 81;
        vm.expectRevert(MemeSwapFeeTooHigh.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_vestingAlloc() public {
        createMemeParams.vestingAllocBps = Constant.CREATOR_MAX_VESTED_ALLOC_BPS+ 1;
        vm.expectRevert(VestingAllocTooHigh.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_targetETH() public {
        createMemeParams.targetETH = 0;
        vm.expectRevert(ZeroAmount.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_max_targetETH() public {
        createMemeParams.targetETH = Constant.MAX_TARGET_ETH + 1;
        vm.expectRevert(MaxTargetETH.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_paused() public {
        vm.startPrank(memeceptionBaseTest.MULTISIG());
        memeception.setPaused(true);
        vm.stopPrank();

        vm.expectRevert(Paused.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }

    function test_404createMeme_fail_maxBuy_too_low() public {
        createMemeParams.maxBuyETH = 0.099 ether;
        vm.expectRevert(MaxBuyETHTooLow.selector);
        memeceptionBaseTest.createMeme404(createMemeParams, tierParams);
    }
}
