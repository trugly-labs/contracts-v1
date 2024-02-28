/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {OinkDeployers} from "./utils/OinkDeployers.sol";

import {IOinkOink} from "../src/contracts/interfaces/IOinkOink.sol";
import {MemeERC20} from "../src/contracts/types/MemeERC20.sol";

contract OinkOinkExitMemeTest is OinkDeployers {
    event MemeGenesisExit(address indexed memeToken, address indexed backer, uint256 amountETH);

    uint256 public backAmount = 50 ether;

    function setUp() public override {
        super.setUp();
        initializeMemeToken();
        backMeme(backAmount);
    }

    function test_exitEarlyOinker_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeGenesisExit(address(memeToken), address(truglyTest), backAmount);

        vm.warp(block.timestamp + 4 days);
        truglyTest.exitEarlyOinker(address(memeToken), backAmount);
    }
}
