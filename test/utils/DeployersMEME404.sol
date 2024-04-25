/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {BaseParameters} from "../../script/parameters/Base.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract DeployersMEME404 is Test, TestHelpers, BaseParameters {
    MEME404 meme404;
    MEME1155 meme1155;
    uint256[] ranks = [100, 1000, 10000, 100000, 1000000];
    string[] uris =
        ["https://nft.com/1", "https://nft.com/2", "https://nft.com/3", "https://nft.com/4", "https://nft.com/5"];

    function setUp() public virtual {
        meme404 = new MEME404("MEME 404", "MEME404", address(this), ranks, uris);
        meme1155 = meme404.nft();
    }
}
