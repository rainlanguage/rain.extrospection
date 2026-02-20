// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the STOP opcode (non-returning function).
contract HasStop {
    uint256 internal sValue;

    function doStop(uint256 v) external {
        sValue = v;
    }
}
