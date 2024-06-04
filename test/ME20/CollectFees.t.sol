/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MEME20} from "../../src/types/MEME20.sol";
import {ISwapRouter} from "../utils/ISwapRouter.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract CollectFees is DeployersME20 {
    error InvalidMemeAddress();
    error Paused();

    uint256 amountIn = 0.01 ether;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBuyMemecoinFullCap();
    }

    function test_collectFees_success() public {
        initSwapFromSwapRouter(amountIn, address(this));
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29700000000000, "treasuryBalance");
    }

    function test_collectFees_success_twice() public {
        initSwapFromSwapRouter(amountIn, address(this));
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29700000000000, "treasuryBalance");

        initSwapFromSwapRouter(amountIn, address(this));
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal + 29700000000000 * 2, "treasuryBalance");
    }

    function test_collectFees_success_no_fees() public {
        uint256 beforeBal = ERC20(WETH9).balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(ERC20(WETH9).balanceOf(treasury), beforeBal, "treasuryBalance");
    }

    function test_collectFees_fail_invalid_meme_address() public {
        vm.expectRevert(InvalidMemeAddress.selector);
        memeceptionBaseTest.collectFees(address(1));
    }

    function test_collectFee_sell_success() public {
        address ALICE = makeAddr("Alice");
        initSwapFromSwapRouter(10 ether, ALICE);
        uint256 amountMemeIn = 10000000 ether;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(memeToken),
            tokenOut: WETH9,
            fee: Constant.UNI_LP_SWAPFEE,
            recipient: ALICE,
            amountIn: amountMemeIn,
            amountOutMinimum: 0,
            // SqrtPrice for Auction step 24 (assuming we ended the auction at step 23)
            sqrtPriceLimitX96: 0
        });
        startHoax(ALICE);
        memeToken.approve(address(swapRouter), amountMemeIn);
        swapRouter.exactInputSingle(params);
        vm.stopPrank();

        uint256 beforeBal = memeToken.balanceOf(treasury);
        memeceptionBaseTest.collectFees(address(memeToken));
        assertEq(memeToken.balanceOf(treasury), beforeBal + 29700000000000000000000, "treasuryBalance");
    }

    function test_collectFee_fail_paused() public {
        initSwapFromSwapRouter(amountIn, address(this));
        vm.startPrank(memeceptionBaseTest.MULTISIG());
        memeception.setPaused(true);
        vm.stopPrank();

        vm.expectRevert(Paused.selector);
        memeception.collectFees(address(memeToken));
    }
}
