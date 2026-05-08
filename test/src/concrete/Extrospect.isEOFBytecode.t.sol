// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectIsEOFBytecodeTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testIsEOFBytecodeEquivalenceFuzz(bytes memory bytecode) external view {
        assertEq(extrospect.isEOFBytecode(bytecode), LibExtrospectBytecode.isEOFBytecode(bytecode));
    }

    function testIsEOFBytecodeEquivalenceTrue() external view {
        bytes memory eof = hex"EF00010203";
        assertTrue(extrospect.isEOFBytecode(eof));
        assertTrue(LibExtrospectBytecode.isEOFBytecode(eof));
    }

    function testIsEOFBytecodeEquivalenceFalse() external view {
        bytes memory notEof = hex"6080";
        assertFalse(extrospect.isEOFBytecode(notEof));
        assertFalse(LibExtrospectBytecode.isEOFBytecode(notEof));
    }
}
