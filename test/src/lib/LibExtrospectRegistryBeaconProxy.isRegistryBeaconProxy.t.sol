// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibICloneableFactoryV5} from "rain-factory-0.2.5/src/lib/LibICloneableFactoryV5.sol";
import {LibICloneableFactoryV6} from "rain-factory-0.2.5/src/lib/LibICloneableFactoryV6.sol";

import {
    LibExtrospectRegistryBeaconProxy,
    REGISTRY_BEACON_PROXY_PREFIX,
    REGISTRY_BEACON_PROXY_SUFFIX,
    REGISTRY_BEACON_PROXY_PREFIX_LENGTH,
    REGISTRY_BEACON_PROXY_SUFFIX_LENGTH,
    REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH,
    REGISTRY_BEACON_PROXY_LENGTH,
    REGISTRY_BEACON_PROXY_PREFIX_HASH,
    REGISTRY_BEACON_PROXY_SUFFIX_HASH
} from "src/lib/LibExtrospectRegistryBeaconProxy.sol";
import {ERC1167_PREFIX, ERC1167_SUFFIX} from "src/lib/LibExtrospectERC1167Proxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {RegistryBeaconSourceFixture} from "test/concrete/RegistryBeaconSourceFixture.sol";

/// @title LibExtrospectRegistryBeaconProxyIsRegistryBeaconProxyTest
/// @notice The oracle is the runtime bytecode of a `RegistryBeaconProxy`
/// deployed from rain-factory 0.2.5's creation code.
contract LibExtrospectRegistryBeaconProxyIsRegistryBeaconProxyTest is Test {
    function deployBeaconAt(address beacon) internal {
        MockBeacon mock = new MockBeacon(address(new NonMetamorphic()), address(0));
        vm.etch(beacon, address(mock).code);
    }

    function deployRegistryBeaconProxy(address beacon) internal returns (address) {
        RegistryBeaconSourceFixture registry = new RegistryBeaconSourceFixture(beacon);
        bytes memory creationCode =
            LibICloneableFactoryV6.registryBeaconProxyCreationCode(address(registry), address(1), bytes32(0));
        address proxy;
        assembly ("memory-safe") {
            proxy := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        assertTrue(proxy != address(0));
        return proxy;
    }

    function realRuntime() internal returns (bytes memory) {
        address beacon = makeAddr("beacon");
        deployBeaconAt(beacon);
        return deployRegistryBeaconProxy(beacon).code;
    }

    function template(bytes32 beaconWord) internal pure returns (bytes memory) {
        return abi.encodePacked(REGISTRY_BEACON_PROXY_PREFIX, beaconWord, REGISTRY_BEACON_PROXY_SUFFIX);
    }

    function assertNotProxy(bytes memory bytecode) internal pure {
        (bool result, address beacon) = LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(bytecode);
        assertFalse(result);
        assertEq(beacon, address(0));
    }

    function testRegistryBeaconProxyConstantsAgree() external pure {
        assertEq(REGISTRY_BEACON_PROXY_PREFIX.length, REGISTRY_BEACON_PROXY_PREFIX_LENGTH);
        assertEq(REGISTRY_BEACON_PROXY_SUFFIX.length, REGISTRY_BEACON_PROXY_SUFFIX_LENGTH);
        assertEq(REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH, 32);
        assertEq(REGISTRY_BEACON_PROXY_LENGTH, 267);
        assertEq(keccak256(REGISTRY_BEACON_PROXY_PREFIX), REGISTRY_BEACON_PROXY_PREFIX_HASH);
        assertEq(keccak256(REGISTRY_BEACON_PROXY_SUFFIX), REGISTRY_BEACON_PROXY_SUFFIX_HASH);
    }

    /// A deployed proxy's runtime is the prefix, its beacon as a word, then the
    /// suffix.
    function testDeployedRegistryBeaconProxyIsTemplateWithBeacon() external {
        address beacon = makeAddr("beacon");
        deployBeaconAt(beacon);
        bytes memory code = deployRegistryBeaconProxy(beacon).code;
        assertEq(code, template(bytes32(uint256(uint160(beacon)))));
    }

    function testDeployedRegistryBeaconProxyYieldsItsBeacon(address beacon) external {
        assumeNotPrecompile(beacon);
        assumeNotForgeAddress(beacon);
        vm.assume(beacon != address(0));
        vm.assume(beacon.code.length == 0);
        deployBeaconAt(beacon);
        (bool result, address extracted) =
            LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(deployRegistryBeaconProxy(beacon).code);
        assertTrue(result);
        assertEq(extracted, beacon);
    }

    function testTemplateWithAnyNonZeroBeaconYieldsIt(address beacon) external pure {
        vm.assume(beacon != address(0));
        (bool result, address extracted) =
            LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(template(bytes32(uint256(uint160(beacon)))));
        assertTrue(result);
        assertEq(extracted, beacon);
    }

    function testTemplateWithZeroBeaconIsNotProxy() external pure {
        assertNotProxy(template(bytes32(0)));
    }

    function testBeaconWordWithDirtyUpperBytesIsNotProxy(uint256 word) external pure {
        vm.assume(word >> 160 != 0);
        assertNotProxy(template(bytes32(word)));
    }

    function testEveryByteOutsideBeaconWordIsChecked() external {
        bytes memory code = realRuntime();
        for (uint256 i = 0; i < code.length; i++) {
            if (i >= REGISTRY_BEACON_PROXY_PREFIX_LENGTH && i < REGISTRY_BEACON_PROXY_PREFIX_LENGTH + 32) {
                continue;
            }
            code[i] = code[i] ^ 0x01;
            assertNotProxy(code);
            code[i] = code[i] ^ 0x01;
        }
        (bool result,) = LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(code);
        assertTrue(result);
    }

    function testAnyByteChangedOutsideBeaconWordIsNotProxy(uint256 index, uint8 delta) external {
        vm.assume(delta != 0);
        bytes memory code = realRuntime();
        index = bound(index, 0, code.length - 1 - REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH);
        if (index >= REGISTRY_BEACON_PROXY_PREFIX_LENGTH) {
            index += REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH;
        }
        code[index] = code[index] ^ bytes1(delta);
        assertNotProxy(code);
    }

    function testTruncatedRegistryBeaconProxyIsNotProxy(uint256 length) external {
        bytes memory code = realRuntime();
        length = bound(length, 0, code.length - 1);
        assembly ("memory-safe") {
            mstore(code, length)
        }
        assertNotProxy(code);
    }

    function testExtendedRegistryBeaconProxyIsNotProxy(bytes memory extra) external {
        vm.assume(extra.length > 0);
        assertNotProxy(bytes.concat(realRuntime(), extra));
    }

    function testAnyOtherLengthIsNotProxy(bytes memory bytecode) external pure {
        vm.assume(bytecode.length != REGISTRY_BEACON_PROXY_LENGTH);
        assertNotProxy(bytecode);
    }

    function testCodelessAccountIsNotProxy() external {
        assertNotProxy(makeAddr("codeless").code);
    }

    function testERC1167ProxyIsNotProxy(address implementation) external pure {
        assertNotProxy(abi.encodePacked(ERC1167_PREFIX, implementation, ERC1167_SUFFIX));
    }

    /// rain-factory 0.2.5 compiles OpenZeppelin `BeaconProxy` to the same runtime
    /// bytecode as `RegistryBeaconProxy`.
    function testRainFactoryOpenZeppelinBeaconProxyYieldsItsBeacon() external {
        address beacon = makeAddr("beacon");
        deployBeaconAt(beacon);
        bytes memory creationCode = LibICloneableFactoryV5.beaconProxyCreationCode(beacon);
        address proxy;
        assembly ("memory-safe") {
            proxy := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        (bool result, address extracted) = LibExtrospectRegistryBeaconProxy.isRegistryBeaconProxy(proxy.code);
        assertTrue(result);
        assertEq(extracted, beacon);
    }

    function testEOFBytecodeOfProxyLengthIsNotProxy(bytes memory body) external pure {
        bytes memory bytecode = new bytes(REGISTRY_BEACON_PROXY_LENGTH);
        for (uint256 i = 2; i < bytecode.length && i - 2 < body.length; i++) {
            bytecode[i] = body[i - 2];
        }
        bytecode[0] = 0xEF;
        bytecode[1] = 0x00;
        assertNotProxy(bytecode);
    }
}
