// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "sol.lib.memory/LibBytes.sol";

import "src/lib/LibExtrospectBytecode.sol";
import "test/lib/LibExtrospectionSlow.sol";

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
