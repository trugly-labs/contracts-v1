/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {MEME404} from "../types/MEME404.sol";
import {MEME721} from "../types/MEME721.sol";
import {MEME1155} from "../types/MEME1155.sol";

contract ME404BaseTest is Test {
    MEME404 public meme404;

    MEME1155 public meme1155;
    MEME721 public meme721;

    MEME404.TierCreateParam[] public params;
    address public CREATOR;

    constructor(string memory _name, string memory _symbol, address _creator, MEME404.TierCreateParam[] memory _tiers) {
        for (uint256 i = 0; i < _tiers.length; i++) {
            params.push(_tiers[i]);
        }
        meme404 = new MEME404(_name, _symbol, _creator, _tiers);
        CREATOR = _creator;

        meme1155 = MEME1155(meme404.getTier(0).nft);
        meme721 = MEME721(meme404.getTier(_tiers.length - 1).nft);
    }

    struct Balances {
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

    function transfer(address from, address to, uint256 amount) public {
        meme404.transfer(from, amount);
        Balances memory beforeBalFrom = _getBalances(from);
        Balances memory beforeBalTo = _getBalances(to);
        NFTData memory beforeNFTData = _getNFTData();

        hoax(from);
        meme404.transfer(to, amount);
        Balances memory afterBalFrom = _getBalances(from);
        Balances memory afterBalTo = _getBalances(to);
        NFTData memory afterNFTData = _getNFTData();

        _assertMemecoins(beforeBalFrom, beforeBalTo, afterBalFrom, afterBalTo, amount);

        _assertNFT(from, afterBalFrom);
        _assertNFT(to, afterBalTo);
        _assertEliteNFT(from, beforeBalFrom, afterBalFrom, beforeBalTo, afterBalTo, beforeNFTData, afterNFTData);
    }

    function _assertEliteNFT(
        address from,
        Balances memory beforeBalFrom,
        Balances memory afterBalFrom,
        Balances memory beforeBalTo,
        Balances memory afterBalTo,
        NFTData memory beforeNFTData,
        NFTData memory afterNFTData
    ) internal {
        bool expectBurnHighestTierFrom = false;
        bool expectBurnSecondHighestTierFrom = false;
        /// Scenario 1 Highest Tier
        if (beforeBalFrom.balCoin >= params[params.length - 1].amountThreshold) {
            /// Scenario 1.1: Highest Tier -> Highest Tier
            if (afterBalFrom.balCoin >= params[params.length - 1].amountThreshold) {
                assertEq(afterBalFrom.balEliteNFT, 1, "assertEliteNFT - #1");
                assertEq(afterBalFrom.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFT - #2");
                assertEq(meme721.ownerOf(beforeBalFrom.eliteNFTId), from, "assertEliteNFT - #2.2");
            } else {
                /// Scenario 1.2: Highest Tier -> 2nd Tier
                if (afterBalFrom.balCoin >= params[params.length - 2].amountThreshold) {
                    assertEq(afterBalFrom.balEliteNFT, 1, "assertEliteNFT - #3");

                    if (
                        beforeBalTo
                            // Scenario 1.2.1: Recipient has 2nd Highest Tier Burn
                            .balCoin >= params[params.length - 2].amountThreshold
                            && afterBalTo.balCoin >= params[params.length - 1].amountThreshold
                    ) {
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
                            meme721.nftIdByOwner(from),
                            beforeNFTData.curIndexSecondHighestTier,
                            "assertEliteNFT - #1.2.2.2"
                        );
                        assertEq(meme721.ownerOf(afterBalFrom.eliteNFTId), from, "assertEliteNFT - #1.2.2.3");
                    }
                    expectBurnHighestTierFrom = true;
                }

                /// Scenario 1.3: Highest Tier -> Fungible Tier or 0
                if (afterBalFrom.balCoin < params[params.length - 2].amountThreshold) {
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
                expectBurnSecondHighestTierFrom
            );
            return;
        }

        /// Scenario 2: 2nd tier
        if (beforeBalFrom.balCoin >= params[params.length - 2].amountThreshold) {
            /// Scenario 2.1 : 2nd tier -> 2nd Tier
            if (afterBalFrom.balCoin >= params[params.length - 2].amountThreshold) {
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
                expectBurnSecondHighestTierFrom
            );
            return;
        }

        /// Scenario 3: Fungible Tier o 0
        if (beforeBalFrom.balCoin < params[params.length - 2].amountThreshold) {
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
                expectBurnSecondHighestTierFrom
            );
            return;
        }
    }

    function _assertEliteNFTTo(
        Balances memory beforeBalFrom,
        Balances memory beforeBalTo,
        Balances memory afterBalTo,
        NFTData memory beforeNFTData,
        NFTData memory afterNFTData,
        bool expectBurnHighestTierFrom,
        bool expectBurnSecondHighestTierFrom
    ) internal {
        /// Recipient has no Highest Tier NFT
        if (beforeBalTo.balCoin < params[params.length - 1].amountThreshold) {
            if (afterBalTo.balCoin >= params[params.length - 1].amountThreshold) {
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
                    if (beforeBalTo.balCoin >= params[params.length - 2].amountThreshold) {
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier, beforeBalTo.eliteNFTId, "assertEliteNFTTo #4.1"
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
                                "assertEliteNFTTo #5"
                            );
                        }
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
                    if (beforeBalTo.balCoin >= params[params.length - 2].amountThreshold) {
                        assertEq(
                            afterNFTData.nextBurnIdSecondHighestTier, beforeBalTo.eliteNFTId, "assertEliteNFTTo #4.1"
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
                                "assertEliteNFTTo #10"
                            );
                        }
                    }
                }
                return;
            }
            if (afterBalTo.balCoin >= params[params.length - 2].amountThreshold) {
                /// Recipient now has a 2nd Highest Tier NFT
                if (expectBurnSecondHighestTierFrom) {
                    // Expect Burn on 2nd Highest Tier
                    assertEq(afterBalTo.eliteNFTId, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #11");
                    assertEq(
                        afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #12"
                    );
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier,
                        "assertEliteNFTTo #13"
                    );

                    assertEq(
                        afterNFTData.nextBurnIdSecondHighestTier,
                        beforeNFTData.nextBurnIdSecondHighestTier,
                        "assertEliteNFTTo #15"
                    );

                    if (expectBurnHighestTierFrom) {
                        assertEq(afterNFTData.nextBurnIdHighestTier, beforeBalFrom.eliteNFTId, "assertEliteNFTTo #14");
                    } else {
                        assertEq(
                            afterNFTData.nextBurnIdHighestTier,
                            beforeNFTData.nextBurnIdHighestTier,
                            "assertEliteNFTTo #14"
                        );
                    }
                } else {
                    // Expect no Burn on 2nd Highest Tier
                    assertEq(afterBalTo.eliteNFTId, beforeNFTData.curIndexSecondHighestTier, "assertEliteNFTTo #16");
                    assertEq(
                        afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #17"
                    );
                    assertEq(
                        afterNFTData.curIndexSecondHighestTier,
                        beforeNFTData.curIndexSecondHighestTier + 1,
                        "assertEliteNFTTo #18"
                    );
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
            if (afterBalTo.balCoin < params[params.length - 2].amountThreshold) {
                assertEq(afterBalTo.eliteNFTId, 0, "assertEliteNFTTo #23");
                assertEq(afterNFTData.curIndexHighestTier, beforeNFTData.curIndexHighestTier, "assertEliteNFTTo #24");
                assertEq(
                    afterNFTData.curIndexSecondHighestTier,
                    beforeNFTData.curIndexSecondHighestTier,
                    "assertEliteNFTTo #25"
                );
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
        Balances memory beforeBalFrom,
        Balances memory beforeBalTo,
        Balances memory afterBalFrom,
        Balances memory afterBalTo,
        uint256 amount
    ) internal {
        /// Normal assert of balances
        assertEq(afterBalFrom.balCoin, beforeBalFrom.balCoin - amount, "[Transfer] from balance");
        assertEq(afterBalTo.balCoin, beforeBalTo.balCoin + amount, "[Transfer] to balance");
    }

    function _assertNFT(address account, Balances memory bal) internal {
        /// Check Balance of NFTs
        /// Assert Highest Tier
        if (bal.balCoin >= params[params.length - 1].amountThreshold) {
            /// Recipient
            assertEq(bal.balEliteNFT, 1, "[Transfer|Tier -1] Balance Elite NFT");
            for (uint256 i = 1; i <= params.length - 2; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier -1] Balance ERC155");
            }
            return;
        }

        /// Assert 2nd Highest Tier
        if (bal.balCoin >= params[params.length - 2].amountThreshold) {
            /// Recipient
            assertEq(bal.balEliteNFT, 1, "[Transfer|Tier-2] Balance Elite NFT");
            for (uint256 i = 1; i <= params.length - 2; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier-2] Balance ERC155");
            }
            return;
        }

        /// Assert lower tier
        for (uint256 i = params.length - 2; i > 0; i--) {
            if (bal.balCoin >= params[i - 1].amountThreshold) {
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

            for (uint256 i = 1; i <= params.length - 1; i++) {
                assertEq(meme1155.balanceOf(account, i), 0, "[Transfer|Tier -0] Balance ERC155");
            }
        }
    }

    function _getBalances(address _account) internal view returns (Balances memory) {
        Balances memory balances;
        balances.balCoin = meme404.balanceOf(_account);
        balances.balEliteNFT = meme721.balanceOf(_account);
        balances.eliteNFTId = meme721.nftIdByOwner(_account);
        return balances;
    }

    function _getNFTData() internal view returns (NFTData memory nftData) {
        MEME404.Tier memory highestTier = meme404.getTier(params.length - 1);
        MEME404.Tier memory secondHighestTier = meme404.getTier(params.length - 2);
        nftData.curIndexHighestTier = highestTier.curIndex;
        nftData.curIndexSecondHighestTier = secondHighestTier.curIndex;
        nftData.nextBurnIdHighestTier =
            highestTier.burnIds.length > 0 ? highestTier.burnIds[highestTier.burnIds.length - 1] : 0;
        nftData.nextBurnIdSecondHighestTier =
            secondHighestTier.burnIds.length > 0 ? secondHighestTier.burnIds[secondHighestTier.burnIds.length - 1] : 0;
    }
}
