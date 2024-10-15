// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes, LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

contract LibExtrospectScanEVMOpcodesPresentInBytecodeTest is Test {
    using LibBytes for bytes;

    function testScanEVMOpcodesPresentSimple() public {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"04050607"), 0xF0);
    }

    function testScanEVMOpcodesPresentPush1() public {
        // PUSH1 01
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"60016002"), 2 ** 0x60);
    }

    function testScanEVMOpcodesPresentReference(bytes memory data) public {
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(data),
            LibExtrospectionSlow.scanEVMOpcodesPresentInBytecodeSlow(data)
        );
    }
}
