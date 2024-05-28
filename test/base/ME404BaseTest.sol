/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {ITruglyMemeception} from "../../src/interfaces/ITruglyMemeception.sol";
import {IUniswapV3Pool} from "../../src/interfaces/external/IUniswapV3Pool.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";
import {ME20BaseTest} from "./ME20BaseTest.sol";
import {MEME404} from "../../src/types/MEME404.sol";
import {MEME721} from "../../src/types/MEME721.sol";
import {MEME1155} from "../../src/types/MEME1155.sol";
import {MockMEME404} from "../mock/MockMEME404.sol";
import {MockMEME721} from "../mock/MockMEME721.sol";

contract ME404BaseTest is ME20BaseTest {
    using FixedPointMathLib for uint256;

    MockMEME404 public meme404;
    MEME1155 public meme1155;
    MockMEME721 public meme721;

    MEME404.TierCreateParam[] public tierParams;

    constructor(address _vesting, address _treasury, address _mockFactory)
        ME20BaseTest(_vesting, _treasury, _mockFactory)
    {}

    function createMeme404(
        ITruglyMemeception.MemeceptionCreationParams memory params,
        MEME404.TierCreateParam[] memory _tierParams
    ) public returns (address meme404Addr, address pool) {
        delete tierParams;
        for (uint256 i = 0; i < _tierParams.length; i++) {
            tierParams.push(_tierParams[i]);
        }
        (meme404Addr, pool) = memeceptionContract.createMeme404(params, _tierParams);
        MEMECREATOR = params.creator;

        uint256 startAt = params.startAt > block.timestamp ? params.startAt : block.timestamp;

        /// Assert Token Creation
        meme404 = MockMEME404(meme404Addr);
        meme1155 = MEME1155(meme404.getTier(0).nft);
        meme721 = MockMEME721(meme404.getTier(_tierParams.length - 1).nft);
        uint256 vestingAllocSupply = MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(params.vestingAllocBps, 1e4);
        assertTrue(address(meme404) > address(WETH9), "meme404Addr > WETH9");
        assertEq(meme404.name(), params.name, "memeName");
        assertEq(meme404.decimals(), MEME20Constant.TOKEN_DECIMALS, "memeDecimals");
        assertEq(meme404.symbol(), params.symbol, "memeSymbol");
        assertEq(meme404.totalSupply(), MEME20Constant.TOKEN_TOTAL_SUPPLY, "memeSupply");
        assertEq(meme404.creator(), MEMECREATOR, "creator");
        assertEq(
            meme404.balanceOf(address(memeceptionContract)),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(10000 - Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4),
            "memeSupplyMinted"
        );
        assertEq(
            meme404.balanceOf(address(0)),
            MEME20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(Constant.CREATOR_MAX_VESTED_ALLOC_BPS, 1e4) - vestingAllocSupply,
            "memeSupplyBurned"
        );

        /// Assert Memeception Creation
        ITruglyMemeception.Memeception memory memeception = memeceptionContract.getMemeception(meme404Addr);
        assertEq(memeception.targetETH, params.targetETH, "memeception.targetETH");
        assertEq(memeception.collectedETH, 0, "memeception.collectedETH");
        assertEq(memeception.tokenId, 0, "memeception.tokenId");
        assertNotEq(memeception.pool, address(0), "memeception.tokenId");
        assertEq(memeception.swapFeeBps, params.swapFeeBps, "memeception.swapFeeBps");
        assertEq(memeception.creator, MEMECREATOR, "memeception.creator");
        assertEq(memeception.startAt, startAt, "memeception.startAt");
        assertEq(memeception.endedAt, 0, "memeception.endedAt");

        /// Assert Uniswap V3 Pool
        assertEq(IUniswapV3Pool(pool).fee(), Constant.UNI_LP_SWAPFEE, "v3Pool.fee");
        if (WETH9 < meme404Addr) {
            assertEq(IUniswapV3Pool(pool).token0(), WETH9, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), meme404Addr, "v3Pool.token1");
        } else {
            assertEq(IUniswapV3Pool(pool).token0(), meme404Addr, "v3Pool.token0");
            assertEq(IUniswapV3Pool(pool).token1(), WETH9, "v3Pool.token1");
        }

        /// Assert Vesting Contract
        assertEq(
            meme404.balanceOf(address(memeceptionContract.vesting())),
            params.vestingAllocBps == 0 ? 0 : vestingAllocSupply,
            "vestingAllocSupply"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(meme404)).totalAllocation,
            params.vestingAllocBps == 0 ? 0 : vestingAllocSupply,
            "Vesting.totalAllocation"
        );
        assertEq(memeceptionContract.vesting().getVestingInfo(address(meme404)).released, 0, "Vesting.released");
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(meme404)).start,
            params.vestingAllocBps == 0 ? 0 : startAt,
            "Vesting.start"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(meme404)).duration,
            params.vestingAllocBps == 0 ? 0 : Constant.VESTING_DURATION,
            "Vesting.duration"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(meme404)).cliff,
            params.vestingAllocBps == 0 ? 0 : Constant.VESTING_CLIFF,
            "Vesting.cliff"
        );
        assertEq(
            memeceptionContract.vesting().getVestingInfo(address(meme404)).creator,
            params.vestingAllocBps == 0 ? address(0) : MEMECREATOR,
            "Vesting.creator"
        );

        assertEq(memeceptionContract.vesting().releasable(address(meme404)), 0, "Vesting.releasable");
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(block.timestamp)),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(startAt + Constant.VESTING_CLIFF - 1)),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(startAt + 91.25 days)),
            vestingAllocSupply / 8,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(startAt + 365 days)),
            vestingAllocSupply / 2,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(startAt + 365 days * 2)),
            vestingAllocSupply,
            "Vesting.vestedAmount"
        );
    }

    function _checkERC1155Received(address _contract, address _operator, address _from, uint256 _id, uint256 _value)
        internal
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC1155TokenReceiver(_contract).onERC1155Received.selector, _operator, _from, _id, _value, ""
        );

        (bool success, bytes memory returnData) = _contract.call(callData);

        // Check both call success and return value
        if (success && returnData.length >= 32) {
            // Make sure there is enough data to cover a `bytes4` return
            bytes4 returned = abi.decode(returnData, (bytes4));
            return returned == ERC1155TokenReceiver.onERC1155Received.selector;
        }

        return false;
    }
}
