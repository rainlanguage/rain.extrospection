// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibPointer.sol";

/// @title LibExtrospectBytecode
/// @notice Internal algorithms for extrospecting bytecode. Notably the EVM
/// opcode scanning needs special care, as the other bytecode functions are mere
/// wrappers around native EVM features.
library LibExtrospectBytecode {
    /// Scans opcodes present in a region of memory, as per
    /// `IExtrospectBytecodeV1.scanEVMOpcodesPresentInAccount`. The start cursor
    /// MUST point to the first byte of a region of memory that contract code has
    /// already been copied to, e.g. with `extcodecopy`.
    function scanEVMOpcodesPresentInMemory(Pointer cursor, uint256 length)
        internal
        pure
        returns (uint256 bytesPresent)
    {
        assembly ("memory-safe") {
            cursor := sub(cursor, 0x20)
            let end := add(cursor, length)
            for {} lt(cursor, end) {} {
                cursor := add(cursor, 1)

                let op := and(mload(cursor), 0xFF)
                //slither-disable-next-line incorrect-shift
                bytesPresent := or(bytesPresent, shl(op, 1))

                // The 32 `PUSH*` opcodes starting at 0x60 indicate that the
                // following bytes MUST be skipped as they are inline stack data
                // and NOT opcodes.
                let push := sub(op, 0x60)
                if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
            }
        }
    }
}
