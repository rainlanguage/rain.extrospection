// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev An address with no leading zero bytes, so solc pushes it with PUSH20.
address constant CONSTANT_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

/// @dev An address with 7 leading zero bytes, so solc pushes it with PUSH13.
address constant NARROW_CONSTANT_ADDRESS = 0x0000000000000068F116a894984e2DB1123eB395;

/// @dev Contract whose code embeds two constant addresses.
contract HasConstantAddress {
    function balances() external view returns (uint256, uint256) {
        return (CONSTANT_ADDRESS.balance, NARROW_CONSTANT_ADDRESS.balance);
    }
}
