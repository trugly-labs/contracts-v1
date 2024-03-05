/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {Constant} from "../../src/libraries/Constant.sol";

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

contract AuctionTestData {
    using FixedPointMathLib for uint256;
    // Array of ether amounts raised at each step

    uint256[] private ethAuction = [
        550 ether, // Step 0
        275 ether, // Step 1
        137.5 ether, // Step 2
        91.85 ether, // Step 3
        68.75 ether, // Step 4
        55 ether, // Step 5
        45.65 ether, // Step 6
        39.05 ether, // Step 7
        34.375 ether, // Step 8
        30.525 ether, // Step 9
        27.5 ether, // Step 10
        24.97 ether, // Step 11
        22.825 ether, // Step 12
        21.12 ether, // Step 13
        19.635 ether, // Step 14
        18.315 ether, // Step 15
        17.16 ether, // Step 16
        16.17 ether, // Step 17
        15.235 ether, // Step 18
        14.465 ether, // Step 19
        13.75 ether, // Step 20
        13.09 ether, // Step 21
        12.485 ether, // Step 22
        11.935 ether // Step 23
    ];

    function getAuctionData(uint256 startAt) public view returns (uint256 ethAuctionBal, uint256 numberMaxBids) {
        uint256 step = (block.timestamp.rawSub(startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);
        ethAuctionBal = ethAuction[step];
        numberMaxBids = ethAuctionBal.divUp(Constant.AUCTION_MAX_BID);
    }
}
