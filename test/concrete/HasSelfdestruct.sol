// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract with a selfdestruct.
contract HasSelfdestruct {
    function destroy(address payable recipient) external {
        selfdestruct(recipient);
    }
}
