// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {LibDataContract, PREFIX_BYTES_LENGTH} from "rain-datacontract-0.2.1/src/lib/LibDataContract.sol";

/// @title LibExtrospectEmbeddedAddress
/// @notice Addresses embedded in bytecode, and whether that bytecode is a data
/// contract whose bytes are rows rather than code.
library LibExtrospectEmbeddedAddress {
    /// @param creationCode The creation code.
    /// @return Whether it is `LibDataContract.contractCreationCode` of the bytes
    /// after its prefix.
    function isDataContract(bytes memory creationCode) internal pure returns (bool) {
        if (
            creationCode.length < PREFIX_BYTES_LENGTH
                || creationCode.length - PREFIX_BYTES_LENGTH >= uint256(type(uint16).max)
        ) {
            return false;
        }
        uint256 prefixBytesLength = PREFIX_BYTES_LENGTH;
        uint256 length = creationCode.length - prefixBytesLength;
        bytes memory data;
        assembly ("memory-safe") {
            data := mload(0x40)
            mstore(data, length)
            mcopy(add(data, 0x20), add(add(creationCode, 0x20), prefixBytesLength), length)
            mstore(0x40, add(add(data, 0x20), length))
        }
        return keccak256(LibDataContract.contractCreationCode(data)) == keccak256(creationCode);
    }

    /// Searches for the address with its leading zero bytes stripped, as solc
    /// pushes a constant address.
    /// @param haystack The bytes to search.
    /// @param needle The address.
    /// @return Whether `haystack` contains it. Never for the zero address.
    function containsAddress(bytes memory haystack, address needle) internal pure returns (bool) {
        uint256 value = uint256(uint160(needle));
        uint256 width = 0;
        for (uint256 remaining = value; remaining != 0; remaining >>= 8) {
            width++;
        }
        if (width == 0 || haystack.length < width) {
            return false;
        }
        uint256 shift = 256 - width * 8;
        bytes32 target = bytes32(value << shift);
        bytes32 mask = bytes32(~uint256(0) << shift);
        uint256 last = haystack.length - width;
        for (uint256 i = 0; i <= last; i++) {
            bytes32 window;
            assembly ("memory-safe") {
                window := mload(add(add(haystack, 0x20), i))
            }
            if (window & mask == target) {
                return true;
            }
        }
        return false;
    }
}
