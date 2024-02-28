/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyLaunchpad} from "../TruglyLaunchpad.sol";
import {ITruglyLaunchpad} from "../interfaces/ITruglyLaunchpad.sol";

contract MockTruglyLaunchpad is TruglyLaunchpad {
    constructor(address _v3Factory, address _v3PositionManager, address _WETH9, address _memeSigner)
        TruglyLaunchpad(_v3Factory, _v3PositionManager, _WETH9, _memeSigner)
    {}

    function _verifyDeposit(address memeToken, bytes calldata sig) internal view override {
        sig;
        ITruglyLaunchpad.Memeception memory memeception = this.getMemeception(memeToken);
        if (msg.value == 0) revert ZeroAmount();
        if (memeception.cap > 0 && memeception.balance >= memeception.cap) revert MemeLaunched();
        if (block.timestamp < memeception.startAt || block.timestamp > memeception.startAt + MEMECEPTION_DEADLINE) {
            revert InvalidMemeceptionDate();
        }
        if (balanceOG[memeToken][msg.sender] > 0) revert DuplicateOG();
    }
}
