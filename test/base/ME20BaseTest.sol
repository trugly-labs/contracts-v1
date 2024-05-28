/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IUniswapV3Pool} from "../../src/interfaces/external/IUniswapV3Pool.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";
import {TestHelpers} from "../utils/TestHelpers.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";

contract ME20BaseTest is Test, TestHelpers, BaseParameters {
    error AuctionOutOfRange();

    using SafeTransferLib for address;

    using FixedPointMathLib for uint256;
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    struct Balances {
        uint256 userETH;
        uint256 memeceptionContractETH;
        uint256 poolWETH;
        uint256 userMeme;
        uint256 memeceptionContractMeme;
        uint256 poolMeme;
        uint256 vestingMeme;
        uint256 collectedETH;
    }

    TruglyMemeception public memeceptionContract;

    address public MULTISIG = makeAddr("multisig");
    address public MEMECREATOR;

    constructor(address _vesting, address _treasury, address _mockFactory) {
        memeceptionContract = new TruglyMemeception(
            V3_FACTORY, V3_POSITION_MANAGER, UNCX_V3_LOCKERS, WETH9, _vesting, _treasury, MULTISIG, _mockFactory
        );

        assertEq(address(memeceptionContract.v3Factory()), V3_FACTORY);
        assertEq(address(memeceptionContract.v3PositionManager()), V3_POSITION_MANAGER);
        assertEq(address(memeceptionContract.WETH9()), WETH9);
        assertEq(address(memeceptionContract.factory()), _mockFactory);
    }

    function createMeme(ITruglyMemeception.MemeceptionCreationParams memory params)
        external
        returns (address memeTokenAddr, address pool)
    {
        (memeTokenAddr, pool) = memeceptionContract.createMeme(params);
        MEMECREATOR = params.creator;

        uint256 startAt = params.startAt > block.timestamp ? params.startAt : block.timestamp;

        /// Assert Token Creation
        MEME20 memeToken = MEME20(memeTokenAddr);
        uint256 vestingAllocSupply = MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(params.vestingAllocBps, 1e4);
        assertTrue(address(memeToken) > address(WETH9), "memeTokenAddr > WETH9");
        assertEq(memeToken.name(), params.name, "memeName");
        assertEq(memeToken.decimals(), MEME20Constant.TOKEN_DECIMALS, "memeDecimals");
        assertEq(memeToken.symbol(), params.symbol, "memeSymbol");
        assertEq(memeToken.totalSupply(), MEME20Constant.TOKEN_TOTAL_SUPPLY, "memeSupply");
        assertEq(memeToken.creator(), MEMECREATOR, "creator");
        assertEq(
            memeToken.balanceOf(address(memeceptionContract)),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4),
            "memeSupplyMinted"
        );
        assertEq(
            memeToken.balanceOf(address(0)),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4) - vestingAllocSupply,
            "memeSupplyBurned"
        );

        /// Assert Memeception Creation
        ITruglyMemeception.Memeception memory memeception = memeceptionContract.getMemeception(memeTokenAddr);
        assertEq(memeception.targetETH, params.targetETH, "memeception.targetETH");
        assertEq(memeception.collectedETH, 0, "memeception.collectedETH");
        assertEq(memeception.tokenId, 0, "memeception.tokenId");
        assertNotEq(memeception.pool, address(0), "memeception.tokenId");
        assertEq(memeception.swapFeeBps, params.swapFeeBps, "memeception.swapFeeBps");
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
            params.vestingAllocBps == 0 ? 0 : vestingAllocSupply,
            "vestingAllocSupply"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(memeToken)).totalAllocation,
            params.vestingAllocBps == 0 ? 0 : vestingAllocSupply,
            "Vesting.totalAllocation"
        );
        assertEq(memeceptionContract.vesting().getVestingInfo(address(memeToken)).released, 0, "Vesting.released");
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(memeToken)).start,
            params.vestingAllocBps == 0 ? 0 : startAt,
            "Vesting.start"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(memeToken)).duration,
            params.vestingAllocBps == 0 ? 0 : Constant.VESTING_DURATION,
            "Vesting.duration"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(memeToken)).cliff,
            params.vestingAllocBps == 0 ? 0 : Constant.VESTING_CLIFF,
            "Vesting.cliff"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(memeToken)).creator,
            params.vestingAllocBps == 0 ? address(0) : MEMECREATOR,
            "Vesting.creator"
        );

        assertEq(memeceptionContract.vesting().releasable(address(memeToken)), 0, "Vesting.releasable");
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(block.timestamp)),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(startAt + Constant.VESTING_CLIFF - 1)),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(startAt + 91.25 days)),
            vestingAllocSupply / 8,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(startAt + 365 days)),
            vestingAllocSupply / 2,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(startAt + 365 days * 2)),
            vestingAllocSupply,
            "Vesting.vestedAmount"
        );
    }

    function buyMemecoin(address memeToken) external payable {
        address SENDER = msg.sender;
        SENDER.safeTransferETH(msg.value);

        ITruglyMemeception.Memeception memory memeception = memeceptionContract.getMemeception(memeToken);
        uint256 remainingETH = memeception.targetETH - memeception.collectedETH;
        uint256 pricePerETH = memeceptionContract.getPricePerETH(memeToken);
        Balances memory beforeBal = getBalances(memeToken);

        vm.startPrank(SENDER);
        memeceptionContract.buyMemecoin{value: msg.value}(memeToken);
        vm.stopPrank();
        Balances memory afterBal = getBalances(memeToken);

        memeception = memeceptionContract.getMemeception(memeToken);

        if (msg.value >= remainingETH) {
            /// Cap is reached
            assertEq(afterBal.collectedETH, memeception.targetETH, "memeception.collectedETH (Cap reached)");
            assertEq(afterBal.userETH, beforeBal.userETH - remainingETH, "userETH Balance (Cap reached)");
            assertApproxEq(
                afterBal.memeceptionContractETH, 0, 0.0000000001e18, "memeceptionContractETH Balance (Cap reached)"
            );
            assertApproxEq(
                afterBal.poolWETH,
                // 0.03 ETH flag fee and 0.8% for UNCX locker
                (memeception.targetETH - 0.03 ether).mulDiv(992, 1000),
                0.0000000001e18,
                "poolWETH Balance (Cap reached)"
            );
            assertEq(
                afterBal.userMeme,
                beforeBal.userMeme + remainingETH.rawMul(pricePerETH),
                "userMeme Balance (Cap reached)"
            );
            assertApproxEq(afterBal.memeceptionContractMeme, 0, 0.0100000001e18, "LaunchpadMeme Balance (Cap reached)");
            assertApproxEq(
                afterBal.poolMeme,
                // 0.8% is taken by UNCX
                Constant.TOKEN_MEMECEPTION_SUPPLY.mulDiv(992, 1000),
                0.0000000001e18,
                "PoolMemeBalance (Cap reached)"
            );
            assertEq(afterBal.vestingMeme, beforeBal.vestingMeme, "VestingMemeBalance (Cap reached)");

            assertEq(memeception.endedAt, uint40(block.timestamp), "memeception.endedAt (Cap Reached)");
            assertNotEq(memeception.tokenId, 0, "memeception.tokenid (Cap Reached)");
        } else {
            /// Cap is not reached
            assertEq(
                afterBal.collectedETH, beforeBal.collectedETH + msg.value, "memeception.collectedETH (Cap not reached)"
            );
            assertEq(afterBal.userETH, beforeBal.userETH - msg.value, "userETH Balance (Cap not reached)");
            assertEq(
                afterBal.memeceptionContractETH,
                beforeBal.memeceptionContractETH + msg.value,
                "memeceptionContractETH Balance (Cap not reached)"
            );
            assertEq(afterBal.poolWETH, 0, "poolWETH Balance (Cap not reached)");
            assertEq(
                afterBal.userMeme,
                beforeBal.userMeme + msg.value.rawMul(pricePerETH),
                "userMeme Balance (Cap not reached)"
            );
            assertEq(
                afterBal.memeceptionContractMeme,
                beforeBal.memeceptionContractMeme - msg.value.rawMul(pricePerETH),
                "LaunchpadMeme Balance (Cap not reached)"
            );
            assertEq(afterBal.poolMeme, 0, "PoolMemeBalance (Cap not reached)");
            assertEq(afterBal.vestingMeme, beforeBal.vestingMeme, "VestingMemeBalance (Cap reached)");
        }
    }

    function exitMemecoin(address memeToken, uint256 amountMeme) external {
        uint256 pricePerETH = memeceptionContract.getPricePerETH(memeToken);
        Balances memory beforeBal = getBalances(memeToken);

        uint256 refundAmountETH = amountMeme.rawDiv(pricePerETH);

        vm.startPrank(msg.sender);
        MEME20(memeToken).approve(address(memeceptionContract), amountMeme);
        memeceptionContract.exitMemecoin(memeToken, amountMeme);
        vm.stopPrank();

        Balances memory afterBal = getBalances(memeToken);

        /// Assert Memeception Exit Balances
        assertEq(afterBal.userETH, beforeBal.userETH + refundAmountETH, "userETH Balance");
        assertEq(
            afterBal.memeceptionContractETH,
            beforeBal.memeceptionContractETH - refundAmountETH,
            "memeceptionContractETH Balance"
        );
        assertEq(afterBal.poolWETH, 0, "poolWETH Balance");
        assertEq(afterBal.userMeme, beforeBal.userMeme - amountMeme, "userMeme Balance");
        assertEq(
            afterBal.memeceptionContractMeme, beforeBal.memeceptionContractMeme + amountMeme, "LaunchpadMeme Balance"
        );
        assertEq(afterBal.poolMeme, 0, "PoolMemeBalance");
        assertEq(afterBal.collectedETH, beforeBal.collectedETH - refundAmountETH, "memeception.collectedETH");
    }

    function getBalances(address memeToken) public view returns (Balances memory bal) {
        bal = Balances({
            userETH: msg.sender.balance,
            memeceptionContractETH: address(memeceptionContract).balance,
            poolWETH: ERC20(WETH9).balanceOf(memeceptionContract.getMemeception(memeToken).pool),
            userMeme: MEME20(memeToken).balanceOf(msg.sender),
            memeceptionContractMeme: MEME20(memeToken).balanceOf(address(memeceptionContract)),
            poolMeme: MEME20(memeToken).balanceOf(memeceptionContract.getMemeception(memeToken).pool),
            vestingMeme: MEME20(memeToken).balanceOf(address(memeceptionContract.vesting())),
            collectedETH: memeceptionContract.getMemeception(memeToken).collectedETH
        });
    }

    function setTreasury(address treasury) external {
        memeceptionContract.setTreasury(treasury);
    }

    function collectFees(address memeToken) external {
        vm.startPrank(msg.sender);
        memeceptionContract.collectFees(memeToken);
        vm.stopPrank();
    }

    function setCreatorAddress(address memeToken, address _newCreator) external {
        MEME20(memeToken).setCreatorAddress(_newCreator);
    }

    /// @notice receive native tokens
    receive() external payable {}
}
