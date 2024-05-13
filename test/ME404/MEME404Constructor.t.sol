/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MEME404} from "../../src/types/MEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404ConstructorTest is DeployersME404 {
    MEME404 meme404;

    function setUp() public override {
        meme404 = new MEME404("HELLO", "WORLD", MEMECREATOR);
    }

    function test_constructor() public {
        assertEq(meme404.name(), "HELLO");
        assertEq(meme404.symbol(), "WORLD");
        assertEq(meme404.creator(), MEMECREATOR);
        assertEq(meme404.tiersCount(), 0);
    }
}
