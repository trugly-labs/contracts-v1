/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {DeployersME20} from "../utils/DeployersME20.sol";
import {Constant} from "../../src/libraries/Constant.sol";
import {MEME20Constant} from "../../src/libraries/MEME20Constant.sol";

contract CreatorProtocolAdminTest is DeployersME20 {
    event CreatorFeesUpdated(uint256 oldFeesBps, uint256 newFeesBps);
    event ProtocolFeesUpdated(uint256 oldFeesBps, uint256 newFeesBps);
    event CreatorAddressUpdated(address oldCreator, address newCreator);
    event ProtocolAddressUpdated(address oldProtocol, address newProtocol);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event PoolOrRouterAdded(address indexed account);
    event ExemptAdded(address indexed account);

    error OnlyCreator();
    error OnlyProtocol();
    error CreatorFeeTooHigh();
    error ProtocolFeeTooHigh();
    error AddressZero();
    error AlreadyInitialized();

    function setUp() public override {
        super.setUp();
        initCreateMeme();
        initBuyMemecoin(10 ether);

        assertEq(memeToken.creator(), MEMECREATOR, "creator post setup");

        hoax(MEMECREATOR);
        memeToken.setCreatorAddress(address(this));
    }

    function test_setCreatorAddress_success() public {
        vm.expectEmit(true, true, false, true);
        emit CreatorAddressUpdated(address(this), makeAddr("bob"));
        memeToken.setCreatorAddress(makeAddr("bob"));

        assertEq(memeToken.creator(), makeAddr("bob"), "creator");
    }

    function test_setCreatorAddress_fail_not_creator() public {
        vm.expectRevert(OnlyCreator.selector);
        hoax(makeAddr("alice"));
        memeToken.setCreatorAddress(makeAddr("bob"));

        assertEq(memeToken.creator(), address(this), "creator");
    }

    function test_setCreatorFeeBps_success() public {
        uint256 newFee = 10;
        vm.expectEmit(true, true, false, true);
        emit CreatorFeesUpdated(80, newFee);
        memeToken.setCreatorFeeBps(newFee);

        assertEq(memeToken.feeBps(), newFee, "creatorFeeBps");
    }

    function test_setCreatorFeeBps_success_zero() public {
        uint256 newFee = 0;
        vm.expectEmit(true, true, false, true);
        emit CreatorFeesUpdated(80, newFee);
        memeToken.setCreatorFeeBps(newFee);

        assertEq(memeToken.feeBps(), newFee, "creatorFeeBps");
    }

    function test_setCreatorFeeBps_fail_not_creator() public {
        vm.expectRevert(OnlyCreator.selector);
        hoax(makeAddr("alice"));
        memeToken.setCreatorFeeBps(10);

        assertEq(memeToken.feeBps(), 80, "creatorFeeBps");
    }

    function test_setCreatorFeeBps_fail_too_high() public {
        vm.expectRevert(CreatorFeeTooHigh.selector);
        memeToken.setCreatorFeeBps(81);

        assertEq(memeToken.feeBps(), 80, "creatorFeeBps");
    }

    function test_addPoolOrRouter_success() public {
        assertEq(memeToken.isPoolOrRouter(makeAddr("newpool")), false, "isPoolOrRouter");
        vm.expectEmit(true, false, false, true);
        emit PoolOrRouterAdded(makeAddr("newpool"));
        memeToken.addPoolOrRouter(makeAddr("newpool"));

        assertEq(memeToken.isPoolOrRouter(makeAddr("newpool")), true, "isPoolOrRouter");
    }

    function test_addPoolOrRouter_fail_not_creator() public {
        vm.expectRevert(OnlyCreator.selector);
        hoax(makeAddr("alice"));
        memeToken.addPoolOrRouter(makeAddr("newpool"));

        assertEq(memeToken.isExempt(makeAddr("newpool")), false, "isPoolOrRouter");
    }

    function test_addExempt_success() public {
        assertEq(memeToken.isExempt(makeAddr("newpool")), false, "isExempt");
        vm.expectEmit(true, false, false, true);
        emit ExemptAdded(makeAddr("newpool"));
        memeToken.addExempt(makeAddr("newpool"));

        assertEq(memeToken.isExempt(makeAddr("newpool")), true, "isExempt");
    }

    function test_addExempt_fail_not_creator() public {
        vm.expectRevert(OnlyCreator.selector);
        hoax(makeAddr("alice"));
        memeToken.addExempt(makeAddr("newpool"));

        assertEq(memeToken.isExempt(makeAddr("newpool")), false, "isExempt");
    }

    function test_setProtocolAddress_success() public {
        vm.expectEmit(true, true, false, true);
        emit ProtocolAddressUpdated(memeceptionBaseTest.MULTISIG(), makeAddr("bob"));
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolAddress(makeAddr("bob"));

        hoax(makeAddr("bob"));
        memeToken.setProtocolFeeBps(0);
    }

    function test_setProtocolAddress_fail_not_protocol() public {
        vm.expectRevert(OnlyProtocol.selector);
        memeToken.setProtocolAddress(makeAddr("bob"));
    }

    function test_setProtocolAddress_fail_address_zero() public {
        hoax(memeceptionBaseTest.MULTISIG());
        vm.expectRevert(AddressZero.selector);
        memeToken.setProtocolAddress(address(0));
    }

    function test_setProtocolFeeBps_success() public {
        uint256 newFee = 10;
        vm.expectEmit(false, false, false, true);
        emit ProtocolFeesUpdated(MEME20Constant.MAX_PROTOCOL_FEE_BPS, newFee);
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(newFee);
    }

    function test_setProtocolFeeBps_zero_success() public {
        uint256 newFee = 0;
        vm.expectEmit(false, false, false, true);
        emit ProtocolFeesUpdated(MEME20Constant.MAX_PROTOCOL_FEE_BPS, newFee);
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setProtocolFeeBps(newFee);
    }

    function test_setProtocolFeeBps_fail_not_protocol() public {
        vm.expectRevert(OnlyProtocol.selector);
        memeToken.setProtocolFeeBps(10);
    }

    function test_setProtocolFeeBps_fail_too_high() public {
        hoax(memeceptionBaseTest.MULTISIG());
        vm.expectRevert(ProtocolFeeTooHigh.selector);
        memeToken.setProtocolFeeBps(MEME20Constant.MAX_PROTOCOL_FEE_BPS + 1);
    }

    function test_setTreasuryAddress_success() public {
        vm.expectEmit(true, true, false, true);
        emit TreasuryUpdated(treasury, makeAddr("bob"));
        hoax(memeceptionBaseTest.MULTISIG());
        memeToken.setTreasuryAddress(makeAddr("bob"));
    }

    function test_setTreasuryAddress_fail_not_protocol() public {
        vm.expectRevert(OnlyProtocol.selector);
        memeToken.setTreasuryAddress(makeAddr("bob"));
    }

    function test_already_initialized() public {
        address[] memory routers = new address[](1);
        routers[0] = makeAddr("router");
        hoax(memeceptionBaseTest.MULTISIG());
        vm.expectRevert(AlreadyInitialized.selector);
        memeToken.initialize(address(2), address(1), 1, 1, address(3), routers, routers);
    }

    function test_post_memeception() public {
        assertEq(memeToken.feeBps(), 80, "post setup feeBps");
        assertEq(memeToken.isExempt(address(memeception)), true, "post setup isExempt memeception");
        assertEq(memeToken.isExempt(address(memeToken)), true, "post setup isExempt memeToken");
        assertEq(memeToken.isExempt(address(0)), true, "post setup isExempt address(0)");
        assertEq(memeToken.isExempt(MEMECREATOR), true, "post setup isExempt creator");
        assertEq(memeToken.isExempt(address(treasury)), true, "post setup isExempt treasury");
        assertEq(memeToken.isExempt(memeceptionBaseTest.MULTISIG()), true, "post setup isExempt protocol multisig");
        assertEq(
            memeToken.isExempt(0x231278eDd38B00B07fBd52120CEf685B9BaEBCC1), true, "post setup isExmeplt UncxV3Lockers"
        );
    }
}
