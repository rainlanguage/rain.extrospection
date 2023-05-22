// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "sol.lib.memory/LibBytes.sol";

import "src/Extrospection.sol";

contract ExtrospectionBytecodeTest is Test {
    using LibBytes for bytes;

    function testBytecode(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(account.code, extrospection.bytecode(account));
        assertEq("", extrospection.bytecode(address(0)));
    }

    function testBytecodeHash(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(account.codehash, extrospection.bytecodeHash(account));
        assertEq(0, extrospection.bytecodeHash(address(0)));
    }

    function testScanEVMOpcodesPresentInAccount(address account) external {
        Extrospection extrospection = new Extrospection();

        bytes memory code = account.code;
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesPresentInMemory(code.dataPointer(), code.length),
            extrospection.scanEVMOpcodesPresentInAccount(account)
        );
    }
}
