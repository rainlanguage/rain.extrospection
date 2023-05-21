// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "sol.lib.memory/LibBytes.sol";

import "src/LibExtrospection.sol";
import "./LibExtrospectionSlow.sol";

contract LibExtrospectionScanEVMOpcodesPresentTest is Test {
    using LibBytes for bytes;

    function testScanEVMOpcodesPresentSimple() public {
        assembly ("memory-safe") {
            mstore(0x20, hex"04050607")
        }

        assertEq(LibExtrospection.scanEVMOpcodesPresent(Pointer.wrap(0x20), 4), 0xF0);
    }

    function testScanEVMOpcodesPresentPush1() public {
        assembly ("memory-safe") {
            // PUSH1 01
            mstore(0x20, hex"60016002")
        }

        assertEq(LibExtrospection.scanEVMOpcodesPresent(Pointer.wrap(0x20), 4), 2 ** 0x60);
    }

    function testScanEVMOpcodesPresentReference(bytes memory data) public {
        assertEq(
            LibExtrospection.scanEVMOpcodesPresent(data.dataPointer(), data.length),
            LibExtrospectionSlow.scanEVMOpcodesPresentSlow(data)
        );
    }
}
