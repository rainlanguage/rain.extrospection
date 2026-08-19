// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// selectors exist and return successfully, but with exactly
/// `2 ** 160` — the first value the dirty-bits gate
/// (`raw > type(uint160).max`) must reject. Only bit 160 is set, so
/// any widening of the gate past 160 bits accepts this word and
/// truncates it to `address(0)`. Pins the reject side of the boundary
/// whose accept side `testMatchesAtMaxAddressBoundary` pins with
/// `2 ** 160 - 1`.
///
/// Cannot `is IBeacon, IOwnable` — return types deliberately differ
/// from the interfaces. That mismatch is the test condition.
contract OneAboveMaxAddressBeacon {
    function implementation() external pure returns (uint256) {
        return uint256(type(uint160).max) + 1;
    }

    function owner() external pure returns (uint256) {
        return uint256(type(uint160).max) + 1;
    }
}
