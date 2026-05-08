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

    function testCheckNotEOFBytecodeEquivalenceRevert() external {
        bytes memory eof = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        extrospect.checkNotEOFBytecode(eof);
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.libCheckNotEOFBytecodeExternal(eof);
    }
}
