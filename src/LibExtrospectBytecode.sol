// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibPointer.sol";
import "./EVMOpcodes.sol";

uint256 constant HALTING_BITMAP =
    (1 << EVM_OP_STOP) | (1 << EVM_OP_RETURN) | (1 << EVM_OP_REVERT) | (1 << EVM_OP_INVALID) | (1 << EVM_OP_SELFDESTRUCT);

/// @title LibExtrospectBytecode
/// @notice Internal algorithms for extrospecting bytecode. Notably the EVM
/// opcode scanning needs special care, as the other bytecode functions are mere
/// wrappers around native EVM features.
library LibExtrospectBytecode {
    /// Scans for opcodes that are reachable during execution of a contract.
    /// Adapted from https://github.com/MrLuit/selfdestruct-detect/blob/master/src/index.ts
    function scanEVMOpcodesReachableInMemory(Pointer cursor, uint256 length)
        internal
        pure
        returns (uint256 bytesReachable)
    {
        uint256 opJumpDest = EVM_OP_JUMPDEST;
        uint256 haltingMask = HALTING_BITMAP;
        assembly ("memory-safe") {
            cursor := sub(cursor, 0x20)
            let end := add(cursor, length)
            let halted := 0
            for {} lt(cursor, end) {} {
                cursor := add(cursor, 1)
                let op := and(mload(cursor), 0xFF)
                switch halted
                case 0 {
                    //slither-disable-next-line incorrect-shift
                    bytesReachable := or(bytesReachable, shl(op, 1))

                    if and(shl(op, 1), haltingMask) {
                        halted := 1
                        continue
                    }
                    // The 32 `PUSH*` opcodes starting at 0x60 indicate that the
                    // following bytes MUST be skipped as they are inline stack
                    // data and NOT opcodes.
                    let push := sub(op, 0x60)
                    if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
                }
                case 1 { if eq(op, opJumpDest) { halted := 0 } }
                // Can't happen, but the compiler doesn't know that.
                default { revert(0, 0) }
            }
        }
    }

    /// Scans opcodes present in a region of memory, as per
    /// `IExtrospectBytecodeV1.scanEVMOpcodesPresentInAccount`. The start cursor
    /// MUST point to the first byte of a region of memory that contract code has
    /// already been copied to, e.g. with `extcodecopy`.
    /// https://github.com/a16z/metamorphic-contract-detector/blob/main/metamorphic_detect/opcodes.py#L52
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
