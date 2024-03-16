// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract GoerliParameters {
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    // Uniswap
    address public constant V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNSUPPORTED_PROTOCOL = address(0);
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
}
