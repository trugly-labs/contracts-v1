/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {OinkDeployers} from "./utils/OinkDeployers.sol";

import {IOinkOink} from "../src/contracts/interfaces/IOinkOink.sol";
import {MemeERC20} from "../src/contracts/types/MemeERC20.sol";

contract OinkOinkClaimMemeTest is OinkDeployers {
    event MemeClaimed(address indexed memeToken, address indexed claimer, uint256 amountMeme);

    uint256 public backAmount = 100 ether;
    uint256 public expectedMemeAmount;

    function setUp() public override {
        super.setUp();
        initializeMemeToken();
        backMeme(backAmount);

        expectedMemeAmount = truglyTest.oink().MEME_EARLY_SUPPLY();
    }

    function test_claimMeme_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeClaimed(address(memeToken), address(truglyTest), expectedMemeAmount);
        truglyTest.claimEarlyMeme(address(memeToken), expectedMemeAmount);
    }
}
