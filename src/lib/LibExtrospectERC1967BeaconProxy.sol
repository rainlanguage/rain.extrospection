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
/// The slot is not the only place a proxy holds its beacon. OpenZeppelin
/// v5 `BeaconProxy` also holds it in `address private immutable _beacon`,
/// which solc inlines into the proxy's runtime bytecode, so `proxy.code`
/// carries the 20 address bytes and any contract can read them.
/// OpenZeppelin v4 `BeaconProxy` has no such immutable, so its runtime
/// bytecode does not carry the address. This library extracts a beacon
/// address from neither.
///
/// EIP-7702 delegated accounts:
///
/// - An account whose code is a 23-byte delegation designator
///   (`0xef0100` followed by a 20-byte delegate address) runs the
///   delegate's code on every call, so it answers `implementation()`
///   and `owner()` and both predicates below can return true for it.
///   Neither predicate inspects the target's code, so a delegated
///   account is indistinguishable from a beacon contract in what they
///   return.
/// - The account holder repoints or revokes the designator in a single
///   transaction, so a true from either predicate about such an account
///   changes without any contract's code changing.
/// - `keccak256(addr.code)` on a delegated account hashes the 23-byte
///   designator, not the delegate's runtime bytecode.
///
/// The slot constants are exported so callers that have storage access
/// elsewhere use a single canonical source for the slot addresses.
library LibExtrospectERC1967BeaconProxy {
    /// @notice Read a beacon's current implementation address via
    /// `IBeacon.implementation()`. Yields `(false, address(0))` rather
    /// than reverting for a target that doesn't expose
    /// `implementation()`, whose call reverts, or whose return data is
    /// not exactly 32 bytes holding a clean address. Callers that need
    /// the implementation's bytecode properties feed the returned
    /// address to `LibExtrospectMetamorphic` / `LibExtrospectBytecode`.
    /// @param beacon The beacon address to query.
    /// @return True if the call to `implementation()` returned a clean
    /// address. False if it failed for any reason.
    /// @return The implementation address the beacon reports.
    /// `address(0)` whenever the first return value is false.
    function beaconImplementation(address beacon) internal view returns (bool, address) {
        return _tryGetAddress(beacon, IBeacon.implementation.selector);
    }

    /// @notice Verify that a beacon's current implementation has runtime
    /// bytecode matching `expectedRuntimeHash`. Useful for asserting a
    /// known-good implementation is behind the beacon. A target whose
    /// `implementation()` call reverts, or answers with anything other
    /// than 32 bytes that decode as an address, fails the check —
    /// returns false rather than reverting, so integrators can collapse
    /// the predicate into a single boolean assertion.
    ///
    /// The caller is responsible for only calling this on beacons.
    ///
    /// An implementation address with no code — an externally owned
    /// account, an unoccupied `CREATE2` target, a self-destructed
    /// account, or `address(0)` — reads as empty bytecode and hashes to
    /// `keccak256("")`, so `expectedRuntimeHash == keccak256("")` is
    /// satisfied by every codeless implementation. Whether the
    /// implementation has any code at all is not checked. Deploying code
    /// to a codeless implementation turns that same call from true to
    /// false.
    ///
    /// An EIP-7702 delegated account answers `implementation()` from its
    /// delegate and so satisfies this check; when `implementation()`
    /// itself returns a delegated account, the hash compared is that of
    /// its 23-byte delegation designator rather than of the delegate's
    /// runtime bytecode.
    /// @param beacon The beacon address to query.
    /// @param expectedRuntimeHash The expected `keccak256` of the
    /// implementation's whole runtime bytecode, including any Solidity CBOR
    /// metadata trailer. Not the same value as
    /// `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash`'s
    /// `expectedTrimmedHash`, which hashes runtime bytecode with that trailer
    /// removed.
    /// @return True if the beacon's current implementation has matching
    /// runtime bytecode. False if the call to `implementation()` fails
    /// for any reason.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) internal view returns (bool) {
        (bool ok, address impl) = _tryGetAddress(beacon, IBeacon.implementation.selector);
        return ok && keccak256(impl.code) == expectedRuntimeHash;
    }

    /// @notice Verify that `beacon`'s current owner equals
    /// `expectedOwner`. A target whose `owner()` call reverts, or
    /// answers with anything other than 32 bytes that decode as an
    /// address, fails the check — returns false rather than reverting,
    /// so integrators can collapse the predicate into a single boolean
    /// assertion.
    ///
    /// The caller is responsible for only calling this on beacons.
    ///
    /// An EIP-7702 delegated account answers `owner()` from its
    /// delegate and so satisfies this check.
    /// @param beacon The beacon address to query.
    /// @param expectedOwner The owner address the beacon should report.
    /// @return True if the ownership matches. False if the call to
    /// `owner()` fails for any reason.
    function isBeaconOwner(address beacon, address expectedOwner) internal view returns (bool) {
        (bool ok, address own) = _tryGetAddress(beacon, IOwnable.owner.selector);
        return ok && own == expectedOwner;
    }

    /// @dev Static-call `selector` on `target` and decode the return as
    /// `address`. Returns `(false, _)` on three failure modes:
    /// low-level call revert, return data that isn't exactly 32 bytes,
    /// or 32-byte return data whose upper 12 bytes are non-zero (which
    /// `abi.decode(_, (address))` would reject as a dirty address).
    ///
    /// A missing selector is only ever rejected through one of those
    /// three, via whatever `target`'s fallback does: no fallback or a
    /// reverting one is the revert case, and a fallback answering with
    /// something other than 32 clean bytes is one of the other two. A
    /// fallback answering with 32 clean bytes is accepted, so
    /// `(true, addr)` says that `target` answered `selector` with
    /// `addr` and nothing more.
    ///
    /// High-level `try IBeacon(...).implementation()` catches the
    /// first two but lets the dirty-address Panic escape, so we go
    /// through the low-level call to fold all three into a single
    /// boolean.
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
