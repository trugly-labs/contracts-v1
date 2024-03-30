/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "../utils/Deployers.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";

contract ReleaseTest is Deployers {
    event MEMERC20Released(address indexed token, address indexed creator, uint256 amount);

    MEMERC20 mockMemeToken;
    uint256 VESTING_ALLOCATION = 1000;
    address CREATOR = address(3);
    uint64 VESTING_START;

    function setUp() public override {
        super.setUp();
        vesting.setMemeception(address(this), true);
        mockMemeToken = new MEMERC20("MEME", "MEME", address(this));
        mockMemeToken.transfer(address(vesting), VESTING_ALLOCATION);
        VESTING_START = uint64(block.timestamp + 3 days);
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            VESTING_START,
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_release_success_before_cliff() public {
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        vm.warp(VESTING_START + Constant.VESTING_CLIFF - 1);
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        vm.expectEmit(true, true, false, true);
        uint256 beforeBal = mockMemeToken.balanceOf(CREATOR);
        emit MEMERC20Released(address(mockMemeToken), CREATOR, 0);
        vesting.release(address(mockMemeToken));

        assertEq(mockMemeToken.balanceOf(CREATOR), beforeBal);
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).released, 0);
        assertEq(vesting.vestedAmount(address(mockMemeToken), uint64(block.timestamp)), 0);
    }

    function test_release_success_cliff() public {
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        vm.warp(VESTING_START + Constant.VESTING_CLIFF);
        assertEq(vesting.releasable(address(mockMemeToken)), VESTING_ALLOCATION / 4);
        vm.expectEmit(true, true, false, true);
        uint256 beforeBal = mockMemeToken.balanceOf(CREATOR);
        emit MEMERC20Released(address(mockMemeToken), CREATOR, VESTING_ALLOCATION / 4);
        vesting.release(address(mockMemeToken));

        assertEq(mockMemeToken.balanceOf(CREATOR), beforeBal + VESTING_ALLOCATION / 4);
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).released, VESTING_ALLOCATION / 4);
        assertEq(vesting.vestedAmount(address(mockMemeToken), uint64(block.timestamp)), VESTING_ALLOCATION / 4);
    }

    function test_release_success_fully_vested() public {
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        vm.warp(VESTING_START + Constant.VESTING_DURATION);
        assertEq(vesting.releasable(address(mockMemeToken)), VESTING_ALLOCATION);
        vm.expectEmit(true, true, false, true);
        uint256 beforeBal = mockMemeToken.balanceOf(CREATOR);
        emit MEMERC20Released(address(mockMemeToken), CREATOR, VESTING_ALLOCATION);
        vesting.release(address(mockMemeToken));

        assertEq(mockMemeToken.balanceOf(CREATOR), beforeBal + VESTING_ALLOCATION);
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).released, VESTING_ALLOCATION);
        assertEq(vesting.vestedAmount(address(mockMemeToken), uint64(block.timestamp)), VESTING_ALLOCATION);
    }

    function test_release_success_fully_vested_above() public {
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        vm.warp(VESTING_START + Constant.VESTING_DURATION + 1 days);
        assertEq(vesting.releasable(address(mockMemeToken)), VESTING_ALLOCATION);
        vm.expectEmit(true, true, false, true);
        uint256 beforeBal = mockMemeToken.balanceOf(CREATOR);
        emit MEMERC20Released(address(mockMemeToken), CREATOR, VESTING_ALLOCATION);
        vesting.release(address(mockMemeToken));

        assertEq(mockMemeToken.balanceOf(CREATOR), beforeBal + VESTING_ALLOCATION);
        assertEq(vesting.releasable(address(mockMemeToken)), 0);
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).released, VESTING_ALLOCATION);
        assertEq(vesting.vestedAmount(address(mockMemeToken), uint64(block.timestamp)), VESTING_ALLOCATION);
    }
}