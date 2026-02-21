// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the GAS opcode.
contract HasGas {
    function getGas() external view returns (uint256 g) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            g := gas()
        }
    }
}
