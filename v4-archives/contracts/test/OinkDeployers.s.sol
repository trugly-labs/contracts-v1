/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";

import {TruglyBaseTest} from "../../src/contracts/test/TruglyBaseTest.sol";
import {HookMiner} from "./HookMiner.sol";

import {MemeERC20} from "../../src/contracts/types/MemeERC20.sol";
import {IOinkOink} from "../../src/contracts/interfaces/IOinkOink.sol";
import {OinkHooks} from "../../src/contracts/OinkHooks.sol";
import {OinkSwap} from "../../src/contracts/OinkSwap.sol";

contract OinkDeployers is Test, Deployers {
    using CurrencyLibrary for Currency;
    using FullMath for uint256;

    uint24 public constant UNI_LP_SWAPFEE = 2000;
    int24 public constant TICK_SPACING = 250;
    uint160 public constant SQRT_RATIO_TICK_LOWER = 4299855743;
    uint256 private constant OINK_SWAPFEE_BPS = 30;
    uint256 private constant BIPS_DENOMINATOR = 1e4;

    IOinkOink.MemeCreation public MEME_CREATION = IOinkOink.MemeCreation({
        name: "MEME Coin",
        symbol: "MEME",
        startAt: block.timestamp + 4 days,
        hookSalt: "",
        backersETHCap: 100 ether,
        swapFeeBps: 100
    });

    uint160 HOOKS_FLAGS = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.ACCESS_LOCK_FLAG);

    // Global variables
    TruglyBaseTest truglyTest;

    MemeERC20 memeToken;
    OinkHooks oinkHooks;

    PoolKey poolKey = PoolKey({
        currency0: CurrencyLibrary.NATIVE,
        currency1: CurrencyLibrary.NATIVE,
        fee: UNI_LP_SWAPFEE,
        tickSpacing: TICK_SPACING,
        hooks: OinkHooks(address(0))
    });

    function setUp() public virtual {
        Deployers.deployFreshManager();
        deployTestOinkContracts();

        (, bytes32 salt) = HookMiner.find(
            address(truglyTest.oink()),
            HOOKS_FLAGS,
            type(OinkHooks).creationCode,
            abi.encode(
                truglyTest.oink().poolManager(),
                address(truglyTest.oink()),
                address(truglyTest),
                MEME_CREATION.swapFeeBps
            )
        );
        MEME_CREATION.hookSalt = salt;
    }

    function deployTestOinkContracts() public {
        truglyTest = new TruglyBaseTest(address(manager));
    }

    function initializeMemeToken() internal {
        (address memeAddr, address hookAddr) = truglyTest.aMemeIsBorn(MEME_CREATION);
        memeToken = MemeERC20(memeAddr);
        oinkHooks = OinkHooks(hookAddr);

        poolKey.currency1 = Currency.wrap(memeAddr);
        poolKey.hooks = oinkHooks;
    }

    function backMeme(uint256 amount) internal {
        vm.warp(block.timestamp + 4 days);
        truglyTest.backMeme{value: amount}(address(memeToken));
    }

    function swap(uint256 swapAmount) internal {
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(swapAmount),
            sqrtPriceLimitX96: SQRT_RATIO_TICK_LOWER
        });

        uint256 swapAmountWithFee = swapAmount + swapAmount.mulDiv(MEME_CREATION.swapFeeBps, BIPS_DENOMINATOR)
            + swapAmount.mulDiv(OINK_SWAPFEE_BPS, BIPS_DENOMINATOR);

        truglyTest.memeSwap{value: uint256(swapAmountWithFee)}(poolKey, params);
    }
}
