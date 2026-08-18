// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";

contract ExtrospectCheckNotMetamorphicTest is ExtrospectEquivalence {
    /// External re-exposure of the library function so it can be reached via a
    /// raw self-call and its returndata captured alongside the concrete's.
    function libCheckNotMetamorphicExternal(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    function assertCheckNotMetamorphicEquivalence(bytes memory bytecode) internal {
        assertEquivalence(
            extrospect.checkNotMetamorphic.selector, this.libCheckNotMetamorphicExternal.selector, abi.encode(bytecode)
        );
    }

    /// Concrete and library agree on the success (no-revert) path: both return
    /// empty returndata.
    function testCheckNotMetamorphicEquivalencePass() external {
        bytes memory clean = hex"60016002F3";
        assertCheckNotMetamorphicEquivalence(clean);
    }

    /// Concrete and library agree on the empty-bytecode success path, which is
    /// the bytecode of every account with no code.
    function testCheckNotMetamorphicEquivalenceEmpty() external {
        assertCheckNotMetamorphicEquivalence(hex"");
    }

    /// Concrete and library revert with the byte-identical `Metamorphic`
    /// payload (selector + the exact reachable-opcode bitmap) for risky
    /// bytecode.
    function testCheckNotMetamorphicEquivalenceRevert() external {
        bytes memory withDelegatecall = hex"60006000600060006000F4";
        assertCheckNotMetamorphicEquivalence(withDelegatecall);
    }

    /// Concrete and library revert with the byte-identical
    /// `EOFBytecodeNotSupported` payload for EOF-prefixed bytecode.
    function testCheckNotMetamorphicEquivalenceEOF() external {
        bytes memory eof = hex"EF0000";
        assertCheckNotMetamorphicEquivalence(eof);
    }

    /// Fuzz the success and both revert paths together: every input yields the
    /// same success flag and byte-identical returndata on both sides.
    function testCheckNotMetamorphicEquivalenceFuzz(bytes memory bytecode) external {
        assertCheckNotMetamorphicEquivalence(bytecode);
    }
}
