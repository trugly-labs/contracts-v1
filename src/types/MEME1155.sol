/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC1155} from "@solmate/tokens/ERC1155.sol";
import {MEME20Constant} from "../libraries/MEME20Constant.sol";

contract MEME1155 is ERC1155 {
    error TransferMemecoinsInstead();

    address public creator;
    address public memecoin;
    mapping(uint256 => string) public uris;

    constructor(string[] memory _uris, address _creator) {
        creator = _creator;
        for (uint256 i = 0; i < _uris.length; i++) {
            uris[i] = _uris[i];
        }
        memecoin = msg.sender;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)
        public
        override
    {
        revert TransferMemecoinsInstead();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        revert TransferMemecoinsInstead();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        require(msg.sender == memecoin, "MEME1155: Only memecoin can mint");
        _mint(account, id, amount, data);
    }

    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == memecoin, "MEME1155: Only memecoin can burn");
        _burn(account, id, amount);
    }
}
