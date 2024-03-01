/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEMERC20} from "../types/MEMERC20.sol";
import {ITruglyLaunchpad} from "../interfaces/ITruglyLaunchpad.sol";
import {TruglyLaunchpad} from "../TruglyLaunchpad.sol";
import {DeploymentAddresses} from "./DeploymentAddresses.sol";
import {Constant} from "../libraries/Constant.sol";
import {FullMath} from "../libraries/external/FullMath.sol";

contract LaunchpadBaseTest is Test, DeploymentAddresses, Constant {
    using FullMath for uint256;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    struct Balances {
        uint256 userETH;
        uint256 launchpadETH;
        uint256 poolWETH;
        uint256 userMeme;
        uint256 launchpadMeme;
        uint256 poolMeme;
        uint256 vestingMeme;
        uint256 memeception;
        uint256 og;
    }

    TruglyLaunchpad public launchpad;

    uint256 constant TOLERANCE = 1 gwei;

    constructor(address _vesting) {
        launchpad = new TruglyLaunchpad(UNISWAP_V3_FACTORY, UNISWAP_V3_POSITION_MANAGER, WETH9, _vesting);

        assertEq(address(launchpad.v3Factory()), UNISWAP_V3_FACTORY);
        assertEq(address(launchpad.v3PositionManager()), UNISWAP_V3_POSITION_MANAGER);
        assertEq(address(launchpad.WETH9()), WETH9);
    }

    function createMeme(ITruglyLaunchpad.MemeCreationParams calldata params)
        external
        returns (address memeTokenAddr, address pool)
    {
        (memeTokenAddr, pool) = launchpad.createMeme(params);

        /// Assert Token Creation
        MEMERC20 memeToken = MEMERC20(memeTokenAddr);
        uint256 vestingAllocSupply = TOKEN_TOTAL_SUPPLY.mulDiv(params.vestingAllocBps, 1e4);
        assertEq(memeToken.name(), params.name, "memeName");
        assertEq(memeToken.decimals(), TOKEN_DECIMALS, "memeDecimals");
        assertEq(memeToken.symbol(), params.symbol, "memeSymbol");
        assertEq(memeToken.totalSupply(), TOKEN_TOTAL_SUPPLY, "memeSupply");
        assertEq(memeToken.balanceOf(address(launchpad)), TOKEN_TOTAL_SUPPLY - vestingAllocSupply, "memeSupplyMinted");

        /// Assert Memeception Creation
        ITruglyLaunchpad.Memeception memory memeception = launchpad.getMemeception(memeTokenAddr);
        assertEq(memeception.balance, 0, "memeception.balance");
        assertEq(memeception.cap, params.cap, "memeception.cap");
        assertEq(memeception.startAt, params.startAt, "memeception.startAt");
        assertEq(memeception.swapFeeBps, params.swapFeeBps, "memeception.swapFeeBps");

        /// Assert Uniswap V3 Pool
        assertEq(IUniswapV3Pool(pool).fee(), UNI_LP_SWAPFEE, "v3Pool.fee");
        if (WETH9 < memeTokenAddr) {
            assertEq(IUniswapV3Pool(pool).token0(), WETH9, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), memeTokenAddr, "v3Pool.token1");
        } else {
            assertEq(IUniswapV3Pool(pool).token0(), memeTokenAddr, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), WETH9, "v3Pool.token1");
        }

        /// Assert Vesting Contract
        assertEq(memeToken.balanceOf(address(launchpad.vesting())), vestingAllocSupply, "vestingAllocSupply");
    }

    function depositMemeception(address memeToken) external payable {
        Balances memory beforeBal = getBalances(memeToken);
        uint256 remainingCap = launchpad.getMemeception(memeToken).cap - launchpad.getMemeception(memeToken).balance;

        launchpad.depositMemeception{value: msg.value}(memeToken, new bytes(0));

        Balances memory afterBal = getBalances(memeToken);
        ITruglyLaunchpad.Memeception memory memeception = launchpad.getMemeception(memeToken);

        if (msg.value >= remainingCap) {
            /// Cap is reached
            uint256 refund = msg.value - remainingCap;
            assertEq(afterBal.userETH, beforeBal.userETH - msg.value + refund, "userETH Balance (Cap reached)");
            assertEq(afterBal.launchpadETH, 0, "launchpadETH Balance (Cap reached)");
            assertEqTol(afterBal.poolWETH, memeception.cap, "poolWETH Balance (Cap reached)");
            assertEq(afterBal.userMeme, 0, "userMeme Balance (Cap reached)");
            assertEqTol(afterBal.launchpadMeme, TOKEN_MEMECEPTION_SUPPLY, "LaunchpadMeme Balance (Cap reached)");
            assertEqTol(
                afterBal.poolMeme,
                TOKEN_TOTAL_SUPPLY - TOKEN_MEMECEPTION_SUPPLY - beforeBal.vestingMeme,
                "PoolMemeBalance (Cap reached)"
            );

            /// Assert Memeception Deposit
            assertEq(memeception.balance, memeception.cap, "memeception.balance (Cap reached)");

            assertEq(launchpad.getBalanceOG(memeToken, address(this)), msg.value - refund, "balanceOG (Cap reached)");
        } else {
            /// Cap is not reached
            assertEq(afterBal.userETH, beforeBal.userETH - msg.value, "userETH Balance (Cap not reached)");
            assertEq(
                afterBal.launchpadETH, beforeBal.launchpadETH + msg.value, "launchpadETH Balance (Cap not reached)"
            );
            assertEq(afterBal.poolWETH, 0, "poolWETH Balance (Cap not reached)");
            assertEq(afterBal.userMeme, 0, "userMeme Balance (Cap not reached)");
            assertEq(
                afterBal.launchpadMeme,
                TOKEN_TOTAL_SUPPLY - beforeBal.vestingMeme,
                "LaunchpadMeme Balance (Cap not reached)"
            );
            assertEq(afterBal.poolMeme, 0, "PoolMemeBalance (Cap not reached)");

            /// Assert Memeception Deposit
            assertEq(memeception.balance, afterBal.launchpadETH, "memeception.balance (Cap not reached)");
            assertEq(launchpad.getBalanceOG(memeToken, address(this)), msg.value, "balanceOG (Cap not reached)");
        }
    }

    function exitMemeception(address memeToken) external {
        Balances memory beforeBal = getBalances(memeToken);

        launchpad.exitMemeception(memeToken);

        Balances memory afterBal = getBalances(memeToken);

        /// Assert Memeception Exit Balances
        assertEq(afterBal.userETH, beforeBal.userETH + beforeBal.og, "userETH Balance");
        assertEq(afterBal.launchpadETH, beforeBal.launchpadETH - beforeBal.og, "launchpadETH Balance");
        assertEq(afterBal.poolWETH, 0, "poolWETH Balance");
        assertEq(afterBal.userMeme, 0, "userMeme Balance");
        assertEq(
            afterBal.launchpadMeme,
            TOKEN_TOTAL_SUPPLY - launchpad.vesting().getVestingInfo(memeToken).totalAllocation,
            "LaunchpadMeme Balance"
        );
        assertEq(afterBal.poolMeme, 0, "PoolMemeBalance");

        /// Assert Memeception Exit
        assertEq(afterBal.memeception, beforeBal.memeception, "memeception.balance");
        assertEq(afterBal.og, 0, "balanceOG");
    }

    function claimMemeception(address memeToken) external {
        Balances memory beforeBal = getBalances(memeToken);
        ITruglyLaunchpad.Memeception memory memeception = launchpad.getMemeception(memeToken);
        // Expected Meme Claimed
        uint256 expectedMeme = beforeBal.og.mulDiv(1e18, memeception.cap).mulDiv(TOKEN_MEMECEPTION_SUPPLY, 1e18);
        launchpad.claimMemeception(memeToken);
        Balances memory afterBal = getBalances(memeToken);

        /// Assert Memeception Claim Balances
        assertEq(afterBal.userETH, beforeBal.userETH, "userETH Balance");
        assertEq(afterBal.launchpadETH, beforeBal.launchpadETH, "launchpadETH Balance");
        assertEq(afterBal.poolWETH, beforeBal.poolWETH, "poolWETH Balance");
        assertEq(afterBal.userMeme, expectedMeme, "userMeme Balance");
        assertEq(afterBal.launchpadMeme, beforeBal.launchpadMeme - expectedMeme, "LaunchpadMeme Balance");
        assertEq(afterBal.poolMeme, beforeBal.poolMeme, "PoolMemeBalance");

        /// Assert Memeception Claim
        assertEq(afterBal.memeception, beforeBal.memeception, "memeception.balance");
        assertEq(afterBal.og, 0, "balanceOG");
    }

    function transferAdmin(address _newAdmin) external {}

    function setMemeSigner(address _memeSigner) external {}

    function getBalances(address memeToken) public view returns (Balances memory bal) {
        bal = Balances({
            userETH: address(this).balance,
            launchpadETH: address(launchpad).balance,
            poolWETH: MEMERC20(WETH9).balanceOf(launchpad.getMemeception(memeToken).pool),
            userMeme: MEMERC20(memeToken).balanceOf(address(this)),
            launchpadMeme: MEMERC20(memeToken).balanceOf(address(launchpad)),
            poolMeme: MEMERC20(memeToken).balanceOf(launchpad.getMemeception(memeToken).pool),
            vestingMeme: MEMERC20(memeToken).balanceOf(address(launchpad.vesting())),
            memeception: launchpad.getMemeception(memeToken).balance,
            og: launchpad.getBalanceOG(memeToken, address(this))
        });
    }

    /// @notice receive native tokens
    receive() external payable {}

    function assertEqTol(uint256 a, uint256 b, string memory reason) public {
        assertEq(a <= b + TOLERANCE && a + TOLERANCE >= b, true, reason);
    }
}
