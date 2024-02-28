/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract DepositMemeceptionTest is Deployers {
    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionDeposit(address indexed memeToken, address indexed og, uint256 amount);

    /// @dev Emitted when liquidity has been added to the UniV3 Pool
    event MemeLiquidityAdded(address indexed memeToken, uint256 amount0, uint256 amount1);

    function setUp() public override {
        super.setUp();
        initCreateMeme();

        vm.warp(block.timestamp + 4 days);
    }

    function test_depositMemeception_success() public {
        uint256 amount = 1 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionDeposit(address(memeToken), address(launchpadBaseTest), amount);

        launchpadBaseTest.depositMemeception{value: amount}(address(memeToken));
    }

    function test_depositMemeceptionCapReached_success() public {
        uint256 amount = createMemeParams.cap;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionDeposit(address(memeToken), address(launchpadBaseTest), amount);

        launchpadBaseTest.depositMemeception{value: amount}(address(memeToken));
    }

    function test_depositMemeceptionCapReached_refund() public {
        uint256 amount = createMemeParams.cap + 5 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionDeposit(address(memeToken), address(launchpadBaseTest), createMemeParams.cap);

        launchpadBaseTest.depositMemeception{value: amount}(address(memeToken));
    }
}
