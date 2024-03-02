/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";
import {Constant} from "../src/libraries/Constant.sol";

contract BidTest is Deployers {
    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionBid(address indexed memeToken, address indexed og, uint256 amountETH, uint256 amountMeme);

    /// @dev Emitted when liquidity has been added to the UniV3 Pool
    event MemeLiquidityAdded(address indexed memeToken, uint256 amount0, uint256 amount1);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_bid_success() public {
        vm.warp(createMemeParams.startAt + 1 seconds);
        uint256 amount = 1 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, 5500000000 ether);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }

    function test_bid_capReached_success() public {
        vm.warp(createMemeParams.startAt + 115 minutes);
        uint256 amount = 10 ether;
        vm.expectEmit(true, true, false, true);
        emit MemeceptionBid(address(memeToken), address(memeceptionBaseTest), amount, Constant.TOKEN_MEMECEPTION_SUPPLY);

        memeceptionBaseTest.bid{value: amount}(address(memeToken));
    }
}
