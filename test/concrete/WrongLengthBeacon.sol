// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// selectors exist and return successfully, but with the wrong
/// number of bytes. Returning `string memory ""` encodes as
/// 64 bytes (offset 0x20 + length 0). Distinguishes the
/// wrong-return-length branch from the dirty-address-bits branch
/// covered by `BogusBeacon`.
contract WrongLengthBeacon {
    function implementation() external pure returns (string memory) {
        return "";
    }

    function owner() external pure returns (string memory) {
        return "";
    }
}
