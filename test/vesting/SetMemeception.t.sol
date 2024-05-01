/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20} from "../../src/types/MEME20.sol";

contract SetMemeceptionTest is DeployersME20 {
    event MemeceptionAuthorized(address indexed memeception, bool isAuthorized);

    function test_setMemeception_success() public {
        vm.expectEmit(true, true, false, true);
        emit MemeceptionAuthorized(address(2), true);
        vesting.setMemeception(address(2), true);
    }

    function test_setMemeception_success_disable() public {
        vm.expectEmit(true, true, false, true);
        emit MemeceptionAuthorized(address(2), false);
        vesting.setMemeception(address(2), false);
    }

    function test_setMemception_fail_not_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        hoax(makeAddr("alice"));
        vesting.setMemeception(address(2), true);
    }
}
