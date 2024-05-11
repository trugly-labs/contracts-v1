/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404TransferTest is DeployersME404 {
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
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[0].amountThreshold, true);
    }

    function test_transferFirstTierHaveSelector() public {
        ContractWithSelector c = new ContractWithSelector();

        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transfer404(BOB, address(c), tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFirstTierHaveNoSelector() public {
        ContractWithoutSelector c = new ContractWithoutSelector();
        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transfer404(BOB, address(c), tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFirstTierFromHaveSelector() public {
        ContractWithSelector c = new ContractWithSelector();

        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transfer404(address(c), BOB, tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFirstTierFromHaveNoSelector() public {
        ContractWithoutSelector c = new ContractWithoutSelector();
        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transfer404(address(c), BOB, tierParams[i].amountThreshold, true);
        }
    }

    function test_transferSecondTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[1].amountThreshold, true);
    }

    function test_transferThirdTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[2].amountThreshold, true);
    }

    function test_transferFourthTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[3].amountThreshold, true);
    }

    function test_transferFifthTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[4].amountThreshold, true);
    }

    function test_transferSecondHighestTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, true);
    }

    function test_transferHighestTier() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, true);
    }

    function test_transferNoBurn_firstTier() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold * 2, false);
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[0].amountThreshold, false);
    }

    function test_transferNoBurn_SecondHighestTier() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold * 2, false
        );
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, false);
    }

    function test_transferNoBurn_HighestTier() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold * 2, false
        );
        memeceptionBaseTest.transfer404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, false);
    }

    function test_transferZero() public {
        memeceptionBaseTest.transfer404(BOB, ALICE, 0, false);
    }

    function test_transferFromAllThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeToken.transfer(FROM, tierParams[i].amountThreshold);
            memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold, false);
        }
    }

    function test_transferFromAllThresholdNoDown() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeToken.transfer(FROM, tierParams[i].amountThreshold);
            memeceptionBaseTest.transfer404(FROM, ALICE, tierParams[i].amountThreshold, false);
        }
    }

    function test_transferEdgeCase() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold);
        memeToken.transfer(TO, tierParams[tierParams.length - 1].amountThreshold - 1);

        memeceptionBaseTest.transfer404(FROM, TO, 1, false);
    }

    function test_transferEdgeCaseTwo() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
        memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold - 1);

        memeceptionBaseTest.transfer404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    }

    function test_transferEdgeCaseThird() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
        memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold);

        memeceptionBaseTest.transfer404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    }

    function test_transferToAllThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            for (uint256 j = 0; j < tierParams.length; j++) {
                address FROM = makeAddr(string.concat("FROM", i.toString(), j.toString()));
                address TO = makeAddr(string.concat("TO", j.toString(), i.toString()));

                memeToken.transfer(FROM, tierParams[i].amountThreshold);
                if (i >= j) {
                    memeceptionBaseTest.transfer404(FROM, TO, tierParams[j].amountThreshold, false);
                } else {
                    vm.expectRevert();
                    memeceptionBaseTest.transfer404(FROM, TO, tierParams[j].amountThreshold, false);
                }
            }
        }
    }
}
