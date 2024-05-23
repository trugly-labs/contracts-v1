/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME721BurnTest is DeployersME404 {
    error OnlyMemecoin();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initializeToken();

        initWalletWithTokens(BOB, getAmountThreshold(3));
    }

    function test_721burn_success() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(BOB, address(0), 1);
        startHoax(address(memeToken));
        meme721.burn(1);
        vm.stopPrank();

        assertEq(meme721.balanceOf(BOB), 0, "balance");
        assertEq(meme721.getIndexForToken(1), 0);
        assertEq(meme721.getTokenAtIndex(BOB, 1), 1);
        assertEq(meme721.getTokenAtIndex(BOB, 0), 0);
        assertEq(meme721.nextOwnedTokenId(BOB), 0);
        vm.expectRevert("NOT_MINTED");
        meme721.ownerOf(1);
    }

    function test_721burn_fail_not_memecoin() public {
        vm.expectRevert(OnlyMemecoin.selector);
        meme721.burn(1);
    }
}
