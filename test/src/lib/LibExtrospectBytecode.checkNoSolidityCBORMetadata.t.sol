// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {SOLIDITY_CBOR_RUNTIME_FIXTURE} from "test/concrete/SolidityCBORFixture.sol";

/// @dev Total length of standard Solidity CBOR metadata, from the CBOR map
/// header to the 2 byte length suffix.
/// https://docs.soliditylang.org/en/latest/metadata.html#encoding-of-the-metadata-hash-in-the-bytecode
uint256 constant SOLIDITY_CBOR_METADATA_LENGTH = 53;

contract LibExtrospectBytecodeCheckNoSolidityCBORMetadataTest is Test {
    /// External wrapper for revert tests.
    //forge-lint: disable-next-line(mixed-case-function)
    function checkNoSolidityCBORMetadataExternal(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// Builds standard Solidity CBOR metadata: CBOR map header, the `ipfs`
    /// key and its 34 byte value, the `solc` key and its 3 byte value, and
    /// the 2 byte length suffix. The IPFS hash and solc version bytes are
    /// filled from `seed`.
    /// @param seed Source of the per-contract bytes.
    /// @return The 53 bytes of metadata.
    //forge-lint: disable-next-line(mixed-case-function)
    function solidityCBORMetadata(bytes32 seed) internal pure returns (bytes memory) {
        bytes memory ipfsHash = new bytes(34);
        for (uint256 i = 0; i < ipfsHash.length; i++) {
            ipfsHash[i] = seed[i % 32];
        }
        bytes memory solcVersion = new bytes(3);
        for (uint256 i = 0; i < solcVersion.length; i++) {
            solcVersion[i] = seed[i];
        }
        return bytes.concat(hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");
    }

    /// The offsets within standard Solidity CBOR metadata of the bytes that
    /// are the same for every contract: `a2 64 "ipfs" 5822` at 0-7,
    /// `64 "solc" 43` at 42-47, and the 2 byte length suffix at 51-52. The
    /// bytes at every other offset are the IPFS hash and the solc version,
    /// which differ per contract.
    /// @return offsets The offsets, ascending.
    //forge-lint: disable-next-line(mixed-case-function)
    function solidityCBORMetadataFixedOffsets() internal pure returns (uint256[16] memory offsets) {
        offsets = [uint256(0), 1, 2, 3, 4, 5, 6, 7, 42, 43, 44, 45, 46, 47, 51, 52];
    }

    /// Account with no code passes (no metadata to detect).
    function testCheckNoMetadataEmptyAccount() external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(address(0xdead));
    }

    /// Contract compiled without metadata passes. This project compiles with
    /// cbor_metadata = false so all contracts deployed in tests lack metadata.
    function testCheckNoMetadataNonMetamorphic() external {
        NonMetamorphic clean = new NonMetamorphic();
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(address(clean));
    }

    /// Bytecode with standard CBOR metadata reverts.
    function testCheckNoMetadataRevertsOnMetadata() external {
        // Runtime bytecode with standard Solidity CBOR metadata appended.
        // We use vm.etch since the project itself compiles without metadata.
        bytes memory runtimeCode = SOLIDITY_CBOR_RUNTIME_FIXTURE;
        address deployed = address(0xbeef);
        vm.etch(deployed, runtimeCode);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.checkNoSolidityCBORMetadataExternal(deployed);
    }

    /// EOF bytecode etched onto an account reverts with EOFBytecodeNotSupported.
    function testCheckNoMetadataEOF() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"EF00010203");
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNoSolidityCBORMetadataExternal(target);
    }

    /// Fuzz: bytecode shorter than Solidity CBOR metadata passes. The
    /// leading `STOP` keeps the bytecode out of the EOF format.
    function testCheckNoMetadataPassesShortBytecode(bytes memory code) external {
        uint256 length = code.length;
        if (length >= SOLIDITY_CBOR_METADATA_LENGTH) {
            length = SOLIDITY_CBOR_METADATA_LENGTH - 1;
        }
        bytes memory short = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            short[i] = code[i];
        }
        if (length > 0) {
            short[0] = 0x00;
        }

        // vm.etch treats bytecode whose first two bytes are 0xef01 as an
        // EIP-7702 delegation designator and rejects it unless it is exactly
        // 23 bytes.
        vm.assume(code.length < 2 || code.length == 23 || uint8(code[0]) != 0xEF || uint8(code[1]) != 0x01);

        address target = address(0xBEEF);
        vm.etch(target, short);
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(target);
    }

    /// Fuzz: bytecode ending in Solidity CBOR metadata with exactly one of
    /// its fixed structure bytes corrupted passes. The leading `STOP` keeps
    /// the bytecode out of the EOF format.
    function testCheckNoMetadataPassesCorruptedMetadata(bytes memory code, uint256 offsetIndex, uint8 corruption)
        external
    {
        uint256[16] memory offsets = solidityCBORMetadataFixedOffsets();
        uint256 offset = offsets[bound(offsetIndex, 0, offsets.length - 1)];
        bytes memory metadata = solidityCBORMetadata(keccak256(code));
        metadata[offset] = bytes1(uint8(metadata[offset]) ^ uint8(bound(corruption, 1, type(uint8).max)));

        address target = address(0xBEEF);
        vm.etch(target, bytes.concat(hex"00", code, metadata));
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(target);
    }

    /// Fuzz: bytecode with valid CBOR metadata appended reverts.
    function testCheckNoMetadataRevertsFuzz(bytes memory code) external {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));

        bytes memory withMetadata = bytes.concat(code, solidityCBORMetadata(keccak256(code)));

        // vm.etch treats bytecode whose first two bytes are 0xef01 as an
        // EIP-7702 delegation designator and rejects it unless it is exactly
        // 23 bytes. withMetadata is always at least 53 bytes.
        vm.assume(uint8(withMetadata[0]) != 0xEF || uint8(withMetadata[1]) != 0x01);

        address target = address(0xBEEF);
        vm.etch(target, withMetadata);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.checkNoSolidityCBORMetadataExternal(target);
    }
}
