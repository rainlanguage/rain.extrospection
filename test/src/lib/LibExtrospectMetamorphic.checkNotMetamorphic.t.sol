// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {EVM_OP_CREATE, EVM_OP_CREATE2} from "src/lib/EVMOpcodes.sol";
import {METAMORPHIC_METADATA} from "test/lib/LibExtrospectBytecode.testConstants.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {HasDelegatecall} from "test/concrete/HasDelegatecall.sol";
import {HasCreate2} from "test/concrete/HasCreate2.sol";
import {HasCallcode} from "test/concrete/HasCallcode.sol";
import {HasCreate} from "test/concrete/HasCreate.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {CreateChildFactory} from "test/concrete/CreateChildFactory.sol";
import {Create2ChildFactory} from "test/concrete/Create2ChildFactory.sol";
import {LibExtrospectTestEtch} from "test/lib/LibExtrospectTestEtch.sol";

contract LibExtrospectMetamorphicCheckNotMetamorphicTest is Test {
    /// External wrapper for revert tests.
    function checkNotMetamorphicExternal(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// External wrapper for address entry point revert tests.
    function checkNotMetamorphicAddressExternal(address account) external view {
        LibExtrospectMetamorphic.checkNotMetamorphic(account);
    }

    /// Clean contract passes.
    function testCheckNotMetamorphicClean() external {
        NonMetamorphic clean = new NonMetamorphic();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(clean).code);
    }

    /// Empty bytecode passes.
    function testCheckNotMetamorphicEmpty() external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(hex"");
    }

    /// An account with no code reads as empty bytecode and so passes.
    function testCheckNotMetamorphicCodelessAccount() external view {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        LibExtrospectMetamorphic.checkNotMetamorphic(codeless.code);
    }

    /// METAMORPHIC_METADATA reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnMetamorphicMetadata() external {
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(METAMORPHIC_METADATA);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(METAMORPHIC_METADATA);
    }

    /// Contract with SELFDESTRUCT reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnSelfdestruct() external {
        HasSelfdestruct c = new HasSelfdestruct();
        bytes memory code = address(c).code;
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// Contract with DELEGATECALL reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnDelegatecall() external {
        HasDelegatecall c = new HasDelegatecall();
        bytes memory code = address(c).code;
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// Contract with CREATE2 reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnCreate2() external {
        HasCreate2 c = new HasCreate2();
        bytes memory code = address(c).code;
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// Contract with CALLCODE reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnCallcode() external {
        HasCallcode c = new HasCallcode();
        bytes memory code = address(c).code;
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// Contract with CREATE reverts with Metamorphic error.
    function testCheckNotMetamorphicRevertsOnCreate() external {
        HasCreate c = new HasCreate();
        bytes memory code = address(c).code;
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// A factory that deploys a single fixed child type with CREATE is rejected,
    /// with the CREATE bit alone reported.
    function testCheckNotMetamorphicRevertsOnCreateChildFactory() external {
        CreateChildFactory factory = new CreateChildFactory();
        bytes memory code = address(factory).code;
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 risk = 1 << uint256(EVM_OP_CREATE);
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(code), risk);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// A factory that deploys a single fixed child type with CREATE2 is rejected,
    /// with the CREATE2 bit alone reported.
    function testCheckNotMetamorphicRevertsOnCreate2ChildFactory() external {
        Create2ChildFactory factory = new Create2ChildFactory();
        bytes memory code = address(factory).code;
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 risk = 1 << uint256(EVM_OP_CREATE2);
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(code), risk);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicExternal(code);
    }

    /// EOF bytecode reverts with EOFBytecodeNotSupported.
    function testCheckNotMetamorphicRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNotMetamorphicExternal(hex"EF00010203");
    }

    /// Address entry point: a codeless account reverts with `CodelessAccount`
    /// carrying the address. The bytes entry point passes the same account's
    /// (empty) code, pinned by `testCheckNotMetamorphicCodelessAccount`; only
    /// the address boundary can refuse to vouch for a codeless account.
    function testCheckNotMetamorphicAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        this.checkNotMetamorphicAddressExternal(codeless);
    }

    /// Address entry point: clean contract passes.
    function testCheckNotMetamorphicAddressClean() external {
        NonMetamorphic clean = new NonMetamorphic();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(clean));
    }

    /// Address entry point: contract with SELFDESTRUCT reverts with the same
    /// `Metamorphic` error as the bytes entry point.
    function testCheckNotMetamorphicAddressRevertsOnSelfdestruct() external {
        HasSelfdestruct c = new HasSelfdestruct();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.checkNotMetamorphicAddressExternal(address(c));
    }

    /// Address entry point: EOF code etched onto an account reverts with
    /// `EOFBytecodeNotSupported` via delegation to the bytes entry point.
    function testCheckNotMetamorphicAddressRevertsOnEOF() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"EF00010203");
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNotMetamorphicAddressExternal(target);
    }

    /// Fuzz: for an account with nonempty non-EOF code, the address entry
    /// point and the bytes entry point agree: both revert with the same
    /// `Metamorphic` bitmap or both pass.
    function testCheckNotMetamorphicAddressEquivalenceFuzz(bytes memory code) external {
        vm.assume(code.length > 0);
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));
        address target = address(0xBEEF);
        LibExtrospectTestEtch.assumeEtch(vm, target, code);

        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(code);
        if (risk != 0) {
            vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        }
        this.checkNotMetamorphicAddressExternal(target);
    }

    /// Fuzz: checkNotMetamorphic reverts iff scanMetamorphicRisk is non-zero.
    function testCheckNotMetamorphicFuzz(bytes memory data) external {
        // Skip EOF bytecode — both functions revert with a different error.
        vm.assume(data.length < 2 || data[0] != 0xEF || data[1] != 0x00);

        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(data);
        if (risk != 0) {
            vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
            this.checkNotMetamorphicExternal(data);
        } else {
            // Should not revert.
            this.checkNotMetamorphicExternal(data);
        }
    }
}
