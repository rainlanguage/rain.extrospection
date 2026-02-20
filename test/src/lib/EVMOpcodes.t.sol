// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibCtPop} from "rain.math.binary/lib/LibCtPop.sol";

import {
    EVM_OP_STOP,
    EVM_OP_ADD,
    EVM_OP_MUL,
    EVM_OP_SUB,
    EVM_OP_DIV,
    EVM_OP_SDIV,
    EVM_OP_MOD,
    EVM_OP_SMOD,
    EVM_OP_ADDMOD,
    EVM_OP_MULMOD,
    EVM_OP_EXP,
    EVM_OP_SIGNEXTEND,
    EVM_OP_LT,
    EVM_OP_GT,
    EVM_OP_SLT,
    EVM_OP_SGT,
    EVM_OP_EQ,
    EVM_OP_ISZERO,
    EVM_OP_AND,
    EVM_OP_OR,
    EVM_OP_XOR,
    EVM_OP_NOT,
    EVM_OP_BYTE,
    EVM_OP_SHL,
    EVM_OP_SHR,
    EVM_OP_SAR,
    EVM_OP_SHA3,
    EVM_OP_ADDRESS,
    EVM_OP_BALANCE,
    EVM_OP_ORIGIN,
    EVM_OP_CALLER,
    EVM_OP_CALLVALUE,
    EVM_OP_CALLDATALOAD,
    EVM_OP_CALLDATASIZE,
    EVM_OP_CALLDATACOPY,
    EVM_OP_CODESIZE,
    EVM_OP_CODECOPY,
    EVM_OP_GASPRICE,
    EVM_OP_EXTCODESIZE,
    EVM_OP_EXTCODECOPY,
    EVM_OP_RETURNDATASIZE,
    EVM_OP_RETURNDATACOPY,
    EVM_OP_EXTCODEHASH,
    EVM_OP_BLOCKHASH,
    EVM_OP_COINBASE,
    EVM_OP_TIMESTAMP,
    EVM_OP_NUMBER,
    EVM_OP_DIFFICULTY,
    EVM_OP_GASLIMIT,
    EVM_OP_CHAINID,
    EVM_OP_SELFBALANCE,
    EVM_OP_BASEFEE,
    EVM_OP_BLOBHASH,
    EVM_OP_BLOBBASEFEE,
    EVM_OP_POP,
    EVM_OP_MLOAD,
    EVM_OP_MSTORE,
    EVM_OP_MSTORE8,
    EVM_OP_SLOAD,
    EVM_OP_SSTORE,
    EVM_OP_JUMP,
    EVM_OP_JUMPI,
    EVM_OP_PC,
    EVM_OP_MSIZE,
    EVM_OP_GAS,
    EVM_OP_JUMPDEST,
    EVM_OP_TLOAD,
    EVM_OP_TSTORE,
    EVM_OP_MCOPY,
    EVM_OP_PUSH0,
    EVM_OP_PUSH1,
    EVM_OP_PUSH2,
    EVM_OP_PUSH3,
    EVM_OP_PUSH4,
    EVM_OP_PUSH5,
    EVM_OP_PUSH6,
    EVM_OP_PUSH7,
    EVM_OP_PUSH8,
    EVM_OP_PUSH9,
    EVM_OP_PUSH10,
    EVM_OP_PUSH11,
    EVM_OP_PUSH12,
    EVM_OP_PUSH13,
    EVM_OP_PUSH14,
    EVM_OP_PUSH15,
    EVM_OP_PUSH16,
    EVM_OP_PUSH17,
    EVM_OP_PUSH18,
    EVM_OP_PUSH19,
    EVM_OP_PUSH20,
    EVM_OP_PUSH21,
    EVM_OP_PUSH22,
    EVM_OP_PUSH23,
    EVM_OP_PUSH24,
    EVM_OP_PUSH25,
    EVM_OP_PUSH26,
    EVM_OP_PUSH27,
    EVM_OP_PUSH28,
    EVM_OP_PUSH29,
    EVM_OP_PUSH30,
    EVM_OP_PUSH31,
    EVM_OP_PUSH32,
    EVM_OP_DUP1,
    EVM_OP_DUP2,
    EVM_OP_DUP3,
    EVM_OP_DUP4,
    EVM_OP_DUP5,
    EVM_OP_DUP6,
    EVM_OP_DUP7,
    EVM_OP_DUP8,
    EVM_OP_DUP9,
    EVM_OP_DUP10,
    EVM_OP_DUP11,
    EVM_OP_DUP12,
    EVM_OP_DUP13,
    EVM_OP_DUP14,
    EVM_OP_DUP15,
    EVM_OP_DUP16,
    EVM_OP_SWAP1,
    EVM_OP_SWAP2,
    EVM_OP_SWAP3,
    EVM_OP_SWAP4,
    EVM_OP_SWAP5,
    EVM_OP_SWAP6,
    EVM_OP_SWAP7,
    EVM_OP_SWAP8,
    EVM_OP_SWAP9,
    EVM_OP_SWAP10,
    EVM_OP_SWAP11,
    EVM_OP_SWAP12,
    EVM_OP_SWAP13,
    EVM_OP_SWAP14,
    EVM_OP_SWAP15,
    EVM_OP_SWAP16,
    EVM_OP_LOG0,
    EVM_OP_LOG1,
    EVM_OP_LOG2,
    EVM_OP_LOG3,
    EVM_OP_LOG4,
    EVM_OP_CREATE,
    EVM_OP_CALL,
    EVM_OP_CALLCODE,
    EVM_OP_RETURN,
    EVM_OP_DELEGATECALL,
    EVM_OP_CREATE2,
    EVM_OP_STATICCALL,
    EVM_OP_REVERT,
    EVM_OP_INVALID,
    EVM_OP_SELFDESTRUCT,
    HALTING_BITMAP
} from "src/lib/EVMOpcodes.sol";

contract EVMOpcodesTest is Test {
    using LibCtPop for uint256;

    /// Validate all 135 opcode constants against raw hex values.
    function testOpcodeValues() external pure {
        // Arithmetic
        assertEq(EVM_OP_STOP, 0x00);
        assertEq(EVM_OP_ADD, 0x01);
        assertEq(EVM_OP_MUL, 0x02);
        assertEq(EVM_OP_SUB, 0x03);
        assertEq(EVM_OP_DIV, 0x04);
        assertEq(EVM_OP_SDIV, 0x05);
        assertEq(EVM_OP_MOD, 0x06);
        assertEq(EVM_OP_SMOD, 0x07);
        assertEq(EVM_OP_ADDMOD, 0x08);
        assertEq(EVM_OP_MULMOD, 0x09);
        assertEq(EVM_OP_EXP, 0x0A);
        assertEq(EVM_OP_SIGNEXTEND, 0x0B);

        // Comparison
        assertEq(EVM_OP_LT, 0x10);
        assertEq(EVM_OP_GT, 0x11);
        assertEq(EVM_OP_SLT, 0x12);
        assertEq(EVM_OP_SGT, 0x13);
        assertEq(EVM_OP_EQ, 0x14);
        assertEq(EVM_OP_ISZERO, 0x15);

        // Bitwise / Shift
        assertEq(EVM_OP_AND, 0x16);
        assertEq(EVM_OP_OR, 0x17);
        assertEq(EVM_OP_XOR, 0x18);
        assertEq(EVM_OP_NOT, 0x19);
        assertEq(EVM_OP_BYTE, 0x1A);
        assertEq(EVM_OP_SHL, 0x1B);
        assertEq(EVM_OP_SHR, 0x1C);
        assertEq(EVM_OP_SAR, 0x1D);

        // Hashing
        assertEq(EVM_OP_SHA3, 0x20);

        // Environmental
        assertEq(EVM_OP_ADDRESS, 0x30);
        assertEq(EVM_OP_BALANCE, 0x31);
        assertEq(EVM_OP_ORIGIN, 0x32);
        assertEq(EVM_OP_CALLER, 0x33);
        assertEq(EVM_OP_CALLVALUE, 0x34);
        assertEq(EVM_OP_CALLDATALOAD, 0x35);
        assertEq(EVM_OP_CALLDATASIZE, 0x36);
        assertEq(EVM_OP_CALLDATACOPY, 0x37);
        assertEq(EVM_OP_CODESIZE, 0x38);
        assertEq(EVM_OP_CODECOPY, 0x39);
        assertEq(EVM_OP_GASPRICE, 0x3A);
        assertEq(EVM_OP_EXTCODESIZE, 0x3B);
        assertEq(EVM_OP_EXTCODECOPY, 0x3C);
        assertEq(EVM_OP_RETURNDATASIZE, 0x3D);
        assertEq(EVM_OP_RETURNDATACOPY, 0x3E);
        assertEq(EVM_OP_EXTCODEHASH, 0x3F);

        // Block information
        assertEq(EVM_OP_BLOCKHASH, 0x40);
        assertEq(EVM_OP_COINBASE, 0x41);
        assertEq(EVM_OP_TIMESTAMP, 0x42);
        assertEq(EVM_OP_NUMBER, 0x43);
        assertEq(EVM_OP_DIFFICULTY, 0x44);
        assertEq(EVM_OP_GASLIMIT, 0x45);
        assertEq(EVM_OP_CHAINID, 0x46);
        assertEq(EVM_OP_SELFBALANCE, 0x47);
        assertEq(EVM_OP_BASEFEE, 0x48);
        assertEq(EVM_OP_BLOBHASH, 0x49);
        assertEq(EVM_OP_BLOBBASEFEE, 0x4A);

        // Stack / Memory / Storage / Flow
        assertEq(EVM_OP_POP, 0x50);
        assertEq(EVM_OP_MLOAD, 0x51);
        assertEq(EVM_OP_MSTORE, 0x52);
        assertEq(EVM_OP_MSTORE8, 0x53);
        assertEq(EVM_OP_SLOAD, 0x54);
        assertEq(EVM_OP_SSTORE, 0x55);
        assertEq(EVM_OP_JUMP, 0x56);
        assertEq(EVM_OP_JUMPI, 0x57);
        assertEq(EVM_OP_PC, 0x58);
        assertEq(EVM_OP_MSIZE, 0x59);
        assertEq(EVM_OP_GAS, 0x5A);
        assertEq(EVM_OP_JUMPDEST, 0x5B);
        assertEq(EVM_OP_TLOAD, 0x5C);
        assertEq(EVM_OP_TSTORE, 0x5D);
        assertEq(EVM_OP_MCOPY, 0x5E);

        // PUSH
        assertEq(EVM_OP_PUSH0, 0x5F);
        assertEq(EVM_OP_PUSH1, 0x60);
        assertEq(EVM_OP_PUSH2, 0x61);
        assertEq(EVM_OP_PUSH3, 0x62);
        assertEq(EVM_OP_PUSH4, 0x63);
        assertEq(EVM_OP_PUSH5, 0x64);
        assertEq(EVM_OP_PUSH6, 0x65);
        assertEq(EVM_OP_PUSH7, 0x66);
        assertEq(EVM_OP_PUSH8, 0x67);
        assertEq(EVM_OP_PUSH9, 0x68);
        assertEq(EVM_OP_PUSH10, 0x69);
        assertEq(EVM_OP_PUSH11, 0x6A);
        assertEq(EVM_OP_PUSH12, 0x6B);
        assertEq(EVM_OP_PUSH13, 0x6C);
        assertEq(EVM_OP_PUSH14, 0x6D);
        assertEq(EVM_OP_PUSH15, 0x6E);
        assertEq(EVM_OP_PUSH16, 0x6F);
        assertEq(EVM_OP_PUSH17, 0x70);
        assertEq(EVM_OP_PUSH18, 0x71);
        assertEq(EVM_OP_PUSH19, 0x72);
        assertEq(EVM_OP_PUSH20, 0x73);
        assertEq(EVM_OP_PUSH21, 0x74);
        assertEq(EVM_OP_PUSH22, 0x75);
        assertEq(EVM_OP_PUSH23, 0x76);
        assertEq(EVM_OP_PUSH24, 0x77);
        assertEq(EVM_OP_PUSH25, 0x78);
        assertEq(EVM_OP_PUSH26, 0x79);
        assertEq(EVM_OP_PUSH27, 0x7A);
        assertEq(EVM_OP_PUSH28, 0x7B);
        assertEq(EVM_OP_PUSH29, 0x7C);
        assertEq(EVM_OP_PUSH30, 0x7D);
        assertEq(EVM_OP_PUSH31, 0x7E);
        assertEq(EVM_OP_PUSH32, 0x7F);

        // DUP
        assertEq(EVM_OP_DUP1, 0x80);
        assertEq(EVM_OP_DUP2, 0x81);
        assertEq(EVM_OP_DUP3, 0x82);
        assertEq(EVM_OP_DUP4, 0x83);
        assertEq(EVM_OP_DUP5, 0x84);
        assertEq(EVM_OP_DUP6, 0x85);
        assertEq(EVM_OP_DUP7, 0x86);
        assertEq(EVM_OP_DUP8, 0x87);
        assertEq(EVM_OP_DUP9, 0x88);
        assertEq(EVM_OP_DUP10, 0x89);
        assertEq(EVM_OP_DUP11, 0x8A);
        assertEq(EVM_OP_DUP12, 0x8B);
        assertEq(EVM_OP_DUP13, 0x8C);
        assertEq(EVM_OP_DUP14, 0x8D);
        assertEq(EVM_OP_DUP15, 0x8E);
        assertEq(EVM_OP_DUP16, 0x8F);

        // SWAP
        assertEq(EVM_OP_SWAP1, 0x90);
        assertEq(EVM_OP_SWAP2, 0x91);
        assertEq(EVM_OP_SWAP3, 0x92);
        assertEq(EVM_OP_SWAP4, 0x93);
        assertEq(EVM_OP_SWAP5, 0x94);
        assertEq(EVM_OP_SWAP6, 0x95);
        assertEq(EVM_OP_SWAP7, 0x96);
        assertEq(EVM_OP_SWAP8, 0x97);
        assertEq(EVM_OP_SWAP9, 0x98);
        assertEq(EVM_OP_SWAP10, 0x99);
        assertEq(EVM_OP_SWAP11, 0x9A);
        assertEq(EVM_OP_SWAP12, 0x9B);
        assertEq(EVM_OP_SWAP13, 0x9C);
        assertEq(EVM_OP_SWAP14, 0x9D);
        assertEq(EVM_OP_SWAP15, 0x9E);
        assertEq(EVM_OP_SWAP16, 0x9F);

        // LOG
        assertEq(EVM_OP_LOG0, 0xA0);
        assertEq(EVM_OP_LOG1, 0xA1);
        assertEq(EVM_OP_LOG2, 0xA2);
        assertEq(EVM_OP_LOG3, 0xA3);
        assertEq(EVM_OP_LOG4, 0xA4);

        // System / Call
        assertEq(EVM_OP_CREATE, 0xF0);
        assertEq(EVM_OP_CALL, 0xF1);
        assertEq(EVM_OP_CALLCODE, 0xF2);
        assertEq(EVM_OP_RETURN, 0xF3);
        assertEq(EVM_OP_DELEGATECALL, 0xF4);
        assertEq(EVM_OP_CREATE2, 0xF5);
        assertEq(EVM_OP_STATICCALL, 0xFA);
        assertEq(EVM_OP_REVERT, 0xFD);
        assertEq(EVM_OP_INVALID, 0xFE);
        assertEq(EVM_OP_SELFDESTRUCT, 0xFF);
    }

    /// Validate HALTING_BITMAP against independently computed value from raw
    /// hex opcode values.
    function testHaltingBitmap() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = (1 << 0x00) // STOP
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xF3) // RETURN
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xFD) // REVERT
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xFE) // INVALID
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0xFF) // SELFDESTRUCT
            //forge-lint: disable-next-line(incorrect-shift)
            | (1 << 0x56); // JUMP
        assertEq(HALTING_BITMAP, expected);
    }

    /// Validate HALTING_BITMAP has exactly 6 bits set.
    function testHaltingBitmapPopcount() external pure {
        assertEq(HALTING_BITMAP.ctpop(), 6);
    }

    /// Validate each halting opcode individually in HALTING_BITMAP.
    function testHaltingBitmapIndividualBits() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0x00) != 0, "STOP");
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0xF3) != 0, "RETURN");
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0xFD) != 0, "REVERT");
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0xFE) != 0, "INVALID");
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0xFF) != 0, "SELFDESTRUCT");
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(HALTING_BITMAP & (1 << 0x56) != 0, "JUMP");
    }

    /// Validate that non-halting opcodes are absent from HALTING_BITMAP.
    function testHaltingBitmapExclusions() external pure {
        // JUMPI is conditional — it does NOT unconditionally halt.
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x57), 0, "JUMPI should not halt");
        // JUMPDEST is a label, not a halting opcode.
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x5B), 0, "JUMPDEST should not halt");
        // Common non-halting opcodes.
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x01), 0, "ADD should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x51), 0, "MLOAD should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x52), 0, "MSTORE should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0x60), 0, "PUSH1 should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0xF1), 0, "CALL should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0xFA), 0, "STATICCALL should not halt");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(HALTING_BITMAP & (1 << 0xF4), 0, "DELEGATECALL should not halt");
    }
}
