/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersMEME404} from "./utils/DeployersMEME404.sol";

contract MEME404Test is DeployersMEME404 {
    function test_transferUp() public {
        address ALICE = makeAddr("alice");

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);

        meme404.transfer(ALICE, ranks[0]);

        assertEq(meme1155.balanceOf(ALICE, 0), 1);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferUpSecondTier() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[1]);

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 1);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferUpLastTier() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[4] + 1000);

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 1);
    }

    function test_transferUpNothing() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[0] - 1);

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferUpBurn() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[0]);
        meme404.transfer(ALICE, ranks[1]);

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 1);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferDownNoBurn() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[0] + 10);

        hoax(ALICE);
        meme404.transfer(makeAddr("bob"), 10);

        assertEq(meme1155.balanceOf(ALICE, 0), 1);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferDownBurn() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[0]);

        hoax(ALICE);
        meme404.transfer(makeAddr("bob"), 1);

        assertEq(meme1155.balanceOf(ALICE, 0), 0);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferDownBurnOneRank() public {
        address ALICE = makeAddr("alice");

        meme404.transfer(ALICE, ranks[1]);

        hoax(ALICE);
        meme404.transfer(makeAddr("bob"), 1);

        assertEq(meme1155.balanceOf(ALICE, 0), 1);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);
    }

    function test_transferDownAndMint() public {
        address ALICE = makeAddr("alice");
        address BOB = makeAddr("bob");

        meme404.transfer(ALICE, ranks[1]);

        hoax(ALICE);
        meme404.transfer(BOB, ranks[0]);

        assertEq(meme1155.balanceOf(ALICE, 0), 1);
        assertEq(meme1155.balanceOf(ALICE, 1), 0);
        assertEq(meme1155.balanceOf(ALICE, 2), 0);
        assertEq(meme1155.balanceOf(ALICE, 3), 0);
        assertEq(meme1155.balanceOf(ALICE, 4), 0);

        assertEq(meme1155.balanceOf(BOB, 0), 1);
        assertEq(meme1155.balanceOf(BOB, 1), 0);
        assertEq(meme1155.balanceOf(BOB, 2), 0);
        assertEq(meme1155.balanceOf(BOB, 3), 0);
        assertEq(meme1155.balanceOf(BOB, 4), 0);
    }
}
