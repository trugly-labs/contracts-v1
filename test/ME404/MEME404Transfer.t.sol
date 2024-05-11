/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404Test is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initFullBid(10 ether);
        vm.warp(block.timestamp + 1 minutes);
        memeceptionBaseTest.claim(address(memeToken));
    }

    function test_transferFirstTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[0].amountThreshold);
    }

    function test_transferSecondTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[1].amountThreshold);
    }

    function test_transferThirdTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[2].amountThreshold);
    }

    function test_transferFourthTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[3].amountThreshold);
    }

    function test_transferFifthTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[4].amountThreshold);
    }

    function test_transferSecondHighestTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold);
    }

    function test_transferHighestTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold);
    }

    function test_transferFromAllThreshold() public {
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeceptionBaseTest.transfer404(address(memeceptionBaseTest), FROM, tierParams[i].amountThreshold);
            memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold);
        }
    }

    function test_transferFromAllThresholdNoDown() public {
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeceptionBaseTest.transfer404(address(memeceptionBaseTest), FROM, tierParams[i].amountThreshold + 1);
            memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold);
        }
    }

    function test_transferToAllThreshold() public {
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeceptionBaseTest.transfer404(address(memeceptionBaseTest), FROM, tierParams[i].amountThreshold + 1);
            for (uint256 j = 0; j < tierParams.length; j++) {
                address TO = makeAddr(string.concat(j.toString(), i.toString()));
                memeceptionBaseTest.transfer404(FROM, TO, tierParams[i].amountThreshold);
            }
        }
    }

    function test_transferNoBurn() public {}

    function test_transferBurn() public {}

    function test_transferZero() public {}
}
