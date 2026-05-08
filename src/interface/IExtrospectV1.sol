// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectV1
/// @notice External interface for the concrete `Extrospect` contract.
/// Per-function semantics live with the library implementations under
/// `src/lib/Lib*.sol`.
interface IExtrospectV1 {
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool);

    function checkNotEOFBytecode(bytes memory bytecode) external pure;

    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode);

    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view;

    function checkNoSolidityCBORMetadata(address account) external view;

    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256);

    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256);

    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256);

    function checkNotMetamorphic(bytes memory bytecode) external pure;

    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address);

    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool);

    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool);
}
