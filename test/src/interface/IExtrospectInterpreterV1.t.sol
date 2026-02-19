// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibCtPop} from "rain.math.binary/lib/LibCtPop.sol";

import {NON_STATIC_OPS, INTERPRETER_DISALLOWED_OPS} from "src/interface/IExtrospectInterpreterV1.sol";

/// @title IExtrospectInterpreterV1Test
/// @notice Tests that the security-critical bitmap constants NON_STATIC_OPS and
/// INTERPRETER_DISALLOWED_OPS contain exactly the expected opcode bits.
/// Expected values are built from raw hex opcode values (not the imported
/// EVM_OP_* constants) to independently verify correctness.
contract IExtrospectInterpreterV1Test is Test {
    using LibCtPop for uint256;

    /// Test NON_STATIC_OPS against EIP-214 specification.
    /// https://eips.ethereum.org/EIPS/eip-214#specification
    /// The list is: CREATE, CREATE2, LOG0-4, SSTORE, SELFDESTRUCT, CALL, TSTORE.
    function testNonStaticOps() external pure {
        // Build expected bitmap from raw hex values.
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = (1 << 0xF0) // CREATE
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF5) // CREATE2
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA0) // LOG0
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA1) // LOG1
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA2) // LOG2
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA3) // LOG3
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA4) // LOG4
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x55) // SSTORE
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xFF) // SELFDESTRUCT
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF1) // CALL
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x5D); // TSTORE
        assertEq(NON_STATIC_OPS, expected);
    }

    /// Test INTERPRETER_DISALLOWED_OPS is NON_STATIC_OPS plus additional
    /// restrictions: SLOAD, TLOAD, DELEGATECALL, CALLCODE.
    function testInterpreterDisallowedOps() external pure {
        // Build expected bitmap from raw hex values.
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = (1 << 0xF0) // CREATE
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF5) // CREATE2
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA0) // LOG0
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA1) // LOG1
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA2) // LOG2
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA3) // LOG3
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xA4) // LOG4
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x55) // SSTORE
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xFF) // SELFDESTRUCT
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF1) // CALL
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x5D) // TSTORE
            // Additional interpreter restrictions beyond EIP-214.
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x54) // SLOAD
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x5C) // TLOAD
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF4) // DELEGATECALL
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF2); // CALLCODE
        assertEq(INTERPRETER_DISALLOWED_OPS, expected);
    }

    /// Test that INTERPRETER_DISALLOWED_OPS is a strict superset of
    /// NON_STATIC_OPS.
    function testInterpreterDisallowedOpsIsSupersetOfNonStaticOps() external pure {
        // Every bit in NON_STATIC_OPS must also be set in INTERPRETER_DISALLOWED_OPS.
        assertEq(NON_STATIC_OPS & INTERPRETER_DISALLOWED_OPS, NON_STATIC_OPS);
        // INTERPRETER_DISALLOWED_OPS must have strictly more bits set.
        assertTrue(INTERPRETER_DISALLOWED_OPS > NON_STATIC_OPS);
    }

    /// Test that each individual opcode in NON_STATIC_OPS is set.
    function testNonStaticOpsIndividualBits() external pure {
        // EIP-214 disallowed opcodes.
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xF0) != 0, "CREATE"); // CREATE
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xF5) != 0, "CREATE2"); // CREATE2
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xA0) != 0, "LOG0"); // LOG0
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xA1) != 0, "LOG1"); // LOG1
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xA2) != 0, "LOG2"); // LOG2
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xA3) != 0, "LOG3"); // LOG3
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xA4) != 0, "LOG4"); // LOG4
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0x55) != 0, "SSTORE"); // SSTORE
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xFF) != 0, "SELFDESTRUCT"); // SELFDESTRUCT
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0xF1) != 0, "CALL"); // CALL
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(NON_STATIC_OPS & (1 << 0x5D) != 0, "TSTORE"); // TSTORE
    }

    /// Test that opcodes NOT in NON_STATIC_OPS are absent.
    function testNonStaticOpsExclusions() external pure {
        // Spot check that safe opcodes are NOT flagged.
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0x00), 0, "STOP should not be flagged");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0x01), 0, "ADD should not be flagged");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0x54), 0, "SLOAD should not be in NON_STATIC_OPS");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0x5C), 0, "TLOAD should not be in NON_STATIC_OPS");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0xF4), 0, "DELEGATECALL should not be in NON_STATIC_OPS");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0xFA), 0, "STATICCALL should not be flagged");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(NON_STATIC_OPS & (1 << 0xFD), 0, "REVERT should not be flagged");
    }

    /// Test the exact popcount of NON_STATIC_OPS.
    /// CREATE, CREATE2, LOG0-4, SSTORE, SELFDESTRUCT, CALL, TSTORE = 11.
    function testNonStaticOpsPopcount() external pure {
        assertEq(NON_STATIC_OPS.ctpop(), 11);
    }

    /// Test the exact popcount of INTERPRETER_DISALLOWED_OPS.
    /// NON_STATIC_OPS (11) + SLOAD, TLOAD, DELEGATECALL, CALLCODE = 15.
    function testInterpreterDisallowedOpsPopcount() external pure {
        assertEq(INTERPRETER_DISALLOWED_OPS.ctpop(), 15);
    }
}
