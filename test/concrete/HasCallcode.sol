// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract with callcode (requires assembly as callcode has no
/// Solidity-level equivalent).
contract HasCallcode {
    function forward(address target) external {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            let success := callcode(gas(), target, 0, 0, 0, 0, 0)
            if iszero(success) { revert(0, 0) }
        }
    }
}
