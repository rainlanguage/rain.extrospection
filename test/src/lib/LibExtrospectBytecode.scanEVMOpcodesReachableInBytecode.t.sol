// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibPointer} from "rain.solmem/lib/LibPointer.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {
    EVM_OP_STOP,
    EVM_OP_RETURN,
    EVM_OP_REVERT,
    EVM_OP_INVALID,
    EVM_OP_SELFDESTRUCT,
    EVM_OP_EQ,
    EVM_OP_JUMPDEST,
    EVM_OP_MULMOD,
    EVM_OP_EXP,
    EVM_OP_SIGNEXTEND,
    EVM_OP_LOG2
} from "src/lib/EVMOpcodes.sol";
import {
    REPORTED_FALSE_POSITIVE,
    REPORTED_FALSE_POSITIVE_BYTECODE,
    METAMORPHIC_METADATA
} from "test/lib/LibExtrospectBytecode.testConstants.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

contract LibExtrospectScanEVMOpcodesReachableInBytecodeTest is Test {
    using LibBytes for bytes;

    /// Test that the simple case of a few standard opcodes works.
    function testScanEVMOpcodesReachableSimple() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"04050607"), 0xF0);
    }

    // Test that stop opcode halts scanning.
    function testScanEVMOpcodesReachableStop() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"00010203"), 1 << EVM_OP_STOP);
    }

    // Test that return opcode halts scanning.
    function testScanEVMOpcodesReachableReturn() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"f300010203"), 1 << EVM_OP_RETURN);
    }

    // Test that revert opcode halts scanning.
    function testScanEVMOpcodesReachableRevert() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"fd00010203"), 1 << EVM_OP_REVERT);
    }

    // Test that invalid opcode halts scanning.
    function testScanEVMOpcodesReachableInvalid() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"fe00010203"), 1 << EVM_OP_INVALID);
    }

    // Test that selfdestruct opcode halts scanning.
    function testScanEVMOpcodesReachableSelfdestruct() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"ff00010203"), 1 << EVM_OP_SELFDESTRUCT);
    }

    // Test that jumpdest opcode resumes scanning.
    function testScanEVMOpcodesReachableJumpdest() public pure {
        // eq + revert + ignore 4 bytes + jumpdest + mulmod + exp + signextend
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"14fdff0102035b090a0b"),
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
    function testScanEVMOpcodesReachablePush1() public pure {
        // PUSH1 01
        assertEq(LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"60016002"), 2 ** 0x60);
    }

    /// Test that push opcode arguments are skipped.
    function testScanEVMOpcodesReachablePush4() public pure {
        // PUSH4 01 02 03 04 PUSH1 01 PUSH1 05
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(hex"630102030460016005"), (1 << 0x63) | (1 << 0x60)
        );
    }

    /// Compare the output of the fast and reference implementations.
    function testScanEVMOpcodesReachableReference(bytes memory data) public pure {
        assertEq(
            LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(data),
            LibExtrospectionSlow.scanEVMOpcodesReachableInBytecodeSlow(data)
        );
    }

    /// A false positive was reported against the upstream reference
    /// implementation. Test that it is not present in our implementation.
    /// This tests the construction code found on etherscan.io.
    function testScanEVMOpcodesReachableReportedFalsePositive() public pure {
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(REPORTED_FALSE_POSITIVE);
        assertEq(scan, 0x240a0000000000000000001a01ff0fff801d6dff0cff00846afc00011eff005f);
        assertEq(scan & (1 << EVM_OP_SELFDESTRUCT), 0);
    }

    /// A false positive was reported against the upstream reference
    /// implementation. Test that it is not present in our implementation.
    /// This tests the deployed bytecode found onchain on mainnet.
    function testScanEVMOpcodesReachableReportedFalsePositiveBytecode() public pure {
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(REPORTED_FALSE_POSITIVE_BYTECODE);
        assertEq(scan, 0x240a0000000000000000001a01ff0fff801d6dff0cff008468fc00011eff005f);
        assertEq(scan & (1 << EVM_OP_SELFDESTRUCT), 0);
    }

    /// Test that we can scan the bytecode of a contract that has a selfdestruct
    /// hidden in its metadata. We also need to be sure that we don't simply
    /// treat the metadata as code, as that would be a false positive.
    function testScanMetamorphicMetadata() public pure {
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(METAMORPHIC_METADATA);
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
