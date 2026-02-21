// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the EXTCODEHASH opcode.
contract HasExtcodehash {
    function codeHash(address account) external view returns (bytes32 hash) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            hash := extcodehash(account)
        }
    }
}
