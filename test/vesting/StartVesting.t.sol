/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20} from "../../src/types/MEME20.sol";

contract StartVestingTest is DeployersME20 {
    error NotMemeception();
    error VestingDurationCannotBeZero();
    error VestingCreatorCannotBeAddressZero();
    error VestingTokenCannotBeAddressZero();
    error VestingCliffCannotBeGreaterThanDuration();

    event MEMERC20VestingStarted(
        address indexed token,
        address indexed creator,
        string symbol,
        uint256 totalAllocation,
        uint64 start,
        uint64 duration,
        uint64 cliff
    );

    MEME20 mockMemeToken;
    uint256 VESTING_ALLOCATION = 1000;

    function setUp() public override {
        super.setUp();
        vesting.setMemeception(address(this), true);
        mockMemeToken = new MEME20("MEME", "MEME", address(this), address(this));
        mockMemeToken.transfer(address(vesting), VESTING_ALLOCATION);
    }

    function test_startVesting_success() public {
        vm.expectEmit(true, true, false, true);

        emit MEMERC20VestingStarted(
            address(mockMemeToken),
            address(3),
            "MEME",
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
        vesting.startVesting(address(mockMemeToken), address(3), Constant.VESTING_DURATION, Constant.VESTING_CLIFF);

        assertEq(
            vesting.getVestingInfo(address(mockMemeToken)).totalAllocation,
            VESTING_ALLOCATION,
            "Vesting.totalAllocation"
        );
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).released, 0, "Vesting.released");
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).start, uint64(block.timestamp), "Vesting.start");
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).duration, Constant.VESTING_DURATION, "Vesting.duration");
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).cliff, Constant.VESTING_CLIFF, "Vesting.cliff");
        assertEq(vesting.getVestingInfo(address(mockMemeToken)).creator, address(3), "Vesting.creator");

        assertEq(vesting.releasable(address(mockMemeToken)), 0, "Vesting.releasable");
        assertEq(vesting.vestedAmount(address(mockMemeToken), uint64(block.timestamp)), 0, "Vesting.vestedAmount");
    }

    function test_startVesting_fail_not_memeception() public {
        vm.expectRevert(NotMemeception.selector);
        hoax(makeAddr("alice"));
        vesting.startVesting(address(mockMemeToken), address(3), Constant.VESTING_DURATION, Constant.VESTING_CLIFF);
    }

    function test_startVesting_fail_duration_zero() public {
        vm.expectRevert(VestingDurationCannotBeZero.selector);
        vesting.startVesting(address(mockMemeToken), address(3), 0, Constant.VESTING_CLIFF);
    }

    function test_startVesting_fail_creator_zero() public {
        vm.expectRevert(VestingCreatorCannotBeAddressZero.selector);
        vesting.startVesting(address(mockMemeToken), address(0), Constant.VESTING_DURATION, Constant.VESTING_CLIFF);
    }

    function test_startVesting_fail_token_zero() public {
        vm.expectRevert(VestingTokenCannotBeAddressZero.selector);
        vesting.startVesting(address(0), address(3), Constant.VESTING_DURATION, Constant.VESTING_CLIFF);
    }

    function test_startVesting_fail_cliff_greater_than_duration() public {
        vm.expectRevert(VestingCliffCannotBeGreaterThanDuration.selector);
        vesting.startVesting(address(mockMemeToken), address(3), Constant.VESTING_CLIFF, Constant.VESTING_CLIFF + 1);
    }
}
