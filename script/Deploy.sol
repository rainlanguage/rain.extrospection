// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {Extrospection} from "src/concrete/Extrospection.sol";

/// @title Deploy
/// @notice A script that deploys Extrospection.
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);
        Extrospection extrospection = new Extrospection();
        (extrospection);
        vm.stopBroadcast();
    }
}
