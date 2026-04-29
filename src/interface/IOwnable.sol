// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IOwnable
/// @notice Minimal owner getter, matching the `owner()` selector exposed
/// by OpenZeppelin's `Ownable` and ERC-5313 (Light Contract Ownership).
/// Replicated locally so callers can read a beacon's owner without
/// pulling in OZ's full Ownable contract just for one selector.
interface IOwnable {
    /// @notice The contract's current owner.
    /// @return The owner address.
    function owner() external view returns (address);
}
