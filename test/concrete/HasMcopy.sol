// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the MCOPY opcode (Cancun).
contract HasMcopy {
    function doCopy(bytes memory data) external pure returns (bytes memory result) {
        result = new bytes(data.length);
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            mcopy(add(result, 0x20), add(data, 0x20), mload(data))
        }
    }
}
