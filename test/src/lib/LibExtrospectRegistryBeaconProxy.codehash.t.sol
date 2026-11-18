// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibExtrospectRegistryBeaconProxy} from "src/lib/LibExtrospectRegistryBeaconProxy.sol";
import {LibExtrospectTestRegistryBeaconProxy} from "test/lib/LibExtrospectTestRegistryBeaconProxy.sol";

contract LibExtrospectRegistryBeaconProxyCodehashTest is Test {
    function deployProxy(address beacon) internal returns (address) {
        assumeNotPrecompile(beacon);
        assumeNotForgeAddress(beacon);
        vm.assume(beacon != address(0));
        vm.assume(beacon.code.length == 0);
        LibExtrospectTestRegistryBeaconProxy.etchBeacon(vm, beacon);
        return LibExtrospectTestRegistryBeaconProxy.deployProxy(beacon);
    }

    /// `codehash(beacon)` is the codehash of a deployed `RegistryBeaconProxy` holding `beacon`.
    function testCodehashIsDeployedProxyCodehash(address beacon) external {
        address proxy = deployProxy(beacon);
        assertEq(LibExtrospectRegistryBeaconProxy.codehash(beacon), proxy.codehash);
    }

    /// Code hashing to `codehash(beacon)` is a `RegistryBeaconProxy` holding `beacon`.
    function testCodeWithCodehashIsProxyHoldingBeacon(address beacon) external {
        bytes memory code = deployProxy(beacon).code;
        assertEq(keccak256(code), LibExtrospectRegistryBeaconProxy.codehash(beacon));
        (bool result, address extracted) = LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(code);
        assertTrue(result);
        assertEq(extracted, beacon);
    }
}
