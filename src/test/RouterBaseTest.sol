/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {RouterParameters} from "@uniswap/universal-router/base/RouterImmutables.sol";

import {Test, console2} from "forge-std/Test.sol";
import {MEMERC20} from "../types/MEMERC20.sol";
import {TruglyUniversalRouter} from "../TruglyUniversalRouter.sol";
import {DeploymentAddresses} from "./DeploymentAddresses.sol";

contract TruglyUniversalRouterBaseTest is Test, DeploymentAddresses {
    TruglyUniversalRouter router;
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
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
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
            routerRewardsDistributor: 0xea37093ce161f090e443f304e1bF3a8f14D7bb40,
            looksRareRewardsDistributor: unsupported,
            looksRareToken: unsupported,
            v2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            v3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
            pairInitCodeHash: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f,
            poolInitCodeHash: 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54
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
        return MEMERC20(token).balanceOf(account);
    }

    /// @notice receive native tokens
    receive() external payable {}
}
