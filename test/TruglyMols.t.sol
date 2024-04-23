/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {TruglyMOLS} from "../src/TruglyMOLS.sol";

contract TruglyMOLsTest is Test {
    TruglyMOLS truglyMOLs;

    error NonExistingToken();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function setUp() public {
        truglyMOLs = new TruglyMOLS(address(this));
    }

    function test_setUp() public {
        assertEq(truglyMOLs.name(), "Trugly MOLs");
        assertEq(truglyMOLs.symbol(), "TRUGLYMOLS");
    }

    function test_success_mint() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(1), 1);

        truglyMOLs.mint(address(1), 1, "https://truglymols.com/1");

        assertEq(truglyMOLs.balanceOf(address(1)), 1);
        assertEq(truglyMOLs.ownerOf(1), address(1));
        assertEq(truglyMOLs.tokenURI(1), "https://truglymols.com/1");
    }

    function test_error_tokenURI() public {
        vm.expectRevert(NonExistingToken.selector);
        truglyMOLs.tokenURI(0);
    }

    function test_error_mint() public {
        vm.expectRevert("UNAUTHORIZED");
        hoax(makeAddr("alice"));
        truglyMOLs.mint(address(1), 1, "https://truglymols.com/1");
    }
}
