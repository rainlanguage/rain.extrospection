// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @dev The 35 bytes of `RegistryBeaconProxy` runtime bytecode before its
/// beacon word, ending in the `PUSH32` that pushes it.
bytes constant REGISTRY_BEACON_PROXY_PREFIX =
    hex"608060405261000c61000e565b005b61001e610019610020565b6100b3565b565b5f7f";
bytes constant REGISTRY_BEACON_PROXY_SUFFIX =
    hex"73ffffffffffffffffffffffffffffffffffffffff16635c60da1b6040518163ffffffff1660e01b8152600401602060405180830381865afa15801561008a573d5f803e3d5ffd5b505050506040513d601f19601f820116820180604052508101906100ae91906100d1565b905090565b365f80375f80365f845af43d5f803e8080156100cd573d5ff35b3d5ffd5b5f602082840312156100e1575f80fd5b815173ffffffffffffffffffffffffffffffffffffffff81168114610104575f80fd5b939250505056";
/// @dev Prefix bytes 0-31.
bytes32 constant REGISTRY_BEACON_PROXY_PREFIX_WORD_0 = 0x608060405261000c61000e565b005b61001e610019610020565b6100b3565b56;
/// @dev Prefix bytes 32-34, left aligned and zero padded.
bytes32 constant REGISTRY_BEACON_PROXY_PREFIX_WORD_1 = 0x5b5f7f0000000000000000000000000000000000000000000000000000000000;
/// @dev Suffix bytes 0-31.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_0 = 0x73ffffffffffffffffffffffffffffffffffffffff16635c60da1b6040518163;
/// @dev Suffix bytes 32-63.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_1 = 0xffffffff1660e01b8152600401602060405180830381865afa15801561008a57;
/// @dev Suffix bytes 64-95.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_2 = 0x3d5f803e3d5ffd5b505050506040513d601f19601f8201168201806040525081;
/// @dev Suffix bytes 96-127.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_3 = 0x01906100ae91906100d1565b905090565b365f80375f80365f845af43d5f803e;
/// @dev Suffix bytes 128-159.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_4 = 0x8080156100cd573d5ff35b3d5ffd5b5f602082840312156100e1575f80fd5b81;
/// @dev Suffix bytes 160-191.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_5 = 0x5173ffffffffffffffffffffffffffffffffffffffff81168114610104575f80;
/// @dev Suffix bytes 192-199, left aligned and zero padded.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_WORD_6 = 0xfd5b939250505056000000000000000000000000000000000000000000000000;
uint256 constant REGISTRY_BEACON_PROXY_PREFIX_LENGTH = 35;
uint256 constant REGISTRY_BEACON_PROXY_SUFFIX_LENGTH = 200;
/// @dev The beacon is an immutable, inlined as the full 32 byte word `PUSH32`
/// pushes.
uint256 constant REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH = 32;
uint256 constant REGISTRY_BEACON_PROXY_LENGTH = REGISTRY_BEACON_PROXY_PREFIX_LENGTH
    + REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH + REGISTRY_BEACON_PROXY_SUFFIX_LENGTH;
/// @dev A literal so that using it allocates no memory.
bytes32 constant REGISTRY_BEACON_PROXY_PREFIX_HASH = 0xa319dcc95a63ad682fd5b379045489cf8f10c90de5829046d659fb7e484b312c;
/// @dev A literal so that using it allocates no memory.
bytes32 constant REGISTRY_BEACON_PROXY_SUFFIX_HASH = 0x5bd46268865ed5cbd699e89c572d3e7022a35e56db67f66d53738f364963732c;
uint256 constant REGISTRY_BEACON_PROXY_PREFIX_START = 0x20;
uint256 constant REGISTRY_BEACON_PROXY_BEACON_WORD_START =
    REGISTRY_BEACON_PROXY_PREFIX_START + REGISTRY_BEACON_PROXY_PREFIX_LENGTH;
uint256 constant REGISTRY_BEACON_PROXY_SUFFIX_START =
    REGISTRY_BEACON_PROXY_BEACON_WORD_START + REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH;

/// @title LibExtrospectRegistryBeaconProxy
/// @notice Detection of rain-factory 0.2.5 `RegistryBeaconProxy` contracts, as
/// `ICloneableFactoryV6.registryBeaconProxy` deploys them, and extraction of
/// their beacon from bytecode.
library LibExtrospectRegistryBeaconProxy {
    /// @notice Checks if the given bytecode is `RegistryBeaconProxy` runtime
    /// bytecode. If so, returns the beacon it holds.
    ///
    /// Every such proxy has the same 267 bytes of runtime bytecode except the
    /// 32 byte word at offset 35 that its `PUSH32` pushes, which is the beacon
    /// immutable. Exactly those bytecodes match whose beacon word is a non-zero
    /// address with its upper 12 bytes zero. A zero word is the template with
    /// no beacon set. Every other bytecode does not match, including ERC1167
    /// proxies and EOF bytecode, none of which revert.
    ///
    /// rain-factory 0.2.5 compiles OpenZeppelin `BeaconProxy`, which
    /// `ICloneableFactoryV5.beaconProxy` deploys, to the same runtime
    /// bytecode, so those proxies match too and yield their beacon. The
    /// bytecode cannot tell the two apart.
    ///
    /// The verdict is a function of the bytes alone. It is the same whether
    /// or not the beacon account exists or has code.
    /// @param bytecode The bytecode to check.
    /// @return True if the bytecode is `RegistryBeaconProxy` runtime bytecode.
    /// @return The beacon the bytecode holds when the first return is true,
    /// else `address(0)`.
    function isRegistryBeaconProxy(bytes memory bytecode) internal pure returns (bool, address) {
        bool result = bytecode.length == REGISTRY_BEACON_PROXY_LENGTH;
        uint256 beaconWord;
        if (result) {
            uint256 prefixStart = REGISTRY_BEACON_PROXY_PREFIX_START;
            uint256 prefixLength = REGISTRY_BEACON_PROXY_PREFIX_LENGTH;
            bytes32 prefixHash = REGISTRY_BEACON_PROXY_PREFIX_HASH;
            uint256 suffixStart = REGISTRY_BEACON_PROXY_SUFFIX_START;
            uint256 suffixLength = REGISTRY_BEACON_PROXY_SUFFIX_LENGTH;
            bytes32 suffixHash = REGISTRY_BEACON_PROXY_SUFFIX_HASH;
            uint256 beaconWordStart = REGISTRY_BEACON_PROXY_BEACON_WORD_START;
            assembly ("memory-safe") {
                beaconWord := mload(add(bytecode, beaconWordStart))
                result := and(
                    eq(keccak256(add(bytecode, prefixStart), prefixLength), prefixHash),
                    eq(keccak256(add(bytecode, suffixStart), suffixLength), suffixHash)
                )
            }
            result = result && beaconWord != 0 && beaconWord <= type(uint160).max;
        }
        if (!result) {
            beaconWord = 0;
        }
        //forge-lint: disable-next-line(unsafe-typecast)
        return (result, address(uint160(beaconWord)));
    }

    /// @notice The runtime code hash of a `RegistryBeaconProxy` holding `beacon`.
    function codehash(address beacon) internal pure returns (bytes32) {
        uint256 beaconWord = uint256(uint160(beacon));
        uint256 beaconWordOffset = REGISTRY_BEACON_PROXY_PREFIX_LENGTH;
        uint256 suffixOffset = REGISTRY_BEACON_PROXY_PREFIX_LENGTH + REGISTRY_BEACON_PROXY_BEACON_WORD_LENGTH;
        uint256 length = REGISTRY_BEACON_PROXY_LENGTH;
        bytes32 result;
        assembly ("memory-safe") {
            let start := mload(0x40)
            mstore(start, REGISTRY_BEACON_PROXY_PREFIX_WORD_0)
            mstore(add(start, 0x20), REGISTRY_BEACON_PROXY_PREFIX_WORD_1)
            mstore(add(start, beaconWordOffset), beaconWord)
            let suffixStart := add(start, suffixOffset)
            mstore(suffixStart, REGISTRY_BEACON_PROXY_SUFFIX_WORD_0)
            mstore(add(suffixStart, 0x20), REGISTRY_BEACON_PROXY_SUFFIX_WORD_1)
            mstore(add(suffixStart, 0x40), REGISTRY_BEACON_PROXY_SUFFIX_WORD_2)
            mstore(add(suffixStart, 0x60), REGISTRY_BEACON_PROXY_SUFFIX_WORD_3)
            mstore(add(suffixStart, 0x80), REGISTRY_BEACON_PROXY_SUFFIX_WORD_4)
            mstore(add(suffixStart, 0xa0), REGISTRY_BEACON_PROXY_SUFFIX_WORD_5)
            mstore(add(suffixStart, 0xc0), REGISTRY_BEACON_PROXY_SUFFIX_WORD_6)
            result := keccak256(start, length)
        }
        return result;
    }
}
