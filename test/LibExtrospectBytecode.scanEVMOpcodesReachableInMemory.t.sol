// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "sol.lib.memory/LibPointer.sol";
import "sol.lib.memory/LibBytes.sol";
import "src/LibExtrospectBytecode.sol";
import "./LibExtrospectBytecode.testConstants.sol";
import "./LibExtrospectionSlow.sol";

contract LibExtrospectScanEVMOpcodesReachableInMemoryTest is Test {
    using LibBytes for bytes;

    /// Test that the simple case of a few standard opcodes works.
    function testScanEVMOpcodesReachableSimple() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"04050607")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 4), 0xF0);
    }

    // Test that stop opcode halts scanning.
    function testScanEVMOpcodesReachableStop() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"00010203")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 4), 1 << EVM_OP_STOP);
    }

    // Test that return opcode halts scanning.
    function testScanEVMOpcodesReachableReturn() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"f300010203")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 5), 1 << EVM_OP_RETURN);
    }

    // Test that revert opcode halts scanning.
    function testScanEVMOpcodesReachableRevert() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"fd00010203")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 5), 1 << EVM_OP_REVERT);
    }

    // Test that invalid opcode halts scanning.
    function testScanEVMOpcodesReachableInvalid() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"fe00010203")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 5), 1 << EVM_OP_INVALID);
    }

    // Test that selfdestruct opcode halts scanning.
    function testScanEVMOpcodesReachableSelfdestruct() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            mstore(ptr, hex"ff00010203")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 5), 1 << EVM_OP_SELFDESTRUCT);
    }

    // Test that jumpdest opcode resumes scanning.
    function testScanEVMOpcodesReachableJumpdest() public {
        Pointer ptr;
        assembly ("memory-safe") {
            ptr := mload(0x40)
            // eq + revert + ignore 4 bytes + jumpdest + mulmod + exp + signextend
            mstore(ptr, hex"14fdff0102035b090a0b")
        }

        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 10),
            // 0x14
            (1 << EVM_OP_EQ)
            // 0xfd
            | (1 << EVM_OP_REVERT)
            // 0x5b
            | (1 << EVM_OP_JUMPDEST)
            // 0x09
            | (1 << EVM_OP_MULMOD)
            // 0x0a
            | (1 << EVM_OP_EXP)
            // 0x0b
            | (1 << EVM_OP_SIGNEXTEND)
        );
    }

    /// Test that push opcode arguments are skipped.
    function testScanEVMOpcodesReachablePush1() public {
        Pointer ptr;
        assembly ("memory-safe") {
            // PUSH1 01
            ptr := mload(0x40)
            mstore(ptr, hex"60016002")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 4), 2 ** 0x60);
    }

    /// Test that push opcode arguments are skipped.
    function testScanEVMOpcodesReachablePush4() public {
        Pointer ptr;
        assembly ("memory-safe") {
            // PUSH4 01 02 03 04 PUSH1 01 PUSH1 05
            ptr := mload(0x40)
            mstore(ptr, hex"630102030460016005")
        }

        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(ptr, 9), (1 << 0x63) | (1 << 0x60));
    }

    /// Compare the output of the fast and reference implementations.
    function testScanEVMOpcodesReachableReference(bytes memory data) public {
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(data.dataPointer(), data.length),
            LibExtrospectionSlow.scanEVMOpcodesReachableInMemorySlow(data)
        );
    }

    /// A false positive was reported against the upstream reference
    /// implementation. Test that it is not present in our implementation.
    /// This tests the construction code found on etherscan.io.
    function testScanEVMOpcodesReachableReportedFalsePositive() public {
        bytes memory reportedFalsePositive = REPORTED_FALSE_POSITIVE;

        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(
            reportedFalsePositive.dataPointer(), reportedFalsePositive.length
        );
        assertEq(scan, 0x240a0000000000000000001a01ff0fff801d6dff0cff00846afc00011eff005f);
        assertEq(scan & (1 << EVM_OP_SELFDESTRUCT), 0);
    }

    /// A false positive was reported against the upstream reference
    /// implementation. Test that it is not present in our implementation.
    /// This tests the deployed bytecode found onchain on mainnet.
    function testScanEVMOpcodesReachableReportedFalsePositiveBytecode() public {
        bytes memory reportedFalsePositiveBytecode = REPORTED_FALSE_POSITIVE_BYTECODE;

        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(
            reportedFalsePositiveBytecode.dataPointer(), reportedFalsePositiveBytecode.length
        );
        assertEq(scan, 0x240a0000000000000000001a01ff0fff801d6dff0cff008468fc00011eff005f);
        assertEq(scan & (1 << EVM_OP_SELFDESTRUCT), 0);
    }

    /// Test that we can scan the bytecode of a contract that has a selfdestruct
    /// hidden in its metadata. We also need to be sure that we don't simply
    /// treat the metadata as code, as that would be a false positive.
    function testScanMetamorphicMetadata() public {
        bytes memory metamorphicMetadata = METAMORPHIC_METADATA;
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInMemory(
            metamorphicMetadata.dataPointer(), metamorphicMetadata.length
        );
        assertEq(scan, 0xa00000000000000000000000000700378000000b08c50000007000001075000b);
        // There IS a selfdestruct in this bytecode, it is hidden in the metadata.
        // It IS reachable, but would be near invisible on etherscan.io or a
        // naive scan that ignores metadata.
        assertEq(scan & (1 << EVM_OP_SELFDESTRUCT), (1 << EVM_OP_SELFDESTRUCT));
        // log2 is a common false positive in a naive scan. It is the first byte
        // of the cbor encoded metadata. As the start of metadata is not
        // reachable and there are no logs in the bytecode, it is not reachable.
        assertEq(scan & (1 << EVM_OP_LOG2), 0);
    }
}
