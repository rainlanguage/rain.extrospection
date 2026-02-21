// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses TSTORE and TLOAD (transient storage, Cancun).
contract HasTstore {
    function store(uint256 slot, uint256 value) external {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            tstore(slot, value)
        }
    }

    function load(uint256 slot) external view returns (uint256 value) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            value := tload(slot)
        }
    }
}
