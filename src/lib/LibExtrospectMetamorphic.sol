// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibExtrospectBytecode} from "./LibExtrospectBytecode.sol";
import {METAMORPHIC_OPS} from "./EVMOpcodes.sol";

/// @dev The lead byte EIP-3541 reserves: since the London hard fork no
/// ordinary deployment can produce code whose first byte is `0xEF`. On a
/// post-London chain new code beginning with it comes from protocol
/// features — an EOF container (`0xEF00`), an EIP-7702 delegation
/// designator (`0xEF0100 || address`), or whatever the prefix is assigned
/// next — none of which a legacy opcode scan can reason about; pre-London
/// deployments and chains without EIP-3541 can carry it as plain legacy
/// code the scan cannot tell apart by inspection. The metamorphic scan
/// fails closed on the first byte alone.
uint8 constant EIP3541_RESERVED_LEAD_BYTE = 0xEF;

/// @title LibExtrospectMetamorphic
/// @notice Detection and guarding against metamorphic contract risk. Scans
/// bytecode for reachable opcodes in `METAMORPHIC_OPS`, failing closed on
/// bytecode whose first byte is the EIP-3541 reserved `0xEF`: such code is a
/// protocol-defined format, not legacy opcodes, and the scan reports the
/// `0xEF` byte itself as the risky element rather than vouch for bytes it
/// cannot disassemble. The bytes-taking entry points are total over bytes and
/// answer only about the bytes given; the address-taking entry points bind
/// the verdict to an account and revert with `CodelessAccount` rather than
/// vouch for an account that has no code.
library LibExtrospectMetamorphic {
    /// Thrown when metamorphic risk opcodes are reachable in bytecode.
    /// @param riskyOpcodes Bitmap of reachable metamorphic opcodes.
    error Metamorphic(uint256 riskyOpcodes);

    /// Scans bytecode for reachable metamorphic risk opcodes. Total over
    /// bytes: never reverts, and answers only about the bytes given. Use
    /// `scanMetamorphicRisk(address)` to bind the scan to an account and
    /// reject a codeless one.
    ///
    /// Bytecode whose first byte is the EIP-3541 reserved `0xEF` fails
    /// closed: the scan reports a bitmap of exactly `1 << 0xEF` before any
    /// opcode scan, whatever the remaining bytes are. EIP-3541 reserves the
    /// prefix for protocol features — an EOF container (`0xEF00`), an
    /// EIP-7702 delegation designator (`0xEF0100 || address`, which the
    /// account holder repoints or revokes with one transaction), or
    /// whatever it is assigned next — that a legacy opcode scan cannot
    /// reason about; pre-London deployments and chains without EIP-3541
    /// can hold `0xEF`-lead legacy code indistinguishable by inspection.
    /// The verdict keys on the first byte alone and vouches for none of
    /// it. The reported bit
    /// is the `0xEF` lead byte itself, not a reachable opcode, and is not a
    /// member of `METAMORPHIC_OPS`. The reserved prefix is the one first
    /// byte that never reaches `scanEVMOpcodesReachableInBytecode`, so
    /// `EOFBytecodeNotSupported` is never thrown here.
    /// @param bytecode The bytecode to scan.
    /// @return Bitmap of risky elements: the reachable metamorphic opcodes,
    /// or exactly `1 << 0xEF` when the first byte is the reserved `0xEF`.
    /// Zero if no metamorphic risk opcodes are reachable, including when
    /// `bytecode` is empty.
    function scanMetamorphicRisk(bytes memory bytecode) internal pure returns (uint256) {
        if (bytecode.length > 0 && uint8(bytecode[0]) == EIP3541_RESERVED_LEAD_BYTE) {
            //forge-lint: disable-next-line(incorrect-shift)
            return uint256(1) << EIP3541_RESERVED_LEAD_BYTE;
        }
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode) & METAMORPHIC_OPS;
    }

    /// Reverts with `Metamorphic` when `scanMetamorphicRisk` reports a
    /// nonzero bitmap for the bytecode: any reachable metamorphic risk
    /// opcode, or a first byte of the EIP-3541 reserved `0xEF` — an EOF
    /// container, an EIP-7702 delegation designator, or any future
    /// assignment of the prefix — which reverts `Metamorphic(1 << 0xEF)`.
    /// Never reverts `EOFBytecodeNotSupported`.
    /// Empty bytecode has no reachable metamorphic opcodes and does not revert,
    /// so an account with no code — an externally owned account, an unoccupied
    /// `CREATE2` target, or a self-destructed account — passes this check on
    /// the same terms as an account whose code has no reachable metamorphic
    /// opcodes. Whether the account has any code at all is not checked here.
    /// Use `checkNotMetamorphic(address)` to bind the verdict to an account
    /// and reject a codeless one.
    /// @param bytecode The bytecode to check.
    function checkNotMetamorphic(bytes memory bytecode) internal pure {
        uint256 riskyOpcodes = scanMetamorphicRisk(bytecode);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }

    /// Reads `account`'s code and scans it for reachable metamorphic risk
    /// opcodes, delegating to `scanMetamorphicRisk(bytes)`. Reverts with
    /// `CodelessAccount` carrying the address when the account has no code:
    /// an account with no code is the maximally metamorphic state — an
    /// unoccupied `CREATE2` target, a self-destructed account between
    /// incarnations, or an EOA that can gain code by EIP-7702 delegation —
    /// and the chain cannot distinguish "can never gain code" from "can gain
    /// anything", so a zero bitmap for it would vouch for nothing. Account
    /// code whose first byte is the EIP-3541 reserved `0xEF` — an EOF
    /// container or an EIP-7702 delegation designator — reports exactly
    /// `1 << 0xEF`, as the bytes scan does.
    /// @param account The account whose code to scan.
    /// @return Bitmap of risky elements in the account's code: the reachable
    /// metamorphic opcodes, or exactly `1 << 0xEF` when the code's first
    /// byte is the reserved `0xEF`. Zero if none are reachable.
    function scanMetamorphicRisk(address account) internal view returns (uint256) {
        bytes memory bytecode = account.code;
        if (bytecode.length == 0) {
            revert LibExtrospectBytecode.CodelessAccount(account);
        }
        return scanMetamorphicRisk(bytecode);
    }

    /// Reads `account`'s code and reverts with `Metamorphic` if any
    /// metamorphic risk opcodes are reachable in it, delegating to
    /// `scanMetamorphicRisk(address)`. Reverts with `CodelessAccount`
    /// carrying the address when the account has no code, on the same terms
    /// as `scanMetamorphicRisk(address)`: no absence check answers "no code"
    /// as a pass. Reverts with `Metamorphic(1 << 0xEF)` when the account's
    /// code begins with the EIP-3541 reserved `0xEF` — an EOF container or
    /// an EIP-7702 delegation designator — as the bytes check does.
    /// @param account The account whose code to check.
    function checkNotMetamorphic(address account) internal view {
        uint256 riskyOpcodes = scanMetamorphicRisk(account);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }
}
