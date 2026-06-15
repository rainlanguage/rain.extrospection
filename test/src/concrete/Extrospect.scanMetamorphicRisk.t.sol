// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";

contract ExtrospectScanMetamorphicRiskTest is ExtrospectEquivalence {
    /// External re-exposure of the library function so it can be reached via a
    /// raw self-call and its returndata captured alongside the concrete's.
    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    function assertScanEquivalence(bytes memory bytecode) internal {
        assertEquivalence(extrospect.scanMetamorphicRisk.selector, this._libScan.selector, abi.encode(bytecode));
    }

    /// Concrete and library agree byte-for-byte on the success path: both
    /// return the same encoded metamorphic-risk bitmap, and on the EOF revert
    /// path both emit the byte-identical `EOFBytecodeNotSupported` payload.
    function testScanMetamorphicRiskEquivalenceFuzz(bytes memory bytecode) external {
        assertScanEquivalence(bytecode);
    }

    /// Concrete and library return the byte-identical metamorphic-risk bitmap
    /// for bytecode containing a reachable DELEGATECALL.
    function testScanMetamorphicRiskEquivalenceWithDelegatecall() external {
        assertScanEquivalence(hex"60006000600060006000F4");
    }

    /// Concrete and library revert with the byte-identical
    /// `EOFBytecodeNotSupported` payload for EOF-prefixed bytecode.
    function testScanMetamorphicRiskEquivalenceEOF() external {
        assertScanEquivalence(hex"EF0000");
    }
}
