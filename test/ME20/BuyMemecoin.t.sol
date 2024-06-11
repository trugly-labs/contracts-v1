/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {LibString} from "@solady/utils/LibString.sol";

import {IUNCX_LiquidityLocker_UniV3} from "../../src/interfaces/external/IUNCX_LiquidityLocker_UniV3.sol";
import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";

contract BuyMemecoinTest is DeployersME20 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using LibString for uint256;

    error MemeLaunched();
    error ZeroAmount();
    error MemeceptionEnded();
    error MemeceptionNotStarted();
    error MaxTargetETH();
    error Paused();

    /// @dev Emitted when a user buy memecoins in the fair launch
    event MemecoinBuy(address indexed memeToken, address indexed user, uint256 buyETHAmount, uint256 amountMeme);

    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_buyMemecoin_under_cap_success() public {
        uint256 amount = createMemeParams.targetETH / 10;
        vm.expectEmit(true, true, false, true);
        emit MemecoinBuy(address(memeToken), address(this), amount, Constant.TOKEN_MEMECEPTION_SUPPLY / 10);

        memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
    }

    function test_buyMemecoin_under_cap_multiple_success() public {
        for (uint256 i = 0; i < 10; i++) {
            address SENDER = makeAddr(i.toString());
            uint256 amount = createMemeParams.targetETH / 10;
            startHoax(SENDER, amount);
            vm.expectEmit(true, true, false, true);
            emit MemecoinBuy(address(memeToken), SENDER, amount, Constant.TOKEN_MEMECEPTION_SUPPLY / 10);
            memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
            vm.stopPrank();
        }
    }

    function test_buyMemecoin_capReached_success() public {
        uint256 amount = createMemeParams.targetETH / 10;
        for (uint256 i = 0; i < 9; i++) {
            address SENDER = makeAddr(i.toString());
            startHoax(SENDER, amount);
            vm.expectEmit(true, true, false, true);
            emit MemecoinBuy(address(memeToken), SENDER, amount, Constant.TOKEN_MEMECEPTION_SUPPLY / 10);
            memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
            vm.stopPrank();
        }

        vm.expectEmit(true, true, false, true);
        emit MemecoinBuy(address(memeToken), address(this), amount, Constant.TOKEN_MEMECEPTION_SUPPLY / 10);

        memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));

        ITruglyMemeception.Memeception memory memeceptionData = memeception.getMemeception(address(memeToken));

        IUNCX_LiquidityLocker_UniV3.Lock memory lock = uncxLocker.getLock(memeceptionData.tokenId);
        assertEq(lock.pool, memeceptionData.pool, "lock.pool");
        assertEq(address(lock.nftPositionManager), Constant.UNISWAP_BASE_V3_POSITION_MANAGER, "lock.nftPositionManager");
        assertEq(lock.lock_id, memeceptionData.tokenId, "lock.lock_id");
        assertEq(lock.owner, memeceptionBaseTest.MULTISIG(), "lock.owner");
        assertEq(lock.pendingOwner, address(0), "lock.pendingOwner");
        assertEq(lock.additionalCollector, address(memeception), "lock.additionalCollector");
        assertEq(lock.unlockDate, type(uint256).max, "lock.unlockDate");
        assertEq(lock.countryCode, 0, "lock.countryCode");
    }

    function test_buyMemecoin_capReached_over_success() public {
        uint256 amount = createMemeParams.targetETH / 10;
        for (uint256 i = 0; i < 10; i++) {
            uint256 expectedMeme = Constant.TOKEN_MEMECEPTION_SUPPLY / 10;
            if (i == 9) {
                amount = amount / 10 * 9;
                expectedMeme = Constant.TOKEN_MEMECEPTION_SUPPLY / 100 * 9;
            }
            address SENDER = makeAddr(i.toString());
            startHoax(SENDER, amount);
            vm.expectEmit(true, true, false, true);
            emit MemecoinBuy(address(memeToken), SENDER, amount, expectedMeme);
            memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
            vm.stopPrank();
        }

        vm.expectEmit(true, true, false, true);
        emit MemecoinBuy(
            address(memeToken), address(this), createMemeParams.targetETH / 100, Constant.TOKEN_MEMECEPTION_SUPPLY / 100
        );

        memeceptionBaseTest.buyMemecoin{value: amount}(address(memeToken));
    }

    function test_buyMemecoin_success_duplicate_og() public {
        memeceptionBaseTest.buyMemecoin{value: createMemeParams.maxBuyETH / 2}(address(memeToken));
        memeceptionBaseTest.buyMemecoin{value: createMemeParams.maxBuyETH / 2}(address(memeToken));
    }

    function test_buyMemecoin_fail_zero_amount() public {
        vm.expectRevert(ZeroAmount.selector);
        memeceptionBaseTest.buyMemecoin{value: 0}(address(memeToken));
    }

    function test_buyMemecoin_fail_memeception_not_started() public {
        vm.warp(block.timestamp - 1 seconds);
        vm.expectRevert(MemeceptionNotStarted.selector);
        memeception.buyMemecoin{value: 1 ether}(address(memeToken));
    }

    function test_buyMemecoin_fail_meme_launched() public {
        initBuyMemecoinFullCap();

        vm.expectRevert(MemeLaunched.selector);
        memeceptionBaseTest.buyMemecoin{value: 1 ether}(address(memeToken));
    }

    function test_buyMemecoin_fail_unknown_meme() public {
        vm.expectRevert();
        memeceptionBaseTest.buyMemecoin{value: 1 ether}(address(1));
    }

    function test_buyMemecoin__fail_max_buy() public {
        vm.expectRevert(MaxTargetETH.selector);
        memeceptionBaseTest.buyMemecoin{value: createMemeParams.targetETH / 10 + 1}(address(memeToken));
    }

    function test_buyMemecoin__fail_max_buy_over_multiple_tx() public {
        memeceptionBaseTest.buyMemecoin{value: createMemeParams.maxBuyETH}(address(memeToken));

        vm.expectRevert(MaxTargetETH.selector);
        memeceptionBaseTest.buyMemecoin{value: 1}(address(memeToken));
    }

    function test_buyMemecoin_fail_paused() public {
        vm.startPrank(memeceptionBaseTest.MULTISIG());
        memeception.setPaused(true);
        vm.stopPrank();

        vm.expectRevert(Paused.selector);
        memeception.buyMemecoin{value: 1}(address(memeToken));
    }
}
