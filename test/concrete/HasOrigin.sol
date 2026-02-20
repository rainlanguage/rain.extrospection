// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the ORIGIN opcode.
contract HasOrigin {
    function getOrigin() external view returns (address) {
        return tx.origin;
    }
}
