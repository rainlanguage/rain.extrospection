// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the SDIV opcode.
contract HasSdiv {
    function sdiv(int256 a, int256 b) external pure returns (int256 result) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            result := sdiv(a, b)
        }
    }
}
