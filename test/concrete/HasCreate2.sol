// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses CREATE2.
contract HasCreate2 {
    function deploy(bytes memory code, bytes32 salt) external returns (address) {
        address deployed;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            deployed := create2(0, add(code, 0x20), mload(code), salt)
        }
        return deployed;
    }
}
