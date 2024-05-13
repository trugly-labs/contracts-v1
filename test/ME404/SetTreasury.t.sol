/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME404} from "../utils/DeployersME404.sol";

contract SetTreasury404 is DeployersME404 {
    error ZeroAddress();
    /// @dev Emited when the treasury is updated

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    function test_setTreasury_success() public {
        vm.expectEmit(true, true, false, true);
        emit TreasuryUpdated(treasury, makeAddr("alice"));

        hoax(memeceptionBaseTest.MULTISIG());
        memeception.setTreasury(makeAddr("alice"));
    }

    function test_setTreasury_fail_not_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        hoax(makeAddr("alice"));
        memeception.setTreasury(makeAddr("alice"));
    }

    function test_setTreasury_fail_address_zero() public {
        hoax(memeceptionBaseTest.MULTISIG());
        vm.expectRevert(ZeroAddress.selector);
        memeception.setTreasury(address(0));
    }
}
