// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the SELFBALANCE opcode.
contract HasSelfbalance {
    function getBalance() external view returns (uint256 bal) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            bal := selfbalance()
        }
    }
}
