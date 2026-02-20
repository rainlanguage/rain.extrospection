// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract with a delegatecall.
contract HasDelegatecall {
    //slither-disable-next-line controlled-delegatecall
    function forward(address target, bytes calldata data) external {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            calldatacopy(0, data.offset, data.length)
            let success := delegatecall(gas(), target, 0, data.length, 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}
