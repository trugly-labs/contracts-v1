/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
import {Owned} from "@solmate/auth/Owned.sol";
import {SafeCastLib} from "@solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Constant} from "./libraries/Constant.sol";
import {MEME20Constant} from "./libraries/MEME20Constant.sol";
import {INonfungiblePositionManager} from "./interfaces/external/INonfungiblePositionManager.sol";
import {ITruglyMemeception} from "./interfaces/ITruglyMemeception.sol";
import {IUniswapV3Factory} from "./interfaces/external/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/external/IUniswapV3Pool.sol";
import {ITruglyVesting} from "./interfaces/ITruglyVesting.sol";
import {MEME20} from "./types/MEME20.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MEME20 and their Memeception
/// @notice Contract generated by https://www.trugly.meme
contract Trugly20Memeception is ITruglyMemeception, Owned {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEME20;
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

    /// @dev Thrown when the cooldown period has not passed
    error ClaimCooldownPeriod();

    /// @dev Thrown when the auction is out of range
    error AuctionOutOfRange();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Zero bytes
    bytes internal constant ZERO_BYTES = new bytes(0);

    /// @dev Address of the UniswapV3 Factory
    IUniswapV3Factory public immutable v3Factory;

    /// @dev Address of the UniswapV3 NonfungiblePositionManager
    INonfungiblePositionManager public immutable v3PositionManager;

    /// @dev Vesting contract for MEME20 tokens
    ITruglyVesting public immutable vesting;

    /// @dev Address of the WETH9 contract
    WETH public immutable WETH9;

    /// @dev Mapping of memeToken => memeceptions
    mapping(address => Memeception) internal memeceptions;

    /// @dev Amount bid by OGs
    mapping(address => mapping(address => Bid)) bidsOG;

    /// @dev Mapping to determine if a token symbol already exists
    mapping(bytes32 => bool) private memeSymbolExist;

    address[] internal SWAP_ROUTERS = [
        0x2626664c2603336E57B271c5C0b26F421741e481, // SwapRouter02
        0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD // UniswapRouter
    ];

    address[] internal EXEMPT_UNISWAP = [
        0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1, // LP Positions
        0x42bE4D6527829FeFA1493e1fb9F3676d2425C3C1, // Staker Address
        0x067170777BA8027cED27E034102D54074d062d71 // Fee Collector
    ];

    uint160[] internal SQRT_PRICES = [
        9.9620638014409013576665500134366e31,
        1.82362737790643434215160709805482e32,
        2.61385148314342471623782117882802e32,
        3.74004952386637585900988618606868e32,
        5.60227709747861399187319382274581e32,
        7.84475704480554846956081104400211e32,
        1.029284437475773524677208730204788e33,
        1.344009007269693266194936117742324e33,
        1.66565590888416773239749174532807e33,
        1.96540882188949032818435859689197e33,
        2.31132305030739515210613901046113e33,
        2.89300345324985299295434785749435e33,
        3.45780049422742027739788815516414e33,
        4.16126696071137508385761524744751e33
    ];

    uint256[] internal AUCTION_PRICES = [
        5.06e11,
        1.51e11,
        7.35e10,
        3.59e10,
        1.6e10,
        8.16e9,
        4.74e9,
        2.78e9,
        1.81e9,
        1.3e9,
        0.94e9,
        0.6e9,
        0.42e9,
        0.29e9
    ];

    address internal treasury;

    uint256 public auctionDuration;
    uint256 public auctionPriceDecayPeriod;

    constructor(
        address _v3Factory,
        address _v3PositionManager,
        address _WETH9,
        address _vesting,
        address _treasury,
        address _multisig
    ) Owned(_multisig) {
        if (AUCTION_PRICES.length != SQRT_PRICES.length) revert InvalidAuctionDuration();
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
        auctionPriceDecayPeriod = 1.5 minutes;
        auctionDuration = auctionPriceDecayPeriod * AUCTION_PRICES.length;

        emit TreasuryUpdated(address(0), _treasury);
    }

    /// @inheritdoc ITruglyMemeception
    function createMeme(MemeceptionCreationParams calldata params) external returns (address, address) {
        _verifyCreateMeme(params);
        MEME20 memeToken = new MEME20{salt: params.salt}(params.name, params.symbol, params.creator);
        if (address(memeToken) <= address(WETH9)) revert InvalidMemeAddress();

        address pool = v3Factory.createPool(address(WETH9), address(memeToken), Constant.UNI_LP_SWAPFEE);

        memeToken.initialize(
            owner, treasury, MEME20Constant.PROTOCOL_FEE_BPS, params.swapFeeBps, pool, SWAP_ROUTERS, EXEMPT_UNISWAP
        );

        memeceptions[address(memeToken)] = Memeception({
            tokenId: 0,
            auctionTokenSold: 0,
            startAt: params.startAt,
            pool: pool,
            creator: params.creator,
            auctionFinalPriceScaled: 0,
            swapFeeBps: params.swapFeeBps,
            auctionEndedAt: 0
        });

        memeSymbolExist[keccak256(abi.encodePacked(params.symbol))] = true;

        if (params.vestingAllocBps > 0) {
            uint256 vestingAlloc = MEME20Constant.TOKEN_TOTAL_SUPPLY.fullMulDiv(params.vestingAllocBps, 1e4);
            memeToken.transfer(address(vesting), vestingAlloc);
            vesting.startVesting(
                address(memeToken),
                params.creator,
                vestingAlloc,
                params.startAt,
                Constant.VESTING_DURATION,
                Constant.VESTING_CLIFF
            );
        }
        uint256 burnAllocBps = Constant.CREATOR_MAX_VESTED_ALLOC_BPS - params.vestingAllocBps;
        if (burnAllocBps > 0) {
            memeToken.transfer(address(0), MEME20Constant.TOKEN_TOTAL_SUPPLY.fullMulDiv(burnAllocBps, 1e4));
        }

        emit MemeCreated(
            address(memeToken),
            params.creator,
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
                MEME20(memeToken).balanceOf(address(this)).rawSub(Constant.TOKEN_MEMECEPTION_SUPPLY)
            );

            memeceptions[memeToken].auctionEndedAt = block.timestamp;
        }

        memeceptions[memeToken].auctionTokenSold += auctionTokenAmount.safeCastTo112();

        bidsOG[memeToken][msg.sender] =
            Bid({amountETH: msg.value.safeCastTo80(), amountMeme: auctionTokenAmount.safeCastTo112()});

        emit MemeceptionBid(memeToken, msg.sender, msg.value, auctionTokenAmount);
    }

    /// @dev Add liquidity to the UniV3 Pool and initialize the pool
    /// @param memeToken Address of the MEME20
    /// @param amountETH Amount of ETH to add to the pool
    /// @param amountMeme Amount of MEME20 to add to the pool
    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH, uint256 amountMeme) internal virtual {
        uint256 step = (block.timestamp.rawSub(memeceptions[memeToken].startAt)).rawDiv(auctionPriceDecayPeriod);
        if (step >= SQRT_PRICES.length) revert AuctionOutOfRange();
        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(SQRT_PRICES[step]);

        WETH9.deposit{value: amountETH}();
        WETH9.safeApprove(address(v3PositionManager), amountETH);
        MEME20(memeToken).safeApprove(address(v3PositionManager), amountMeme);

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

    /// @dev Check a MEME20's UniV3 Pool is initialized with liquidity
    /// @param memeception Memeception
    /// @return bool True if the pool is initialized with liquidity
    function _poolLaunched(Memeception memory memeception) private pure returns (bool) {
        return memeception.auctionFinalPriceScaled > 0;
    }

    /// @notice Verify the validity of a bid
    /// @param memeception Memeception
    /// @param memeToken Address of the MEME20
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
        if (memeception.auctionEndedAt + Constant.AUCTION_CLAIM_COOLDOWN > block.timestamp) {
            revert ClaimCooldownPeriod();
        }

        Bid memory bidOG = bidsOG[memeToken][msg.sender];
        if (bidOG.amountETH == 0 || bidOG.amountMeme == 0) revert ZeroAmount();

        // Unchecked as Dutch Auction has a decaying price over time - this cannot < 0
        uint256 refund =
            uint256(bidOG.amountETH).rawSub(uint256(bidOG.amountMeme).mulWadUp(memeception.auctionFinalPriceScaled));
        uint256 claimableMeme = bidOG.amountMeme;

        delete bidsOG[memeToken][msg.sender];
        MEME20(memeToken).safeTransfer(msg.sender, claimableMeme);
        if (refund > 0) msg.sender.safeTransferETH(refund);

        emit MemeceptionClaimed(memeToken, msg.sender, claimableMeme, refund);
    }

    function collectFees(address memeToken) external {
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

        uint256 step = (block.timestamp.rawSub(memeception.startAt)).rawDiv(auctionPriceDecayPeriod);

        if (step >= AUCTION_PRICES.length) revert AuctionOutOfRange();
        return AUCTION_PRICES[step];
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
    /// @dev Update the duration per tier
    /// @param _duration The new duration per tier
    function setAuctionPriceDecayPeriod(uint256 _duration) external onlyOwner {
        if (_duration < Constant.MIN_AUCTION_PRICE_DECAY_PERIOD || _duration > Constant.MAX_AUCTION_PRICE_DECAY_PERIOD)
        {
            revert InvalidAuctionDuration();
        }
        emit AuctionDurationUpdated(auctionPriceDecayPeriod, _duration);
        auctionPriceDecayPeriod = _duration;
    }
}
