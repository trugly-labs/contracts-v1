/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

contract TestHelpers is Test {
    function assertApproxEq(uint256 a, uint256 b, uint256 maxDelta, string memory reason) internal virtual {
        uint256 delta = a > b ? a - b : b - a;

        if (delta > maxDelta) {
            emit log(reason);
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqLow(uint256 a, uint256 b, uint256 maxDelta, string memory reason) internal virtual {
        if (b > a) {
            emit log(reason);
            emit log("assertApproxEqLow: b < a not satisfied");
            fail();
            return;
        }
        uint256 delta = a - b;

        if (delta > maxDelta) {
            emit log(reason);
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            emit log_named_uint(" Max Delta", maxDelta);
            emit log_named_uint("     Delta", delta);
            fail();
        }
    }
}
