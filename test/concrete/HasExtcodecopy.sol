// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the EXTCODECOPY opcode.
contract HasExtcodecopy {
    function getCode(address account) external view returns (bytes memory code) {
        uint256 size;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            size := extcodesize(account)
        }
        code = new bytes(size);
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            extcodecopy(account, add(code, 0x20), 0, size)
        }
    }
}
