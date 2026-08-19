// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectCheckNotEOFBytecodeTest is ExtrospectEquivalence {
    function libCheckNotEOFBytecodeExternal(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    function testCheckNotEOFBytecodeEquivalencePass() external view {
        bytes memory clean = hex"6080";
        extrospect.checkNotEOFBytecode(clean);
        LibExtrospectBytecode.checkNotEOFBytecode(clean);
    }

    /// Bytecode whose only notable content is a reachable CREATE (a metamorphic
    /// risk op) is NOT EOF, so this must return without reverting. Pins that
    /// `checkNotEOFBytecode` delegates to the EOF check and not to the
    /// metamorphic check, which would revert `Metamorphic(1 << 0xF0)` here.
    function testCheckNotEOFBytecodeMetamorphicButNotEOF() external view {
        bytes memory createOnly = hex"F0";
        extrospect.checkNotEOFBytecode(createOnly);
        LibExtrospectBytecode.checkNotEOFBytecode(createOnly);
    }

    function testCheckNotEOFBytecodeEquivalenceRevert() external {
        bytes memory eof = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        extrospect.checkNotEOFBytecode(eof);
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.libCheckNotEOFBytecodeExternal(eof);
    }
}
