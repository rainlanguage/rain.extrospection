// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

/// No test in this contract forks, so every test here runs without any RPC
/// environment variable. The tests of `checkCBORTrimmedBytecodeHash` that fork
/// Arbitrum live in
/// `test/src/lib/LibExtrospectBytecode.checkCBORTrimmedBytecodeHash.fork.t.sol`.
contract LibExtrospectBytecodeCheckCBORTrimmedBytecodeHashTest is Test {
    function externalCheckCBORTrimmedBytecodeHash(address target, bytes32 expectedCodeHash) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(target, expectedCodeHash);
    }

    /// Test that an empty account (no deployed code) reverts with
    /// MetadataNotTrimmed since there is no metadata to trim.
    function testCheckCBORTrimmedBytecodeHashEmptyAccount() external {
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(address(0xdead), bytes32(0));
    }

    /// Fuzz test: etch bytecode with valid CBOR metadata onto an address,
    /// then verify checkCBORTrimmedBytecodeHash accepts the correct trimmed
    /// hash and rejects incorrect hashes.
    function testCheckCBORTrimmedBytecodeHashFuzz(bytes memory code, bytes32 wrongHash) external {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));

        // Build a synthetic IPFS hash and solc version from the fuzz input.
        bytes32 seed = keccak256(code);
        bytes memory ipfsHash = new bytes(34);
        assembly ("memory-safe") {
            mstore(add(ipfsHash, 0x20), seed)
            mstore(add(ipfsHash, 0x40), keccak256(0, 0x20))
        }
        bytes memory solcVersion = new bytes(3);
        assembly ("memory-safe") {
            mstore(add(solcVersion, 0x20), seed)
        }

        // Append valid CBOR metadata.
        bytes memory withMetadata =
            bytes.concat(code, hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");

        // vm.etch treats bytecode whose first two bytes are 0xef01 as an
        // EIP-7702 delegation designator and rejects it unless it is exactly
        // 23 bytes. withMetadata is always at least 53 bytes.
        vm.assume(uint8(withMetadata[0]) != 0xEF || uint8(withMetadata[1]) != 0x01);

        // Compute the expected trimmed hash (hash of code without metadata).
        bytes32 expectedHash = keccak256(code);

        // Etch the bytecode onto an address.
        address target = address(0xBEEF);
        vm.etch(target, withMetadata);

        // Correct hash should succeed.
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(target, expectedHash);

        // Wrong hash should revert with BytecodeHashMismatch.
        vm.assume(wrongHash != expectedHash);
        vm.expectRevert(
            abi.encodeWithSelector(LibExtrospectBytecode.BytecodeHashMismatch.selector, wrongHash, expectedHash)
        );
        this.externalCheckCBORTrimmedBytecodeHash(target, wrongHash);
    }

    /// EOF bytecode etched onto an account reverts with EOFBytecodeNotSupported.
    function testCheckCBORTrimmedBytecodeHashEOF() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"EF00010203");
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.externalCheckCBORTrimmedBytecodeHash(target, bytes32(0));
    }

    /// Fuzz test: etch bytecode WITHOUT valid metadata and verify it reverts
    /// with MetadataNotTrimmed.
    function testCheckCBORTrimmedBytecodeHashNoMetadataFuzz(bytes memory code, bytes32 anyHash) external {
        vm.assume(code.length > 0);
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));
        // Ensure the code does not already contain valid CBOR metadata.
        vm.assume(!LibExtrospectBytecode.tryTrimSolidityCBORMetadata(code));

        // vm.etch treats bytecode whose first two bytes are 0xef01 as an
        // EIP-7702 delegation designator and rejects it unless it is exactly
        // 23 bytes.
        vm.assume(code.length < 2 || code.length == 23 || uint8(code[0]) != 0xEF || uint8(code[1]) != 0x01);

        address target = address(0xBEEF);
        vm.etch(target, code);

        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(target, anyHash);
    }
}
