// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract MumbaiParameters {
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    /// This really is WMATIC
    address public constant WETH9 = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    // Uniswap
    address public constant V2_FACTORY = UNSUPPORTED_PROTOCOL;
    address public constant V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNSUPPORTED_PROTOCOL = address(0);
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH = bytes32(0);
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    address public constant TREASURY = 0x8Cfc6Aaa6AD7f765699aCeA366a134AF644093e3;
}
