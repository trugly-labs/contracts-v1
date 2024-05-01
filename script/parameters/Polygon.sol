// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract PolygonParameters {
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant WETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    // Uniswap
    address[] public SWAP_ROUTERS = [
        0xE592427A0AEce92De3Edee1F18E0157C05861564,
        0xec7BE89e9d109e7e3Fec59c222CF297125FEFda2,
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    ];

    address[] public EXEMPT_UNISWAP = [
        0x6BC825a870804cBcB3327FD1bae051259AE4E98e, // Fee Collectors
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88, // LP manager
        0xe34139463bA50bD61336E0c446Bd8C0867c6fE65 // Staker
    ];
    // address public constant V2_FACTORY = UNSUPPORTED_PROTOCOL;
    // address public constant V3_FACTORY = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    // address public constant V3_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    // address public constant UNSUPPORTED_PROTOCOL = address(0);
    // bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
    //     0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    // bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    // address public constant TREASURY = 0x8Cfc6Aaa6AD7f765699aCeA366a134AF644093e3;
}
