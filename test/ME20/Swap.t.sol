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

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 19979859013091641490321, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 31967774420946626384513, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3944024169184290030189393, "aliceBalance");
    }

    function test_swap_sell_no_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);
        uint256 amountIn = 3944024169184290030189393;
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

        assertEq(memeToken.balanceOf(treasury), 13422032085561497325869369, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), 21475251336898395721390991, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 1966072289156626505880925896, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 651852844533213066245700573, "bobBalance");
    }

    function test_swap_exempt_treasury_success() public {
        initSwapFromSwapRouter(10 ether, treasury);
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 1991967871485943774955345385, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
    }

    function test_swap_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        initSwapFromSwapRouter(10 ether, memeceptionAddr);
        assertEq(
            memeToken.balanceOf(memeceptionAddr), initialBalance + 1991967871485943774955345385, "memeceptionBalance"
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

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 19979859013091641490321, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3975991943605236656573906, "aliceBalance");
    }

    function test_swap_protocol_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 31967774420946626384513, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3964004028197381671679714, "aliceBalance");
    }

    function test_swap_both_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        hoax(MEMECREATOR);
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3995971802618328298064227, "aliceBalance");
    }

    function test_swap_buy_fee_change_address() public {
        hoax(MEMECREATOR);
        memeToken.setCreatorAddress(makeAddr("newCreator"));

        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setTreasuryAddress(makeAddr("newTreasury"));

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(makeAddr("newTreasury")), 19979859013091641490321, "treasuryBalance");
        assertEq(memeToken.balanceOf(makeAddr("newCreator")), 31967774420946626384513, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3944024169184290030189393, "aliceBalance");
    }
}
