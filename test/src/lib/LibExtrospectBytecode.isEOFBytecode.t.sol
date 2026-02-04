// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

contract LibExtrospectBytecodeIsEOFBytecodeTest is Test {
    /// External version of checkNotEOFBytecode for testing.
    function checkNotEOFBytecodeExternal(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    /// Test that an empty bytecode is not EOF.
    function testIsEOFBytecodeEmpty() external pure {
        assertFalse(LibExtrospectBytecode.isEOFBytecode(hex""));
    }

    /// Test that a single bytecode is not EOF.
    function testIsEOFBytecodeSingleByte() external pure {
        assertFalse(LibExtrospectBytecode.isEOFBytecode(hex"EF"));
    }

    /// Test that a non-EOF bytecode is not EOF.
    function testIsEOFBytecodeNonEOF() external pure {
        assertFalse(LibExtrospectBytecode.isEOFBytecode(hex"6001600055"));
    }

    /// Test that an EOF bytecode is detected.
    function testIsEOFBytecodeEOF() external pure {
        assertTrue(LibExtrospectBytecode.isEOFBytecode(hex"EF00010203"));
    }

    /// Test that checkNotEOFBytecode reverts on EOF bytecode.
    function testCheckNotEOFBytecodeRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNotEOFBytecodeExternal(hex"EF00010203");
    }

    /// Test that checkNotEOFBytecode does not revert on non-EOF bytecode.
    function testCheckNotEOFBytecodeDoesNotRevertOnNonEOF() external view {
        this.checkNotEOFBytecodeExternal(hex"6001600055");
    }

    /// Fuzz test isEOFBytecode against reference implementation.
    function testIsEOFBytecodeFuzz(bytes memory bytecode) external pure {
        vm.assertEq(LibExtrospectBytecode.isEOFBytecode(bytecode), LibExtrospectionSlow.isEOFBytecodeSlow(bytecode));
    }
}
