// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std-1.16.1/src/Script.sol";
import {LibRainDeploy} from "rain-deploy-0.1.2/src/lib/LibRainDeploy.sol";
import {
    EXTROSPECT_CREATION_BYTECODE_V1,
    EXTROSPECT_RUNTIME_CODEHASH_V1,
    EXTROSPECT_ZOLTU_ADDRESS_V1
} from "../src/concrete/Extrospect.sol";

/// @dev Hash of the "extrospect" deployment suite string.
bytes32 constant DEPLOYMENT_SUITE_EXTROSPECT = keccak256("extrospect");

/// @title Deploy
/// @notice Deploys `Extrospect` via the Zoltu deterministic-deployment
/// factory across every Rain-supported network so the same address is
/// reached on every EVM chain that has the factory. Requires
/// `DEPLOYMENT_KEY` env var.
contract Deploy is Script {
    mapping(string network => mapping(address dep => bytes32 codehash)) internal _depCodeHashes;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        bytes32 suite = keccak256(bytes(vm.envOr("DEPLOYMENT_SUITE", string("extrospect"))));
        if (suite == DEPLOYMENT_SUITE_EXTROSPECT) {
            LibRainDeploy.deployAndBroadcast(
                vm,
                LibRainDeploy.supportedNetworks(),
                deployerPrivateKey,
                EXTROSPECT_CREATION_BYTECODE_V1,
                "src/concrete/Extrospect.sol:Extrospect",
                EXTROSPECT_ZOLTU_ADDRESS_V1,
                EXTROSPECT_RUNTIME_CODEHASH_V1,
                new address[](0),
                _depCodeHashes
            );
        } else {
            revert(
                "Invalid deployment suite specified. Please set the DEPLOYMENT_SUITE environment variable to 'extrospect'."
            );
        }
    }
}
