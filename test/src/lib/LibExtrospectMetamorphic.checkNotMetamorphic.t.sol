// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {METAMORPHIC_METADATA} from "test/lib/LibExtrospectBytecode.testConstants.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {HasDelegatecall} from "test/concrete/HasDelegatecall.sol";
import {HasCreate2} from "test/concrete/HasCreate2.sol";
import {HasCallcode} from "test/concrete/HasCallcode.sol";
import {HasCreate} from "test/concrete/HasCreate.sol";
import {CleanContract} from "test/concrete/CleanContract.sol";

contract LibExtrospectMetamorphicCheckNotMetamorphicTest is Test {
    /// External wrapper for revert tests.
    function checkNotMetamorphicExternal(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// Clean contract passes.
    function testCheckNotMetamorphicClean() external {
        CleanContract clean = new CleanContract();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(clean).code);
    }

    /// Empty bytecode passes.
    function testCheckNotMetamorphicEmpty() external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(hex"");
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

    /// EOF bytecode reverts with EOFBytecodeNotSupported.
    function testCheckNotMetamorphicRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNotMetamorphicExternal(hex"EF00010203");
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
