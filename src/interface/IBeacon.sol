// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IBeacon
/// @notice De-facto interface every ERC-1967 beacon contract exposes so
/// the proxies routed through it can fetch the current implementation
/// each delegate call. Replicated from OpenZeppelin's `IBeacon` to keep
/// rain.extrospection callable without pulling the full OZ dependency
/// for one selector.
interface IBeacon {
    /// @notice The implementation contract the beacon currently points
    /// at. Beacon proxies route every delegate call through this getter.
    /// @return The implementation address.
    function implementation() external view returns (address);
}
