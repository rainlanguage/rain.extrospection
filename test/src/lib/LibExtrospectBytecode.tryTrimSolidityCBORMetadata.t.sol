// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract LibExtrospectBytecodeTryTrimSolidityCBORMetadataTest is Test {
    /// External version of tryTrimSolidityCBORMetadata for testing.
    function tryTrimSolidityCBORMetadataExternal(bytes memory bytecode) external pure returns (bool) {
        return LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode);
    }

    function testTryTrimSolidityCBORMetadataBytecodeShort(bytes memory bytecode) external pure {
        vm.assume(bytecode.length < 53);
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(bytecode));
        assertEq(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode), false);
    }

    function testTryTrimSolidityCBORMetdataBytecodeReal() external pure {
        // Blank contract + cbor.
        bytes memory bytecode =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        bytes memory expected = hex"6080604052600080fdfe";

        uint256 length = bytecode.length;
        assertTrue(length >= 53);
        assertEq(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode), true);
        assertEq(bytecode, expected);
    }

    function testTryTrimSolidityCBORMetadataBytecodeContrived(bytes memory bytecode) external pure {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(bytecode));
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
        vm.assume(!LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
        assertEq(keccak256(bytecode), before);

        // Now add the metadata.
        bytes memory withMetadata =
            bytes.concat(bytecode, hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");

        before = keccak256(withMetadata);
        uint256 beforeLength = withMetadata.length;
        assertNotEq(bytecode, withMetadata);
        assertEq(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(withMetadata), true);
        assertEq(withMetadata.length, beforeLength - 53);
        assertTrue(keccak256(withMetadata) != before);

        assertEq(bytecode, withMetadata);
    }

    /// Test exactly 53-byte bytecode that IS valid CBOR metadata (no code
    /// prefix). The entire bytecode is the metadata.
    function testTryTrimSolidityCBORMetadataExactly53BytesValid() external pure {
        // Construct a valid 53-byte CBOR metadata from the real test above.
        bytes memory metadata =
            hex"a26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        assertEq(metadata.length, 53);
        assertTrue(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(metadata));
        assertEq(metadata.length, 0);
    }

    /// Test exactly 53-byte bytecode that is NOT valid CBOR metadata.
    function testTryTrimSolidityCBORMetadataExactly53BytesInvalid() external pure {
        bytes memory notMetadata =
            hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        assertEq(notMetadata.length, 53);
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(notMetadata));
        assertEq(notMetadata.length, 53);
    }

    /// Test that calling tryTrimSolidityCBORMetadata twice on already-trimmed
    /// bytecode returns false on the second call.
    function testTryTrimSolidityCBORMetadataIdempotency() external pure {
        bytes memory bytecode =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        assertTrue(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
        // Second call should return false — metadata already trimmed.
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
    }

    /// False negative: bzzr1 (Swarm) metadata is not trimmed.
    /// This demonstrates the documented false-negative behavior for
    /// non-standard CBOR metadata structures.
    function testTryTrimSolidityCBORMetadataFalseNegativeBzzr1() external pure {
        // Construct bytecode with bzzr1 Swarm metadata (52 bytes, not 53).
        // a2 = map(2), 65 = text(5), "bzzr1", 5820 = bytes(32), [32-byte hash],
        // 64 = text(4), "solc", 43 = bytes(3), [version], 0032 = length(50)
        bytes memory bytecode = bytes.concat(
            hex"6001600055",
            hex"a265627a7a72315820",
            bytes32(0),
            hex"64736f6c634300081900",
            hex"32"
        );
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
    }

    /// False negative: reversed key ordering (solc before ipfs) is not trimmed.
    function testTryTrimSolidityCBORMetadataFalseNegativeReversedKeys() external pure {
        // Same 53-byte length but keys in reverse order (solc first, ipfs second).
        bytes memory bytecode = bytes.concat(
            hex"6001600055",
            hex"a264736f6c63430008196469706673582200000000000000000000000000000000000000000000000000000000000000000000",
            hex"0033"
        );
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
    }

    /// False negative: single-entry metadata (ipfs only, no solc) is not trimmed.
    function testTryTrimSolidityCBORMetadataFalseNegativeSingleEntry() external pure {
        // a1 = map(1), 64 = text(4), "ipfs", 5822 = bytes(34), [34-byte hash],
        // 002a = length(42)
        bytes memory bytecode = bytes.concat(
            hex"6001600055",
            hex"a16469706673582200000000000000000000000000000000000000000000000000000000000000000000",
            hex"002a"
        );
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode));
    }

    /// Test exactly 52-byte bytecode (off-by-one below the 53-byte minimum).
    function testTryTrimSolidityCBORMetadataExactly52Bytes() external pure {
        bytes memory code = new bytes(52);
        assertFalse(LibExtrospectBytecode.tryTrimSolidityCBORMetadata(code));
        assertEq(code.length, 52);
    }

    /// EOF bytecode is not supported.
    function testTryTrimSolidityCBORMetadataRevertsOnEOF() external {
        bytes memory eofBytecode = hex"EF00010203";
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.tryTrimSolidityCBORMetadataExternal(eofBytecode);
    }
}
