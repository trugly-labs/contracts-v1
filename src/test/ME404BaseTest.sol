/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";
import {ITruglyMemeception} from "../interfaces/ITruglyMemeception.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {Constant} from "../libraries/Constant.sol";
import {MEME20Constant} from "../libraries/MEME20Constant.sol";
import {Test, console2} from "forge-std/Test.sol";
import {ME20BaseTest} from "./ME20BaseTest.sol";
import {MEME404} from "../types/MEME404.sol";
import {MEME721} from "../types/MEME721.sol";
import {MEME1155} from "../types/MEME1155.sol";

contract ME404BaseTest is ME20BaseTest {
    using FixedPointMathLib for uint256;

    MEME404 public meme404;
    MEME1155 public meme1155;
    MEME721 public meme721;

    MEME404.TierCreateParam[] public tierParams;

    constructor(address _vesting, address _treasury) ME20BaseTest(_vesting, _treasury) {}

    struct Balances404 {
        /// memecoin balances
        uint256 balCoin;
        /// nft balances
        uint256 balEliteNFT;
        uint256 eliteNFTId;
    }

    struct NFTData {
        uint256 curIndexHighestTier;
        uint256 curIndexSecondHighestTier;
        uint256 nextBurnIdHighestTier;
        uint256 nextBurnIdSecondHighestTier;
    }

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

        /// Assert Token Creation
        meme404 = MEME404(meme404Addr);
        meme1155 = MEME1155(meme404.getTier(0).nft);
        meme721 = MEME721(meme404.getTier(_tierParams.length - 1).nft);
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
        assertEq(memeception.auctionTokenSold, 0, "memeception.auctionTokenSold");
        assertEq(memeception.auctionFinalPriceScaled, 0, "memeception.auctionFinalPrice");
        assertEq(memeception.creator, MEMECREATOR, "memeception.creator");
        assertEq(memeception.startAt, params.startAt, "memeception.startAt");
        assertEq(memeception.swapFeeBps, params.swapFeeBps, "memeception.swapFeeBps");

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
            params.vestingAllocBps == 0 ? 0 : params.startAt,
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
            memeceptionContract.vesting().vestedAmount(
                address(meme404), uint64(params.startAt + Constant.VESTING_CLIFF - 1)
            ),
            0,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(params.startAt + 91.25 days)),
            vestingAllocSupply / 8,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(params.startAt + 365 days)),
            vestingAllocSupply / 2,
            "Vesting.vestedAmount"
        );
        assertEq(
            memeceptionContract.vesting().vestedAmount(address(meme404), uint64(params.startAt + 365 days * 2)),
            vestingAllocSupply,
            "Vesting.vestedAmount"
        );
    }

    function transfer404(address from, address to, uint256 amount, bool fundFrom) public {
        if (fundFrom == true) {
            meme404.transfer(from, amount);
        }
        Balances404 memory beforeBalFrom = _getBalances404(from);
        Balances404 memory beforeBalTo = _getBalances404(to);
        NFTData memory beforeNFTData = _getNFTData();

        hoax(from);
        meme404.transfer(to, amount);
        Balances404 memory afterBalFrom = _getBalances404(from);
        Balances404 memory afterBalTo = _getBalances404(to);
        NFTData memory afterNFTData = _getNFTData();

        _assertMemecoins(beforeBalFrom, beforeBalTo, afterBalFrom, afterBalTo, amount);

        _assertNFT(from, afterBalFrom);
        _assertNFT(to, afterBalTo);
        _assertEliteNFT(from, beforeBalFrom, afterBalFrom, beforeBalTo, afterBalTo, beforeNFTData, afterNFTData);
    }

    function transferFrom404(address from, address to, uint256 amount, bool fundFrom) public {
        if (fundFrom == true) {
            meme404.transfer(from, amount);
        }
        Balances404 memory beforeBalFrom = _getBalances404(from);
        Balances404 memory beforeBalTo = _getBalances404(to);
        NFTData memory beforeNFTData = _getNFTData();

        meme404.transferFrom(from, to, amount);
        Balances404 memory afterBalFrom = _getBalances404(from);
        Balances404 memory afterBalTo = _getBalances404(to);
        NFTData memory afterNFTData = _getNFTData();

        _assertMemecoins(beforeBalFrom, beforeBalTo, afterBalFrom, afterBalTo, amount);

        _assertNFT(from, afterBalFrom);
        _assertNFT(to, afterBalTo);
        _assertEliteNFT(from, beforeBalFrom, afterBalFrom, beforeBalTo, afterBalTo, beforeNFTData, afterNFTData);
    }

    function _assertEliteNFT(
        address from,
        Balances404 memory beforeBalFrom,
        Balances404 memory afterBalFrom,
        Balances404 memory beforeBalTo,
        Balances404 memory afterBalTo,
        NFTData memory beforeNFTData,
        NFTData memory afterNFTData
    ) internal {
        bool expectBurnHighestTierFrom = false;
        bool expectBurnSecondHighestTierFrom = false;
        bool expectMintSecondHighestTierFrom = false;
        /// Scenario 1 Highest Tier
        if (beforeBalFrom.balCoin >= tierParams[tierParams.length - 1].amountThreshold) {
            /// Scenario 1.1: Highest Tier -> Highest Tier
            if (afterBalFrom.balCoin >= tierParams[tierParams.length - 1].amountThreshold) {
                assertEq(afterBalFrom.balEliteNFT, 1, "assertEliteNFT - #1");
                assertEq(afterBalFrom.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFT - #2");
                assertEq(meme721.ownerOf(beforeBalFrom.eliteNFTId), from, "assertEliteNFT - #2.2");
            } else {
                /// Scenario 1.2: Highest Tier -> 2nd Tier
                if (afterBalFrom.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                    assertEq(afterBalFrom.balEliteNFT, 1, "assertEliteNFT - #3");

                    if (
                        beforeBalTo.balCoin >= tierParams[tierParams.length - 2].amountThreshold
                            && afterBalTo.balCoin >= tierParams[tierParams.length - 1].amountThreshold
                    ) {
                        // Scenario 1.2.1: Recipient has 2nd Highest Tier Burn
                        assertEq(afterBalFrom.eliteNFTId, beforeBalTo.eliteNFTId, "assertEliteNFT - #1,2,1");
                        assertEq(meme721.ownerOf(beforeBalTo.eliteNFTId), from, "assertEliteNFT - #1.2.3");
                    } else {
                        // Scenario 1.2.2: Recipient has no 2nd Highest Tier Burn
                        assertEq(
                            afterBalFrom.eliteNFTId,
                            beforeNFTData.curIndexSecondHighestTier,
                            "assertEliteNFT - #1.2.2.1"
                        );
                        assertEq(
                            meme721.tokenIdByOwner(from),
                            beforeNFTData.curIndexSecondHighestTier,
                            "assertEliteNFT - #1.2.2.2"
                        );
                        assertEq(meme721.ownerOf(afterBalFrom.eliteNFTId), from, "assertEliteNFT - #1.2.2.3");
                    }
                    expectBurnHighestTierFrom = true;
                    expectMintSecondHighestTierFrom = true;
                }

                /// Scenario 1.3: Highest Tier -> Fungible Tier or 0
                if (afterBalFrom.balCoin < tierParams[tierParams.length - 2].amountThreshold) {
                    assertEq(afterBalFrom.balEliteNFT, 0, "assertEliteNFT - #6");
                    assertEq(afterBalFrom.eliteNFTId, 0, "assertEliteNFT - #7");
                    expectBurnHighestTierFrom = true;
                }
            }

            _assertEliteNFTTo(
                beforeBalFrom,
                beforeBalTo,
                afterBalTo,
                beforeNFTData,
                afterNFTData,
                expectBurnHighestTierFrom,
                expectBurnSecondHighestTierFrom,
                expectMintSecondHighestTierFrom
            );
            return;
        }

        /// Scenario 2: 2nd tier
        if (beforeBalFrom.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
            /// Scenario 2.1 : 2nd tier -> 2nd Tier
            if (afterBalFrom.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                assertEq(afterBalFrom.balEliteNFT, 1, "assertEliteNFT - #8");
                assertEq(afterBalFrom.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFT - #9");
            } else {
                /// Scenario 2.1 : 2nd tier -> Fungible Tier or 0
                assertEq(afterBalFrom.balEliteNFT, 0, "assertEliteNFT - #10");
                assertEq(afterBalFrom.eliteNFTId, 0, "assertEliteNFT - #11");
                expectBurnSecondHighestTierFrom = true;
            }

            _assertEliteNFTTo(
                beforeBalFrom,
                beforeBalTo,
                afterBalTo,
                beforeNFTData,
                afterNFTData,
                expectBurnHighestTierFrom,
                expectBurnSecondHighestTierFrom,
                expectMintSecondHighestTierFrom
            );
            return;
        }

        /// Scenario 3: Fungible Tier or 0
        if (beforeBalFrom.balCoin < tierParams[tierParams.length - 2].amountThreshold) {
            // Assert From
            assertEq(beforeBalFrom.eliteNFTId, 0, "assertEliteNFT - eliteNFTId 0");
            assertEq(beforeBalFrom.balEliteNFT, 0, "assertEliteNFT - balEliteNFT 0");

            _assertEliteNFTTo(
                beforeBalFrom,
                beforeBalTo,
                afterBalTo,
                beforeNFTData,
                afterNFTData,
                expectBurnHighestTierFrom,
                expectBurnSecondHighestTierFrom,
                expectMintSecondHighestTierFrom
            );
            return;
        }
    }

    function _assertEliteNFTTo(
        Balances404 memory beforeBalFrom,
        Balances404 memory beforeBalTo,
        Balances404 memory afterBalTo,
        NFTData memory beforeNFTData,
        NFTData memory afterNFTData,
        bool expectBurnHighestTierFrom,
        bool expectBurnSecondHighestTierFrom,
        bool expectMintSecondHighestTierFrom
    ) internal {
        /// Recipient has no Highest Tier NFT
        if (beforeBalTo.balCoin < tierParams[tierParams.length - 1].amountThreshold) {
            if (afterBalTo.balCoin >= tierParams[tierParams.length - 1].amountThreshold) {
                /// Recipient now has a Highest Tier NFT
                if (expectBurnHighestTierFrom) {
                    // Expect Burn on Highest Tier
                    assertEq(afterBalTo.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #1");
                    assertEq(afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #2");
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier,
                        "assertEliteNFTTo #3"
                    );
                    assertEq(
                        afterNFTData.nextBurnIdHighestTier, beforeNFTData.nextBurnIdHighestTier, "assertEliteNFTTo #4"
                    );
                    if (beforeBalTo.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                        if (expectMintSecondHighestTierFrom) {
                            assertEq(
                                afterNFTData.nextBurnIdSecondHighestTier,
                                beforeNFTData.nextBurnIdSecondHighestTier,
                                "assertEliteNFTTo #4.2"
                            );
                        } else {
                            assertEq(
                                afterNFTData.nextBurnIdSecondHighestTier,
                                beforeBalTo.eliteNFTId,
                                "assertEliteNFTTo #4.1"
                            );
                        }
                    } else {
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier,
                            beforeNFTData.nextBurnIdSecondHighestTier,
                            "assertEliteNFTTo #5.1"
                        );
                    }
                } else {
                    // Expect No Burn on Highest Tier
                    assertEq(afterBalTo.eliteNFTId, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #6");
                    assertEq(
                        afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier + 1, "assertEliteNFTTo #7"
                    );
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier,
                        "assertEliteNFTTo #8"
                    );
                    assertEq(
                        afterNFTData.nextBurnIdHighestTier, beforeNFTData.nextBurnIdHighestTier, "assertEliteNFTTo #9"
                    );
                    if (beforeBalTo.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier, beforeBalTo.eliteNFTId, "assertEliteNFTTo #9.1"
                        );
                    } else {
                        if (expectBurnSecondHighestTierFrom) {
                            assertEq(
                                afterNFTData.nextBurnIdSecondHighestTier,
                                beforeBalFrom.eliteNFTId,
                                "assertEliteNFTTo #10"
                            );
                        } else {
                            assertEq(
                                afterNFTData.nextBurnIdSecondHighestTier,
                                beforeNFTData.nextBurnIdSecondHighestTier,
                                "assertEliteNFTTo #10.1"
                            );
                        }
                    }
                }
                return;
            }

            if (afterBalTo.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                /// Recipient now has a 2nd Highest Tier NFT
                if (expectBurnSecondHighestTierFrom) {
                    // Expect Burn on 2nd Highest Tier
                    if (beforeBalTo.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
                        assertEq(afterBalTo.eliteNFTId, beforeBalTo.eliteNFTId, "assertEliteNFTTo #11.1");
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #15.1"
                        );
                    } else {
                        assertEq(afterBalTo.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #11.2");
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier,
                            beforeNFTData.nextBurnIdSecondHighestTier,
                            "assertEliteNFTTo #15.2"
                        );
                    }
                    assertEq(
                        afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #12"
                    );
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier,
                        "assertEliteNFTTo #13"
                    );
                    assertEq(
                        afterNFTData.nextBurnIdHighestTier, beforeNFTData.nextBurnIdHighestTier, "assertEliteNFTTo #14"
                    );
                } else {
                    // Expect no Burn (From) on 2nd Highest Tier
                    assertEq(
                        afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #17"
                    );

                    if (expectMintSecondHighestTierFrom) {
                        assertEq(
                            afterBalTo.eliteNFTId, beforeNFTData.curIndexSecondHighestTier + 1, "assertEliteNFTTo #16"
                        );

                        assertEq(
                            afterNFTData.curIndexSecondHighestTier,
                            beforeNFTData.curIndexSecondHighestTier + 2,
                            "assertEliteNFTTo #18"
                        );
                    } else {
                        assertEq(afterBalTo.eliteNFTId, beforeNFTData.curIndexSecondHighestTier, "assertEliteNFTTo #16");
                        assertEq(
                            afterNFTData.curIndexSecondHighestTier,
                            beforeNFTData.curIndexSecondHighestTier + 1,
                            "assertEliteNFTTo #18"
                        );
                    }
                    assertEq(
                        afterNFTData.nextBurnIdSecondHighestTier,
                        beforeNFTData.nextBurnIdSecondHighestTier,
                        "assertEliteNFTTo #20"
                    );
                    if (expectBurnHighestTierFrom) {
                        assertEq(afterNFTData.nextBurnIdHighestTier, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #21");
                    } else {
                        assertEq(
                            afterNFTData.nextBurnIdHighestTier,
                            beforeNFTData.nextBurnIdHighestTier,
                            "assertEliteNFTTo #22"
                        );
                    }
                }
                return;
            }
            // Recipeint has either Fungible or 0
            if (afterBalTo.balCoin < tierParams[tierParams.length - 2].amountThreshold) {
                assertEq(afterBalTo.eliteNFTId, 0, "assertEliteNFTTo #23");
                assertEq(afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #24");

                if (expectMintSecondHighestTierFrom) {
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier + 1,
                        "assertEliteNFTTo #25"
                    );
                } else {
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier,
                        "assertEliteNFTTo #25.1"
                    );
                }
                if (expectBurnHighestTierFrom) {
                    assertEq(afterNFTData.nextBurnIdHighestTier, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #26");
                } else {
                    assertEq(
                        afterNFTData.nextBurnIdHighestTier, beforeNFTData.nextBurnIdHighestTier, "assertEliteNFTTo #27"
                    );
                }
                if (expectBurnSecondHighestTierFrom) {
                    assertEq(afterNFTData.nextBurnIdSecondHighestTier, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #28");
                } else {
                    assertEq(
                        afterNFTData.nextBurnIdSecondHighestTier,
                        beforeNFTData.nextBurnIdSecondHighestTier,
                        "assertEliteNFTTo #29"
                    );
                }
                return;
            }
        }
    }

    function _assertMemecoins(
        Balances404 memory beforeBalFrom,
        Balances404 memory beforeBalTo,
        Balances404 memory afterBalFrom,
        Balances404 memory afterBalTo,
        uint256 amount
    ) internal {
        /// Normal assert of balances
        assertEq(afterBalFrom.balCoin, beforeBalFrom.balCoin - amount, "[Transfer] from balance");
        assertEq(afterBalTo.balCoin, beforeBalTo.balCoin + amount, "[Transfer] to balance");
    }

    function _assertNFT(address account, Balances404 memory bal) internal {
        if (account.code.length != 0 && !_checkERC1155Received(account, msg.sender, address(0), 0, 1)) {
            for (uint256 i = 1; i <= tierParams.length - 1; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier -0] Balance ERC155");
            }
            return;
        }
        /// Check Balance of NFTs
        /// Assert Highest Tier
        if (bal.balCoin >= tierParams[tierParams.length - 1].amountThreshold) {
            /// Recipient
            assertEq(bal.balEliteNFT, 1, "[Transfer|Tier -1] Balance Elite NFT");
            for (uint256 i = 1; i <= tierParams.length - 2; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier -1] Balance ERC155");
            }
            return;
        }

        /// Assert 2nd Highest Tier
        if (bal.balCoin >= tierParams[tierParams.length - 2].amountThreshold) {
            /// Recipient
            assertEq(bal.balEliteNFT, 1, "[Transfer|Tier-2] Balance Elite NFT");
            for (uint256 i = 1; i <= tierParams.length - 2; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier-2] Balance ERC155");
            }
            return;
        }

        /// Assert lower tier
        for (uint256 i = tierParams.length - 2; i > 0; i--) {
            if (bal.balCoin >= tierParams[i - 1].amountThreshold) {
                assertEq(bal.balEliteNFT, 0, "[Transfer|Tier-n] Balance Elite NFT");
                assertEq(bal.eliteNFTId, 0, "[Transfer|Tier-n] elite NFT id");
                assertEq(meme1155.balanceOf(account, i), 1, "[Transfer|Tier-n] Balance ERC155");
                for (uint256 j = i - 1; j > 0; --j) {
                    assertEq(meme1155.balanceOf(account, j), 0, "[Transfer|Tier-n] Balance ERC155");
                }
                return;
            }
        }

        if (bal.balCoin == 0) {
            assertEq(bal.balEliteNFT, 0, "[Transfer|Tier-0] Balance Elite NFT");
            assertEq(bal.eliteNFTId, 0, "[Transfer|Tier-0] elite NFT id");

            for (uint256 i = 1; i <= tierParams.length - 1; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier -0] Balance ERC155");
            }
        }
    }

    function _getBalances404(address _account) internal view returns (Balances404 memory) {
        Balances404 memory balances;
        balances.balCoin = meme404.balanceOf(_account);
        balances.balEliteNFT = meme721.balanceOf(_account);
        balances.eliteNFTId = meme721.tokenIdByOwner(_account);
        return balances;
    }

    function _getNFTData() internal view returns (NFTData memory nftData) {
        MEME404.Tier memory highestTier = meme404.getTier(tierParams.length - 1);
        MEME404.Tier memory secondHighestTier = meme404.getTier(tierParams.length - 2);
        nftData.curIndexHighestTier = highestTier.curIndex;
        nftData.curIndexSecondHighestTier = secondHighestTier.curIndex;
        nftData.nextBurnIdHighestTier =
            highestTier.burnIds.length > 0 ? highestTier.burnIds[highestTier.burnIds.length - 1] : 0;
        nftData.nextBurnIdSecondHighestTier =
            secondHighestTier.burnIds.length > 0 ? secondHighestTier.burnIds[secondHighestTier.burnIds.length - 1] : 0;
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
