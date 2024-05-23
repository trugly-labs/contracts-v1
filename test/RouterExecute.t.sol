// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "./utils/DeployersME20.sol";
import {RouterBaseTest} from "./base/RouterBaseTest.sol";

contract TruglyUniversalRouterExecuteTest is DeployersME20 {
    /// @notice Test the execute function for a V3 Swap In with creator fees
    /// @dev From this TX: https://basescan.org/tx/0x76967c6c9f233537748b1869fbcd42af3f21a214c0c789c2cc321efaec4b3f97
    function test_execute_creator_success() public {
        (
            bytes memory commands,
            bytes[] memory inputs,
            uint256 deadline,
            uint256 amount,
            RouterBaseTest.ExpectedBalances memory expectedBalances
        ) = initSwapParams();
        routerBaseTest.execute{value: amount}(commands, inputs, deadline, expectedBalances);
    }
}
