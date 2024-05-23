/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {ContractWithSelector} from "../utils/ContractWithSelector.sol";
import {ContractWithoutSelector} from "../utils/ContractWithoutSelector.sol";
import {LibString} from "@solmate/utils/LibString.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";

contract MEME1155BurnTest is DeployersME404 {
    error OnlyMemecoin();

    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    using LibString for uint256;

    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initializeToken();

        initWalletWithTokens(BOB, getAmountThreshold(1));
    }

    function test_1155burn_success() public {
        vm.expectEmit(true, true, false, true);
        emit TransferSingle(address(memeToken), BOB, address(0), 1, 1);
        startHoax(address(memeToken));
        meme1155.burn(BOB, 1, 1);
        vm.stopPrank();

        assertEq(meme1155.balanceOf(BOB, 1), 0, "balance");
    }

    function test_1155burn_fail_not_memecoin() public {
        vm.expectRevert(OnlyMemecoin.selector);
        meme1155.burn(BOB, 1, 1);
    }
}
