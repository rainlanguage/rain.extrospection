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

    /// METAMORPHIC_METADATA reverts due to reachable SELFDESTRUCT.
    function testCheckNotMetamorphicRevertsOnMetamorphicMetadata() external {
        vm.expectRevert();
        this.checkNotMetamorphicExternal(METAMORPHIC_METADATA);
    }

    /// Contract with SELFDESTRUCT reverts.
    function testCheckNotMetamorphicRevertsOnSelfdestruct() external {
        HasSelfdestruct c = new HasSelfdestruct();
        vm.expectRevert();
        this.checkNotMetamorphicExternal(address(c).code);
    }

    /// Contract with DELEGATECALL reverts.
    function testCheckNotMetamorphicRevertsOnDelegatecall() external {
        HasDelegatecall c = new HasDelegatecall();
        vm.expectRevert();
        this.checkNotMetamorphicExternal(address(c).code);
    }

    /// Contract with CREATE2 reverts.
    function testCheckNotMetamorphicRevertsOnCreate2() external {
        HasCreate2 c = new HasCreate2();
        vm.expectRevert();
        this.checkNotMetamorphicExternal(address(c).code);
    }

    /// EOF bytecode reverts.
    function testCheckNotMetamorphicRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNotMetamorphicExternal(hex"EF00010203");
    }
}
