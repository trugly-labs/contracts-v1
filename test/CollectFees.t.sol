/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract CollectFees is Deployers {
    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initFullBid(MAX_BID_AMOUNT);

        bytes memory commands = hex"0b000604";
        bytes[] memory inputs = new bytes[](4);
        inputs[0] =
            hex"000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000014d1120d7b160000";
        inputs[1] =
            hex"000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000014d1120d7b160000000000000000000000000000000000000000000020b64f99b7956fab772a8f8400000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2002710b9f599ce614feb2e1bbe58f180f370d05b39344e000000000000000000000000000000000000000000";
        inputs[2] =
            hex"000000000000000000000000b9f599ce614feb2e1bbe58f180f370d05b39344e00000000000000000000000017cc6042605381c158d2adab487434bde79aa61c0000000000000000000000000000000000000000000000000000000000000064";
        inputs[3] =
            hex"000000000000000000000000b9f599ce614feb2e1bbe58f180f370d05b39344e0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000020b64f99b7956fab772a8f84";
        uint256 deadline = 1708664855;

        uint256 amount = 1.5 ether;
        routerBaseTest.router().execute{value: amount}(commands, inputs, deadline);
    }

    function test_collectFees_success() public {
        // memeceptionBaseTest.collectFees(uint256 );
    }

    function test_collectFees_success_no_fees() public {
        // memeceptionBaseTest.collectFees(uint256 );
    }

    function test_collectFees_fail_no_meme_address() public {
        // memeceptionBaseTest.collectFees(uint256 );
    }

    function test_collectFees_fail_no_owner() public {
        vm.expectRevert("UNAUTHORIZED");
        memeception.collectFees(address(memeToken));
    }
}
