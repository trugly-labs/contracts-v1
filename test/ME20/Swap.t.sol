/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {ISwapRouter} from "../utils/ISwapRouter.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract SwapTest is DeployersME20 {
    address ALICE;

    uint256 initTreasuryBal;
    uint256 initCreatorBal;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBuyMemecoin(createMemeParams.targetETH);

        ALICE = makeAddr("Alice");

        initTreasuryBal = memeToken.balanceOf(treasury);
        initCreatorBal = memeToken.balanceOf(MEMECREATOR);
    }

    function test_swap_buy_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 22477341389728096676707, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 35963746223564954682732, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 4437027190332326283982147, "aliceBalance");
    }

    function test_swap_sell_no_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);
        uint256 amountIn = 4437027190332326283982147;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(memeToken),
            tokenOut: WETH9,
            fee: Constant.UNI_LP_SWAPFEE,
            recipient: ALICE,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // SqrtPrice for Auction step 24 (assuming we ended the auction at step 23)
            sqrtPriceLimitX96: 0
        });
        startHoax(ALICE);
        MEME20(memeToken).approve(address(swapRouter), amountIn);

        initTreasuryBal = memeToken.balanceOf(treasury);
        initCreatorBal = memeToken.balanceOf(MEMECREATOR);
        swapRouter.exactInputSingle(params);
        vm.stopPrank();

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 0, "aliceBalance");
    }

    function test_swap_fee_twice_success() public {
        address BOB = makeAddr("bob");
        initSwapFromSwapRouter(10 ether, ALICE);
        initSwapFromSwapRouter(10 ether, BOB);

        assertEq(memeToken.balanceOf(treasury), 15099786096256684491535744, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), 24159657754010695186457191, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 2211831325301204819275676924, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 733334450099864699353481192, "bobBalance");
    }

    function test_swap_exempt_treasury_success() public {
        initSwapFromSwapRouter(10 ether, treasury);
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 2240963855421686746986501442, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
    }

    function test_swap_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        initSwapFromSwapRouter(10 ether, memeceptionAddr);
        assertEq(
            memeToken.balanceOf(memeceptionAddr), initialBalance + 2240963855421686746986501442, "memeceptionBalance"
        );
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
    }

    function test_swap_pool_to_router() public {
        address pool = memeceptionBaseTest.memeceptionContract().getMemeception(address(memeToken)).pool;
        uint256 initialBalance = memeToken.balanceOf(pool);
        initSwapFromSwapRouter(10 ether, pool);
        assertEq(memeToken.balanceOf(pool), initialBalance, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
    }

    function test_swap_creator_zero_fee() public {
        hoax(MEMECREATOR);
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 22477341389728096676707, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 4472990936555891238664879, "aliceBalance");
    }

    function test_swap_protocol_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 35963746223564954682732, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 4459504531722054380658854, "aliceBalance");
    }

    function test_swap_both_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        hoax(MEMECREATOR);
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 4495468277945619335341586, "aliceBalance");
    }

    function test_swap_buy_fee_change_address() public {
        hoax(MEMECREATOR);
        memeToken.setCreatorAddress(makeAddr("newCreator"));

        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setTreasuryAddress(makeAddr("newTreasury"));

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(makeAddr("newTreasury")), 22477341389728096676707, "treasuryBalance");
        assertEq(memeToken.balanceOf(makeAddr("newCreator")), 35963746223564954682732, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 4437027190332326283982147, "aliceBalance");
    }
}
