// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "rain.solmem/lib/LibBytes.sol";

import "src/concrete/Extrospection.sol";

/// @title ExtrospectionBytecodeTest
/// @notice Tests the Extrospection contract implementation of
/// `IExtrospectBytecodeV2`.
contract ExtrospectionBytecodeTest is Test {
    using LibBytes for bytes;

    /// Extrospection can return the bytecode of any account.
    function testBytecode(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(account.code, extrospection.bytecode(account));
        assertEq("", extrospection.bytecode(address(0)));
    }

    /// Extrospection can return the bytecode hash of any account.
    function testBytecodeHash(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(account.codehash, extrospection.bytecodeHash(account));
        assertEq(0, extrospection.bytecodeHash(address(0)));
    }

    /// Extrospection can return the EVM opcodes present in any account as a
    /// scan bitmap.
    function testScanEVMOpcodesPresentInAccount(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(account.code),
            extrospection.scanEVMOpcodesPresentInAccount(account)
        );
    }

    /// Extrospection can return the EVM opcodes reachable during EVM execution
    /// in any account as a scan bitmap.
    function testScanEVMOpcodesReachableInAccount(address account) external {
        Extrospection extrospection = new Extrospection();

        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(account.code),
            extrospection.scanEVMOpcodesReachableInAccount(account)
        );
    }
}
