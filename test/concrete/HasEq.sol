// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the EQ opcode.
contract HasEq {
    function eq(uint256 a, uint256 b) external pure returns (bool result) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            result := eq(a, b)
        }
    }
}
