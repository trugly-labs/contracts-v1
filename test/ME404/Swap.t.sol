/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {MEME20} from "../../src/types/MEME20.sol";
import {ISwapRouter} from "../utils/ISwapRouter.sol";
import {DeployersME404} from "../utils/DeployersME404.sol";
import {Constant} from "../../src/libraries/Constant.sol";

contract SwapTest404 is DeployersME404 {
    address ALICE;

    uint256 initTreasuryBal;
    uint256 initCreatorBal;

    function setUp() public override {
        super.setUp();
        initCreateMeme404();
        initFullBid(10 ether);

        ALICE = makeAddr("Alice");

        initTreasuryBal = memeToken.balanceOf(treasury);
        initCreatorBal = memeToken.balanceOf(MEMECREATOR);
    }

    function test_swap_buy_fee_success() public {
        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 55871686075491953069537, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 223486744301967812278148, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27656484607368516769420862, "aliceBalance");
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

        initTreasuryBal = memeToken.balanceOf(treasury);
        initCreatorBal = memeToken.balanceOf(MEMECREATOR);
        swapRouter.exactInputSingle(params);
        vm.stopPrank();

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 17656484607368516769420862, "aliceBalance");
    }

    function test_swap_fee_twice_success() public {
        address BOB = makeAddr("bob");
        initSwapFromSwapRouter(10 ether, ALICE);
        initSwapFromSwapRouter(10 ether, BOB);

        assertEq(memeToken.balanceOf(treasury), 6695352279012269864561593, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), 26781409116049079458246375, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 3103147362449742906127151267, "aliceBalance");
        assertEq(memeToken.balanceOf(BOB), 182892015664146676830839191, "bobBalance");
    }

    function test_swap_exempt_treasury_success() public {
        initSwapFromSwapRouter(10 ether, treasury);
        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 3134492285302770612249647743, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
    }

    function test_swap_exempt_memeception_success() public {
        address memeceptionAddr = address(memeceptionBaseTest.memeceptionContract());
        uint256 initialBalance = memeToken.balanceOf(memeceptionAddr);
        initSwapFromSwapRouter(10 ether, memeceptionAddr);
        assertEq(
            memeToken.balanceOf(memeceptionAddr), initialBalance + 3134492285302770612249647743, "memeceptionBalance"
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

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal + 55871686075491953069537, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27879971351670484581699010, "aliceBalance");
    }

    function test_swap_protocol_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal + 223486744301967812278148, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27712356293444008722490399, "aliceBalance");
    }

    function test_swap_both_zero_fee() public {
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(0);

        hoax(MEMECREATOR);
        memeToken.setCreatorFeeBps(0);

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(treasury), initTreasuryBal, "treasuryBalance");
        assertEq(memeToken.balanceOf(MEMECREATOR), initCreatorBal, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27935843037745976534768547, "aliceBalance");
    }

    function test_swap_buy_fee_change_address() public {
        hoax(MEMECREATOR);
        memeToken.setCreatorAddress(makeAddr("newCreator"));

        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setTreasuryAddress(makeAddr("newTreasury"));

        initSwapFromSwapRouter(0.01 ether, ALICE);

        assertEq(memeToken.balanceOf(makeAddr("newTreasury")), 55871686075491953069537, "treasuryBalance");
        assertEq(memeToken.balanceOf(makeAddr("newCreator")), 223486744301967812278148, "creatorBalance");
        assertEq(memeToken.balanceOf(ALICE), 27656484607368516769420862, "aliceBalance");
    }
}
