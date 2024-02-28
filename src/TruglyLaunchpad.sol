/// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SignatureChecker} from "@openzeppelin/utils/cryptography/SignatureChecker.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {WETH} from "@solmate/tokens/WETH";

import {SqrtPriceX96} from "./libraries/external/SqrtPriceX96.sol";
import {INonfungiblePositionManager} from "./interfaces/external/INonfungiblePositionManager.sol";
import {ITruglyLaunchpad} from "./interfaces/ITruglyLaunchpad.sol";
import {IUniswapV3Factory} from "./interfaces/external/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/external/IUniswapV3Pool.sol";
import {FullMath} from "./libraries/external/FullMath.sol";
import {SafeCast} from "./libraries/external/SafeCast.sol";
import {MEMERC20} from "./types/MEMERC20.sol";
import {Constant} from "./libraries/Constant.sol";

/// @title The interface for the Trugly Launchpad
/// @notice Launchpad is in charge of creating MEMERC20 and their Memeception
contract TruglyLaunchpad is ITruglyLaunchpad, Constant {
    using FullMath for uint256;
    using SafeCast for uint256;
    using SafeTransferLib for WETH;
    using SafeTransferLib for MEMERC20;
    using SafeTransferLib for address;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Emitted when a memeceptions is created
    event MemeCreated(
        address indexed memeToken, address indexed creator, uint256 cap, uint256 startAt, uint256 creatorSwapFeeBps
    );

    /// @dev Emitted when a OG participates in the memeceptions
    event MemeceptionDeposit(address indexed memeToken, address indexed og, uint256 amount);

    /// @dev Emitted when liquidity has been added to the UniV3 Pool
    event MemeLiquidityAdded(address indexed memeToken, uint256 amount0, uint256 amount1);

    /// @dev Emitted when an OG claims their allocated Meme tokens
    event MemeClaimed(address indexed memeToken, address indexed claimer, uint256 amountMeme);

    /// @dev Emitted when an OG exits the memeceptions
    event MemeceptionExit(address indexed memeToken, address indexed backer, uint256 amount);

    /// @dev Emitted when the admin is updated
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    /// @dev Emited when the memeSigner is updated
    event MemeSignerUpdated(address indexed oldSigner, address indexed newSigner);

    //     event CollectProtocolFees(address indexed token, address recipient, uint256 amount);

    //     event CollectLPFees(address indexed token, address recipient, uint256 amount);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Thrown when the caller is not the admin
    error OnlyAdmin();

    /// @dev Thrown when the swap fee is too high
    error MemeSwapFeeTooHigh();

    /// @dev Thrown when the Meme symbol already exists
    error MemeSymbolExist();

    // @dev Thrown when the memeceptions cap is too low or too high
    error InvalidMemeceptionCap();

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

    /// @dev Thrown when the signature is invalid
    error InvalidMemeceptionSig();

    /// @dev Zero bytes
    bytes internal constant ZERO_BYTES = new bytes(0);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Address of the UniswapV3 Factory
    IUniswapV3Factory public immutable v3Factory;

    /// @dev Address of the UniswapV3 NonfungiblePositionManager
    INonfungiblePositionManager public immutable v3PositionManager;

    /// @dev Address of the WETH9 contract
    WETH public immutable WETH9;

    /// @dev Address of the TruglyLaunchpad Admin
    address private admin;

    /// @dev Address of the signer for any memeceptions
    address private memeSigner;

    /// @dev Mapping of memeToken => memeceptions
    mapping(address => Memeception) private memeceptions;

    /// @dev Amount contributed per OG
    mapping(address => mapping(address => uint256)) balanceOG;

    /// @dev Mapping to determine if a token symbol already exists
    mapping(string => bool) private memeSymbolExist;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       MODIFIERS                   */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/

    /// @dev Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        if (admin != msg.sender) revert OnlyAdmin();
        _;
    }

    constructor(address _v3Factory, address _v3PositionManager, address _WETH9, address _memeSigner) {
        if (
            _v3Factory == address(0) || _v3PositionManager == address(0) || _WETH9 == address(0)
                || _memeSigner == address(0)
        ) {
            revert ZeroAddress();
        }
        v3Factory = IUniswapV3Factory(_v3Factory);
        v3PositionManager = INonfungiblePositionManager(_v3PositionManager);
        WETH9 = WETH(_WETH9);
        admin = msg.sender;
        memeSigner = _memeSigner;

        emit AdminUpdated(address(0), admin);
        emit MemeSignerUpdated(address(0), memeSigner);
    }

    /// @inheritdoc ITruglyLaunchpad
    function createMeme(MemeCreationParams calldata params) external returns (address, address) {
        _verifyCreateMeme(params);
        MEMERC20 memeToken = new MEMERC20(params.name, params.symbol);
        (address token0, address token1) = _getTokenOrder(address(memeToken));

        address pool = v3Factory.createPool(token0, token1, UNI_LP_SWAPFEE);

        memeceptions[address(memeToken)] = Memeception({
            pool: pool,
            creator: msg.sender,
            startAt: params.startAt,
            balance: 0,
            cap: params.cap,
            swapFeeBps: params.swapFeeBps
        });

        memeSymbolExist[params.symbol] = true;

        emit MemeCreated(address(memeToken), msg.sender, params.cap, params.startAt, params.swapFeeBps);
        return (address(memeToken), pool);
    }

    /// @dev Verify the validity of the parameters for the creation of a memeception
    /// @param params List of parameters for the creation of a memeception
    /// Revert if any parameters are invalid
    function _verifyCreateMeme(MemeCreationParams calldata params) internal view {
        if (memeSymbolExist[params.symbol]) revert MemeSymbolExist();
        if (params.cap < MEMECEPTION_MIN_ETHCAP || params.cap > MEMECEPTION_MAX_ETHCAP) {
            revert InvalidMemeceptionCap();
        }
        if (
            params.startAt < block.timestamp + MEMECEPTION_MIN_START_AT
                || params.startAt > block.timestamp + MEMECEPTION_MAX_START_AT
        ) revert InvalidMemeceptionDate();
        if (params.swapFeeBps > CREATOR_MAX_FEE_BPS) revert MemeSwapFeeTooHigh();
    }

    /// @inheritdoc ITruglyLaunchpad
    function depositMemeception(address memeToken, bytes calldata sig) external payable {
        _verifyDeposit(memeToken, sig);
        uint80 msgValueUint80 = msg.value.toUint80();
        Memeception storage memeception = memeceptions[memeToken];

        uint80 amount = memeception.balance + msgValueUint80 <= memeception.cap
            ? msgValueUint80
            : memeception.cap - memeception.balance;

        if (memeception.balance + amount == memeception.cap) {
            /// Cap is reached - Adding liquidity to Uni V3 Pool
            _addLiquidityToUniV3Pool(memeToken, memeception.cap);

            /// Refund as the Cap has been reached
            if (msgValueUint80 > amount) {
                (bool success,) = msg.sender.call{value: uint256(msgValueUint80 - amount)}("");
                if (!success) revert("Refund failed");
            }

            emit MemeLiquidityAdded(memeToken, memeception.cap, TOKEN_LP_SUPPLY);
        }

        memeception.balance += amount;
        balanceOG[memeToken][msg.sender] = uint256(amount);
        emit MemeceptionDeposit(memeToken, msg.sender, amount);
    }

    /// @dev Add liquidity to the UniV3 Pool and initialize the pool
    /// @param memeToken Address of the MEMERC20
    /// @param amountETH Amount of ETH to add to the pool
    function _addLiquidityToUniV3Pool(address memeToken, uint256 amountETH) internal {
        (address token0, address token1) = _getTokenOrder(address(memeToken));
        uint256 amount0 = token0 == address(WETH9) ? amountETH : TOKEN_LP_SUPPLY;
        uint256 amount1 = token0 == address(WETH9) ? TOKEN_LP_SUPPLY : amountETH;

        uint160 sqrtPriceX96 = SqrtPriceX96.calcSqrtPriceX96(amount0, amount1);
        IUniswapV3Pool(memeceptions[memeToken].pool).initialize(sqrtPriceX96);

        WETH9.deposit{value: amountETH}();
        WETH9.safeApprove(address(v3PositionManager), amountETH);
        MEMERC20(memeToken).safeApprove(address(v3PositionManager), TOKEN_LP_SUPPLY);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: UNI_LP_SWAPFEE,
            tickLower: TICK_LOWER,
            tickUpper: TICK_UPPER,
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
    /// @param memeToken Address of the MEMERC20
    /// @return bool True if the pool is initialized with liquidity
    function _isLaunched(address memeToken) private view returns (bool) {
        return (memeceptions[memeToken].cap > 0 && memeceptions[memeToken].balance >= memeceptions[memeToken].cap);
    }

    /// @dev Verify the validity of the deposit in a Memeception
    /// @param memeToken Address of the MEMERC20
    /// @param sig Signature to authorize the deposit
    /// Revert if any parameters are invalid
    function _verifyDeposit(address memeToken, bytes calldata sig) internal view virtual {
        if (msg.value == 0) revert ZeroAmount();
        if (_isLaunched(memeToken)) revert MemeLaunched();
        if (
            block.timestamp < memeceptions[memeToken].startAt
                || block.timestamp > memeceptions[memeToken].startAt + MEMECEPTION_DEADLINE
        ) {
            revert InvalidMemeceptionDate();
        }
        if (balanceOG[memeToken][msg.sender] > 0) revert DuplicateOG();
        if (
            !SignatureChecker.isValidSignatureNow(
                memeSigner, keccak256(abi.encode(memeToken, msg.sender, msg.value, block.chainid)), sig
            )
        ) revert InvalidMemeceptionSig();
    }

    /// @inheritdoc ITruglyLaunchpad
    function exitMemeception(address memeToken) external {
        if (_isLaunched(memeToken)) revert MemeLaunched();
        if (block.timestamp < memeceptions[memeToken].startAt + MEMECEPTION_DEADLINE) {
            revert InvalidMemeceptionDate();
        }

        uint256 exitAmount = balanceOG[memeToken][msg.sender];
        balanceOG[memeToken][msg.sender] = 0;
        msg.sender.safeTransferETH(exitAmount);

        emit MemeceptionExit(memeToken, msg.sender, exitAmount);
    }

    /// @inheritdoc ITruglyLaunchpad
    function claimMemeception(address memeToken) external {
        if (!_isLaunched(memeToken)) revert MemeNotLaunched();

        uint256 ogPct = balanceOG[memeToken][msg.sender].mulDiv(1e18, uint256(memeceptions[memeToken].cap));
        uint256 claimableMeme = TOKEN_MEMECEPTION_SUPPLY.mulDiv(ogPct, 1e18);

        MEMERC20 meme = MEMERC20(memeToken);

        if (claimableMeme > meme.balanceOf(address(this))) {
            claimableMeme = meme.balanceOf(address(this));
        }

        balanceOG[memeToken][msg.sender] = 0;
        meme.safeTransfer(msg.sender, claimableMeme);

        emit MemeClaimed(memeToken, msg.sender, claimableMeme);
    }

    // function collectProtocolFees(Currency currency) external onlyAdmin {
    //     uint256 amount = abi.decode(
    //         poolManager.lock(address(this), abi.encodeCall(this.lockCollectProtocolFees, (jug, currency))), (uint256)
    //     );

    //     emit CollectProtocolFees(Currency.unwrap(currency), jug, amount);
    // }

    // function collectLPFees(PoolKey[] calldata poolKeys) external onlyAdmin {
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

    /// @inheritdoc ITruglyLaunchpad
    function transferAdmin(address _newAdmin) external onlyAdmin {
        emit AdminUpdated(admin, _newAdmin);
        admin = _newAdmin;
    }

    /// @inheritdoc ITruglyLaunchpad
    function setMemeSigner(address _memeSigner) external onlyAdmin {
        emit MemeSignerUpdated(memeSigner, _memeSigner);
        memeSigner = _memeSigner;
    }

    /// @inheritdoc ITruglyLaunchpad
    function getMemeception(address memeToken) external view returns (Memeception memory) {
        return memeceptions[memeToken];
    }

    /// @inheritdoc ITruglyLaunchpad
    function getBalanceOG(address memeToken, address og) external view returns (uint256) {
        return balanceOG[memeToken][og];
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
