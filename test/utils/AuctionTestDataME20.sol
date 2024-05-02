/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {Constant} from "../../src/libraries/Constant.sol";

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

contract AuctionTestData {
    using FixedPointMathLib for uint256;

    uint256[] public ETH_RAISED = [
        2.248888888664e21,
        6.71111111044e20,
        3.26666666634e20,
        1.595555555396e20,
        7.1111111104e19,
        3.626666666304e19,
        2.106666666456e19,
        1.235555555432e19,
        8.04444444364e18,
        5.7777777772e18,
        4.17777777736e18,
        2.6666666664e18,
        1.86666666648e18,
        1.28888888876e18
    ];

    function getAuctionData(uint256 startAt, uint256 auctionPriceDecayPeriod)
        public
        view
        returns (uint256 ethAuctionBal, uint256 numberMaxBids, uint256 ethRaised)
    {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(auctionPriceDecayPeriod);

        // 0.03 ETH flag fee and 0.8% for UNCX locker
        ethAuctionBal = (ETH_RAISED[step] - 0.03 ether).mulDiv(992, 1000);
        numberMaxBids = ETH_RAISED[step].divUp(Constant.AUCTION_MAX_BID);
        ethRaised = ETH_RAISED[step];
    }
}
