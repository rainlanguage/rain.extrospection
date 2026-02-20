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
    EVM_OP_CREATE2,
    EVM_OP_CALL,
    EVM_OP_STATICCALL,
    EVM_OP_LOG1,
    EVM_OP_TLOAD,
    EVM_OP_TSTORE,
    EVM_OP_BALANCE,
    EVM_OP_SELFBALANCE,
    EVM_OP_EXTCODESIZE,
    EVM_OP_EXTCODEHASH
} from "src/lib/EVMOpcodes.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {HasDelegatecall} from "test/concrete/HasDelegatecall.sol";
import {HasCallcode} from "test/concrete/HasCallcode.sol";
import {HasCreate} from "test/concrete/HasCreate.sol";
import {HasCreate2} from "test/concrete/HasCreate2.sol";
import {CleanContract} from "test/concrete/CleanContract.sol";
import {HasCall} from "test/concrete/HasCall.sol";
import {HasStaticcall} from "test/concrete/HasStaticcall.sol";
import {HasLog} from "test/concrete/HasLog.sol";
import {HasTstore} from "test/concrete/HasTstore.sol";
import {HasBalance} from "test/concrete/HasBalance.sol";
import {HasSelfbalance} from "test/concrete/HasSelfbalance.sol";
import {HasExtcodesize} from "test/concrete/HasExtcodesize.sol";
import {HasExtcodehash} from "test/concrete/HasExtcodehash.sol";

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

    /// Scan a compiled contract with CALL.
    function testScanEVMOpcodesPresentCall_Source() public {
        HasCall c = new HasCall();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CALL)) != 0);
    }

    /// Scan a compiled contract with STATICCALL.
    function testScanEVMOpcodesPresentStaticcall_Source() public {
        HasStaticcall c = new HasStaticcall();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_STATICCALL)) != 0);
    }

    /// Scan a compiled contract with LOG (event emission).
    function testScanEVMOpcodesPresentLog_Source() public {
        HasLog c = new HasLog();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LOG1)) != 0);
    }

    /// Scan a compiled contract with TSTORE/TLOAD.
    function testScanEVMOpcodesPresentTstore_Source() public {
        HasTstore c = new HasTstore();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_TSTORE)) != 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_TLOAD)) != 0);
    }

    /// Scan a compiled contract with BALANCE.
    function testScanEVMOpcodesPresentBalance_Source() public {
        HasBalance c = new HasBalance();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BALANCE)) != 0);
    }

    /// Scan a compiled contract with SELFBALANCE.
    function testScanEVMOpcodesPresentSelfbalance_Source() public {
        HasSelfbalance c = new HasSelfbalance();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SELFBALANCE)) != 0);
    }

    /// Scan a compiled contract with EXTCODESIZE.
    function testScanEVMOpcodesPresentExtcodesize_Source() public {
        HasExtcodesize c = new HasExtcodesize();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_EXTCODESIZE)) != 0);
    }

    /// Scan a compiled contract with EXTCODEHASH.
    function testScanEVMOpcodesPresentExtcodehash_Source() public {
        HasExtcodehash c = new HasExtcodehash();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_EXTCODEHASH)) != 0);
    }

    /// Check that EOF bytecode reverts as not supported.
    function testScanEVMOpcodesPresentRevertsOnEOF() public {
        bytes memory eofBytecode = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanEVMOpcodesPresentInBytecodeExternal(eofBytecode);
    }
}
