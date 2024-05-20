/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {TruglyMemeception} from "../../src/TruglyMemeception.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {MockMEME404} from "./MockMEME404.sol";

contract MockTruglyMemeception is TruglyMemeception {
    constructor(
        address _v3Factory,
        address _v3PositionManager,
        address _uncxLockers,
        address _WETH9,
        address _vesting,
        address _treasury,
        address _multisig
    ) TruglyMemeception(_v3Factory, _v3PositionManager, _uncxLockers, _WETH9, _vesting, _treasury, _multisig) {}

    function createMeme404(MemeceptionCreationParams calldata params, MEME404.TierCreateParam[] calldata tiers)
        external
        override
        nonReentrant
        returns (address, address)
    {
        _verifyCreateMeme(params);
        MockMEME404 memeToken = new MockMEME404{salt: params.salt}(params.name, params.symbol, params.creator);
        address pool = v3Factory.createPool(address(WETH9), address(memeToken), Constant.UNI_LP_SWAPFEE);

        /// List of exempt addresses for MEME404 NFT minting
        address[] memory exemptNFTMint = new address[](7);
        exemptNFTMint[0] = address(this);
        exemptNFTMint[1] = address(vesting);
        exemptNFTMint[2] = address(v3PositionManager);
        exemptNFTMint[3] = address(treasury);
        exemptNFTMint[4] = pool;
        exemptNFTMint[5] = params.creator;
        exemptNFTMint[6] = Constant.UNCX_TREASURY;
        memeToken.initializeTiers(tiers, exemptNFTMint);

        _createMeme(params, memeToken, pool);
        emit Meme404Created(
            address(memeToken),
            params.creator,
            params.symbol,
            pool,
            params.startAt,
            params.swapFeeBps,
            params.vestingAllocBps,
            tiers
        );
        return (address(memeToken), pool);
    }
}
