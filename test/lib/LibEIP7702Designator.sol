// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @dev The three-byte prefix of an EIP-7702 delegation designator.
bytes3 constant EIP7702_DELEGATION_PREFIX = 0xef0100;

/// @dev Total byte length of an EIP-7702 delegation designator: the
/// three-byte prefix plus a 20-byte delegate address.
uint256 constant EIP7702_DESIGNATOR_LENGTH = 23;

/// @title LibEIP7702Designator
/// @notice Test-only builder for the EIP-7702 delegation designator an
/// authorised account carries as its code, so the shape lives in one
/// place across the test suite.
library LibEIP7702Designator {
    /// @notice Build the delegation designator that points at
    /// `delegate`.
    /// @param delegate The address whose code the delegating account
    /// executes.
    /// @return The 23-byte designator.
    function designator(address delegate) internal pure returns (bytes memory) {
        return bytes.concat(EIP7702_DELEGATION_PREFIX, bytes20(delegate));
    }
}
