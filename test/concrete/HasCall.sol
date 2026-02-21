// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses CALL.
contract HasCall {
    function forward(address target, bytes calldata data) external {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            calldatacopy(0, data.offset, data.length)
            let success := call(gas(), target, 0, 0, data.length, 0, 0)
            if iszero(success) { revert(0, 0) }
        }
    }
}
