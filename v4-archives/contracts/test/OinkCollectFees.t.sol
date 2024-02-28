/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

import {OinkDeployers} from "./utils/OinkDeployers.sol";

contract OinkCollectFees is OinkDeployers {
    using CurrencyLibrary for Currency;

    event CollectProtocolFees(address indexed token, address recipient, uint256 amount);

    event CollectLPFees(address indexed token, address recipient, uint256 amount);

    function setUp() public override {
        super.setUp();
        initializeMemeToken();
        backMeme(MEME_CREATION.backersETHCap);
        swap(10 ether);
    }

    function test_collectProtocolFees_success() public {
        uint256 expectedFees = 0.03 ether;
        vm.expectEmit(true, false, false, true);
        emit CollectProtocolFees(Currency.unwrap(CurrencyLibrary.NATIVE), address(truglyTest), expectedFees);
        truglyTest.collectProtocolFees(CurrencyLibrary.NATIVE, expectedFees);
    }

    function test_collectLPFees_success() public {
        PoolKey[] memory poolKeys = new PoolKey[](1);
        poolKeys[0] = poolKey;
        truglyTest.collectLPFees(poolKeys);
    }
}
