// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {EXTROSPECT_ZOLTU_ADDRESS_V1} from "../src/concrete/Extrospect.sol";

/// @title PrintExtrospectAddress
/// @notice Emits the pinned `EXTROSPECT_ZOLTU_ADDRESS_V1` so CI can capture
/// the address without hardcoding it in workflow YAML.
contract PrintExtrospectAddress is Script {
    function run() external pure {
        console2.log(EXTROSPECT_ZOLTU_ADDRESS_V1);
    }
}
