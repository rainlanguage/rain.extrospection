// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectMetamorphicV1
/// @notice External functions for offchain processing to determine if a
/// contract has metamorphic risk. A contract is at risk of metamorphism if it
/// contains reachable opcodes that could enable destruction and redeployment
/// with different code at the same address. The `METAMORPHIC_OPS` bitmap in
/// `EVMOpcodes.sol` defines the set of risky opcodes.
interface IExtrospectMetamorphicV1 {
    /// Scan the bytecode of an account for reachable metamorphic risk opcodes.
    /// @param account The account to scan.
    /// @return riskyOpcodes Bitmap of reachable metamorphic opcodes. Zero if
    /// no metamorphic risk opcodes are reachable.
    function scanMetamorphicRisk(address account) external view returns (uint256 riskyOpcodes);
}
