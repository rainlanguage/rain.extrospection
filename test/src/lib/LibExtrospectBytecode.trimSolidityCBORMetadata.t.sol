// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract LibExtrospectBytecodeTrimSolidityCBORMetadataTest is Test {
    function testTrimSolidityCBORMetadataBytecodeShort(bytes memory bytecode) external pure {
        vm.assume(bytecode.length < 53);
        assertEq(LibExtrospectBytecode.trimSolidityCBORMetadata(bytecode), false);
    }

    function testTrimSolidityCBORMetdataBytecodeReal() external pure {
        // Blank contract + cbor.
        bytes memory bytecode =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        bytes memory expected = hex"6080604052600080fdfe";

        uint256 length = bytecode.length;
        assertTrue(length >= 53);
        assertEq(LibExtrospectBytecode.trimSolidityCBORMetadata(bytecode), true);
        assertEq(bytecode, expected);
    }

    function testTrimSolidityCBORMetadataBytecodeContrived(bytes memory bytecode) external pure {
        bytes32 a = keccak256(bytecode);
        bytes memory ipfsHash;
        bytes memory solcVersion;
        assembly ("memory-safe") {
            mstore(0, a)
            mstore(0x20, keccak256(0, 0x20))
            ipfsHash := mload(0x40)
            mstore(ipfsHash, 34)
            mstore(add(ipfsHash, 0x20), mload(0))
            mstore(add(ipfsHash, 0x40), mload(0x20))
            solcVersion := add(ipfsHash, 0x60)
            mstore(solcVersion, 3)
            mstore(0, keccak256(0, 0x40))
            mstore(add(solcVersion, 0x20), mload(0))
            mstore(0x40, add(solcVersion, 0x40))
        }

        bytes32 before = keccak256(bytecode);
        assertEq(LibExtrospectBytecode.trimSolidityCBORMetadata(bytecode), false);
        assertEq(keccak256(bytecode), before);

        // Now add the metadata.
        bytes memory withMetadata =
            bytes.concat(bytecode, hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");

        before = keccak256(withMetadata);
        uint256 beforeLength = withMetadata.length;
        assertNotEq(bytecode, withMetadata);
        assertEq(LibExtrospectBytecode.trimSolidityCBORMetadata(withMetadata), true);
        assertEq(withMetadata.length, beforeLength - 53);
        assertTrue(keccak256(withMetadata) != before);

        assertEq(bytecode, withMetadata);
    }
}
