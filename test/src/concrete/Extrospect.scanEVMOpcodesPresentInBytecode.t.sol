// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectScanEVMOpcodesPresentInBytecodeTest is ExtrospectEquivalence {
    /// External re-exposure of the library function so it can be reached via a
    /// raw self-call and its returndata captured alongside the concrete's.
    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    function assertScanEquivalence(bytes memory bytecode) internal {
        assertEquivalence(
            extrospect.scanEVMOpcodesPresentInBytecode.selector, this._libScan.selector, abi.encode(bytecode)
        );
    }

    /// Concrete and library agree byte-for-byte on the success path: both
    /// return the same encoded opcode bitmap, and on the EOF revert path both
    /// emit the byte-identical `EOFBytecodeNotSupported` payload.
    function testScanEVMOpcodesPresentInBytecodeEquivalenceFuzz(bytes memory bytecode) external {
        assertScanEquivalence(bytecode);
    }

    /// Concrete and library return the byte-identical opcode bitmap for a
    /// concrete success-path input.
    function testScanEVMOpcodesPresentInBytecodeEquivalenceConcrete() external {
        assertScanEquivalence(hex"60016002F3");
    }

    /// Concrete and library revert with the byte-identical
    /// `EOFBytecodeNotSupported` payload for EOF-prefixed bytecode.
    function testScanEVMOpcodesPresentInBytecodeEquivalenceEOF() external {
        assertScanEquivalence(hex"EF0000");
    }

    /// `hex"00F0"` is STOP followed by CREATE, so CREATE is present in the
    /// bytecode but unreachable (no JUMPDEST resumes execution after the halt).
    /// The concrete must report the PRESENT bitmap — STOP and CREATE — which a
    /// delegation to the reachable scan would not contain.
    function testScanEVMOpcodesPresentInBytecodeUnreachableCreateCounted() external view {
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = uint256(1) | (uint256(1) << uint256(0xF0));
        assertEq(extrospect.scanEVMOpcodesPresentInBytecode(hex"00F0"), expected);
    }
}
