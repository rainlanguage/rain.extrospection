// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {IBeacon} from "../interface/IBeacon.sol";
import {IOwnable} from "../interface/IOwnable.sol";

/// @dev EIP-1967 implementation storage slot, derived in-source from the
/// spec formula. Evaluated at compile time, zero runtime cost.
bytes32 constant ERC1967_IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

/// @dev EIP-1967 admin storage slot, derived in-source from the spec
/// formula.
bytes32 constant ERC1967_ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

/// @dev EIP-1967 beacon storage slot, derived in-source from the spec
/// formula.
bytes32 constant ERC1967_BEACON_SLOT = bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

/// @title LibExtrospectERC1967BeaconProxy
/// @notice Introspection helpers for ERC-1967 beacon proxies and the
/// beacons they point at.
///
/// What's possible from a runtime contract context (no cheat codes):
///
/// - Read a beacon's implementation via `IBeacon.implementation()` —
///   well-defined interface, callable from anywhere.
/// - Read a beacon's owner via `Ownable.owner()` — de-facto convention
///   for beacons that inherit OZ `Ownable` or equivalent.
/// - Hash a contract's runtime bytecode via `keccak256(addr.code)` to
///   compare against an expected template.
///
/// What's NOT possible from a runtime contract context:
///
/// - Reading a proxy's beacon storage slot directly. ERC-1967 specifies
///   the slot but not a getter — proxies route everything through
///   `delegatecall`, with no public function exposing the slot. To read
///   it you need either Foundry's `vm.load` (tests), an off-chain
///   `eth_getStorageAt`, or `sload` from a delegatecall context running
///   as the proxy.
///
/// The slot constants are exported so callers that have storage access
/// elsewhere use a single canonical source for the slot addresses.
library LibExtrospectERC1967BeaconProxy {
    /// @notice Read the current implementation address of `beacon` via
    /// `IBeacon.implementation()`. Reverts if `beacon` does not expose
    /// the standard interface.
    /// @param beacon The beacon address to query.
    /// @return The implementation address the beacon currently points at.
    function implementationOf(address beacon) internal view returns (address) {
        return IBeacon(beacon).implementation();
    }

    /// @notice Read the owner of `beacon` via `Ownable.owner()`. Reverts
    /// if `beacon` does not expose the standard interface.
    /// @param beacon The beacon address to query.
    /// @return The current owner of the beacon.
    function ownerOf(address beacon) internal view returns (address) {
        return IOwnable(beacon).owner();
    }

    /// @notice Verify that a beacon's current implementation has runtime
    /// bytecode matching `expectedRuntimeHash`. Useful for asserting a
    /// known-good implementation is behind the beacon without trusting
    /// any storage-side state. A target that doesn't expose
    /// `implementation()` (or whose call reverts) is not a valid beacon
    /// and trivially fails the check — returns false rather than
    /// reverting, so integrators can collapse the predicate into a
    /// single boolean assertion.
    /// @param beacon The beacon address to query.
    /// @param expectedRuntimeHash The expected `keccak256` of the
    /// implementation's runtime bytecode.
    /// @return True if the beacon's current implementation has matching
    /// runtime bytecode. False if the call to `implementation()` fails
    /// for any reason.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) internal view returns (bool) {
        try IBeacon(beacon).implementation() returns (address impl) {
            return keccak256(impl.code) == expectedRuntimeHash;
        } catch {
            return false;
        }
    }

    /// @notice Verify that the runtime bytecode at `target` matches
    /// `expectedRuntimeHash`. Standalone helper for any runtime
    /// bytecode comparison the caller knows the expected hash for.
    /// @param target The contract address whose runtime to hash.
    /// @param expectedRuntimeHash The expected `keccak256` of the
    /// runtime bytecode.
    /// @return True if the hashes match.
    function isRuntimeBytecode(address target, bytes32 expectedRuntimeHash) internal view returns (bool) {
        return keccak256(target.code) == expectedRuntimeHash;
    }

    /// @notice Verify that `beacon`'s current owner equals
    /// `expectedOwner`. A target that doesn't expose `owner()` (or
    /// whose call reverts) is not a valid beacon and trivially fails
    /// the check — returns false rather than reverting, so integrators
    /// can collapse the predicate into a single boolean assertion.
    /// @param beacon The beacon address to query.
    /// @param expectedOwner The owner address the beacon should report.
    /// @return True if the ownership matches. False if the call to
    /// `owner()` fails for any reason.
    function isBeaconOwner(address beacon, address expectedOwner) internal view returns (bool) {
        try IOwnable(beacon).owner() returns (address own) {
            return own == expectedOwner;
        } catch {
            return false;
        }
    }
}
