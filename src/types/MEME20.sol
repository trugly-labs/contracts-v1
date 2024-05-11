/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {Constant} from "../libraries/Constant.sol";
import {ISwapRouter} from "../interfaces/external/ISwapRouter.sol";
import {IUniswapV3Pool} from "../interfaces/external/IUniswapV3Pool.sol";
import {MEME20Constant} from "../libraries/MEME20Constant.sol";

/// @title ERC20 memecoin created by Trugly
/// @notice Contract automatically generated by https://www.trugly.meme
contract MEME20 is ERC20 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       EVENTS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    event CreatorFeesUpdated(uint256 oldFeesBps, uint256 newFeesBps);
    event ProtocolFeesUpdated(uint256 oldFeesBps, uint256 newFeesBps);
    event CreatorAddressUpdated(address oldCreator, address newCreator);
    event ProtocolAddressUpdated(address oldProtocol, address newProtocol);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event PoolOrRouterAdded(address indexed account);
    event ExemptAdded(address indexed account);

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       ERRORS                      */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    error OnlyCreator();
    error OnlyProtocol();
    error CreatorFeeTooHigh();
    error ProtocolFeeTooHigh();
    error AddressZero();
    error AlreadyInitialized();

    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    /*                       STORAGE                     */
    /* ¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯¯\_(ツ)_/¯*/
    bool private _initialized;
    address public creator;
    address private _protocol;

    address private _pTreasury;

    uint256 public feeBps;
    uint256 private _pFeesBps;

    mapping(address => bool) private _exemptFees;
    mapping(address => bool) private _routersAndPools;

    modifier onlyCreator() {
        if (msg.sender != creator) revert OnlyCreator();
        _;
    }

    modifier onlyProtocol() {
        if (msg.sender != _protocol) revert OnlyProtocol();
        _;
    }

    constructor(string memory _name, string memory _symbol, address _creator)
        ERC20(_name, _symbol, MEME20Constant.TOKEN_DECIMALS)
    {
        // Set Creator
        creator = _creator;
        // Set Temporarily to Launchpad (will be transfer to protocol after deployment and setting routers & pools)
        _protocol = msg.sender;

        // Exempt
        _exemptFees[msg.sender] = true;
        _exemptFees[address(this)] = true;
        _exemptFees[address(0)] = true;
        _exemptFees[_creator] = true;

        // Mint to Launchpad
        _mint(msg.sender, MEME20Constant.TOKEN_TOTAL_SUPPLY);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (amount == 0) {
            return super.transferFrom(from, to, 0);
        }

        // @dev skip to avoid double fees;
        bool skip = _routersAndPools[from] && _routersAndPools[to];

        if (!_exemptFees[from] && !_exemptFees[to] && !skip && _routersAndPools[from]) {
            uint256 feesCreator = amount.mulDiv(feeBps, 1e4);
            uint256 feesProtocol = amount.mulDiv(_pFeesBps, 1e4);
            amount = amount - feesCreator - feesProtocol;
            if (feesCreator > 0) super.transfer(creator, feesCreator);
            if (feesProtocol > 0) super.transfer(_pTreasury, feesProtocol);
        }

        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (amount == 0) {
            return super.transfer(to, 0);
        }

        // @dev skip to avoid double fees;
        bool skip = _routersAndPools[msg.sender] && _routersAndPools[to];

        if (!_exemptFees[msg.sender] && !_exemptFees[to] && !skip && _routersAndPools[msg.sender]) {
            uint256 feesCreator = amount.mulDiv(feeBps, 1e4);
            uint256 feesProtocol = amount.mulDiv(_pFeesBps, 1e4);
            amount = amount - feesCreator - feesProtocol;
            if (feesCreator > 0) super.transfer(creator, feesCreator);
            if (feesProtocol > 0) super.transfer(_pTreasury, feesProtocol);
        }

        return super.transfer(to, amount);
    }

    function isExempt(address account) public view returns (bool) {
        return _exemptFees[account];
    }

    function isPoolOrRouter(address account) public view returns (bool) {
        return _routersAndPools[account];
    }

    function addPoolOrRouter(address _contract) public onlyCreator {
        _routersAndPools[_contract] = true;
        emit PoolOrRouterAdded(_contract);
    }

    function addExempt(address _contract) public onlyCreator {
        _exemptFees[_contract] = true;
        emit ExemptAdded(_contract);
    }

    function setCreatorFeeBps(uint256 _newFeeBps) public onlyCreator {
        if (_newFeeBps > MEME20Constant.MAX_CREATOR_FEE_BPS) revert CreatorFeeTooHigh();
        emit CreatorFeesUpdated(feeBps, _newFeeBps);
        feeBps = _newFeeBps;
    }

    function setCreatorAddress(address _creator) public onlyCreator {
        emit CreatorAddressUpdated(creator, _creator);
        creator = _creator;
    }

    function recovery(address _stuckToken) public onlyCreator {
        if (_stuckToken == address(0)) {
            creator.safeTransferETH(address(this).balance);
        } else {
            if (_stuckToken != address(this)) {
                ERC20(_stuckToken).safeTransfer(msg.sender, ERC20(_stuckToken).balanceOf(address(this)));
            }
        }
    }

    function setProtocolFeeBps(uint256 _newFeeBps) public onlyProtocol {
        if (_newFeeBps > MEME20Constant.MAX_PROTOCOL_FEE_BPS) revert ProtocolFeeTooHigh();
        emit ProtocolFeesUpdated(_pFeesBps, _newFeeBps);
        _pFeesBps = _newFeeBps;
    }

    function setProtocolAddress(address _protocolAddress) public onlyProtocol {
        if (_protocolAddress == address(0)) revert AddressZero();
        emit ProtocolAddressUpdated(_protocol, _protocolAddress);
        _protocol = _protocolAddress;
    }

    function setTreasuryAddress(address _treasury) public onlyProtocol {
        if (_treasury == address(0)) revert AddressZero();
        emit TreasuryUpdated(_pTreasury, _treasury);
        _pTreasury = _treasury;
    }

    function initialize(
        address _protocolAddr,
        address _protocolTreasury,
        uint256 _protocolFeesBps,
        uint256 _creatorFeesBps,
        address _pool,
        address[] calldata _routers,
        address[] calldata _exemptsAddr
    ) public onlyProtocol {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;
        feeBps = _creatorFeesBps;

        // Set Protocol
        _pFeesBps = _protocolFeesBps;
        _pTreasury = _protocolTreasury;

        _exemptFees[_pTreasury] = true;
        _exemptFees[_protocolAddr] = true;

        // Uniswap
        for (uint256 i = 0; i < _routers.length; i++) {
            _routersAndPools[_routers[i]] = true;
            emit PoolOrRouterAdded(_routers[i]);
        }
        _routersAndPools[_pool] = true;
        emit PoolOrRouterAdded(_pool);

        for (uint256 i = 0; i < _exemptsAddr.length; i++) {
            _exemptFees[_exemptsAddr[i]] = true;
            emit ExemptAdded(_exemptsAddr[i]);
        }

        // Transfer to Protocol
        setProtocolAddress(_protocolAddr);
    }
}
