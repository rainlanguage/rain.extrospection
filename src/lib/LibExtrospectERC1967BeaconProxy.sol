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
/// @notice Extrospection of ERC-1967 beacon proxies and the beacons
/// they point at.
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
        (bool ok, address impl) = _tryGetAddress(beacon, IBeacon.implementation.selector);
        return ok && keccak256(impl.code) == expectedRuntimeHash;
    }

    /// @notice Verify that the runtime bytecode at `target` matches
    /// `expectedRuntimeHash`. Available standalone for any runtime
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
        (bool ok, address own) = _tryGetAddress(beacon, IOwnable.owner.selector);
        return ok && own == expectedOwner;
    }

    /// @dev Static-call `selector` on `target` and decode the return as
    /// `address`. Returns `(false, _)` on any failure mode: low-level
    /// call revert, missing selector, fallback returning the wrong
    /// length, or 32-byte return data whose upper 12 bytes are
    /// non-zero (which `abi.decode(_, (address))` would reject as a
    /// dirty address). High-level `try IBeacon(...).implementation()`
    /// catches the first three but lets the dirty-address Panic
    /// escape, so we go through the low-level call to fold all four
    /// into a single boolean.
    function _tryGetAddress(address target, bytes4 selector) private view returns (bool, address) {
        // Low-level staticcall is required to validate return-data length
        // and reject dirty address bits ourselves; high-level
        // `try IBeacon(...).implementation() returns (address)` lets the
        // dirty-address Panic escape past the catch.
        //slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) = target.staticcall(abi.encodeWithSelector(selector));
        if (!success || returnData.length != 32) return (false, address(0));
        uint256 raw;
        assembly ("memory-safe") {
            raw := mload(add(returnData, 0x20))
        }
        if (raw > type(uint160).max) return (false, address(0));
        return (true, address(uint160(raw)));
    }
}
