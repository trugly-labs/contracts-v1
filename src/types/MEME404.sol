/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC1155} from "@solmate/tokens/ERC1155.sol";

import {MEME1155} from "./MEME1155.sol";
import {MEMERC20Constant} from "../libraries/MEMERC20Constant.sol";

contract MEME404 is ERC20 {
    error NoRanks();
    error MismatchLength();

    address public creator;
    MEME1155 public nft;

    mapping(uint256 => uint256) public ranks;
    uint256 public rankCount;

    constructor(
        string memory _name,
        string memory _symbol,
        address _creator,
        uint256[] memory _ranks,
        string[] memory _uris
    ) ERC20(_name, _symbol, MEMERC20Constant.TOKEN_DECIMALS) {
        if (_ranks.length == 0) revert NoRanks();
        if (_ranks.length != _uris.length) revert MismatchLength();

        _mint(msg.sender, MEMERC20Constant.TOKEN_TOTAL_SUPPLY);
        creator = _creator;

        for (uint256 i = 0; i < _ranks.length; i++) {
            ranks[i] = _ranks[i];
        }
        rankCount = _ranks.length;

        nft = new MEME1155(_uris, _creator);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        int256 rankBeforeSender = _getRank(msg.sender);
        int256 rankBeforeRecipient = _getRank(to);
        bool success = super.transfer(to, amount);
        int256 rankAfterSender = _getRank(msg.sender);
        int256 rankAfterRecipient = _getRank(to);

        if (rankBeforeSender != rankAfterSender) {
            _burnForEligibleRanks(msg.sender, rankBeforeSender);
            _mintForEligibleRanks(msg.sender, rankAfterSender);
        }

        if (rankBeforeRecipient != rankAfterRecipient) {
            _burnForEligibleRanks(to, rankBeforeRecipient);
            _mintForEligibleRanks(to, rankAfterRecipient);
        }

        return success;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        int256 rankBeforeSender = _getRank(msg.sender);
        int256 rankBeforeRecipient = _getRank(to);
        bool success = super.transferFrom(from, to, amount);

        int256 rankAfterSender = _getRank(msg.sender);
        int256 rankAfterRecipient = _getRank(to);

        if (rankBeforeSender != rankAfterSender) {
            _burnForEligibleRanks(msg.sender, rankBeforeSender);
            _mintForEligibleRanks(msg.sender, rankAfterSender);
        }

        if (rankBeforeRecipient != rankAfterRecipient) {
            _burnForEligibleRanks(to, rankBeforeRecipient);
            _mintForEligibleRanks(to, rankAfterRecipient);
        }

        return success;
    }

    function _mintForEligibleRanks(address _owner, int256 rank) internal {
        if (rank < 0 || nft.balanceOf(_owner, uint256(rank)) >= 1) return;
        nft.mint(_owner, uint256(rank), 1, "");
    }

    function _burnForEligibleRanks(address _owner, int256 rank) internal {
        if (rank < 0 || nft.balanceOf(_owner, uint256(rank)) == 0) return;
        nft.burn(_owner, uint256(rank), 1);
    }

    function _getRank(address _owner) internal view returns (int256) {
        uint256 balance = balanceOf[_owner];
        for (uint256 i = rankCount - 1; i >= 0; i--) {
            if (balance >= ranks[i]) {
                return int256(i);
            }
            if (i == 0) return -1;
        }
        return -1;
    }
}