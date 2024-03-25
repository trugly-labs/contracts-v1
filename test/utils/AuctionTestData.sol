/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {Constant} from "../../src/libraries/Constant.sol";

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {PoolLiquidity} from "../../src/test/PoolLiquidity.sol";

contract AuctionTestData {
    using FixedPointMathLib for uint256;

    function getAuctionData(uint256 startAt) public view returns (uint256 ethAuctionBal, uint256 numberMaxBids) {
        ethAuctionBal = PoolLiquidity.getETHLiquidity(startAt);
        numberMaxBids = ethAuctionBal.divUp(Constant.AUCTION_MAX_BID);
    }
}
