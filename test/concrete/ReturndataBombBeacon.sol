// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Gas budget a `ReturndataBombBeacon` is called under. Large
/// enough that the twelfth the bomb leaves unspent, plus the sixty
/// fourth the EVM withholds from the inner call, is far less than the
/// memory expansion the returned blob would cost to copy.
uint256 constant RETURNDATA_BOMB_GAS_BUDGET = 3_000_000;

/// @dev Hostile beacon test fixture. Answers every selector, including
/// `implementation()` and `owner()`, by expanding memory until only a
/// twelfth of the gas it was forwarded remains, then returning that
/// whole region as return data. Reading `gas()` sizes the blob to
/// whatever budget the caller forwards, so it is always large relative
/// to the gas the caller has left when the call returns.
///
/// Cannot `is IBeacon, IOwnable` — the fallback answers with a blob
/// rather than an `address`. That mismatch is the test condition.
contract ReturndataBombBeacon {
    fallback() external {
        //forge-lint: disable-next-line(assembly-usage)
        assembly {
            let floor_ := div(gas(), 12)
            let end := 0x20
            for {} gt(gas(), floor_) { end := add(end, 0x400) } { mstore(end, 0) }
            return(0, end)
        }
    }
}
