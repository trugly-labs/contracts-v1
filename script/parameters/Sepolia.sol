// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract SepoliaParameters {
    // Trugly
    address public constant TREASURY = 0x0804a74CB85d6bE474a4498fCe76481822AdFFa4;
    address public constant MEMECEPTION_SIGNER = 0x0D37fC458B1C02649ED99C7238Cd91Ea797f34FD;
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    // Uniswap
    address public constant V2_FACTORY = 0xB7f907f7A9eBC822a80BD25E224be42Ce0A698A0;
    address public constant V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    address public constant V3_POSITION_MANAGER = 0x1238536071E1c677A632429e3655c799b22cDA52;
    address public constant UNSUPPORTED_PROTOCOL = 0x5302086A3a25d473aAbBd0356eFf8Dd811a4d89B;
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
}
