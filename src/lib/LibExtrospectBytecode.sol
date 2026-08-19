// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibBytes, Pointer} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";
import {EVM_OP_JUMPDEST, HALTING_BITMAP} from "./EVMOpcodes.sol";

/// @dev Byte length of the standard Solidity CBOR metadata trailer that
/// `LibExtrospectBytecode.tryTrimSolidityCBORMetadata` matches and trims. The
/// trailer is 51 bytes of CBOR body followed by 2 bytes that encode that body
/// length, so every byte of it is accounted for by
/// `SOLIDITY_CBOR_METADATA_HEAD_MASK` and `SOLIDITY_CBOR_METADATA_TAIL_MASK`
/// together.
uint256 constant SOLIDITY_CBOR_METADATA_LENGTH = 53;

/// @dev Mask for the first of the two overlapping 32-byte words that cover the
/// final `SOLIDITY_CBOR_METADATA_LENGTH` bytes of bytecode. That word holds the
/// 11 bytes preceding the metadata in memory, which are bytecode unless the
/// bytecode is shorter than 64 bytes, followed by metadata bytes 0-20. The mask
/// keeps metadata bytes 0-7 (`a2` map header, `64` text header, `69706673` as
/// `ipfs`, `5822` byte string header) and zeros both those 11 preceding bytes
/// and metadata bytes 8-20, which are the first 13 bytes of the 34-byte IPFS
/// hash.
//slither-disable-next-line too-many-digits
uint256 constant SOLIDITY_CBOR_METADATA_HEAD_MASK = 0xFFFFFFFFFFFFFFFF00000000000000000000000000;

/// @dev Mask for the second of the two overlapping 32-byte words that cover the
/// final `SOLIDITY_CBOR_METADATA_LENGTH` bytes of bytecode. That word holds
/// metadata bytes 21-52. The mask keeps metadata bytes 42-47 (`64` text header,
/// `736f6c63` as `solc`, `43` byte string header) and metadata bytes 51-52 (the
/// 2-byte body length), and zeros metadata bytes 21-41, the last 21 bytes of the
/// IPFS hash, along with metadata bytes 48-50, the 3-byte solc version.
//slither-disable-next-line too-many-digits
uint256 constant SOLIDITY_CBOR_METADATA_TAIL_MASK = 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF;

/// @dev `keccak256` of `SOLIDITY_CBOR_METADATA_HEAD_MASK` applied to the first
/// word concatenated with `SOLIDITY_CBOR_METADATA_TAIL_MASK` applied to the
/// second, for bytecode whose final `SOLIDITY_CBOR_METADATA_LENGTH` bytes are
/// standard Solidity CBOR metadata. Because the masks zero every variable byte,
/// this single hash pins every structural byte the masks keep, including the
/// `0033` body length that makes the trailer 53 bytes long.
bytes32 constant SOLIDITY_CBOR_METADATA_MASKED_HASH =
    0x0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62;

/// @title LibExtrospectBytecode
/// @notice Internal algorithms for extrospecting bytecode. Notably the EVM
/// opcode scanning needs special care, as the other bytecode functions are mere
/// wrappers around native EVM features.
library LibExtrospectBytecode {
    using LibBytes for bytes;

    /// Thrown when bytecode metadata is not trimmed as expected.
    error MetadataNotTrimmed();

    /// Thrown when `isEOFBytecode` reports the bytecode as EOF.
    error EOFBytecodeNotSupported();

    /// Thrown when the bytecode hash does not match the expected value.
    /// @param expected The expected bytecode hash.
    /// @param actual The actual bytecode hash.
    error BytecodeHashMismatch(bytes32 expected, bytes32 actual);

    /// Thrown when bytecode ends in the one Solidity CBOR metadata layout that
    /// `tryTrimSolidityCBORMetadata` matches.
    error UnexpectedMetadata();

    /// Thrown when an address-taking absence check is asked about an account
    /// that has no code. An account with no code can gain any code later — an
    /// unoccupied `CREATE2` target, a self-destructed account between
    /// incarnations, or an EOA that can gain code by EIP-7702 delegation — so
    /// absence of code proves nothing and no absence check answers "no code"
    /// as a pass.
    /// @param account The account that has no code.
    error CodelessAccount(address account);

    /// Returns whether the first two bytes of the bytecode are the EOF magic
    /// `0xEF00`. The version byte that follows the magic in an EIP-3540
    /// container is not read, so `0xEF00` alone and `0xEF00` followed by any
    /// version byte are both reported as EOF. Bytecode shorter than two bytes
    /// is not reported as EOF — explicitly including empty bytecode, such as
    /// the code of an account that has none — and neither is bytecode starting
    /// with `0xEF` followed by any byte other than `0x00`, including the
    /// `0xEF01` of an EIP-7702 delegation designator. A `false` result says
    /// the bytes are not an EOF container; over empty bytes it says nothing
    /// about what code a codeless account may later gain.
    /// @param bytecode The bytecode to check.
    /// @return isEOF Whether the first two bytes are `0xEF00`.
    function isEOFBytecode(bytes memory bytecode) internal pure returns (bool isEOF) {
        if (bytecode.length >= 2) {
            assembly ("memory-safe") {
                let firstTwoBytes := and(mload(add(bytecode, 2)), 0xFFFF)
                isEOF := eq(firstTwoBytes, 0xEF00)
            }
        }
    }

    /// Reverts with `EOFBytecodeNotSupported` if `isEOFBytecode` returns true
    /// for the bytecode.
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
    /// - First byte `0xa2` is cbor map header (map with 2 entries)
    /// - Next byte `0x64` is cbor text string prefix (4-byte string follows)
    /// - Next 4 bytes `0x69706673` as `ipfs` ascii/utf8
    /// - Next 2 bytes `0x5822` as cbor byte string prefix (34-byte hash follows)
    /// - Next 34 bytes are the IPFS hash (yes 34, not 32)
    /// - Next byte `0x64` is cbor text string prefix (4-byte string follows)
    /// - Next 4 bytes `0x736f6c63` as `solc` ascii/utf8
    /// - Next byte `0x43` is cbor byte string prefix (3-byte version follows)
    /// - Next 3 bytes as solc version (e.g. `0x000804`)
    /// - Final 2 bytes specify length of metadata which is always 51 bytes
    ///
    /// For the sake of trimming metadata in an 80/20 way we check that all the
    /// static parts are present and correct, and ignore the parts that change.
    /// The length of the metadata must always be 51+2 bytes, as the dynamic
    /// parts still have constant length.
    ///
    /// NOTE bytecode is mutated in place. Trimming writes the shorter length
    /// over the array's own length word, so every reference to that same array
    /// observes the trim, not just the one passed here.
    ///
    /// NOTE EOF bytecode is not supported by this function and reverts with
    /// `EOFBytecodeNotSupported`.
    ///
    /// NOTE this function constrains only the 16 structural bytes of the 53
    /// byte trailer. Taking the first trailer byte as offset 0, the constrained
    /// offsets are 0-7 (`a2 64 "ipfs" 5822`), 42-47 (`64 "solc" 43`) and 51-52
    /// (`0033`). The 34 IPFS hash bytes at offsets 8-41 and the 3 solc version
    /// bytes at offsets 48-50, 37 bytes in total, are unconstrained and may
    /// hold any value. Any 53 byte tail carrying the 16 structural bytes at
    /// those offsets is trimmed, whether or not a compiler emitted it.
    ///
    /// NOTE metadata that does not match the assumed structure is not trimmed,
    /// even if it is valid Solidity CBOR metadata or some other form of
    /// metadata, and even if it is 53 bytes long. That case DOES NOT revert or
    /// cause any other issues, it just causes the function to return `false`
    /// and leave the bytecode untrimmed.
    ///
    /// @param bytecode The bytecode to trim metadata from.
    /// @return didTrim Whether metadata was detected and trimmed.
    //forge-lint: disable-next-line(mixed-case-function)
    function tryTrimSolidityCBORMetadata(bytes memory bytecode) internal pure returns (bool didTrim) {
        checkNotEOFBytecode(bytecode);
        uint256 length = bytecode.length;
        if (length >= SOLIDITY_CBOR_METADATA_LENGTH) {
            // Two adjacent 32-byte reads span the last
            // `SOLIDITY_CBOR_METADATA_LENGTH` bytes of bytecode (the metadata)
            // plus the 11 bytes of memory immediately before them. The masks
            // zero those 11 bytes and the variable parts of the metadata
            // (34-byte IPFS hash and 3-byte solc version), preserving only the
            // fixed CBOR structure bytes: a2 64 "ipfs" 5822 ... 64 "solc" 43
            // ... 0033. The masked result hashes to
            // `SOLIDITY_CBOR_METADATA_MASKED_HASH` exactly when the metadata
            // matches.
            //slither-disable-next-line too-many-digits
            uint256 maskA = SOLIDITY_CBOR_METADATA_HEAD_MASK;
            //slither-disable-next-line too-many-digits
            uint256 maskB = SOLIDITY_CBOR_METADATA_TAIL_MASK;
            bytes32 expectedHash = SOLIDITY_CBOR_METADATA_MASKED_HASH;
            bytes32 relevantHash;
            assembly ("memory-safe") {
                // Point 0x20 bytes before the end of the bytecode.
                let end := add(bytecode, length)
                mstore(0, and(maskA, mload(sub(end, 0x20))))
                mstore(0x20, and(maskB, mload(end)))
                relevantHash := keccak256(0, 0x40)
                didTrim := eq(relevantHash, expectedHash)
                if didTrim { mstore(bytecode, sub(length, SOLIDITY_CBOR_METADATA_LENGTH)) }
            }
        }
    }

    /// Checks that the bytecode of an account, after trimming Solidity CBOR
    /// metadata, matches an expected hash. Reverts with `MetadataNotTrimmed` if
    /// the metadata was not trimmed, or with `BytecodeHashMismatch` if the hash
    /// does not match after trimming.
    ///
    /// NOTE EOF bytecode is not supported by this function and reverts with
    /// `EOFBytecodeNotSupported` before either of the above is reached.
    ///
    /// NOTE `expectedTrimmedHash` covers only the bytecode left after
    /// trimming. The 53 trimmed bytes are runtime code that the EVM executes
    /// if a jump lands in them, and 37 of them are unconstrained by
    /// `tryTrimSolidityCBORMetadata`. Two accounts whose code differs only in
    /// those 37 bytes both satisfy the same `expectedTrimmedHash`.
    ///
    /// NOTE an account whose code is exactly the 53 byte metadata trailer and
    /// nothing else trims to an empty remainder, so the trimmed hash is
    /// `keccak256("")` for every such account. As the trailer's 34 byte IPFS
    /// hash and 3 byte solc version are not constrained by the trim, an
    /// `expectedTrimmedHash` of `keccak256("")` matches all of them and does
    /// not identify any one of them.
    /// @param account The account whose bytecode to check.
    /// @param expectedTrimmedHash The expected hash of the trimmed bytecode.
    /// Not the same value as
    /// `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`'s
    /// `expectedRuntimeHash`, which hashes runtime bytecode whole.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expectedTrimmedHash) internal view {
        bytes memory bytecode = account.code;
        bool didTrim = tryTrimSolidityCBORMetadata(bytecode);
        if (!didTrim) {
            revert MetadataNotTrimmed();
        }
        bytes32 actual = keccak256(bytecode);
        if (expectedTrimmedHash != actual) {
            revert BytecodeHashMismatch(expectedTrimmedHash, actual);
        }
    }

    /// Checks that no standard Solidity CBOR metadata is present in the
    /// bytecode of an account. Reverts with `UnexpectedMetadata` if metadata is
    /// detected. This is the inverse of `checkCBORTrimmedBytecodeHash` — use
    /// this when bytecode should have been compiled without metadata (e.g.
    /// `cbor_metadata = false` in foundry.toml) as a defense against the
    /// metamorphic metadata attack.
    ///
    /// NOTE EOF bytecode is not supported by this function. An account whose
    /// bytecode is EOF reverts with `EOFBytecodeNotSupported`, so for such an
    /// account neither the passing case nor `UnexpectedMetadata` is reached.
    ///
    /// NOTE detection is `tryTrimSolidityCBORMetadata`, which constrains only
    /// 16 of the 53 trailer bytes, so an account whose code merely ends with
    /// those 16 bytes at the expected offsets reverts here even if no compiler
    /// emitted metadata for it.
    ///
    /// NOTE every trailer `tryTrimSolidityCBORMetadata` does not match returns
    /// without reverting, and that includes Solidity CBOR metadata in other
    /// encodings: the solc-version-only trailer emitted when `bytecode_hash` is
    /// `none` and `cbor_metadata` is left on, `bzzr1`/Swarm hashes, reordered
    /// or additional CBOR map keys, and solc versions not encoded as `0x43`
    /// plus three bytes. Returning without reverting therefore establishes that
    /// this one layout is absent, not that the account carries no metadata.
    ///
    /// NOTE an account with no code reverts with `CodelessAccount` carrying
    /// the address, before metadata detection is attempted. Absence of code
    /// is not absence of metadata risk: a codeless account can gain any code
    /// later, so this check refuses to vouch for it.
    ///
    /// @param account The account whose bytecode to check.
    //forge-lint: disable-next-line(mixed-case-function)
    function checkNoSolidityCBORMetadata(address account) internal view {
        bytes memory bytecode = account.code;
        if (bytecode.length == 0) {
            revert CodelessAccount(account);
        }
        bool didTrim = tryTrimSolidityCBORMetadata(bytecode);
        if (didTrim) {
            revert UnexpectedMetadata();
        }
    }

    /// Scans for opcodes that are reachable during execution of a contract.
    /// Uses a linear over-approximation: scans sequentially, skipping PUSH*
    /// inline data. When a halting opcode is encountered (STOP, RETURN, REVERT,
    /// INVALID, SELFDESTRUCT, or unconditional JUMP per `HALTING_BITMAP`),
    /// scanning pauses. Scanning resumes at the next JUMPDEST. Opcodes between
    /// a halt and the next JUMPDEST are treated as unreachable and excluded.
    /// The sweep does not distinguish code from data, so a JUMPDEST byte that it
    /// lands on inside a data region such as Solidity CBOR metadata resumes
    /// scanning, and the opcodes after it in that region are reported as
    /// reachable.
    /// This is an over-approximation: not all JUMPDESTs are actually reachable
    /// at runtime, and the byte values Cancun leaves unassigned other than
    /// INVALID do not pause scanning even though the EVM halts on them.
    /// A trailing PUSH* whose inline data runs past the end of the bytecode
    /// ends the scan. The PUSH* opcode itself is recorded per the rules above,
    /// and every byte after it is treated as that PUSH*'s inline data, so none
    /// of those bytes are scanned as opcodes.
    /// Adapted from https://github.com/MrLuit/selfdestruct-detect/blob/master/src/index.ts
    /// NOTE: Reverts with `EOFBytecodeNotSupported` if the bytecode is EOF
    /// (EIP-7692).
    /// NOTE: Empty bytecode scans to a zero bitmap: there are no bytes, so no
    /// opcode is reachable. The empty code of a codeless account scans the
    /// same way, and zero says nothing about what opcodes that account may
    /// later gain. Use `scanEVMOpcodesReachableInBytecode(address)` to bind
    /// the scan to an account and reject a codeless one.
    /// @param bytecode The bytecode to scan.
    /// @return bytesReachable A `uint256` where each bit represents the presence
    /// of a reachable opcode in the source bytecode.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) internal pure returns (uint256 bytesReachable) {
        checkNotEOFBytecode(bytecode);
        Pointer cursor = bytecode.dataPointer();
        uint256 length = bytecode.length;
        uint256 opJumpDest = EVM_OP_JUMPDEST;
        uint256 haltingMask = HALTING_BITMAP;
        assembly ("memory-safe") {
            cursor := sub(cursor, 0x20)
            let end := add(cursor, length)
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

    /// Reads `account`'s code and scans it for reachable opcodes, delegating
    /// to `scanEVMOpcodesReachableInBytecode(bytes)`. Reverts with
    /// `CodelessAccount` carrying the address when the account has no code:
    /// an account with no code can gain any code later — an unoccupied
    /// `CREATE2` target, a self-destructed account between incarnations, or
    /// an EOA that can gain code by EIP-7702 delegation — so a zero bitmap
    /// for it would vouch for nothing. Reverts with `EOFBytecodeNotSupported`
    /// if the account's code is EOF, as the bytes scan does.
    /// @param account The account whose code to scan.
    /// @return A `uint256` where each bit represents the presence of a
    /// reachable opcode in the account's code.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesReachableInBytecode(address account) internal view returns (uint256) {
        bytes memory bytecode = account.code;
        if (bytecode.length == 0) {
            revert CodelessAccount(account);
        }
        return scanEVMOpcodesReachableInBytecode(bytecode);
    }

    /// Scans all opcodes present in bytecode, respecting PUSH* inline data.
    /// A trailing PUSH* whose inline data runs past the end of the bytecode
    /// ends the scan. The PUSH* opcode itself is recorded, and every byte after
    /// it is treated as that PUSH*'s inline data, so none of those bytes are
    /// scanned as opcodes.
    /// Adapted from
    /// https://github.com/a16z/metamorphic-contract-detector/blob/main/metamorphic_detect/opcodes.py#L52
    /// NOTE: Reverts with `EOFBytecodeNotSupported` if the bytecode is EOF
    /// (EIP-7692).
    /// NOTE: Empty bytecode scans to a zero bitmap: there are no bytes, so no
    /// opcode is present. The empty code of a codeless account scans the same
    /// way, and zero says nothing about what opcodes that account may later
    /// gain. Use `scanEVMOpcodesPresentInBytecode(address)` to bind the scan
    /// to an account and reject a codeless one.
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

    /// Reads `account`'s code and scans it for present opcodes, delegating to
    /// `scanEVMOpcodesPresentInBytecode(bytes)`. Reverts with
    /// `CodelessAccount` carrying the address when the account has no code:
    /// an account with no code can gain any code later — an unoccupied
    /// `CREATE2` target, a self-destructed account between incarnations, or
    /// an EOA that can gain code by EIP-7702 delegation — so a zero bitmap
    /// for it would vouch for nothing. Reverts with `EOFBytecodeNotSupported`
    /// if the account's code is EOF, as the bytes scan does.
    /// @param account The account whose code to scan.
    /// @return A `uint256` where each bit represents the presence of an
    /// opcode in the account's code.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesPresentInBytecode(address account) internal view returns (uint256) {
        bytes memory bytecode = account.code;
        if (bytecode.length == 0) {
            revert CodelessAccount(account);
        }
        return scanEVMOpcodesPresentInBytecode(bytecode);
    }
}
