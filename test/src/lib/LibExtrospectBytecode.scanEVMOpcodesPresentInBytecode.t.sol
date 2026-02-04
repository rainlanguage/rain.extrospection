// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes, LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

contract LibExtrospectBytecodeScanEVMOpcodesPresentInBytecodeTest is Test {
    using LibBytes for bytes;

    /// External version of scanEVMOpcodesPresentInBytecode for testing.
    function scanEVMOpcodesPresentInBytecodeExternal(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    function testScanEVMOpcodesPresentSimple() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"04050607"), 0xF0);
    }

    function testScanEVMOpcodesPresentPush1() public pure {
        // PUSH1 01
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"60016002"), 2 ** 0x60);
    }

    /// Check that non-EOF bytecode fuzz matches reference implementation.
    function testScanEVMOpcodesPresentReference(bytes memory data) public pure {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(data));
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(data),
            LibExtrospectionSlow.scanEVMOpcodesPresentInBytecodeSlow(data)
        );
    }

    /// Check that EOF bytecode reverts as not supported.
    function testScanEVMOpcodesPresentRevertsOnEOF() public {
        bytes memory eofBytecode = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanEVMOpcodesPresentInBytecodeExternal(eofBytecode);
    }
}
