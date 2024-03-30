/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "../utils/Deployers.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEMERC20} from "../../src/types/MEMERC20.sol";

contract StartVestingTest is Deployers {
    error NotMemeception();
    error VestingAlreadyStarted();
    error VestingAmountCannotBeZero();
    error VestingDurationCannotBeZero();
    error VestingCreatorCannotBeAddressZero();
    error VestingTokenCannotBeAddressZero();
    error VestingStartInPast();
    error VestingCliffCannotBeGreaterThanDuration();
    error InsufficientBalance();

    event MEMERC20VestingStarted(
        address indexed token,
        address indexed creator,
        string symbol,
        uint256 totalAllocation,
        uint64 start,
        uint64 duration,
        uint64 cliff
    );

    MEMERC20 mockMemeToken;
    uint256 VESTING_ALLOCATION = 1000;

    function setUp() public override {
        super.setUp();
        vesting.setMemeception(address(this), true);
        mockMemeToken = new MEMERC20("MEME", "MEME", address(this));
        mockMemeToken.transfer(address(vesting), VESTING_ALLOCATION);
    }

    function test_startVesting_success() public {
        vm.expectEmit(true, true, false, true);

        emit MEMERC20VestingStarted(
            address(mockMemeToken),
            address(this),
            "MEME",
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );

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
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_already_started() public {
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
        vm.expectRevert(VestingAlreadyStarted.selector);
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_amount_zero() public {
        vm.expectRevert(VestingAmountCannotBeZero.selector);
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            0,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_duration_zero() public {
        vm.expectRevert(VestingDurationCannotBeZero.selector);
        vesting.startVesting(
            address(mockMemeToken), address(3), VESTING_ALLOCATION, uint64(block.timestamp), 0, Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_creator_zero() public {
        vm.expectRevert(VestingCreatorCannotBeAddressZero.selector);
        vesting.startVesting(
            address(mockMemeToken),
            address(0),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_token_zero() public {
        vm.expectRevert(VestingTokenCannotBeAddressZero.selector);
        vesting.startVesting(
            address(0),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }

    function test_startVesting_fail_cliff_greater_than_duration() public {
        vm.expectRevert(VestingCliffCannotBeGreaterThanDuration.selector);
        vesting.startVesting(
            address(mockMemeToken),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_CLIFF,
            Constant.VESTING_CLIFF - 1
        );
    }

    function test_startVesting_fail_insufficient_balance() public {
        MEMERC20 mockMemeToken2 = new MEMERC20("MEME", "MEME", address(this));
        mockMemeToken2.transfer(address(vesting), VESTING_ALLOCATION - 1);
        vm.expectRevert(InsufficientBalance.selector);
        vesting.startVesting(
            address(mockMemeToken2),
            address(3),
            VESTING_ALLOCATION,
            uint64(block.timestamp),
            Constant.VESTING_DURATION,
            Constant.VESTING_CLIFF
        );
    }
}
