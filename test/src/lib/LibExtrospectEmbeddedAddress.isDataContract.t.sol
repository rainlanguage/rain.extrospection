// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibDataContract, PREFIX_BYTES_LENGTH} from "rain-datacontract-0.2.1/src/lib/LibDataContract.sol";

import {LibExtrospectEmbeddedAddress} from "src/lib/LibExtrospectEmbeddedAddress.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

/// @title LibExtrospectEmbeddedAddressIsDataContractTest
/// @notice The oracle is `LibDataContract.contractCreationCode`: creation code
/// is a data contract exactly when it is that function's output for the bytes
/// after the prefix.
contract LibExtrospectEmbeddedAddressIsDataContractTest is Test {
    /// Bytes 1 and 2 of the prefix are the PUSH2 operand: payload length + 1.
    function withLengthField(bytes memory creationCode, uint16 length) internal pure returns (bytes memory) {
        bytes2 field = bytes2(length);
        creationCode[1] = field[0];
        creationCode[2] = field[1];
        return creationCode;
    }

    function payloadOfLength(uint256 length) internal pure returns (bytes memory payload) {
        payload = new bytes(length);
        assembly ("memory-safe") {
            for { let i := 0 } lt(i, length) { i := add(i, 0x20) } {
                mstore(add(add(payload, 0x20), i), xor(i, 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef))
            }
        }
    }

    function testDataContractOfAnyPayloadIsDataContract(bytes memory data) external pure {
        assertTrue(LibExtrospectEmbeddedAddress.isDataContract(LibDataContract.contractCreationCode(data)));
    }

    function testEmptyDataContractIsDataContract() external pure {
        bytes memory creationCode = LibDataContract.contractCreationCode("");
        assertEq(creationCode.length, PREFIX_BYTES_LENGTH);
        assertTrue(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
    }

    function testLargestDataContractIsDataContract() external pure {
        bytes memory creationCode =
            LibDataContract.contractCreationCode(payloadOfLength(uint256(type(uint16).max) - 1));
        assertEq(uint8(creationCode[1]), 0xff);
        assertEq(uint8(creationCode[2]), 0xff);
        assertTrue(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
    }

    function testDataContractWithAPrefixByteChangedIsNot(bytes memory data, uint8 flip) external pure {
        vm.assume(flip != 0);
        for (uint256 i = 0; i < PREFIX_BYTES_LENGTH; i++) {
            bytes memory creationCode = LibDataContract.contractCreationCode(data);
            creationCode[i] ^= bytes1(flip);
            assertFalse(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
        }
    }

    function testDataContractWithAnotherLengthFieldIsNot(bytes memory data, uint16 length) external pure {
        vm.assume(uint256(length) != data.length + 1);
        bytes memory creationCode = withLengthField(LibDataContract.contractCreationCode(data), length);
        assertFalse(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
    }

    function testDataContractWithTrailingBytesIsNot(bytes memory data, bytes memory trailing) external pure {
        vm.assume(trailing.length != 0);
        bytes memory creationCode = bytes.concat(LibDataContract.contractCreationCode(data), trailing);
        assertFalse(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
    }

    /// The cut bytes stay in memory past the end.
    function testTruncatedDataContractIsNot(bytes memory data, uint256 cut) external pure {
        vm.assume(data.length != 0);
        cut = bound(cut, 1, data.length);
        bytes memory creationCode = LibDataContract.contractCreationCode(data);
        uint256 length = creationCode.length - cut;
        assembly ("memory-safe") {
            mstore(creationCode, length)
        }
        assertFalse(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
    }

    /// `LibDataContract.contractCreationCode` reverts on these payloads, so
    /// no length field can make them a data contract.
    function testPayloadTooLargeIsNot() external pure {
        uint256[2] memory lengths = [uint256(type(uint16).max), uint256(type(uint16).max) + 1];
        uint16[3] memory fields = [type(uint16).max, 0, 1];
        for (uint256 i = 0; i < lengths.length; i++) {
            bytes memory payload = payloadOfLength(lengths[i]);
            for (uint256 j = 0; j < fields.length; j++) {
                bytes memory prefix = withLengthField(LibDataContract.contractCreationCode(""), fields[j]);
                assertFalse(LibExtrospectEmbeddedAddress.isDataContract(bytes.concat(prefix, payload)));
            }
        }
    }

    function testEveryTruncatedPrefixIsNot() external pure {
        for (uint256 length = 0; length < PREFIX_BYTES_LENGTH; length++) {
            bytes memory creationCode = LibDataContract.contractCreationCode("");
            assembly ("memory-safe") {
                mstore(creationCode, length)
            }
            assertFalse(LibExtrospectEmbeddedAddress.isDataContract(creationCode));
        }
    }

    function testCodeShorterThanThePrefixIsNot(bytes memory code) external pure {
        uint256 length = code.length % PREFIX_BYTES_LENGTH;
        assembly ("memory-safe") {
            mstore(code, length)
        }
        assertFalse(LibExtrospectEmbeddedAddress.isDataContract(code));
    }

    function testCompiledContractIsNot() external pure {
        assertFalse(LibExtrospectEmbeddedAddress.isDataContract(type(EmptyContract).creationCode));
    }
}
