// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the EXTCODESIZE opcode.
contract HasExtcodesize {
    function codeSize(address account) external view returns (uint256 size) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            size := extcodesize(account)
        }
    }
}
