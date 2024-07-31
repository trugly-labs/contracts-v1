/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {TruglyMemeXTreasury} from "../src/TruglyMemeXTreasury.sol";


contract TruglyMemeXTreasuyTest is Test {
    TruglyMemeXTreasury truglyMemeXTreasury;
    address public owner = makeAddr("OWNER");
    address public memeToken = makeAddr("MEME_TOKEN");

    event Deposited(address indexed memeToken, uint256 amount);
    event TransferToXOwner(address indexed memeToken, address accountOwner, uint256 amount);

    function setUp() public {
        truglyMemeXTreasury = new TruglyMemeXTreasury(owner);

        payable(owner).transfer(100 ether);
    }

    function test_deposit_success() public {
        vm.startPrank(owner);
        truglyMemeXTreasury.deposit{value: 10 ether}(memeToken);
        vm.stopPrank();

        assertEq(truglyMemeXTreasury.treasuryBalances(memeToken), 10 ether);
        assertEq(address(truglyMemeXTreasury).balance, 10 ether);
    }

    function test_transferToXAccountOwner_success() public {
        address accountOwner = makeAddr("ACCOUNT_OWNER");

        vm.startPrank(owner);
        truglyMemeXTreasury.deposit{value: 10 ether}(memeToken);
        truglyMemeXTreasury.transferToXAccountOwner(memeToken, accountOwner);
        vm.stopPrank();

        assertEq(truglyMemeXTreasury.treasuryBalances(memeToken), 0);
        assertEq(address(truglyMemeXTreasury).balance, 0);
        assertEq(address(accountOwner).balance, 10 ether);
    }

    function test_deposit_error_not_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        truglyMemeXTreasury.deposit{value: 10 ether}(memeToken);
    }

    function test_transferToXAccountOwner_error_not_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        truglyMemeXTreasury.transferToXAccountOwner(memeToken, makeAddr("ACCOUNT_OWNER"));
    }
}


