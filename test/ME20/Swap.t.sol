/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {ISwapRouter} from "../utils/ISwapRouter.sol";
import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract SwapTest is DeployersME20 {
    address ALICE;

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(10 ether);

        ALICE = makeAddr("Alice");
    }

    function test_swap_buy_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), 54584665342955757900125, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 218338661371823031600500, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27019409344763100160561892, "aliceBalance");
    }

    function test_swap_sell_no_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);
        uint256 amountIn = 10000000 ether;
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
        swapRouter.exactInputSingle(params);
        vm.stopPrank();

        assertEq(memeToken.balanceOf(treasury), 54584665342955757900125, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 218338661371823031600500, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 17019409344763100160561892, "aliceBalance");
    }

    function test_swap_fee_twice_success() public {
        address BOB = makeAddr("bob");
        initSwapFromSwapRouter(10 ether, ALICE);
        initSwapFromSwapRouter(10 ether, BOB);

        assertEq(memeToken.balanceOf(treasury), 6679367737256003698082469, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 26717470949024014792329879, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3117039376019252004979161083, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 189247653922469825571661554, "bobBalance");
    }

    function test_swap_exempt_treasury_success() public {
        initSwapFromSwapRouter(10 ether, treasury);
        assertEq(memeToken.balanceOf(treasury), 3148524622241668691898142508, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
    }

    function test_swap_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        initSwapFromSwapRouter(10 ether, memeceptionAddr);
        assertEq(
            memeToken.balanceOf(memeceptionAddr), initialBalance + 3148524622241668691898142508, "memeceptionBalance"
        );
        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
    }

    function test_swap_pool_to_router() public {
        address pool = memeceptionBaseTest.memeceptionContract().getMemeception(address(memeToken)).pool;
        uint256 initialBalance = memeToken.balanceOf(pool);
        initSwapFromSwapRouter(10 ether, pool);
        assertEq(memeToken.balanceOf(pool), initialBalance, "memeceptionBalance");
        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
    }

    function test_swap_creator_zero_fee() public {
        hoax(address(memeceptionBaseTest));
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), 54584665342955757900125, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27237748006134923192162392, "aliceBalance");
    }

    function test_swap_protocol_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 218338661371823031600500, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27073994010106055918462017, "aliceBalance");
    }

    function test_swap_both_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        hoax(address(memeceptionBaseTest));
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), 0, "treasuryBalance");
        assertEq(memeToken.balanceOf(address(memeceptionBaseTest)), 0, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27292332671477878950062517, "aliceBalance");
    }

    function test_swap_buy_fee_change_address() public {
        hoax(address(memeceptionBaseTest));
        memeToken.setCreatorAddress(makeAddr("newCreator"));

        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setTreasuryAddress(makeAddr("newTreasury"));

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(makeAddr("newTreasury")), 54584665342955757900125, "treasuryBalance");
        assertEq(memeToken.balanceOf(makeAddr("newCreator")), 218338661371823031600500, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27019409344763100160561892, "aliceBalance");
    }
}
