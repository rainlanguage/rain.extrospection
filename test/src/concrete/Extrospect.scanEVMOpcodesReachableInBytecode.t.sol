// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectScanEVMOpcodesReachableInBytecodeTest is ExtrospectEquivalence {
    /// External re-exposure of the library function so it can be reached via a
    /// raw self-call and its returndata captured alongside the concrete's.
    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    function assertScanEquivalence(bytes memory bytecode) internal {
        assertEquivalence(
            extrospect.scanEVMOpcodesReachableInBytecode.selector, this._libScan.selector, abi.encode(bytecode)
        );
    }

    /// Concrete and library agree byte-for-byte on the success path: both
    /// return the same encoded reachable-opcode bitmap, and on the EOF revert
    /// path both emit the byte-identical `EOFBytecodeNotSupported` payload.
    function testScanEVMOpcodesReachableInBytecodeEquivalenceFuzz(bytes memory bytecode) external {
        assertScanEquivalence(bytecode);
    }

    /// Concrete and library return the byte-identical reachable-opcode bitmap
    /// for a concrete success-path input.
    function testScanEVMOpcodesReachableInBytecodeEquivalenceConcrete() external {
        // PUSH1 0x01 PUSH1 0x02 RETURN
        assertScanEquivalence(hex"60016002F3");
    }

    /// Concrete and library revert with the byte-identical
    /// `EOFBytecodeNotSupported` payload for EOF-prefixed bytecode.
    function testScanEVMOpcodesReachableInBytecodeEquivalenceEOF() external {
        assertScanEquivalence(hex"EF0000");
    }

    /// `hex"00F0"` is STOP followed by CREATE, so only STOP is reachable. The
    /// concrete must report the REACHABLE bitmap, which a delegation to the
    /// present scan would pollute with the CREATE bit.
    function testScanEVMOpcodesReachableInBytecodeUnreachableCreateNotCounted() external view {
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = uint256(1);
        assertEq(extrospect.scanEVMOpcodesReachableInBytecode(hex"00F0"), expected);
    }
}
