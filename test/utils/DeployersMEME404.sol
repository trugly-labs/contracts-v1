/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {BaseParameters} from "../../script/parameters/Base.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {ME404BaseTest} from "../../src/test/ME404BaseTest.sol";

import {TestHelpers} from "./TestHelpers.sol";

contract DeployersMEME404 is Test, TestHelpers, BaseParameters {
    ME404BaseTest me404BaseTest;
    MEME404 meme404;
    address CREATOR = makeAddr("CREATOR");
    MEME404.TierCreateParam[] public params;

    function setUp() public virtual {
        _initParams();

        MEME404.TierCreateParam[] memory _params = new MEME404.TierCreateParam[](params.length);
        _params[0] = params[0];
        _params[1] = params[1];
        _params[2] = params[2];
        _params[3] = params[3];
        _params[4] = params[4];
        _params[5] = params[5];
        _params[6] = params[6];
        _params[7] = params[7];

        me404BaseTest = new ME404BaseTest("MEME 404", "ME404", CREATOR, _params);
        meme404 = me404BaseTest.meme404();
    }

    function getNormalNFTCollection() public view returns (address) {
        return meme404.getTier(0).nft;
    }

    function getEliteNFTCollection() public view returns (address) {
        return meme404.getTier(params.length - 1).nft;
    }

    function _initParams() private {
        /// Fungible Tiers
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 1, 0, 1, 1, true));
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 222222 ether, 0, 2, 2, true));
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 444444 ether, 0, 3, 3, true));
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 888888 ether, 0, 4, 4, true));
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 2222222 ether, 0, 5, 5, true));
        params.push(MEME404.TierCreateParam("https://nft.com/", "Normal NFT", "NORMAL", 4444444 ether, 0, 6, 6, true));

        /// Non Fungible Tiers
        params.push(
            MEME404.TierCreateParam("https://elite.com/", "Elite NFT", "ELITE", 6666666 ether, 1, 1, 2000, false)
        );
        params.push(
            MEME404.TierCreateParam("https://elite.com/", "Elite NFT", "ELITE", 8888888 ether, 1, 2001, 2101, false)
        );
    }
}
