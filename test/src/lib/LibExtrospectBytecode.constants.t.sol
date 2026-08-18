// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    SOLIDITY_CBOR_METADATA_LENGTH,
    SOLIDITY_CBOR_METADATA_HEAD_MASK,
    SOLIDITY_CBOR_METADATA_TAIL_MASK,
    SOLIDITY_CBOR_METADATA_MASKED_HASH
} from "src/lib/LibExtrospectBytecode.sol";
import {SOLIDITY_CBOR_RUNTIME_FIXTURE} from "test/concrete/SolidityCBORFixture.sol";

/// @dev The two 32-byte words that the head and tail masks leave behind for
/// bytecode ending in standard Solidity CBOR metadata. The head word is 11
/// zeroed bytes preceding the metadata, then metadata bytes 0-7
/// `a2 64 69706673 5822`, then 13 zeroed bytes of IPFS hash.
bytes32 constant EXPECTED_MASKED_HEAD_WORD = 0x0000000000000000000000a26469706673582200000000000000000000000000;

/// @dev The tail word is the remaining 21 zeroed bytes of IPFS hash, then
/// metadata bytes 42-47 `64 736f6c63 43`, then 3 zeroed bytes of solc version,
/// then metadata bytes 51-52 `0033`.
bytes32 constant EXPECTED_MASKED_TAIL_WORD = 0x00000000000000000000000000000000000000000064736f6c63430000000033;

/// @dev Number of bytes that precede the metadata inside the first
/// of the two overlapping 32-byte reads.
uint256 constant HEAD_WORD_PREFIX_LENGTH = 11;

contract LibExtrospectBytecodeConstantsTest is Test {
    /// Builds the 64 bytes that the two overlapping reads cover: an arbitrary
    /// 11-byte prefix followed by 53 bytes of metadata, then returns
    /// the two words with the pinned masks applied.
    function maskWindow(bytes memory prefix, bytes memory metadata)
        internal
        pure
        returns (bytes32 maskedHead, bytes32 maskedTail)
    {
        assertEq(prefix.length, HEAD_WORD_PREFIX_LENGTH);
        assertEq(metadata.length, SOLIDITY_CBOR_METADATA_LENGTH);
        bytes memory window = bytes.concat(prefix, metadata);
        assertEq(window.length, 0x40);
        uint256 headWord;
        uint256 tailWord;
        assembly ("memory-safe") {
            headWord := mload(add(window, 0x20))
            tailWord := mload(add(window, 0x40))
        }
        maskedHead = bytes32(headWord & SOLIDITY_CBOR_METADATA_HEAD_MASK);
        maskedTail = bytes32(tailWord & SOLIDITY_CBOR_METADATA_TAIL_MASK);
    }

    /// Returns the final `SOLIDITY_CBOR_METADATA_LENGTH` bytes of `bytecode`.
    function metadataOf(bytes memory bytecode) internal pure returns (bytes memory metadata) {
        metadata = new bytes(SOLIDITY_CBOR_METADATA_LENGTH);
        uint256 offset = bytecode.length - SOLIDITY_CBOR_METADATA_LENGTH;
        for (uint256 i = 0; i < SOLIDITY_CBOR_METADATA_LENGTH; i++) {
            metadata[i] = bytecode[offset + i];
        }
    }

    /// The masks zero every byte outside the fixed CBOR structure, including
    /// the 11 bytes that precede the metadata, the 34-byte IPFS hash and the
    /// 3-byte solc version, when all of those bytes are set.
    function testSolidityCBORMetadataMasksZeroVariableBytes() external pure {
        bytes memory ipfsHash = new bytes(34);
        bytes memory solcVersion = new bytes(3);
        bytes memory prefix = new bytes(HEAD_WORD_PREFIX_LENGTH);
        for (uint256 i = 0; i < ipfsHash.length; i++) {
            ipfsHash[i] = 0xFF;
        }
        for (uint256 i = 0; i < solcVersion.length; i++) {
            solcVersion[i] = 0xFF;
        }
        for (uint256 i = 0; i < prefix.length; i++) {
            prefix[i] = 0xFF;
        }
        bytes memory metadata = bytes.concat(hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");

        (bytes32 maskedHead, bytes32 maskedTail) = maskWindow(prefix, metadata);

        assertEq(maskedHead, EXPECTED_MASKED_HEAD_WORD);
        assertEq(maskedTail, EXPECTED_MASKED_TAIL_WORD);
    }

    /// The same two masked words come out of real metadata, i.e. an IPFS hash
    /// and solc version that are not all set.
    function testSolidityCBORMetadataMasksZeroRealVariableBytes() external pure {
        bytes memory metadata = metadataOf(SOLIDITY_CBOR_RUNTIME_FIXTURE);
        bytes memory prefix = new bytes(HEAD_WORD_PREFIX_LENGTH);

        (bytes32 maskedHead, bytes32 maskedTail) = maskWindow(prefix, metadata);

        assertEq(maskedHead, EXPECTED_MASKED_HEAD_WORD);
        assertEq(maskedTail, EXPECTED_MASKED_TAIL_WORD);
    }

    /// The pinned hash is `keccak256` of the two masked words.
    function testSolidityCBORMetadataMaskedHash() external pure {
        assertEq(
            keccak256(abi.encodePacked(EXPECTED_MASKED_HEAD_WORD, EXPECTED_MASKED_TAIL_WORD)),
            SOLIDITY_CBOR_METADATA_MASKED_HASH
        );
    }

    /// The trailer bytes the tail mask keeps encode a CBOR body length that is
    /// `SOLIDITY_CBOR_METADATA_LENGTH` minus those 2 trailer bytes.
    function testSolidityCBORMetadataLengthMatchesTrailer() external pure {
        uint256 bodyLength = uint256(EXPECTED_MASKED_TAIL_WORD) & 0xFFFF;
        assertEq(bodyLength, 51);
        assertEq(bodyLength + 2, SOLIDITY_CBOR_METADATA_LENGTH);
    }
}
