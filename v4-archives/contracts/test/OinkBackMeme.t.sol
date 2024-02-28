/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {OinkDeployers} from "./utils/OinkDeployers.sol";

import {IOinkOink} from "../src/contracts/interfaces/IOinkOink.sol";
import {MemeERC20} from "../src/contracts/types/MemeERC20.sol";

contract OinkOinkBackMemeTest is OinkDeployers {
    event MemeBacked(address indexed memeToken, address indexed backer, uint256 amountETH);

    event MemeLiquidityAdded(address indexed memeToken, uint256 amount0, uint256 amount1);

    function setUp() public override {
        super.setUp();
        initializeMemeToken();

        vm.warp(block.timestamp + 4 days);
    }

    function test_backMeme_success() public {
        uint256 backAmount = 1 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeBacked(address(memeToken), address(truglyTest), backAmount);
        truglyTest.backMeme{value: backAmount}(address(memeToken));
    }

    function test_backMemeCapReached_success() public {
        uint256 backAmount = MEME_CREATION.backersETHCap;
        vm.expectEmit(true, true, false, true);
        emit MemeBacked(address(memeToken), address(truglyTest), backAmount);
        truglyTest.backMeme{value: backAmount}(address(memeToken));
    }

    function test_backMemeCapReachedRefund_success() public {
        uint256 backAmount = MEME_CREATION.backersETHCap + 5 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeBacked(address(memeToken), address(truglyTest), MEME_CREATION.backersETHCap);
        truglyTest.backMeme{value: backAmount}(address(memeToken));
    }
}
