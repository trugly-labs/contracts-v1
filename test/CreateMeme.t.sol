/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Deployers} from "./utils/Deployers.sol";

contract CreateMemeTest is Deployers {
    function test_createMeme_success() public {
        createMemeParams.startAt = uint64(block.timestamp) + 3 days;
        launchpadBaseTest.createMeme(createMemeParams);
    }
}
