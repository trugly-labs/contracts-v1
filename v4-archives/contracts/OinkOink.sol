/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";

import {LiquidityAmounts} from "./libraries/external/LiquidityAmounts.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {IOinkOink} from "./interfaces/IOinkOink.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {OinkMath} from "./libraries/OinkMath.sol";
import {MemeERC20} from "./types/MemeERC20.sol";
import {OinkHooks} from "./OinkHooks.sol";

contract OinkOink is IOinkOink, Errors, Events {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    using FullMath for uint256;
    using SafeCast for uint256;

    /// 60% of MEME_TOTAL_SUPPLY
    uint256 public constant MEME_EARLY_SUPPLY = 6_000_000_000_000 ether;
    /// 40% of MEME_EARLY_SUPPLY
    uint256 public constant MEME_LP_SUPPLY = 4_000_000_000_000 ether;

    uint256 internal constant BACKERS_MIN_ETHCAP = 25 ether;
    uint256 internal constant BACKERS_MAX_ETHCAP = 1000 ether;
    uint256 internal constant BACKERS_MIN_START_AT = 1 days;
    uint256 internal constant BACKERS_MAX_START_AT = 30 days;
    uint256 internal constant BACKERS_DEADLINE = 3 days;

    /// 1%
    uint256 private constant CREATOR_MAX_FEE_BPS = 100;

    /// 2%
    uint24 private constant UNI_LP_SWAPFEE = 2000;
    int24 private constant TICK_SPACING = 250;
    int24 private constant TICK_LOWER = -887250;
    int24 private constant TICK_UPPER = -TICK_LOWER;

    uint160 private constant SQRT_RATIO_TICK_LOWER = 4299855743;
    uint160 private constant SQRT_RATIO_TICK_UPPER = 1459840076248373162167899255275506587012164559123;

    bytes constant ZERO_BYTES = new bytes(0);

    /// UniswapV4 Pool Manager
    IPoolManager public immutable poolManager;

    address private farmer;

    address private jug;

    address private memeLord;

    /// @dev MemeToken => Backers => ETH allocated
    mapping(address => mapping(address => uint256)) private earlyOinkerETH;

    mapping(address => MemePoolInfo) private memePoolInfo;

    mapping(string => bool) private memeSymbolExist;

    modifier onlyAdmin() {
        if (farmer != msg.sender) revert OnlyFarmer();
        _;
    }

    constructor(IPoolManager _poolManager, address _memeLord) {
        if (address(_poolManager) == address(0) || address(_memeLord) == address(0)) {
            revert ZeroAddress();
        }
        poolManager = _poolManager;
        farmer = msg.sender;
        jug = msg.sender;
        memeLord = _memeLord;
    }

    function aMemeIsBorn(MemeCreation calldata memeCreation) external returns (address, address) {
        _verifyReqMemeisBorn(memeCreation);
        MemeERC20 memeToken = new MemeERC20(memeCreation.name, memeCreation.symbol);

        OinkHooks hooks = new OinkHooks{salt: memeCreation.hookSalt}(
            poolManager, address(this), msg.sender, uint256(memeCreation.swapFeeBps)
        );

        PoolKey memory poolKey = PoolKey({
            currency0: CurrencyLibrary.NATIVE,
            currency1: Currency.wrap(address(memeToken)),
            fee: UNI_LP_SWAPFEE,
            tickSpacing: TICK_SPACING,
            hooks: hooks
        });

        memePoolInfo[address(memeToken)] = MemePoolInfo({
            backersETH: 0,
            backersETHCap: memeCreation.backersETHCap,
            creator: msg.sender,
            hooks: address(hooks),
            startAt: memeCreation.startAt,
            swapFeeBps: memeCreation.swapFeeBps
        });

        uint160 sqrtPriceX96 = OinkMath.calculateSqrtPriceX96(memeCreation.backersETHCap, MEME_LP_SUPPLY);
        poolManager.lock(address(this), abi.encodeCall(this.lockInitialize, (poolKey, sqrtPriceX96)));

        memeSymbolExist[memeCreation.symbol] = true;

        /// Emit Events
        emit MemeIsBorn(
            address(memeToken),
            msg.sender,
            memeCreation.backersETHCap,
            memeCreation.startAt,
            memeCreation.swapFeeBps,
            address(hooks)
        );

        return (address(memeToken), address(hooks));
    }

    function _verifyReqMemeisBorn(MemeCreation calldata memeCreation) internal view {
        if (memeSymbolExist[memeCreation.symbol]) revert MemeSymbolExist();
        if (memeCreation.backersETHCap < BACKERS_MIN_ETHCAP || memeCreation.backersETHCap > BACKERS_MAX_ETHCAP) {
            revert InvalidBackersETHCap();
        }
        if (
            memeCreation.startAt < block.timestamp + BACKERS_MIN_START_AT
                || memeCreation.startAt > block.timestamp + BACKERS_MAX_START_AT
        ) revert InvalidStartAt();
        if (memeCreation.swapFeeBps > CREATOR_MAX_FEE_BPS) revert MemeSwapFeeTooHigh();
    }

    function backMeme(address memeToken, bytes calldata sig) external payable {
        uint80 msgValueUint80 = msg.value.toUint80();
        MemePoolInfo storage poolInfo = memePoolInfo[memeToken];

        _verifyReqBackers(memeToken, sig);

        uint80 backingEthAmount = poolInfo.backersETH + msgValueUint80 <= poolInfo.backersETHCap
            ? msgValueUint80
            : poolInfo.backersETHCap - poolInfo.backersETH;

        poolInfo.backersETH += backingEthAmount;
        earlyOinkerETH[memeToken][msg.sender] = uint256(backingEthAmount);

        if (poolInfo.backersETH == poolInfo.backersETHCap) {
            /// Cap is reached - Adding liquidity to Uni V4 Pool
            uint160 sqrtPriceX96 = OinkMath.calculateSqrtPriceX96(poolInfo.backersETH, MEME_LP_SUPPLY);

            uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96, SQRT_RATIO_TICK_LOWER, SQRT_RATIO_TICK_UPPER, poolInfo.backersETH, MEME_LP_SUPPLY
            );

            /// Initial liquidity is provided on the full range of the pool
            IPoolManager.ModifyLiquidityParams memory modifyLiqParams = IPoolManager.ModifyLiquidityParams({
                tickLower: TICK_LOWER,
                tickUpper: TICK_UPPER,
                liquidityDelta: int256(int128(liquidityDelta))
            });

            PoolKey memory poolKey = PoolKey({
                currency0: CurrencyLibrary.NATIVE,
                currency1: Currency.wrap(memeToken),
                fee: UNI_LP_SWAPFEE,
                tickSpacing: TICK_SPACING,
                hooks: OinkHooks(poolInfo.hooks)
            });

            poolManager.lock(
                address(this), abi.encodeCall(this.lockModifyLiquidity, (poolKey, modifyLiqParams, address(this)))
            );

            /// Refund as the BackersETHCap has been reached
            CurrencyLibrary.NATIVE.transfer(msg.sender, uint256(msgValueUint80 - backingEthAmount));

            emit MemeLiquidityAdded(memeToken, poolInfo.backersETH, MEME_LP_SUPPLY);
        }

        emit MemeBacked(memeToken, msg.sender, backingEthAmount);
    }

    function _isLaunched(address memeToken) private view returns (bool) {
        return (
            memePoolInfo[memeToken].backersETHCap > 0
                && memePoolInfo[memeToken].backersETH >= memePoolInfo[memeToken].backersETHCap
        );
    }

    function _verifyReqBackers(address memeToken, bytes calldata sig) internal view virtual {
        if (msg.value == 0) revert ZeroAmount();
        if (_isLaunched(memeToken)) revert MemeAlreadyLaunched();
        if (
            memePoolInfo[memeToken].startAt < block.timestamp
                || memePoolInfo[memeToken].startAt > block.timestamp + BACKERS_DEADLINE
        ) {
            revert BackersDateError();
        }
        if (earlyOinkerETH[memeToken][msg.sender] > 0) revert WalletAlreadyBacked();
        if (
            !SignatureChecker.isValidSignatureNow(
                memeLord, keccak256(abi.encode(memeToken, msg.sender, msg.value, block.chainid)), sig
            )
        ) revert InvalidBackersSignature();
    }

    function exitEarlyOinker(address memeToken) external {
        if (_isLaunched(memeToken)) revert MemeAlreadyLaunched();
        if (block.timestamp < memePoolInfo[memeToken].startAt + BACKERS_DEADLINE) revert GenesisDeadlineNotReached();

        uint256 exitAmount = earlyOinkerETH[memeToken][msg.sender];

        earlyOinkerETH[memeToken][msg.sender] = 0;
        memePoolInfo[memeToken].backersETH -= exitAmount.toUint80();
        CurrencyLibrary.NATIVE.transfer(msg.sender, exitAmount);

        emit MemeGenesisExit(memeToken, msg.sender, exitAmount);
    }

    function claimEarlyMeme(address memeToken) external {
        if (!_isLaunched(memeToken)) revert MemeNotLaunched();

        uint256 backersPct =
            earlyOinkerETH[memeToken][msg.sender].mulDiv(1e18, uint256(memePoolInfo[memeToken].backersETH));
        uint256 claimableMeme = MEME_EARLY_SUPPLY.mulDiv(backersPct, 1e18);

        Currency currency = Currency.wrap(memeToken);

        if (claimableMeme > currency.balanceOf(address(this))) {
            claimableMeme = currency.balanceOf(address(this));
        }

        earlyOinkerETH[memeToken][msg.sender] = 0;
        Currency.wrap(memeToken).transfer(msg.sender, claimableMeme);

        emit MemeClaimed(memeToken, msg.sender, claimableMeme);
    }

    function lockAcquired(address lockCaller, bytes calldata data) external override returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        if (lockCaller != address(this)) revert OnlyOink();

        (bool success, bytes memory returnData) = address(this).call(data);
        if (success) return returnData;
        if (returnData.length == 0) revert LockFailure();
        // if the call failed, bubble up the reason
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    function lockInitialize(PoolKey memory poolKey, uint160 sqrtPriceX96) external {
        if (msg.sender != address(this)) revert OnlyOink();
        poolManager.initialize(poolKey, sqrtPriceX96, ZERO_BYTES);
    }

    function lockModifyLiquidity(
        PoolKey calldata poolKey,
        IPoolManager.ModifyLiquidityParams calldata modifyLiqParams,
        address recipient
    ) external returns (bytes memory) {
        if (msg.sender != address(this)) revert OnlyOink();
        BalanceDelta delta = poolManager.modifyLiquidity(poolKey, modifyLiqParams, ZERO_BYTES);

        _settleCurrencyBalance(poolKey.currency0, delta.amount0(), recipient);
        _settleCurrencyBalance(poolKey.currency1, delta.amount1(), recipient);

        return abi.encode(delta);
    }

    function _settleCurrencyBalance(Currency currency, int128 deltaAmount, address recipient) private {
        if (deltaAmount > 0) {
            currency.transfer(address(poolManager), uint128(deltaAmount));
            poolManager.settle(currency);
        }
        if (deltaAmount < 0) {
            poolManager.take(currency, recipient, uint128(-deltaAmount));
        }
    }

    function collectProtocolFees(Currency currency) external onlyAdmin {
        uint256 amount = abi.decode(
            poolManager.lock(address(this), abi.encodeCall(this.lockCollectProtocolFees, (jug, currency))), (uint256)
        );

        emit CollectProtocolFees(Currency.unwrap(currency), jug, amount);
    }

    function collectLPFees(PoolKey[] calldata poolKeys) external onlyAdmin {
        IPoolManager.ModifyLiquidityParams memory modifyLiqParams =
            IPoolManager.ModifyLiquidityParams({tickLower: TICK_LOWER, tickUpper: TICK_UPPER, liquidityDelta: 0});

        for (uint256 i = 0; i < poolKeys.length; i++) {
            PoolKey memory poolKey = poolKeys[i];
            BalanceDelta delta = abi.decode(
                poolManager.lock(
                    address(this), abi.encodeCall(this.lockModifyLiquidity, (poolKey, modifyLiqParams, jug))
                ),
                (BalanceDelta)
            );
            emit CollectLPFees(Currency.unwrap(poolKey.currency0), jug, uint256(int256(delta.amount0())));
            emit CollectLPFees(Currency.unwrap(poolKey.currency1), jug, uint256(int256(delta.amount1())));
        }
    }

    function lockCollectProtocolFees(address recipient, Currency currency) external returns (uint256 amount) {
        if (msg.sender != address(this)) revert OnlyOink();

        amount = poolManager.balanceOf(address(this), currency.toId());
        poolManager.burn(address(this), currency.toId(), amount);

        poolManager.take(currency, recipient, amount);
    }

    function transferFarmership(address _newFarmer) external onlyAdmin {
        farmer = _newFarmer;
    }

    function setJug(address _jug) external onlyAdmin {
        jug = _jug;
    }

    function setMemelord(address _memeLord) external onlyAdmin {
        memeLord = _memeLord;
    }

    function getMemePoolInfo(address memeToken) external view returns (MemePoolInfo memory) {
        return memePoolInfo[memeToken];
    }

    function getBackersETH(address memeToken, address backer) external view returns (uint256) {
        return earlyOinkerETH[memeToken][backer];
    }

    /// @notice receive native tokens
    receive() external payable {}
}
