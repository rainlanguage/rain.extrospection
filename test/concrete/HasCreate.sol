// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses CREATE.
contract HasCreate {
    function deploy(bytes memory code) external returns (address) {
        address deployed;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            deployed := create(0, add(code, 0x20), mload(code))
        }
        return deployed;
    }
}
