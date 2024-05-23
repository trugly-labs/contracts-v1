/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {RouterParameters} from "@trugly-labs/universal-router-fork/base/RouterImmutables.sol";
import {Test, console2} from "forge-std/Test.sol";

import {MEME20} from "../../src/types/MEME20.sol";
import {TruglyUniversalRouter} from "../../src/TruglyUniversalRouter.sol";
import {BaseParameters} from "../../script/parameters/Base.sol";

contract RouterBaseTest is Test, BaseParameters {
    TruglyUniversalRouter public router;
    address public treasury = 0x0804a74CB85d6bE474a4498fCe76481822AdFFa4;

    struct ExpectedBalances {
        address token0;
        address token1;
        address creator;
        int256 userDelta0;
        int256 userDelta1;
        int256 treasuryDelta0;
        int256 treasuryDelta1;
        int256 creatorDelta0;
        int256 creatorDelta1;
    }

    struct Balances {
        uint256 userBalance0;
        uint256 userBalance1;
        uint256 treasuryBalance0;
        uint256 treasuryBalance1;
        uint256 creatorBalance0;
        uint256 creatorBalance1;
    }

    constructor() {
        address unsupported = 0x76D631990d505E4e5b432EEDB852A60897824D68;
        RouterParameters memory params = RouterParameters({
            permit2: PERMIT2,
            weth9: WETH9,
            seaportV1_5: unsupported,
            seaportV1_4: unsupported,
            openseaConduit: unsupported,
            nftxZap: unsupported,
            x2y2: unsupported,
            foundation: unsupported,
            sudoswap: unsupported,
            elementMarket: unsupported,
            nft20Zap: unsupported,
            cryptopunks: unsupported,
            looksRareV2: unsupported,
            routerRewardsDistributor: unsupported,
            looksRareRewardsDistributor: unsupported,
            looksRareToken: unsupported,
            v2Factory: unsupported,
            v3Factory: V3_FACTORY,
            pairInitCodeHash: ROUTER_PAIR_INIT_CODE_HASH,
            poolInitCodeHash: POOL_INIT_CODE_HASH
        });

        router = new TruglyUniversalRouter(params, treasury);
    }

    function execute(
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline,
        ExpectedBalances memory balances
    ) public payable {
        Balances memory beforeBalances = getBalances(balances);
        router.execute{value: msg.value}(commands, inputs, deadline);
        Balances memory afterBalances = getBalances(balances);

        assertEq(
            afterBalances.userBalance0,
            uint256(int256(beforeBalances.userBalance0) + balances.userDelta0),
            "userBalance0"
        );
        assertEq(
            afterBalances.userBalance1,
            uint256(int256(beforeBalances.userBalance1) + balances.userDelta1),
            "userBalance1"
        );
        assertEq(
            afterBalances.treasuryBalance0,
            uint256(int256(beforeBalances.treasuryBalance0) + balances.treasuryDelta0),
            "treasuryBalance0"
        );
        assertEq(
            afterBalances.treasuryBalance1,
            uint256(int256(beforeBalances.treasuryBalance1) + balances.treasuryDelta1),
            "treasuryBalance1"
        );
        assertEq(
            afterBalances.creatorBalance0,
            uint256(int256(beforeBalances.creatorBalance0) + balances.creatorDelta0),
            "creatorBalance0"
        );
        assertEq(
            afterBalances.creatorBalance1,
            uint256(int256(beforeBalances.creatorBalance1) + balances.creatorDelta1),
            "creatorBalance1"
        );
    }

    function getBalances(ExpectedBalances memory expectedBalances) public view returns (Balances memory) {
        return Balances({
            userBalance0: _getBalance(expectedBalances.token0, address(this)),
            userBalance1: _getBalance(expectedBalances.token1, address(this)),
            treasuryBalance0: _getBalance(expectedBalances.token0, treasury),
            treasuryBalance1: _getBalance(expectedBalances.token1, treasury),
            creatorBalance0: _getBalance(expectedBalances.token0, expectedBalances.creator),
            creatorBalance1: _getBalance(expectedBalances.token1, expectedBalances.creator)
        });
    }

    function _getBalance(address token, address account) internal view returns (uint256) {
        if (token == address(0)) return account.balance;
        return MEME20(token).balanceOf(account);
    }

    /// @notice receive native tokens
    receive() external payable {}
}
