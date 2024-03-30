/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract CollectFees is Deployers {
    function setUp() public override {
        super.setUp();
        initCreateMeme();
    }

    function test_collectFees_success() public {
        initFullBid(MAX_BID_AMOUNT);
        // memeceptionBaseTest.collectFees(uint256 );
    }

    function test_collectFees_success_no_fees() public {
        // memeceptionBaseTest.collectFees(address(memeToken));
    }

    function test_collectFees_fail_invalid_meme_address() public {
        // memeceptionBaseTest.collectFees(address(1));
    }

    function test_collectFees_fail_no_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        memeception.collectFees(address(memeToken));
    }
}
