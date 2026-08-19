// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibExtrospectBytecode} from "./LibExtrospectBytecode.sol";
import {METAMORPHIC_OPS} from "./EVMOpcodes.sol";

/// @title LibExtrospectMetamorphic
/// @notice Detection and guarding against metamorphic contract risk. Scans
/// bytecode for reachable opcodes in `METAMORPHIC_OPS`. The bytes-taking
/// entry points are total over bytes and answer only about the bytes given;
/// the address-taking entry points bind the verdict to an account and revert
/// with `CodelessAccount` rather than vouch for an account that has no code.
library LibExtrospectMetamorphic {
    /// Thrown when metamorphic risk opcodes are reachable in bytecode.
    /// @param riskyOpcodes Bitmap of reachable metamorphic opcodes.
    error Metamorphic(uint256 riskyOpcodes);

    /// Scans bytecode for reachable metamorphic risk opcodes. Reverts with
    /// `EOFBytecodeNotSupported` if the bytecode is EOF.
    /// Answers only about the bytes given. Use `scanMetamorphicRisk(address)`
    /// to bind the scan to an account and reject a codeless one.
    /// @param bytecode The bytecode to scan.
    /// @return riskyOpcodes Bitmap of reachable metamorphic opcodes. Zero if
    /// no metamorphic risk opcodes are reachable, including when `bytecode` is
    /// empty.
    function scanMetamorphicRisk(bytes memory bytecode) internal pure returns (uint256 riskyOpcodes) {
        riskyOpcodes = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode) & METAMORPHIC_OPS;
    }

    /// Reverts if any metamorphic risk opcodes are reachable in bytecode.
    /// Also reverts with `EOFBytecodeNotSupported` if the bytecode is EOF.
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
    /// anything", so a zero bitmap for it would vouch for nothing. Reverts
    /// with `EOFBytecodeNotSupported` if the account's code is EOF, as the
    /// bytes scan does.
    /// @param account The account whose code to scan.
    /// @return riskyOpcodes Bitmap of reachable metamorphic opcodes in the
    /// account's code. Zero if none are reachable.
    function scanMetamorphicRisk(address account) internal view returns (uint256 riskyOpcodes) {
        bytes memory bytecode = account.code;
        if (bytecode.length == 0) {
            revert LibExtrospectBytecode.CodelessAccount(account);
        }
        riskyOpcodes = scanMetamorphicRisk(bytecode);
    }

    /// Reads `account`'s code and reverts with `Metamorphic` if any
    /// metamorphic risk opcodes are reachable in it, delegating to
    /// `scanMetamorphicRisk(address)`. Reverts with `CodelessAccount`
    /// carrying the address when the account has no code, on the same terms
    /// as `scanMetamorphicRisk(address)`: no absence check answers "no code"
    /// as a pass. Reverts with `EOFBytecodeNotSupported` if the account's
    /// code is EOF.
    /// @param account The account whose code to check.
    function checkNotMetamorphic(address account) internal view {
        uint256 riskyOpcodes = scanMetamorphicRisk(account);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }
}
