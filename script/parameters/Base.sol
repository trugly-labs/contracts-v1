// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract BaseParameters {
    address public constant UNSUPPORTED_PROTOCOL = address(0);
    // General
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    /// This really is WMATIC
    address public constant WETH9 = 0x4200000000000000000000000000000000000006;
    // Uniswap
    address public constant V2_FACTORY = UNSUPPORTED_PROTOCOL;
    address public constant V3_FACTORY = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    address public constant V3_POSITION_MANAGER = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    bytes32 public constant ROUTER_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    bytes32 public constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    address public constant SWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;

    address public constant TREASURY = 0x2f5417Dee5bF31fe270Bb9e7F48962dDDA77b755;

    address public constant ADMIN = 0xb2660C551AB31FAc6D01a75f628Af2d200FfD1F2;

    // UNCX Uniswap V3 LP Lockers
    address public constant UNCX_V3_LOCKERS = 0x231278eDd38B00B07fBd52120CEf685B9BaEBCC1;
}
