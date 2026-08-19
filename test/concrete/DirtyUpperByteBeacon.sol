// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// selectors exist and return successfully, but with a 32-byte word
/// holding a real address below a dirty byte: only bits 160-167 are
/// set above the 160 address bits. A gate widened to any width of
/// 168 bits or more accepts this word and truncates it to the
/// embedded address, so both public predicates would then compare an
/// attacker-chosen address where they must report failure. Pins the
/// second cell of the reject-side partition, alongside
/// `OneAboveMaxAddressBeacon`'s exact-boundary `2 ** 160`.
///
/// Cannot `is IBeacon, IOwnable` — return types deliberately differ
/// from the interfaces. That mismatch is the test condition.
contract DirtyUpperByteBeacon {
    /// @dev The dirty word both selectors answer with: `addr` with all
    /// eight of bits 160-167 set above it.
    uint256 private immutable _dirtyWord;

    constructor(address addr) {
        _dirtyWord = (uint256(0xFF) << 160) | uint256(uint160(addr));
    }

    function implementation() external view returns (uint256) {
        return _dirtyWord;
    }

    function owner() external view returns (uint256) {
        return _dirtyWord;
    }
}
