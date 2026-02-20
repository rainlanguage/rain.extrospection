// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes, LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {
    EVM_OP_SELFDESTRUCT,
    EVM_OP_DELEGATECALL,
    EVM_OP_CALLCODE,
    EVM_OP_CREATE,
    EVM_OP_CREATE2
} from "src/lib/EVMOpcodes.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {HasDelegatecall} from "test/concrete/HasDelegatecall.sol";
import {HasCallcode} from "test/concrete/HasCallcode.sol";
import {HasCreate} from "test/concrete/HasCreate.sol";
import {HasCreate2} from "test/concrete/HasCreate2.sol";
import {CleanContract} from "test/concrete/CleanContract.sol";

contract LibExtrospectBytecodeScanEVMOpcodesPresentInBytecodeTest is Test {
    using LibBytes for bytes;

    /// External version of scanEVMOpcodesPresentInBytecode for testing.
    function scanEVMOpcodesPresentInBytecodeExternal(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    /// Test that empty bytecode returns 0.
    function testScanEVMOpcodesPresentEmpty() public pure {
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex""), 0);
    }

    /// Test single-byte non-PUSH bytecodes.
    function testScanEVMOpcodesPresentSingleByte() public pure {
        // STOP
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"00"), 1);
        // ADD
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"01"), 2);
    }

    /// Test truncated PUSH1 at end of bytecode (no data byte following).
    function testScanEVMOpcodesPresentTruncatedPush1() public pure {
        // PUSH1 with no data: the PUSH1 opcode itself is recorded, cursor
        // skips past end.
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"60"), 1 << 0x60);
    }

    /// Test truncated PUSH32 at end of bytecode (no data bytes following).
    function testScanEVMOpcodesPresentTruncatedPush32() public pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"7f"), 1 << 0x7f);
    }

    /// Test PUSH32 with only 1 byte of data following (31 bytes short).
    function testScanEVMOpcodesPresentTruncatedPush32Partial() public pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(hex"7fFF"), 1 << 0x7f);
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

    /// Scan a compiled contract with SELFDESTRUCT.
    function testScanEVMOpcodesPresentSelfdestruct_Source() public {
        HasSelfdestruct c = new HasSelfdestruct();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SELFDESTRUCT)) != 0);
    }

    /// Scan a compiled contract with DELEGATECALL.
    function testScanEVMOpcodesPresentDelegatecall_Source() public {
        HasDelegatecall c = new HasDelegatecall();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_DELEGATECALL)) != 0);
    }

    /// Scan a compiled contract with CALLCODE.
    function testScanEVMOpcodesPresentCallcode_Source() public {
        HasCallcode c = new HasCallcode();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CALLCODE)) != 0);
    }

    /// Scan a compiled contract with CREATE.
    function testScanEVMOpcodesPresentCreate_Source() public {
        HasCreate c = new HasCreate();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CREATE)) != 0);
    }

    /// Scan a compiled contract with CREATE2.
    function testScanEVMOpcodesPresentCreate2_Source() public {
        HasCreate2 c = new HasCreate2();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CREATE2)) != 0);
    }

    /// Scan a compiled clean contract — no metamorphic opcodes present.
    function testScanEVMOpcodesPresentClean_Source() public {
        CleanContract c = new CleanContract();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(scan & (1 << uint256(EVM_OP_SELFDESTRUCT)), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(scan & (1 << uint256(EVM_OP_DELEGATECALL)), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(scan & (1 << uint256(EVM_OP_CALLCODE)), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(scan & (1 << uint256(EVM_OP_CREATE)), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(scan & (1 << uint256(EVM_OP_CREATE2)), 0);
    }

    /// Check that EOF bytecode reverts as not supported.
    function testScanEVMOpcodesPresentRevertsOnEOF() public {
        bytes memory eofBytecode = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanEVMOpcodesPresentInBytecodeExternal(eofBytecode);
    }
}
