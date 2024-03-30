/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Deployers} from "./utils/Deployers.sol";

contract CollectFees is Deployers {
    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(MAX_BID_AMOUNT);
    }

    function test_collectFees_success() public {
        initSwapFromSwapRouter();
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29999999999999, "treasuryBalance");
    }

    function test_collectFees_success_twice() public {
        initSwapFromSwapRouter();
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29999999999999, "treasuryBalance");

        initSwapFromSwapRouter();
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29999999999999 * 2, "treasuryBalance");
    }

    function test_collectFees_success_no_fees() public {
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal, "treasuryBalance");
    }

    function test_collectFees_fail_invalid_meme_address() public {
        vm.expectRevert("ERC721: operator query for nonexistent token");
        memeceptionBaseTest.collectFees(address(1));
    }

    function test_collectFees_fail_no_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        memeception.collectFees(address(memeToken));
    }
}
