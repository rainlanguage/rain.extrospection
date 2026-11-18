// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std-1.17.0/src/Vm.sol";

import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {RegistryBeaconSourceFixture} from "test/concrete/RegistryBeaconSourceFixture.sol";
import {REGISTRY_BEACON_PROXY_CREATION_CODE} from "test/lib/LibExtrospectRegistryBeaconProxy.testConstants.sol";

error RegistryBeaconProxyDeployFailed();

library LibExtrospectTestRegistryBeaconProxy {
    function etchBeacon(Vm vm, address beacon) internal {
        MockBeacon mock = new MockBeacon(address(new NonMetamorphic()), address(0));
        vm.etch(beacon, address(mock).code);
    }

    function deployProxy(address beacon) internal returns (address) {
        RegistryBeaconSourceFixture registry = new RegistryBeaconSourceFixture(beacon);
        bytes memory creationCode =
            bytes.concat(REGISTRY_BEACON_PROXY_CREATION_CODE, abi.encode(address(registry), address(1), bytes32(0)));
        address proxy;
        assembly ("memory-safe") {
            proxy := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        if (proxy == address(0)) {
            revert RegistryBeaconProxyDeployFailed();
        }
        return proxy;
    }
}
