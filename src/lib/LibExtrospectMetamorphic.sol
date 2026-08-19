// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibExtrospectBytecode} from "./LibExtrospectBytecode.sol";
import {METAMORPHIC_OPS} from "./EVMOpcodes.sol";

/// @title LibExtrospectMetamorphic
/// @notice Detection and guarding against metamorphic contract risk. Scans
/// bytecode for reachable opcodes in `METAMORPHIC_OPS`.
library LibExtrospectMetamorphic {
    /// Thrown when metamorphic risk opcodes are reachable in bytecode.
    /// @param riskyOpcodes Bitmap of reachable metamorphic opcodes.
    error Metamorphic(uint256 riskyOpcodes);

    /// Scans bytecode for reachable metamorphic risk opcodes. Reverts with
    /// `EOFBytecodeNotSupported` if the bytecode is EOF.
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
    /// @param bytecode The bytecode to check.
    function checkNotMetamorphic(bytes memory bytecode) internal pure {
        uint256 riskyOpcodes = scanMetamorphicRisk(bytecode);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }

    /// Reads `account`'s code and scans it for reachable metamorphic risk
    /// opcodes, delegating to `scanMetamorphicRisk(bytes)`.
    /// @param account The account whose code to scan.
    /// @return riskyOpcodes Bitmap of reachable metamorphic opcodes in the
    /// account's code. Zero if none are reachable.
    function scanMetamorphicRisk(address account) internal view returns (uint256 riskyOpcodes) {
        bytes memory bytecode = account.code;
        riskyOpcodes = scanMetamorphicRisk(bytecode);
    }

    /// Reads `account`'s code and reverts with `Metamorphic` if any
    /// metamorphic risk opcodes are reachable in it, delegating to
    /// `scanMetamorphicRisk(address)`.
    /// @param account The account whose code to check.
    function checkNotMetamorphic(address account) internal view {
        uint256 riskyOpcodes = scanMetamorphicRisk(account);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }
}
