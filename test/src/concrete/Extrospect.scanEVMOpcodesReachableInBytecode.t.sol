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
}
