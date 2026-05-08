// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {Extrospect} from "../src/concrete/Extrospect.sol";

/// @title Deploy
/// @notice Deploys `Extrospect` via the Zoltu deterministic-deployment
/// factory across every Rain-supported network so the same address is
/// reached on every EVM chain that has the factory. Requires
/// `DEPLOYMENT_KEY` env var.
contract Deploy is Script {
    /// @dev Records each network's dependency codehashes between the
    /// `checkDependencies` and `deployToNetworks` phases inside
    /// `LibRainDeploy.deployAndBroadcast`. Extrospect has no
    /// dependencies — the mapping stays empty in practice.
    mapping(string network => mapping(address dep => bytes32 codehash)) internal _depCodeHashes;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
        bytes memory creationCode = type(Extrospect).creationCode;

        address expectedAddress = vm.envAddress("EXPECTED_EXTROSPECT_ADDRESS");
        bytes32 expectedCodeHash = vm.envBytes32("EXPECTED_EXTROSPECT_CODEHASH");

        LibRainDeploy.deployAndBroadcast(
            vm,
            LibRainDeploy.supportedNetworks(),
            deployerPrivateKey,
            creationCode,
            "src/concrete/Extrospect.sol:Extrospect",
            expectedAddress,
            expectedCodeHash,
            new address[](0),
            _depCodeHashes
        );
    }
}
