/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME404TansferFromTest is DeployersME404 {
    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initFullBid(10 ether);
        vm.warp(block.timestamp + 1 minutes);
        memeceptionBaseTest.claim(address(memeToken));

        hoax(BOB);
        memeToken.approve(address(memeceptionBaseTest), type(uint256).max);
    }

    function test_transferFromNotApproval() public {
        address NO_APPROVAL = makeAddr("NO_APPROVAL");

        vm.expectRevert();
        memeceptionBaseTest.transferFrom404(NO_APPROVAL, ALICE, tierParams[0].amountThreshold, true);
    }

    function test_transferFromNotEnoughApproval() public {
        address NOT_ENOUGH_APPROVAL = makeAddr("NOT_ENOUGH_APPROVAL");
        hoax(NOT_ENOUGH_APPROVAL);
        memeToken.approve(address(memeceptionBaseTest), 1);

        vm.expectRevert();
        memeceptionBaseTest.transferFrom404(NOT_ENOUGH_APPROVAL, ALICE, 2, true);
    }

    function test_transferFromFirstTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[0].amountThreshold, true);
    }

    function test_transferFromFirstTierHaveSelector() public {
        ContractWithSelector c = new ContractWithSelector();

        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transferFrom404(BOB, address(c), tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFromFirstTierHaveNoSelector() public {
        ContractWithoutSelector c = new ContractWithoutSelector();
        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transferFrom404(BOB, address(c), tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFromFirstTierFromHaveSelector() public {
        ContractWithSelector c = new ContractWithSelector();

        hoax(address(c));
        memeToken.approve(address(memeceptionBaseTest), type(uint256).max);

        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transferFrom404(address(c), BOB, tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFromFirstTierFromHaveNoSelector() public {
        ContractWithoutSelector c = new ContractWithoutSelector();

        hoax(address(c));
        memeToken.approve(address(memeceptionBaseTest), type(uint256).max);
        for (uint256 i = 0; i < tierParams.length; i++) {
            memeceptionBaseTest.transferFrom404(address(c), BOB, tierParams[i].amountThreshold, true);
        }
    }

    function test_transferFromSecondTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[1].amountThreshold, true);
    }

    function test_transferFromThirdTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[2].amountThreshold, true);
    }

    function test_transferFromFourthTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[3].amountThreshold, true);
    }

    function test_transferFromFifthTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[4].amountThreshold, true);
    }

    function test_transferFromSecondHighestTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, true);
    }

    function test_transferFromHighestTier() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, true);
    }

    function test_transferFromNoBurn_firstTier() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, tierParams[0].amountThreshold * 2, false);
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[0].amountThreshold, false);
    }

    function test_transferFromNoBurn_SecondHighestTier() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 2].amountThreshold * 2, false
        );
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[tierParams.length - 2].amountThreshold, false);
    }

    function test_transferFromNoBurn_HighestTier() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), BOB, tierParams[tierParams.length - 1].amountThreshold * 2, false
        );
        memeceptionBaseTest.transferFrom404(BOB, ALICE, tierParams[tierParams.length - 1].amountThreshold, false);
    }

    function test_transferFromZero() public {
        memeceptionBaseTest.transferFrom404(BOB, ALICE, 0, false);
    }

    function test_transferFromNotEnoughBal() public {
        memeceptionBaseTest.transfer404(address(memeceptionBaseTest), BOB, 1, false);
        vm.expectRevert();
        memeceptionBaseTest.transferFrom404(BOB, ALICE, 2, false);
    }

    function test_transferFromNoUpgradeTier() public {
        for (uint256 i = 0; i < tierParams.length; i++) {
            address RECEIVER = makeAddr(i.toString());
            memeceptionBaseTest.transfer404(BOB, RECEIVER, tierParams[i].amountThreshold, true);

            // No Upgrade 2nd time
            uint256 deltaToNexTier = i < tierParams.length - 1
                ? tierParams[i + 1].amountThreshold - tierParams[i].amountThreshold - 1
                : tierParams[i].amountThreshold;
            memeceptionBaseTest.transferFrom404(BOB, RECEIVER, deltaToNexTier, true);
        }
    }

    function test_transferFromFromAllThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeToken.transfer(FROM, tierParams[i].amountThreshold);

            hoax(FROM);
            memeToken.approve(address(memeceptionBaseTest), tierParams[i].amountThreshold);
            memeceptionBaseTest.transferFrom404(FROM, ALICE, tierParams[i].amountThreshold, false);
        }
    }

    function test_transferFromFromAllThresholdNoDown() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            address FROM = makeAddr(i.toString());
            memeToken.transfer(FROM, tierParams[i].amountThreshold);
            hoax(FROM);
            memeToken.approve(address(memeceptionBaseTest), tierParams[i].amountThreshold);
            memeceptionBaseTest.transferFrom404(FROM, ALICE, tierParams[i].amountThreshold, false);
        }
    }

    function test_transferFromEdgeCase() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold);
        memeToken.transfer(TO, tierParams[tierParams.length - 1].amountThreshold - 1);

        hoax(FROM);
        memeToken.approve(address(memeceptionBaseTest), type(uint256).max);
        memeceptionBaseTest.transferFrom404(FROM, TO, 1, false);
    }

    function test_transferFromEdgeCaseTwo() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
        memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold - 1);

        hoax(FROM);
        memeToken.approve(address(memeceptionBaseTest), type(uint256).max);
        memeceptionBaseTest.transferFrom404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    }

    function test_transferFromEdgeCaseThird() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );

        address FROM = makeAddr("FROM");
        address TO = makeAddr("TO");
        memeToken.transfer(FROM, tierParams[tierParams.length - 1].amountThreshold - 1);
        memeToken.transfer(TO, tierParams[tierParams.length - 2].amountThreshold);

        hoax(FROM);
        memeToken.approve(address(memeceptionBaseTest), tierParams[tierParams.length - 1].amountThreshold - 1);
        memeceptionBaseTest.transferFrom404(FROM, TO, tierParams[tierParams.length - 1].amountThreshold - 1, false);
    }

    function test_transferFromToAllThreshold() public {
        memeceptionBaseTest.transfer404(
            address(memeceptionBaseTest), address(this), memeToken.balanceOf(address(memeceptionBaseTest)), false
        );
        for (uint256 i = 0; i < tierParams.length; i++) {
            for (uint256 j = 0; j < tierParams.length; j++) {
                address FROM = makeAddr(string.concat("FROM", i.toString(), j.toString()));

                hoax(FROM);
                memeToken.approve(address(memeceptionBaseTest), tierParams[i].amountThreshold);
                address TO = makeAddr(string.concat("TO", j.toString(), i.toString()));

                memeToken.transfer(FROM, tierParams[i].amountThreshold);
                if (i >= j) {
                    memeceptionBaseTest.transferFrom404(FROM, TO, tierParams[j].amountThreshold, false);
                } else {
                    vm.expectRevert();
                    memeceptionBaseTest.transferFrom404(FROM, TO, tierParams[j].amountThreshold, false);
                }
            }
        }
    }
}
