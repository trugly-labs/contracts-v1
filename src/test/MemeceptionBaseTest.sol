/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {PoolLiquidity} from "./PoolLiquidity.sol";
import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEMERC20} from "../types/MEMERC20.sol";
import {ITruglyMemeception} from "../interfaces/ITruglyMemeception.sol";
import {TruglyMemeception} from "../TruglyMemeception.sol";
import {Constant} from "../libraries/Constant.sol";
import {MEMERC20Constant} from "../libraries/MEMERC20Constant.sol";
import {TestHelpers} from "../../test/utils/TestHelpers.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";

contract MemeceptionBaseTest is Test, TestHelpers, BaseParameters {
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
        uint256 auctionMeme;
        uint256 auctionFinalPrice;
        uint256 bidAmountETH;
        uint256 bidAmountMeme;
    }

    TruglyMemeception public memeceptionContract;

    constructor(address _vesting, address _treasury) {
        memeceptionContract = new TruglyMemeception(V3_FACTORY, V3_POSITION_MANAGER, WETH9, _vesting, _treasury);

        assertEq(address(memeceptionContract.v3Factory()), V3_FACTORY);
        assertEq(address(memeceptionContract.v3PositionManager()), V3_POSITION_MANAGER);
        assertEq(address(memeceptionContract.WETH9()), WETH9);
    }

    function createMeme(ITruglyMemeception.MemeceptionCreationParams calldata params)
        external
        returns (address memeTokenAddr, address pool)
    {
        (memeTokenAddr, pool) = memeceptionContract.createMeme(params);

        /// Assert Token Creation
        MEMERC20 memeToken = MEMERC20(memeTokenAddr);
        uint256 vestingAllocSupply = MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(params.vestingAllocBps, 1e4);
        assertTrue(address(memeToken) > address(WETH9), "memeTokenAddr > WETH9");
        assertEq(memeToken.name(), params.name, "memeName");
        assertEq(memeToken.decimals(), MEMERC20Constant.TOKEN_DECIMALS, "memeDecimals");
        assertEq(memeToken.symbol(), params.symbol, "memeSymbol");
        assertEq(memeToken.totalSupply(), MEMERC20Constant.TOKEN_TOTAL_SUPPLY, "memeSupply");
        assertEq(memeToken.creator(), address(this), "creator");
        assertEq(
            memeToken.balanceOf(address(memeceptionContract)),
            MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4),
            "memeSupplyMinted"
        );
        assertEq(
            memeToken.balanceOf(address(0)),
            MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4) - vestingAllocSupply,
            "memeSupplyBurned"
        );

        /// Assert Memeception Creation
        ITruglyMemeception.Memeception memory memeception = memeceptionContract.getMemeception(memeTokenAddr);
        assertEq(memeception.auctionTokenSold, 0, "memeception.auctionTokenSold");
        assertEq(memeception.auctionFinalPriceScaled, 0, "memeception.auctionFinalPrice");
        assertEq(memeception.creator, address(this), "memeception.creator");
        assertEq(memeception.startAt, params.startAt, "memeception.startAt");
        assertEq(memeception.swapFeeBps, params.swapFeeBps, "memeception.swapFeeBps");

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
            params.vestingAllocBps == 0 ? 0 : params.startAt,
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
            params.vestingAllocBps == 0 ? address(0) : address(this),
            "Vesting.creator"
        );

        assertEq(memeceptionContract.vesting().releasable(address(memeToken)), 0, "Vesting.releasable");
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(block.timestamp)),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(
                address(memeToken), uint64(params.startAt + Constant.VESTING_CLIFF - 1)
            ),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(params.startAt + 365 days)),
            vestingAllocSupply / 4,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(params.startAt + 365 days * 2)),
            vestingAllocSupply / 2,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(memeToken), uint64(params.startAt + 365 days * 4)),
            vestingAllocSupply,
            "Vesting.vestedAmount"
        );
    }

    function bid(address memeToken) external payable {
        Balances memory beforeBal = getBalances(memeToken);
        uint256 remainingAuctionToken =
            Constant.TOKEN_MEMECEPTION_SUPPLY - memeceptionContract.getMemeception(memeToken).auctionTokenSold;
        uint256 curPriceScaled = memeceptionContract.getAuctionPriceScaled(memeToken);
        uint256 bidTokenAmount = msg.value * 1e18 / curPriceScaled;

        memeceptionContract.bid{value: msg.value}(memeToken);

        Balances memory afterBal = getBalances(memeToken);

        if (bidTokenAmount >= remainingAuctionToken) {
            /// Cap is reached
            assertEq(afterBal.userETH, beforeBal.userETH - msg.value, "userETH Balance (Cap reached)");
            assertApproxEq(
                afterBal.memeceptionContractETH,
                beforeBal.memeceptionContractETH + msg.value - Constant.TOKEN_MEMECEPTION_SUPPLY.mulWad(curPriceScaled),
                0.0000000001e18,
                "memeceptionContractETH Balance (Cap reached)"
            );
            assertApproxEq(
                afterBal.poolWETH,
                PoolLiquidity.getETHLiquidity(memeceptionContract.getMemeception(memeToken).startAt),
                0.0000000001e18,
                "poolWETH Balance (Cap reached)"
            );
            assertEq(afterBal.userMeme, 0, "userMeme Balance (Cap reached)");
            assertApproxEq(
                afterBal.memeceptionContractMeme,
                Constant.TOKEN_MEMECEPTION_SUPPLY,
                0.0000000001e18,
                "LaunchpadMeme Balance (Cap reached)"
            );
            assertApproxEq(
                afterBal.poolMeme,
                MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4)
                    - Constant.TOKEN_MEMECEPTION_SUPPLY,
                0.0000000001e18,
                "PoolMemeBalance (Cap reached)"
            );
            assertEq(afterBal.vestingMeme, beforeBal.vestingMeme, "VestingMemeBalance (Cap reached)");
            assertEq(afterBal.bidAmountETH, msg.value, "bidAmountETH (Cap reached)");
            assertEq(afterBal.bidAmountMeme, remainingAuctionToken, "bidAmountMeme (Cap reached)");

            /// Assert Memeception Auction
            assertEq(
                afterBal.auctionMeme, Constant.TOKEN_MEMECEPTION_SUPPLY, "memeception.auctionTokenSold(Cap reached)"
            );
            assertEq(afterBal.auctionFinalPrice, curPriceScaled, "memeception.auctionFinalPrice (Cap reached)");
        } else {
            /// Cap is not reached
            assertEq(afterBal.userETH, beforeBal.userETH - msg.value, "userETH Balance (Cap not reached)");
            assertEq(
                afterBal.memeceptionContractETH,
                beforeBal.memeceptionContractETH + msg.value,
                "memeceptionContractETH Balance (Cap not reached)"
            );
            assertEq(afterBal.poolWETH, 0, "poolWETH Balance (Cap not reached)");
            assertEq(afterBal.userMeme, 0, "userMeme Balance (Cap not reached)");
            assertEq(
                afterBal.memeceptionContractMeme,
                MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4),
                "LaunchpadMeme Balance (Cap not reached)"
            );
            assertEq(afterBal.poolMeme, 0, "PoolMemeBalance (Cap not reached)");
            assertEq(afterBal.vestingMeme, beforeBal.vestingMeme, "VestingMemeBalance (Cap reached)");
            assertEq(afterBal.bidAmountETH, msg.value, "bidAmountETH (Cap reached)");
            assertEq(afterBal.bidAmountMeme, bidTokenAmount, "bidAmountMeme (Cap reached)");

            /// Assert Memeception Auction
            assertEq(
                afterBal.auctionMeme,
                beforeBal.auctionMeme + bidTokenAmount,
                "memeception.auctionTokenSold(Cap reached)"
            );
            assertEq(afterBal.auctionFinalPrice, 0, "memeception.auctionFinalPrice (Cap reached)");
        }
    }

    function exit(address memeToken) external {
        Balances memory beforeBal = getBalances(memeToken);

        memeceptionContract.exit(memeToken);

        Balances memory afterBal = getBalances(memeToken);

        /// Assert Memeception Exit Balances
        assertEq(afterBal.userETH, beforeBal.userETH + beforeBal.bidAmountETH, "userETH Balance");
        assertEq(
            afterBal.memeceptionContractETH,
            beforeBal.memeceptionContractETH - beforeBal.bidAmountETH,
            "memeceptionContractETH Balance"
        );
        assertEq(afterBal.poolWETH, 0, "poolWETH Balance");
        assertEq(afterBal.userMeme, 0, "userMeme Balance");
        assertEq(afterBal.memeceptionContractMeme, beforeBal.memeceptionContractMeme, "LaunchpadMeme Balance");
        assertEq(afterBal.poolMeme, 0, "PoolMemeBalance");
        assertEq(afterBal.auctionMeme, beforeBal.auctionMeme, "memeception.auctionTokenSold");
        assertEq(afterBal.auctionFinalPrice, 0, "memeception.auctionFinalPrice");
        assertEq(afterBal.bidAmountETH, 0, "bidAmountETH");
        assertEq(afterBal.bidAmountMeme, 0, "bidAmountMeme");
    }

    function claim(address memeToken) external {
        Balances memory beforeBal = getBalances(memeToken);
        memeceptionContract.claim(memeToken);
        Balances memory afterBal = getBalances(memeToken);

        uint256 refund = beforeBal.bidAmountETH - beforeBal.auctionFinalPrice.mulWadUp(beforeBal.bidAmountMeme);

        /// Assert Memeception Claim Balances
        assertEq(afterBal.userETH, beforeBal.userETH + refund, "userETH Balance");
        assertEq(
            afterBal.memeceptionContractETH, beforeBal.memeceptionContractETH - refund, "memeceptionContractETH Balance"
        );
        assertEq(afterBal.poolWETH, beforeBal.poolWETH, "poolWETH Balance");
        assertEq(afterBal.userMeme, beforeBal.bidAmountMeme, "userMeme Balance");
        assertEq(
            afterBal.memeceptionContractMeme,
            beforeBal.memeceptionContractMeme - beforeBal.bidAmountMeme,
            "LaunchpadMeme Balance"
        );
        assertEq(afterBal.poolMeme, beforeBal.poolMeme, "PoolMemeBalance");
        assertEq(afterBal.vestingMeme, beforeBal.vestingMeme, "VestingMemeBalance");
        assertEq(afterBal.auctionMeme, beforeBal.auctionMeme, "memeception.auctionTokenSold");
        assertEq(afterBal.auctionFinalPrice, beforeBal.auctionFinalPrice, "memeception.auctionFinalPrice");
        assertEq(afterBal.bidAmountETH, 0, "bidAmountETH");
        assertEq(afterBal.bidAmountMeme, 0, "bidAmountMeme");
    }

    function getBalances(address memeToken) public view returns (Balances memory bal) {
        bal = Balances({
            userETH: address(this).balance,
            memeceptionContractETH: address(memeceptionContract).balance,
            poolWETH: MEMERC20(WETH9).balanceOf(memeceptionContract.getMemeception(memeToken).pool),
            userMeme: MEMERC20(memeToken).balanceOf(address(this)),
            memeceptionContractMeme: MEMERC20(memeToken).balanceOf(address(memeceptionContract)),
            poolMeme: MEMERC20(memeToken).balanceOf(memeceptionContract.getMemeception(memeToken).pool),
            vestingMeme: MEMERC20(memeToken).balanceOf(address(memeceptionContract.vesting())),
            auctionMeme: memeceptionContract.getMemeception(memeToken).auctionTokenSold,
            auctionFinalPrice: memeceptionContract.getMemeception(memeToken).auctionFinalPriceScaled,
            bidAmountETH: memeceptionContract.getBid(memeToken, address(this)).amountETH,
            bidAmountMeme: memeceptionContract.getBid(memeToken, address(this)).amountMeme
        });
    }

    function setAuctionDuration(uint256 duration) external {
        memeceptionContract.setAuctionDuration(duration);
    }

    function setTreasury(address treasury) external {
        memeceptionContract.setTreasury(treasury);
    }

    function collectFees(address memeToken) external {
        memeceptionContract.collectFees(memeToken);
    }

    /// @notice receive native tokens
    receive() external payable {}
}
