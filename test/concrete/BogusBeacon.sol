// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// selectors exist and return successfully, but with bytes that
/// can't decode as `address` — the upper 12 bytes are non-zero, so
/// the ABI decoder rejects them. Distinguishes a third failure mode
/// from "selector missing" and "selector reverts": the call succeeds
/// but the return data is structurally invalid for the typed
/// interface.
contract BogusBeacon {
    function implementation() external pure returns (uint256) {
        return type(uint256).max;
    }

    function owner() external pure returns (uint256) {
        return type(uint256).max;
    }
}
