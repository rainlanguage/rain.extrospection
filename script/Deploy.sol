// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {Extrospect} from "../src/concrete/Extrospect.sol";

/// @dev The Zoltu deterministic-deployment factory address. Same on every
/// EVM chain. See https://github.com/Zoltu/deterministic-deployment-proxy.
address constant ZOLTU_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;

/// @title Deploy
/// @notice Deploys `Extrospect` via the Zoltu deterministic-deployment
/// factory so the same address is reached on every EVM chain that has
/// the Zoltu factory deployed. Requires `DEPLOYMENT_KEY` env var.
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Zoltu factory deploys creation bytecode prefixed with a 32-byte
        // salt. We pass salt=0 — Extrospect has no constructor args, so
        // the resulting address is determined entirely by the creation
        // bytecode and is identical across chains.
        bytes memory creation = type(Extrospect).creationCode;
        address deployed;
        bool success;
        assembly ("memory-safe") {
            mstore(0, 0)
            success := call(gas(), ZOLTU_FACTORY, 0, add(creation, 0x20), mload(creation), 12, 20)
            deployed := mload(0)
        }
        if (!success) {
            revert("Extrospect Zoltu deploy failed");
        }

        // Sanity check: the returned address must have the Extrospect
        // runtime code.
        if (deployed.code.length == 0) {
            revert("Extrospect Zoltu deploy produced empty address");
        }

        vm.stopBroadcast();
    }
}
