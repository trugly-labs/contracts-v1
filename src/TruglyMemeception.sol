/// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {wadDiv} from "@solmate/utils/SignedWadMath.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {SafeCastLib} from "@solmate/utils/SafeCastLib.sol";

import {Constant} from "./libraries/Constant.sol";
import {MEMERC20Constant} from "./libraries/MEMERC20Constant.sol";
import {FullMath} from "./libraries/external/FullMath.sol";
import {INonfungiblePositionManager} from "./interfaces/external/INonfungiblePositionManager.sol";
import {ITruglyMemeception} from "./interfaces/ITruglyMemeception.sol";
import {IUniswapV3Factory} from "./interfaces/external/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/external/IUniswapV3Pool.sol";
import {ITruglyVesting} from "./interfaces/ITruglyVesting.sol";
import {MEMERC20} from "./types/MEMERC20.sol";
import {SqrtPriceX96} from "./libraries/external/SqrtPriceX96.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MEMERC20 and their Memeception
contract TruglyMemeception is ITruglyMemeception, Owned {
    using FullMath for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEMERC20;
    using SafeTransferLib for address;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Emitted when a memeceptions is created
    event MemeCreated(
        string indexed symbol,
        address indexed memeToken,
        address indexed creator,
        uint40 startAt,
        uint16 creatorSwapFeeBps,
        uint16 vestingAllocBps
    );

    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionBid(address indexed memeToken, address indexed og, uint256 amountETH, uint256 amountMeme);

    /// @dev Emitted when liquidity has been added to the UniV3 Pool
    event MemeLiquidityAdded(address indexed memeToken, uint256 amount0, uint256 amount1);

    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeClaimed(address indexed memeToken, address indexed claimer, uint256 amountMeme, uint256 refundETH);

    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 amount);

    //     event CollectProtocolFees(address indexed token, address recipient, uint256 amount);

    //     event CollectLPFees(address indexed token, address recipient, uint256 amount);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Thrown when the swap fee is too high
    error MemeSwapFeeTooHigh();

    /// @dev Thrown when the vesting allocation is too high
    error VestingAllocTooHigh();

    /// @dev Thrown when the Meme symbol already exists
    error MemeSymbolExist();

    /// @dev Thrown when the memeceptions startAt is invalid (too early/too late)
    error InvalidMemeceptionDate();

    /// @dev Thrown when the memeceptions ended and the Meme pool is launched
    error MemeLaunched();

    /// @dev Thrown when the Meme pool is not launche
    error MemeNotLaunched();

    /// @dev Thrown when address is address(0)
    error ZeroAddress();

    /// @dev Thrown when a OG has already participated in the memeceptions
    error DuplicateOG();

    /// @dev Thrown when the amount is 0
    error ZeroAmount();

    /// @dev Thrown when the amount is too high
    error BidAmountTooHigh();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Zero bytes
    bytes internal constant ZERO_BYTES = new bytes(0);

    /// @dev Address of the UniswapV3 Factory
    IUniswapV3Factory public immutable v3Factory;

    /// @dev Address of the UniswapV3 NonfungiblePositionManager
    INonfungiblePositionManager public immutable v3PositionManager;

    /// @dev Vesting contract for MEMERC20 tokens
    ITruglyVesting public immutable vesting;

    /// @dev Address of the WETH9 contract
    WETH public immutable WETH9;

    /// @dev Mapping of memeToken => memeceptions
    mapping(address => Memeception) private memeceptions;

    /// @dev Amount bid by OGs
    mapping(address => mapping(address => Bid)) bidsOG;

    /// @dev Mapping to determine if a token symbol already exists
    mapping(string => bool) private memeSymbolExist;

    constructor(address _v3Factory, address _v3PositionManager, address _WETH9, address _vesting) Owned(msg.sender) {
        if (
            _v3Factory == address(0) || _v3PositionManager == address(0) || _WETH9 == address(0)
                || _vesting == address(0)
        ) {
            revert ZeroAddress();
        }
        v3Factory = IUniswapV3Factory(_v3Factory);
        v3PositionManager = INonfungiblePositionManager(_v3PositionManager);
        WETH9 = WETH(payable(_WETH9));
        vesting = ITruglyVesting(_vesting);
    }

    /// @inheritdoc ITruglyMemeception
    function createMeme(MemeceptionCreationParams calldata params) external returns (address, address) {
        _verifyCreateMeme(params);
        MEMERC20 memeToken = new MEMERC20(params.name, params.symbol);
        (address token0, address token1) = _getTokenOrder(address(memeToken));

        address pool = v3Factory.createPool(token0, token1, Constant.UNI_LP_SWAPFEE);

        memeceptions[address(memeToken)] = Memeception({
            auctionTokenSold: 0,
            startAt: params.startAt,
            pool: pool,
            creator: msg.sender,
            auctionFinalPrice: 0,
            swapFeeBps: params.swapFeeBps
        });

        memeSymbolExist[params.symbol] = true;

        if (params.vestingAllocBps > 0) {
            uint256 vestingAlloc = MEMERC20Constant.TOKEN_TOTAL_SUPPLY.mulDiv(params.vestingAllocBps, 1e4);
            memeToken.safeApprove(address(vesting), vestingAlloc);
            vesting.startVesting(
                address(memeToken),
                msg.sender,
                vestingAlloc,
                params.startAt,
                Constant.VESTING_DURATION,
                Constant.VESTING_CLIFF
            );
        }

        emit MemeCreated(
            params.symbol, address(memeToken), msg.sender, params.startAt, params.swapFeeBps, params.vestingAllocBps
        );
        return (address(memeToken), pool);
    }

    /// @dev Verify the validity of the parameters for the creation of a memeception
    /// @param params List of parameters for the creation of a memeception
    /// Revert if any parameters are invalid
    function _verifyCreateMeme(MemeceptionCreationParams calldata params) internal view {
        if (memeSymbolExist[params.symbol]) revert MemeSymbolExist();
        if (
            params.startAt < uint40(block.timestamp) + Constant.MEMECEPTION_MIN_START_AT
                || params.startAt > uint40(block.timestamp) + Constant.MEMECEPTION_MAX_START_AT
        ) revert InvalidMemeceptionDate();
        if (params.swapFeeBps > Constant.CREATOR_MAX_FEE_BPS) revert MemeSwapFeeTooHigh();
        if (params.vestingAllocBps > Constant.CREATOR_MAX_VESTED_ALLOC_BPS) revert VestingAllocTooHigh();
    }

    /// @inheritdoc ITruglyMemeception
    function bid(address memeToken) external payable {
        Memeception memory memeception = memeceptions[memeToken];
        _verifyBid(memeception, memeToken);

        uint256 curPrice = _getAuctionPrice(memeception);
        console2.log("curPrice", curPrice);
        uint256 auctionTokenAmount = msg.value * curPrice;
        console2.log("auctionTokenSold", auctionTokenAmount);

        if (memeception.auctionTokenSold + auctionTokenAmount >= Constant.TOKEN_MEMECEPTION_SUPPLY) {
            auctionTokenAmount = Constant.TOKEN_MEMECEPTION_SUPPLY - memeception.auctionTokenSold;

            memeceptions[memeToken].auctionFinalPrice = curPrice.safeCastTo64();
            /// Adding liquidity to Uni V3 Pool
            _addLiquidityToUniV3Pool(
                memeToken,
                Constant.TOKEN_MEMECEPTION_SUPPLY * curPrice,
                MEMERC20(memeToken).balanceOf(address(this)) - Constant.TOKEN_MEMECEPTION_SUPPLY
            );
        }

        memeceptions[memeToken].auctionTokenSold += auctionTokenAmount.safeCastTo112();

        bidsOG[memeToken][msg.sender] =
            Bid({amountETH: msg.value.safeCastTo80(), amountMeme: auctionTokenAmount.safeCastTo112()});

        emit MemeceptionBid(memeToken, msg.sender, msg.value, auctionTokenAmount);
    }

    /// @dev Add liquidity to the UniV3 Pool and initialize the pool
    /// @param memeToken Address of the MEMERC20
    /// @param amountETH Amount of ETH to add to the pool
    /// @param amountMeme Amount of MEMERC20 to add to the pool
    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal {
        (address token0, address token1) = _getTokenOrder(address(memeToken));
        uint256 amount0 = token0 == address(WETH9) ? amountETH : amountMeme;
        uint256 amount1 = token0 == address(WETH9) ? amountMeme : amountETH;

        uint160 sqrtPriceX96 = SqrtPriceX96.calcSqrtPriceX96(amount0, amount1);
        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(sqrtPriceX96);

        WETH9.deposit{value: amountETH}();
        WETH9.safeApprove(address(v3PositionManager), amountETH);
        MEMERC20(memeToken).safeApprove(address(v3PositionManager), amountMeme);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: Constant.UNI_LP_SWAPFEE,
            tickLower: Constant.TICK_LOWER,
            tickUpper: Constant.TICK_UPPER,
            amount0Desired: amount0,
            amount1Desired: amount1,
            /// TODO: Provide a better value
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 30 minutes
        });

        v3PositionManager.mint(params);

        emit MemeLiquidityAdded(memeToken, amount0, amount1);
    }

    /// @dev Check a MEMERC20's UniV3 Pool is initialized with liquidity
    /// @param memeception Memeception
    /// @return bool True if the pool is initialized with liquidity
    function _poolLaunched(Memeception memory memeception) private pure returns (bool) {
        return memeception.auctionFinalPrice > 0;
    }

    /// @notice Verify the validity of a bid
    /// @param memeception Memeception
    /// @param memeToken Address of the MEMERC20
    function _verifyBid(Memeception memory memeception, address memeToken) internal view virtual {
        if (msg.value == 0) revert ZeroAmount();
        if (msg.value > Constant.AUCTION_MAX_BID) revert BidAmountTooHigh();
        if (_poolLaunched(memeception)) revert MemeLaunched();
        if (block.timestamp < memeception.startAt || _auctionEnded(memeception)) revert InvalidMemeceptionDate();

        if (bidsOG[memeToken][msg.sender].amountETH > 0) revert DuplicateOG();
    }

    /// @inheritdoc ITruglyMemeception
    function exit(address memeToken) external {
        Memeception memory memeception = memeceptions[memeToken];
        if (_poolLaunched(memeception)) revert MemeLaunched();
        if (!_auctionEnded(memeception)) revert InvalidMemeceptionDate();

        uint256 refundAmount = bidsOG[memeToken][msg.sender].amountETH;
        delete bidsOG[memeToken][msg.sender];
        msg.sender.safeTransferETH(refundAmount);

        emit MemeceptionExit(memeToken, msg.sender, refundAmount);
    }

    /// @inheritdoc ITruglyMemeception
    function claim(address memeToken) external {
        Memeception memory memeception = memeceptions[memeToken];
        if (!_poolLaunched(memeception)) revert MemeNotLaunched();

        Bid memory bidOG = bidsOG[memeToken][msg.sender];
        if (bidOG.amountETH == 0 || bidOG.amountMeme == 0) revert ZeroAmount();

        uint256 refund = bidOG.amountETH - uint256(bidOG.amountMeme).mulDiv(1e18, memeception.auctionFinalPrice);
        uint256 claimableMeme = bidOG.amountMeme;

        MEMERC20 meme = MEMERC20(memeToken);

        delete bidsOG[memeToken][msg.sender];
        meme.safeTransfer(msg.sender, claimableMeme);
        if (refund > 0) msg.sender.safeTransferETH(refund);

        emit MemeClaimed(memeToken, msg.sender, claimableMeme, refund);
    }

    // function collectProtocolFees(Currency currency) external onlyOwner {
    //     uint256 amount = abi.decode(
    //         poolManager.lock(address(this), abi.encodeCall(this.lockCollectProtocolFees, (jug, currency))), (uint256)
    //     );

    //     emit CollectProtocolFees(Currency.unwrap(currency), jug, amount);
    // }

    // function collectLPFees(PoolKey[] calldata poolKeys) external onlyOwner {
    //     IPoolManager.ModifyLiquidityParams memory modifyLiqParams =
    //         IPoolManager.ModifyLiquidityParams({tickLower: TICK_LOWER, tickUpper: TICK_UPPER, liquidityDelta: 0});

    //     for (uint256 i = 0; i < poolKeys.length; i++) {
    //         PoolKey memory poolKey = poolKeys[i];
    //         BalanceDelta delta = abi.decode(
    //             poolManager.lock(
    //                 address(this), abi.encodeCall(this.lockModifyLiquidity, (poolKey, modifyLiqParams, jug))
    //             ),
    //             (BalanceDelta)
    //         );
    //         emit CollectLPFees(Currency.unwrap(poolKey.currency0), jug, uint256(int256(delta.amount0())));
    //         emit CollectLPFees(Currency.unwrap(poolKey.currency1), jug, uint256(int256(delta.amount1())));
    //     }
    // }

    // function lockCollectProtocolFees(address recipient, Currency currency) external returns (uint256 amount) {
    //     if (msg.sender != address(this)) revert OnlyOink();

    //     amount = poolManager.balanceOf(address(this), currency.toId());
    //     poolManager.burn(address(this), currency.toId(), amount);

    //     poolManager.take(currency, recipient, amount);
    // }

    function _auctionEnded(Memeception memory memeception) internal view returns (bool) {
        return block.timestamp >= memeception.startAt + Constant.AUCTION_DURATION || _poolLaunched(memeception);
    }

    /// @inheritdoc ITruglyMemeception
    function getMemeception(address memeToken) external view returns (Memeception memory) {
        return memeceptions[memeToken];
    }

    /// @inheritdoc ITruglyMemeception
    function getBid(address memeToken, address og) external view returns (Bid memory) {
        return bidsOG[memeToken][og];
    }

    /// @inheritdoc ITruglyMemeception
    function getAuctionPrice(address memeToken) public view returns (uint256) {
        Memeception memory memeception = memeceptions[memeToken];
        return _getAuctionPrice(memeception);
    }

    /// @dev Get the current auction price for a given Memeception
    /// @notice Using y = 0.5 / x with (y price, x timeElapsedPerPeriod)
    /// @param memeception Memeception
    /// @return currentPrice uint256 Current auction price
    function _getAuctionPrice(Memeception memory memeception) internal view returns (uint256 currentPrice) {
        if (_auctionEnded(memeception)) return memeception.auctionFinalPrice;
        uint256 timeElapsedPerPeriod = (block.timestamp - memeception.startAt) / Constant.AUCTION_PRICE_DECAY_PERIOD;
        return Constant.AUCTION_STARTING_PRICE / (timeElapsedPerPeriod * 2);
    }

    /// @dev Get the order of the tokens in the UniV3 Pool by comparing their addresses
    /// @param memeToken Address of the MEMERC20
    /// @return token0 Address of the first token
    /// @return token1 Address of the second token
    function _getTokenOrder(address memeToken) internal view returns (address token0, address token1) {
        if (address(WETH9) < address(memeToken)) {
            token0 = address(WETH9);
            token1 = address(memeToken);
        } else {
            token0 = address(memeToken);
            token1 = address(WETH9);
        }
    }

    /// @notice receive native tokens
    receive() external payable {}

    /// @dev receive ERC721 tokens for Univ3 LP Positions
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
