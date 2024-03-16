// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract BaseSepoliaParameters {
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant WETH9 = 0x4200000000000000000000000000000000000006;
    // Uniswap
    address public constant V2_FACTORY = UNSUPPORTED_PROTOCOL;
    address public constant V3_FACTORY = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public constant V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address public constant UNSUPPORTED_PROTOCOL = address(0);
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
}
