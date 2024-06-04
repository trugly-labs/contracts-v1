/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {IUniswapV3Pool} from "../../src/interfaces/external/IUniswapV3Pool.sol";
import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";
import {Meme20AddressMiner} from "../utils/Meme20AddressMiner.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";
import {MEME20} from "../../src/types/MEME20.sol";

contract CreateMemeKOLTest is DeployersME20 {
    using FixedPointMathLib for uint256;

    error InvalidMemeAddress();
    error MemeSwapFeeTooHigh();
    error VestingAllocTooHigh();
    error ZeroAmount();
    error MaxTargetETH();
    error Paused();

    string constant symbol = "MEME";

    TruglyMemeception public memeceptionContract;

    function setUp() public override {
        super.setUp();
        memeceptionContract = memeceptionBaseTest.memeceptionContract();
    }

    function createMemeKOL(string memory name) public {
        uint40 startAt = createMemeParams.startAt == 0 ? uint40(block.timestamp) : createMemeParams.startAt;
        createMemeParams.name = name;
        (, bytes32 salt) = Meme20AddressMiner.find(
            address(factory), WETH9, createMemeParams.name, symbol, address(memeception), MEMECREATOR
        );
        createMemeParams.startAt = startAt;
        createMemeParams.symbol = symbol;
        createMemeParams.salt = salt;

        (address memeTokenAddr, address pool) = memeception.createMemeKOL(createMemeParams);

        MEMECREATOR = createMemeParams.creator;

        MEME20 memeToken = MEME20(memeTokenAddr);
        uint256 vestingAllocSupply = MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(createMemeParams.vestingAllocBps, 1e4);
        assertTrue(address(memeToken) > address(WETH9), "memeTokenAddr > WETH9");
        assertEq(memeToken.name(), createMemeParams.name, "memeName");
        assertEq(memeToken.decimals(), MEME20Constant.TOKEN_DECIMALS, "memeDecimals");
        assertEq(memeToken.symbol(), createMemeParams.symbol, "memeSymbol");
        assertEq(memeToken.totalSupply(), MEME20Constant.TOKEN_TOTAL_SUPPLY, "memeSupply");
        assertEq(memeToken.creator(), MEMECREATOR, "creator");
        assertEq(
            memeToken.balanceOf(address(memeceptionBaseTest.memeceptionContract())),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4),
            "memeSupplyMinted"
        );
        assertEq(
            memeToken.balanceOf(address(0)),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4) - vestingAllocSupply,
            "memeSupplyBurned"
        );

        ITruglyMemeception.Memeception memory memeception = memeceptionContract.getMemeception(memeTokenAddr);
        assertEq(memeception.targetETH, createMemeParams.targetETH, "memeception.targetETH");
        assertEq(memeception.collectedETH, 0, "memeception.collectedETH");
        assertEq(memeception.tokenId, 0, "memeception.tokenId");
        assertNotEq(memeception.pool, address(0), "memeception.tokenId");
        assertEq(memeception.swapFeeBps, createMemeParams.swapFeeBps, "memeception.swapFeeBps");
        assertEq(memeception.creator, MEMECREATOR, "memeception.creator");
        assertEq(memeception.startAt, startAt, "memeception.startAt");
        assertEq(memeception.endedAt, 0, "memeception.endedAt");

        /// Assert Uniswap V3 Pool
        assertEq(IUniswapV3Pool(pool).fee(), Constant.UNI_LP_SWAPFEE, "v3Pool.fee");
        if (WETH9 < memeTokenAddr) {
            assertEq(IUniswapV3Pool(pool).token0(), WETH9, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), memeTokenAddr, "v3Pool.token1");
        } else {
            assertEq(IUniswapV3Pool(pool).token0(), memeTokenAddr, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), WETH9, "v3Pool.token1");
        }

        /// Assert Vesting Contract
        assertEq(
            memeToken.balanceOf(address(memeceptionContract.vesting())),
            createMemeParams.vestingAllocBps == 0 ? 0 : vestingAllocSupply,
            "vestingAllocSupply"
        );
    }

    function test_createMemeKOL_success_simple() public {
        createMemeKOL("MEME");
    }

    function test_createMemeKOL_success_zero_swap() public {
        createMemeParams.swapFeeBps = 0;
        createMemeKOL("MEME");
    }

    function test_createMemeKOL_success_zero_vesting() public {
        createMemeParams.vestingAllocBps = 0;
        createMemeKOL("MEME");
    }

    function test_createMemeKOL_success_max_vesting() public {
        createMemeParams.vestingAllocBps = 1000;
        createMemeKOL("MEME");
    }

    function test_createMemeKOLSymbolExist_success() public {
        createMemeKOL("MEME");

        createMemeParams.salt = bytes32("2");
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeSameSymbolAndSalt_collision_revert() public {
        createMemeKOL("MEME");

        vm.expectRevert();
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeKOL_fail_swapFee() public {
        createMemeParams.swapFeeBps = 81;
        vm.expectRevert(MemeSwapFeeTooHigh.selector);
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeKOL_fail_vestingAlloc() public {
        createMemeParams.vestingAllocBps = 1001;
        vm.expectRevert(VestingAllocTooHigh.selector);
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeKOL_fail_targetETH() public {
        createMemeParams.targetETH = 0;
        vm.expectRevert(ZeroAmount.selector);
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeKOL_fail_max_targetETH() public {
        createMemeParams.targetETH = Constant.MAX_TARGET_ETH + 1;
        vm.expectRevert(MaxTargetETH.selector);
        memeception.createMemeKOL(createMemeParams);
    }

    function test_createMemeKOL_fail_paused() public {
        vm.startPrank(memeceptionBaseTest.MULTISIG());
        memeception.setPaused(true);
        vm.stopPrank();

        vm.expectRevert(Paused.selector);
        memeception.createMemeKOL(createMemeParams);
    }
}
