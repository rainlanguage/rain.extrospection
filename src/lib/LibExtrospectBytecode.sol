// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.18;

import {LibBytes, Pointer} from "rain.solmem/lib/LibBytes.sol";
import {EVM_OP_JUMPDEST, HALTING_BITMAP} from "./EVMOpcodes.sol";

/// @title LibExtrospectBytecode
/// @notice Internal algorithms for extrospecting bytecode. Notably the EVM
/// opcode scanning needs special care, as the other bytecode functions are mere
/// wrappers around native EVM features.
library LibExtrospectBytecode {
    using LibBytes for bytes;

    /// https://docs.soliditylang.org/en/latest/metadata.html#encoding-of-the-metadata-hash-in-the-bytecode
    ///
    /// The encoding is not super complex, but requires having a CBOR decoder to
    /// do anything properly at all. At the time of writing, the existing CBOR
    /// decoding options in Solidity are 3+ years old and not maintained, nor is
    /// it clear what quality or maturity they have.
    ///
    /// MOST OF THE TIME, the metadata is either not present or will follow the
    /// default structure. This is:
    /// - First 2 bytes of the 51 bytes are `0xa264` as cbor structure
    /// - Next 4 bytes `0x69706673` as `ipfs` ascii/utf8
    /// - Next 2 bytes `0x5822` as cbor structure
    /// - Next 34 bytes are the IPFS hash (yes 34, not 32)
    /// - Next 1 bytes `0x64` as cbor structure
    /// - Next 4 byte `0x736f6c63` as `solc` ascii/utf8
    /// - Next 1 byte `0x43` as cbor structure
    /// - Next 3 bytes as solc version (e.g. `0x000804`)
    /// - Final 2 bytes specify length of metadata which is always 51 bytes
    ///
    /// For the sake of trimming metadata in an 80/20 way we check that all the
    /// static parts are present and correct, and ignore the parts that change.
    /// The length of the metadata must always be 51+2 bytes, as the dynamic
    /// parts still have constant length.
    ///
    /// NOTE bytecode is mutated in place.
    function trimSolidityCBORMetadata(bytes memory bytecode) internal pure returns (bool didTrim) {
        uint256 length = bytecode.length;
        if (length >= 53) {
            uint256 maskA = 0x0000000000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000;
            uint256 maskB = 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF;
            bytes32 expectedHash = bytes32(uint256(0xe55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62));
            bytes32 relevantHash;
            assembly ("memory-safe") {
                // Point 0x20 bytes before the end of the bytecode.
                let end := add(bytecode, length)
                mstore(0, and(maskA, mload(sub(end, 0x20))))
                mstore(0x20, and(maskB, mload(end)))
                relevantHash := keccak256(0, 0x40)
                didTrim := eq(relevantHash, expectedHash)
                if didTrim { mstore(bytecode, sub(length, 53)) }
            }
        }
    }

    /// Scans for opcodes that are reachable during execution of a contract.
    /// Adapted from https://github.com/MrLuit/selfdestruct-detect/blob/master/src/index.ts
    /// @param bytecode The bytecode to scan.
    /// @return bytesReachable A `uint256` where each bit represents the presence
    /// of a reachable opcode in the source bytecode.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) internal pure returns (uint256 bytesReachable) {
        Pointer cursor = bytecode.dataPointer();
        uint256 length = bytecode.length;
        Pointer end;
        uint256 opJumpDest = EVM_OP_JUMPDEST;
        uint256 haltingMask = HALTING_BITMAP;
        assembly ("memory-safe") {
            cursor := sub(cursor, 0x20)
            end := add(cursor, length)
            let halted := 0
            for {} lt(cursor, end) {} {
                cursor := add(cursor, 1)
                let op := and(mload(cursor), 0xFF)
                switch halted
                case 0 {
                    //slither-disable-next-line incorrect-shift
                    bytesReachable := or(bytesReachable, shl(op, 1))

                    //slither-disable-next-line incorrect-shift
                    if and(shl(op, 1), haltingMask) {
                        halted := 1
                        continue
                    }
                    // The 32 `PUSH*` opcodes starting at 0x60 indicate that the
                    // following bytes MUST be skipped as they are inline stack
                    // data and NOT opcodes.
                    let push := sub(op, 0x60)
                    if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
                    continue
                }
                case 1 {
                    if eq(op, opJumpDest) {
                        halted := 0
                        //slither-disable-next-line incorrect-shift
                        bytesReachable := or(bytesReachable, shl(op, 1))
                    }
                    continue
                }
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
    /// @param bytecode The bytecode to scan.
    /// @return bytesPresent A `uint256` where each bit represents the presence
    /// of an opcode in the source bytecode.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) internal pure returns (uint256 bytesPresent) {
        Pointer cursor = bytecode.dataPointer();
        uint256 length = bytecode.length;
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
