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

    /// Thrown when bytecode metadata is not trimmed as expected.
    error MetadataNotTrimmed();

    /// Thrown when processing an EOF formatted bytecode.
    error EOFBytecodeNotSupported();

    /// Thrown when the bytecode hash does not match the expected value.
    /// @param expected The expected bytecode hash.
    /// @param actual The actual bytecode hash.
    error BytecodeHashMismatch(bytes32 expected, bytes32 actual);

    /// Returns whether the bytecode is in EOF format.
    /// @param bytecode The bytecode to check.
    /// @return isEOF Whether the bytecode is in EOF format.
    function isEOFBytecode(bytes memory bytecode) internal pure returns (bool isEOF) {
        if (bytecode.length >= 2) {
            assembly ("memory-safe") {
                let firstTwoBytes := and(mload(add(bytecode, 2)), 0xFFFF)
                isEOF := eq(firstTwoBytes, 0xEF00)
            }
        }
    }

    /// Checks that the bytecode is not in EOF format. Reverts if it is.
    /// @param bytecode The bytecode to check.
    //forge-lint: disable-next-line(mixed-case-function)
    function checkNotEOFBytecode(bytes memory bytecode) internal pure {
        if (isEOFBytecode(bytecode)) {
            revert EOFBytecodeNotSupported();
        }
    }

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
    /// @param bytecode The bytecode to trim metadata from.
    /// @return didTrim Whether metadata was detected and trimmed.
    //forge-lint: disable-next-line(mixed-case-function)
    function trimSolidityCBORMetadata(bytes memory bytecode) internal pure returns (bool didTrim) {
        checkNotEOFBytecode(bytecode);
        uint256 length = bytecode.length;
        if (length >= 53) {
            //slither-disable-next-line too-many-digits
            uint256 maskA = 0xFFFFFFFFFFFFFFFF00000000000000000000000000;
            //slither-disable-next-line too-many-digits
            uint256 maskB = 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF;
            bytes32 expectedHash = bytes32(uint256(0x0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62));
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

    /// Checks that the bytecode of an account, after trimming Solidity CBOR
    /// metadata, matches an expected hash. Reverts if the metadata was not
    /// trimmed or if the hash does not match after trimming.
    /// @param account The account whose bytecode to check.
    /// @param expected The expected hash of the trimmed bytecode.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) internal view {
        bytes memory bytecode = account.code;
        bool didTrim = LibExtrospectBytecode.trimSolidityCBORMetadata(bytecode);
        if (!didTrim) {
            revert MetadataNotTrimmed();
        }
        bytes32 actual = keccak256(bytecode);
        if (expected != actual) {
            revert BytecodeHashMismatch(expected, actual);
        }
    }

    /// Scans for opcodes that are reachable during execution of a contract.
    /// Adapted from https://github.com/MrLuit/selfdestruct-detect/blob/master/src/index.ts
    /// @param bytecode The bytecode to scan.
    /// @return bytesReachable A `uint256` where each bit represents the presence
    /// of a reachable opcode in the source bytecode.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) internal pure returns (uint256 bytesReachable) {
        checkNotEOFBytecode(bytecode);
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
                // The 32 `PUSH*` opcodes starting at 0x60 indicate that the
                // following bytes MUST be skipped as they are inline stack
                // data and NOT opcodes.
                let push := sub(op, 0x60)
                if lt(push, 0x20) {
                    cursor := add(cursor, add(push, 1))
                }
                switch halted
                case 0 {
                    //slither-disable-next-line incorrect-shift
                    bytesReachable := or(bytesReachable, shl(op, 1))

                    //slither-disable-next-line incorrect-shift
                    if and(shl(op, 1), haltingMask) {
                        halted := 1
                    }
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
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) internal pure returns (uint256 bytesPresent) {
        checkNotEOFBytecode(bytecode);
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
