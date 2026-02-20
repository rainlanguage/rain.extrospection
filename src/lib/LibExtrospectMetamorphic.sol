// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibExtrospectBytecode} from "./LibExtrospectBytecode.sol";
import {METAMORPHIC_OPS} from "./EVMOpcodes.sol";

/// @title LibExtrospectMetamorphic
/// @notice Detection and guarding against metamorphic contract risk. Scans
/// bytecode for reachable opcodes that could enable a contract to be destroyed
/// and redeployed with different code at the same address.
library LibExtrospectMetamorphic {
    /// Thrown when metamorphic risk opcodes are reachable in bytecode.
    /// @param riskyOpcodes Bitmap of reachable metamorphic opcodes.
    error Metamorphic(uint256 riskyOpcodes);

    /// Scans bytecode for reachable metamorphic risk opcodes.
    /// @param bytecode The bytecode to scan.
    /// @return riskyOpcodes Bitmap of reachable metamorphic opcodes. Zero if
    /// no metamorphic risk opcodes are reachable.
    function scanMetamorphicRisk(bytes memory bytecode) internal pure returns (uint256 riskyOpcodes) {
        riskyOpcodes = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode) & METAMORPHIC_OPS;
    }

    /// Reverts if any metamorphic risk opcodes are reachable in bytecode.
    /// @param bytecode The bytecode to check.
    function checkNotMetamorphic(bytes memory bytecode) internal pure {
        uint256 riskyOpcodes = scanMetamorphicRisk(bytecode);
        if (riskyOpcodes != 0) {
            revert Metamorphic(riskyOpcodes);
        }
    }
}
