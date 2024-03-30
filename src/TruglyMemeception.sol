/// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {SafeCastLib} from "@solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Auction} from "./libraries/Auction.sol";
import {Constant} from "./libraries/Constant.sol";
import {MEMERC20Constant} from "./libraries/MEMERC20Constant.sol";
import {INonfungiblePositionManager} from "./interfaces/external/INonfungiblePositionManager.sol";
import {ITruglyMemeception} from "./interfaces/ITruglyMemeception.sol";
import {IUniswapV3Factory} from "./interfaces/external/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/external/IUniswapV3Pool.sol";
import {ITruglyVesting} from "./interfaces/ITruglyVesting.sol";
import {MEMERC20} from "./types/MEMERC20.sol";
import {SqrtPriceX96} from "./libraries/SqrtPriceX96.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MEMERC20 and their Memeception
contract TruglyMemeception is ITruglyMemeception, Owned {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEMERC20;
    using SafeTransferLib for address;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Emitted when a memeceptions is created
    event MemeCreated(
        address indexed memeToken,
        address indexed creator,
        string symbol,
        address pool,
        uint40 startAt,
        uint16 creatorSwapFeeBps,
        uint16 vestingAllocBps
    );

    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionBid(address indexed memeToken, address indexed og, uint256 amountETH, uint256 amountMeme);

    /// @dev Emitted when liquidity has been added to the UniV3 Pool
    event MemeLiquidityAdded(address indexed memeToken, address pool, uint256 amountMeme, uint256 amountETH);

    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeceptionClaimed(address indexed memeToken, address indexed og, uint256 amountMeme, uint256 refundETH);

    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed og, uint256 refundETH);

    /// @dev Emited when the treasury is updated
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /// @dev Emited when the auction duration is updated
    event AuctionDurationUpdated(uint256 oldDuration, uint256 newDuration);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Invalid Meme Address (has to be > WETH9)
    error InvalidMemeAddress();

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

    /// @dev Thrown when the Meme pool is not launched
    error MemeNotLaunched();

    /// @dev Thrown when the Memeception has ended
    error MemeceptionEnded();

    /// @dev Thrown when the Memeception has not started
    error MemeceptionNotStarted();

    /// @dev Thrown when address is address(0)
    error ZeroAddress();

    /// @dev Thrown when a OG has already participated in the memeceptions
    error DuplicateOG();

    /// @dev Thrown when the amount is 0
    error ZeroAmount();

    /// @dev Thrown when the amount is too high
    error BidAmountTooHigh();

    /// @dev Thrown when the auction duration is out of range
    error InvalidAuctionDuration();

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
    mapping(address => Memeception) internal memeceptions;

    /// @dev Amount bid by OGs
    mapping(address => mapping(address => Bid)) bidsOG;

    /// @dev Mapping to determine if a token symbol already exists
    mapping(bytes32 => bool) private memeSymbolExist;

    address internal treasury;

    uint256 internal auctionDuration;

    constructor(address _v3Factory, address _v3PositionManager, address _WETH9, address _vesting, address _treasury)
        Owned(msg.sender)
    {
        if (
            _v3Factory == address(0) || _v3PositionManager == address(0) || _WETH9 == address(0)
                || _vesting == address(0) || _treasury == address(0)
        ) {
            revert ZeroAddress();
        }
        v3Factory = IUniswapV3Factory(_v3Factory);
        v3PositionManager = INonfungiblePositionManager(_v3PositionManager);
        WETH9 = WETH(payable(_WETH9));
        vesting = ITruglyVesting(_vesting);
        treasury = _treasury;
        auctionDuration = Constant.MIN_AUCTION_DURATION;

        emit TreasuryUpdated(address(0), _treasury);
    }

    /// @inheritdoc ITruglyMemeception
    function createMeme(MemeceptionCreationParams calldata params) external returns (address, address) {
        _verifyCreateMeme(params);
        MEMERC20 memeToken = new MEMERC20{salt: params.salt}(params.name, params.symbol, msg.sender);
        if (address(memeToken) <= address(WETH9)) revert InvalidMemeAddress();

        address pool = v3Factory.createPool(address(WETH9), address(memeToken), Constant.UNI_LP_SWAPFEE);

        memeceptions[address(memeToken)] = Memeception({
            tokenId: 0,
            auctionTokenSold: 0,
            startAt: params.startAt,
            pool: pool,
            creator: msg.sender,
            auctionFinalPriceScaled: 0,
            swapFeeBps: params.swapFeeBps
        });

        memeSymbolExist[keccak256(abi.encodePacked(params.symbol))] = true;

        if (params.vestingAllocBps > 0) {
            uint256 vestingAlloc = MEMERC20Constant.TOKEN_TOTAL_SUPPLY.fullMulDiv(params.vestingAllocBps, 1e4);
            memeToken.safeTransfer(address(vesting), vestingAlloc);
            vesting.startVesting(
                address(memeToken),
                msg.sender,
                vestingAlloc,
                params.startAt,
                Constant.VESTING_DURATION,
                Constant.VESTING_CLIFF
            );
        }
        uint256 burnAllocBps = Constant.CREATOR_MAX_VESTED_ALLOC_BPS - params.vestingAllocBps;
        if (burnAllocBps > 0) {
            memeToken.safeTransfer(address(0), MEMERC20Constant.TOKEN_TOTAL_SUPPLY.fullMulDiv(burnAllocBps, 1e4));
        }

        emit MemeCreated(
            address(memeToken),
            msg.sender,
            params.symbol,
            pool,
            params.startAt,
            params.swapFeeBps,
            params.vestingAllocBps
        );
        return (address(memeToken), pool);
    }

    /// @dev Verify the validity of the parameters for the creation of a memeception
    /// @param params List of parameters for the creation of a memeception
    /// Revert if any parameters are invalid
    function _verifyCreateMeme(MemeceptionCreationParams calldata params) internal view virtual {
        if (memeSymbolExist[keccak256(abi.encodePacked(params.symbol))]) revert MemeSymbolExist();
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

        uint256 curPriceScaled = _getAuctionPriceScaled(memeception);
        uint256 auctionTokenAmount = msg.value.rawDivWad(curPriceScaled);

        if (memeception.auctionTokenSold + auctionTokenAmount >= Constant.TOKEN_MEMECEPTION_SUPPLY) {
            auctionTokenAmount = Constant.TOKEN_MEMECEPTION_SUPPLY.rawSub(memeception.auctionTokenSold);

            memeceptions[memeToken].auctionFinalPriceScaled = curPriceScaled.safeCastTo64();
            /// Adding liquidity to Uni V3 Pool
            _addLiquidityToUniV3Pool(
                memeToken,
                Constant.TOKEN_MEMECEPTION_SUPPLY.rawMulWad(curPriceScaled),
                MEMERC20(memeToken).balanceOf(address(this)).rawSub(Constant.TOKEN_MEMECEPTION_SUPPLY)
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
    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal virtual {
        uint160 sqrtPriceX96 = SqrtPriceX96.sqrtPriceX96(memeceptions[memeToken].startAt);
        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(sqrtPriceX96);

        WETH9.deposit{value: amountETH}();
        WETH9.safeApprove(address(v3PositionManager), amountETH);
        MEMERC20(memeToken).safeApprove(address(v3PositionManager), amountMeme);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(WETH9),
            token1: memeToken,
            fee: Constant.UNI_LP_SWAPFEE,
            tickLower: Constant.TICK_LOWER,
            tickUpper: Constant.TICK_UPPER,
            amount0Desired: amountETH,
            amount1Desired: amountMeme,
            amount0Min: amountETH.mulDiv(99, 100),
            amount1Min: amountMeme.mulDiv(99, 100),
            recipient: address(this),
            deadline: block.timestamp + 30 minutes
        });

        (uint256 tokenId,,,) = v3PositionManager.mint(params);
        memeceptions[memeToken].tokenId = tokenId;

        emit MemeLiquidityAdded(memeToken, memeceptions[memeToken].pool, amountMeme, amountETH);
    }

    /// @dev Check a MEMERC20's UniV3 Pool is initialized with liquidity
    /// @param memeception Memeception
    /// @return bool True if the pool is initialized with liquidity
    function _poolLaunched(Memeception memory memeception) private pure returns (bool) {
        return memeception.auctionFinalPriceScaled > 0;
    }

    /// @notice Verify the validity of a bid
    /// @param memeception Memeception
    /// @param memeToken Address of the MEMERC20
    function _verifyBid(Memeception memory memeception, address memeToken) internal view virtual {
        if (msg.value == 0) revert ZeroAmount();
        if (msg.value > Constant.AUCTION_MAX_BID) revert BidAmountTooHigh();
        if (_poolLaunched(memeception)) revert MemeLaunched();
        if (block.timestamp < memeception.startAt) revert MemeceptionNotStarted();
        if (_auctionEnded(memeception)) revert MemeceptionEnded();

        if (bidsOG[memeToken][msg.sender].amountETH > 0) revert DuplicateOG();
    }

    /// @inheritdoc ITruglyMemeception
    function exit(address memeToken) external {
        Memeception memory memeception = memeceptions[memeToken];
        if (memeception.startAt == 0) revert InvalidMemeAddress();
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

        // Unchecked as Dutch Auction has a decaying price over time - this cannot < 0
        uint256 refund =
            uint256(bidOG.amountETH).rawSub(uint256(bidOG.amountMeme).mulWadUp(memeception.auctionFinalPriceScaled));
        uint256 claimableMeme = bidOG.amountMeme;

        MEMERC20 meme = MEMERC20(memeToken);

        delete bidsOG[memeToken][msg.sender];
        meme.safeTransfer(msg.sender, claimableMeme);
        if (refund > 0) msg.sender.safeTransferETH(refund);

        emit MemeceptionClaimed(memeToken, msg.sender, claimableMeme, refund);
    }

    function collectFees(address memeToken) external onlyOwner {
        INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams({
            tokenId: memeceptions[memeToken].tokenId,
            recipient: treasury,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        v3PositionManager.collect(collectParams);
    }

    function _auctionEnded(Memeception memory memeception) internal view virtual returns (bool) {
        return uint40(block.timestamp) >= memeception.startAt + auctionDuration || _poolLaunched(memeception);
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
    function getAuctionPriceScaled(address memeToken) public view returns (uint256) {
        Memeception memory memeception = memeceptions[memeToken];
        return _getAuctionPriceScaled(memeception);
    }

    /// @dev Get the current auction price for a given Memeception
    /// @notice Using y = 0.5 / x with (y price, x timeElapsedPerPeriod)
    /// @param memeception Memeception
    /// @return currentPrice uint256 Current auction price (Scaled by 1e18)
    function _getAuctionPriceScaled(Memeception memory memeception) internal view virtual returns (uint256) {
        if (_auctionEnded(memeception)) return memeception.auctionFinalPriceScaled;

        uint256 step = (block.timestamp.rawSub(memeception.startAt)).rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD);

        if (step >= auctionDuration.rawDiv(Constant.AUCTION_PRICE_DECAY_PERIOD)) revert Auction.AuctionOutOfRange();
        return Auction.price(step);
    }

    /// @notice receive native tokens
    receive() external payable {}

    /// @dev receive ERC721 tokens for Univ3 LP Positions
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Only the owner can call this function
    /// @dev Update the treasury address
    /// @param _newTreasury The new treasury address
    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /// @notice Only the owner can call this function
    /// @dev Update the auction duration
    /// @param duration The new dureation
    function setAuctionDuration(uint256 duration) external onlyOwner {
        if (duration < Constant.MIN_AUCTION_DURATION || duration > Constant.MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }
        emit AuctionDurationUpdated(auctionDuration, duration);
        auctionDuration = duration;
    }
}
