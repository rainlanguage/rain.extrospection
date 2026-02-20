// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibBytes, LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
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
    EVM_OP_SLT,
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
    EVM_OP_ORIGIN,
    EVM_OP_CALLER,
    EVM_OP_CALLVALUE,
    EVM_OP_CALLDATACOPY,
    EVM_OP_CODESIZE,
    EVM_OP_GASPRICE,
    EVM_OP_EXTCODECOPY,
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
    EVM_OP_MSTORE8,
    EVM_OP_GAS,
    EVM_OP_MCOPY,
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
    EVM_OP_BALANCE,
    EVM_OP_EXTCODESIZE,
    EVM_OP_EXTCODEHASH,
    EVM_OP_TLOAD,
    EVM_OP_TSTORE
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
import {HasAdd} from "test/concrete/HasAdd.sol";
import {HasMul} from "test/concrete/HasMul.sol";
import {HasSub} from "test/concrete/HasSub.sol";
import {HasDiv} from "test/concrete/HasDiv.sol";
import {HasMod} from "test/concrete/HasMod.sol";
import {HasSdiv} from "test/concrete/HasSdiv.sol";
import {HasSmod} from "test/concrete/HasSmod.sol";
import {HasAddmod} from "test/concrete/HasAddmod.sol";
import {HasMulmod} from "test/concrete/HasMulmod.sol";
import {HasExp} from "test/concrete/HasExp.sol";
import {HasSignextend} from "test/concrete/HasSignextend.sol";
import {HasLt} from "test/concrete/HasLt.sol";
import {HasSlt} from "test/concrete/HasSlt.sol";
import {HasEq} from "test/concrete/HasEq.sol";
import {HasIszero} from "test/concrete/HasIszero.sol";
import {HasAnd} from "test/concrete/HasAnd.sol";
import {HasOr} from "test/concrete/HasOr.sol";
import {HasXor} from "test/concrete/HasXor.sol";
import {HasNot} from "test/concrete/HasNot.sol";
import {HasByte} from "test/concrete/HasByte.sol";
import {HasShl} from "test/concrete/HasShl.sol";
import {HasShr} from "test/concrete/HasShr.sol";
import {HasSar} from "test/concrete/HasSar.sol";
import {HasSha3} from "test/concrete/HasSha3.sol";
import {HasAddress} from "test/concrete/HasAddress.sol";
import {HasOrigin} from "test/concrete/HasOrigin.sol";
import {HasCaller} from "test/concrete/HasCaller.sol";
import {HasCallvalue} from "test/concrete/HasCallvalue.sol";
import {HasGasprice} from "test/concrete/HasGasprice.sol";
import {HasCalldatacopy} from "test/concrete/HasCalldatacopy.sol";
import {HasCodesize} from "test/concrete/HasCodesize.sol";
import {HasExtcodecopy} from "test/concrete/HasExtcodecopy.sol";
import {HasBlockhash} from "test/concrete/HasBlockhash.sol";
import {HasCoinbase} from "test/concrete/HasCoinbase.sol";
import {HasTimestamp} from "test/concrete/HasTimestamp.sol";
import {HasNumber} from "test/concrete/HasNumber.sol";
import {HasDifficulty} from "test/concrete/HasDifficulty.sol";
import {HasGaslimit} from "test/concrete/HasGaslimit.sol";
import {HasChainid} from "test/concrete/HasChainid.sol";
import {HasBasefee} from "test/concrete/HasBasefee.sol";
import {HasBlobhash} from "test/concrete/HasBlobhash.sol";
import {HasBlobbasefee} from "test/concrete/HasBlobbasefee.sol";
import {HasMstore8} from "test/concrete/HasMstore8.sol";
import {HasGas} from "test/concrete/HasGas.sol";
import {HasMcopy} from "test/concrete/HasMcopy.sol";
import {HasLog0} from "test/concrete/HasLog0.sol";
import {HasLog2} from "test/concrete/HasLog2.sol";
import {HasLog3} from "test/concrete/HasLog3.sol";
import {HasLog4} from "test/concrete/HasLog4.sol";
import {HasStop} from "test/concrete/HasStop.sol";
import {HasRevert} from "test/concrete/HasRevert.sol";
import {HasInvalid} from "test/concrete/HasInvalid.sol";

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

    /// Scan a compiled contract with ADD.
    function testScanEVMOpcodesPresentAdd_Source() public {
        HasAdd c = new HasAdd();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_ADD)) != 0);
    }

    /// Scan a compiled contract with MUL.
    function testScanEVMOpcodesPresentMul_Source() public {
        HasMul c = new HasMul();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_MUL)) != 0);
    }

    /// Scan a compiled contract with SUB.
    function testScanEVMOpcodesPresentSub_Source() public {
        HasSub c = new HasSub();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SUB)) != 0);
    }

    /// Scan a compiled contract with DIV.
    function testScanEVMOpcodesPresentDiv_Source() public {
        HasDiv c = new HasDiv();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_DIV)) != 0);
    }

    /// Scan a compiled contract with MOD.
    function testScanEVMOpcodesPresentMod_Source() public {
        HasMod c = new HasMod();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_MOD)) != 0);
    }

    /// Scan a compiled contract with SDIV.
    function testScanEVMOpcodesPresentSdiv_Source() public {
        HasSdiv c = new HasSdiv();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SDIV)) != 0);
    }

    /// Scan a compiled contract with SMOD.
    function testScanEVMOpcodesPresentSmod_Source() public {
        HasSmod c = new HasSmod();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SMOD)) != 0);
    }

    /// Scan a compiled contract with ADDMOD.
    function testScanEVMOpcodesPresentAddmod_Source() public {
        HasAddmod c = new HasAddmod();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_ADDMOD)) != 0);
    }

    /// Scan a compiled contract with MULMOD.
    function testScanEVMOpcodesPresentMulmod_Source() public {
        HasMulmod c = new HasMulmod();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_MULMOD)) != 0);
    }

    /// Scan a compiled contract with EXP.
    function testScanEVMOpcodesPresentExp_Source() public {
        HasExp c = new HasExp();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_EXP)) != 0);
    }

    /// Scan a compiled contract with SIGNEXTEND.
    function testScanEVMOpcodesPresentSignextend_Source() public {
        HasSignextend c = new HasSignextend();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SIGNEXTEND)) != 0);
    }

    /// Scan a compiled contract with LT.
    function testScanEVMOpcodesPresentLt_Source() public {
        HasLt c = new HasLt();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LT)) != 0);
    }

    /// Scan a compiled contract with SLT.
    function testScanEVMOpcodesPresentSlt_Source() public {
        HasSlt c = new HasSlt();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SLT)) != 0);
    }

    /// Scan a compiled contract with EQ.
    function testScanEVMOpcodesPresentEq_Source() public {
        HasEq c = new HasEq();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_EQ)) != 0);
    }

    /// Scan a compiled contract with ISZERO.
    function testScanEVMOpcodesPresentIszero_Source() public {
        HasIszero c = new HasIszero();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_ISZERO)) != 0);
    }

    /// Scan a compiled contract with AND.
    function testScanEVMOpcodesPresentAnd_Source() public {
        HasAnd c = new HasAnd();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_AND)) != 0);
    }

    /// Scan a compiled contract with OR.
    function testScanEVMOpcodesPresentOr_Source() public {
        HasOr c = new HasOr();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_OR)) != 0);
    }

    /// Scan a compiled contract with XOR.
    function testScanEVMOpcodesPresentXor_Source() public {
        HasXor c = new HasXor();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_XOR)) != 0);
    }

    /// Scan a compiled contract with NOT.
    function testScanEVMOpcodesPresentNot_Source() public {
        HasNot c = new HasNot();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_NOT)) != 0);
    }

    /// Scan a compiled contract with BYTE.
    function testScanEVMOpcodesPresentByte_Source() public {
        HasByte c = new HasByte();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BYTE)) != 0);
    }

    /// Scan a compiled contract with SHL.
    function testScanEVMOpcodesPresentShl_Source() public {
        HasShl c = new HasShl();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SHL)) != 0);
    }

    /// Scan a compiled contract with SHR.
    function testScanEVMOpcodesPresentShr_Source() public {
        HasShr c = new HasShr();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SHR)) != 0);
    }

    /// Scan a compiled contract with SAR.
    function testScanEVMOpcodesPresentSar_Source() public {
        HasSar c = new HasSar();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SAR)) != 0);
    }

    /// Scan a compiled contract with SHA3.
    function testScanEVMOpcodesPresentSha3_Source() public {
        HasSha3 c = new HasSha3();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_SHA3)) != 0);
    }

    /// Scan a compiled contract with ADDRESS.
    function testScanEVMOpcodesPresentAddress_Source() public {
        HasAddress c = new HasAddress();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_ADDRESS)) != 0);
    }

    /// Scan a compiled contract with ORIGIN.
    function testScanEVMOpcodesPresentOrigin_Source() public {
        HasOrigin c = new HasOrigin();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_ORIGIN)) != 0);
    }

    /// Scan a compiled contract with CALLER.
    function testScanEVMOpcodesPresentCaller_Source() public {
        HasCaller c = new HasCaller();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CALLER)) != 0);
    }

    /// Scan a compiled contract with CALLVALUE.
    function testScanEVMOpcodesPresentCallvalue_Source() public {
        HasCallvalue c = new HasCallvalue();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CALLVALUE)) != 0);
    }

    /// Scan a compiled contract with GASPRICE.
    function testScanEVMOpcodesPresentGasprice_Source() public {
        HasGasprice c = new HasGasprice();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_GASPRICE)) != 0);
    }

    /// Scan a compiled contract with CALLDATACOPY.
    function testScanEVMOpcodesPresentCalldatacopy_Source() public {
        HasCalldatacopy c = new HasCalldatacopy();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CALLDATACOPY)) != 0);
    }

    /// Scan a compiled contract with CODESIZE.
    function testScanEVMOpcodesPresentCodesize_Source() public {
        HasCodesize c = new HasCodesize();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CODESIZE)) != 0);
    }

    /// Scan a compiled contract with EXTCODECOPY.
    function testScanEVMOpcodesPresentExtcodecopy_Source() public {
        HasExtcodecopy c = new HasExtcodecopy();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_EXTCODECOPY)) != 0);
    }

    /// Scan a compiled contract with BLOCKHASH.
    function testScanEVMOpcodesPresentBlockhash_Source() public {
        HasBlockhash c = new HasBlockhash();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BLOCKHASH)) != 0);
    }

    /// Scan a compiled contract with COINBASE.
    function testScanEVMOpcodesPresentCoinbase_Source() public {
        HasCoinbase c = new HasCoinbase();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_COINBASE)) != 0);
    }

    /// Scan a compiled contract with TIMESTAMP.
    function testScanEVMOpcodesPresentTimestamp_Source() public {
        HasTimestamp c = new HasTimestamp();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_TIMESTAMP)) != 0);
    }

    /// Scan a compiled contract with NUMBER.
    function testScanEVMOpcodesPresentNumber_Source() public {
        HasNumber c = new HasNumber();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_NUMBER)) != 0);
    }

    /// Scan a compiled contract with DIFFICULTY.
    function testScanEVMOpcodesPresentDifficulty_Source() public {
        HasDifficulty c = new HasDifficulty();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_DIFFICULTY)) != 0);
    }

    /// Scan a compiled contract with GASLIMIT.
    function testScanEVMOpcodesPresentGaslimit_Source() public {
        HasGaslimit c = new HasGaslimit();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_GASLIMIT)) != 0);
    }

    /// Scan a compiled contract with CHAINID.
    function testScanEVMOpcodesPresentChainid_Source() public {
        HasChainid c = new HasChainid();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_CHAINID)) != 0);
    }

    /// Scan a compiled contract with BASEFEE.
    function testScanEVMOpcodesPresentBasefee_Source() public {
        HasBasefee c = new HasBasefee();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BASEFEE)) != 0);
    }

    /// Scan a compiled contract with BLOBHASH.
    function testScanEVMOpcodesPresentBlobhash_Source() public {
        HasBlobhash c = new HasBlobhash();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BLOBHASH)) != 0);
    }

    /// Scan a compiled contract with BLOBBASEFEE.
    function testScanEVMOpcodesPresentBlobbasefee_Source() public {
        HasBlobbasefee c = new HasBlobbasefee();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_BLOBBASEFEE)) != 0);
    }

    /// Scan a compiled contract with MSTORE8.
    function testScanEVMOpcodesPresentMstore8_Source() public {
        HasMstore8 c = new HasMstore8();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_MSTORE8)) != 0);
    }

    /// Scan a compiled contract with GAS.
    function testScanEVMOpcodesPresentGas_Source() public {
        HasGas c = new HasGas();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_GAS)) != 0);
    }

    /// Scan a compiled contract with MCOPY.
    function testScanEVMOpcodesPresentMcopy_Source() public {
        HasMcopy c = new HasMcopy();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_MCOPY)) != 0);
    }

    /// Scan a compiled contract with LOG0.
    function testScanEVMOpcodesPresentLog0_Source() public {
        HasLog0 c = new HasLog0();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LOG0)) != 0);
    }

    /// Scan a compiled contract with LOG2.
    function testScanEVMOpcodesPresentLog2_Source() public {
        HasLog2 c = new HasLog2();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LOG2)) != 0);
    }

    /// Scan a compiled contract with LOG3.
    function testScanEVMOpcodesPresentLog3_Source() public {
        HasLog3 c = new HasLog3();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LOG3)) != 0);
    }

    /// Scan a compiled contract with LOG4.
    function testScanEVMOpcodesPresentLog4_Source() public {
        HasLog4 c = new HasLog4();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_LOG4)) != 0);
    }

    /// Scan a compiled contract with STOP.
    function testScanEVMOpcodesPresentStop_Source() public {
        HasStop c = new HasStop();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_STOP)) != 0);
    }

    /// Scan a compiled contract with REVERT.
    function testScanEVMOpcodesPresentRevert_Source() public {
        HasRevert c = new HasRevert();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_REVERT)) != 0);
    }

    /// Scan a compiled contract with INVALID.
    function testScanEVMOpcodesPresentInvalid_Source() public {
        HasInvalid c = new HasInvalid();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_INVALID)) != 0);
    }

    /// Scan a compiled contract with RETURN.
    function testScanEVMOpcodesPresentReturn_Source() public {
        // Every compiled contract uses RETURN, so we can use any contract.
        CleanContract c = new CleanContract();
        uint256 scan = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(scan & (1 << uint256(EVM_OP_RETURN)) != 0);
    }

    /// Check that EOF bytecode reverts as not supported.
    function testScanEVMOpcodesPresentRevertsOnEOF() public {
        bytes memory eofBytecode = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanEVMOpcodesPresentInBytecodeExternal(eofBytecode);
    }
}
