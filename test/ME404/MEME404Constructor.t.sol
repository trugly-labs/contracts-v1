/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MockMEME404} from "../mock/MockMEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404ConstructorTest is DeployersME404 {
    MockMEME404 meme404;

    function setUp() public override {
        meme404 = new MockMEME404("HELLO", "WORLD", address(memeception), MEMECREATOR, address(factoryNFT));
    }

    function test_constructor() public {
        assertEq(meme404.name(), "HELLO");
        assertEq(meme404.symbol(), "WORLD");
        assertEq(meme404.creator(), MEMECREATOR);
        assertEq(meme404.tiersCount(), 0);
        assertEq(meme404.exemptNFTMint(MEMECREATOR), false);
        assertEq(meme404.initialized(), false);
    }
}
