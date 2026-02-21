// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectTestProd} from "test/lib/LibExtrospectTestProd.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract LibExtrospectBytecodeCheckCBORTrimmedBytecodeHashTest is Test {
    address constant PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1 = address(0xe01Db32B1E03976b24e3A948A560f4b97Dd732dA);
    bytes32 constant PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1 =
        bytes32(0x7b085ca3e5c659da29caf26d23e7b72fd4fdbc59aa6b5611cf3918c4586ec73a);

    function externalCheckCBORTrimmedBytecodeHash(address target, bytes32 expectedCodeHash) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(target, expectedCodeHash);
    }

    function testCheckCBORTrimmedBytecodeHashSuccess() external {
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(
            PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1, PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1
        );
    }

    function testCheckCBORTrimmedBytecodeHashFailure() external {
        bytes32 expectedCodeHash = bytes32(0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF);
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        bytes32 actualCodeHash = PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1;

        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector, expectedCodeHash, actualCodeHash
            )
        );
        this.externalCheckCBORTrimmedBytecodeHash(PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1, expectedCodeHash);
    }

    /// Test that an empty account (no deployed code) reverts with
    /// MetadataNotTrimmed since there is no metadata to trim.
    function testCheckCBORTrimmedBytecodeHashEmptyAccount() external {
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(address(0xdead), bytes32(0));
    }

    function testCheckCBORTrimmedBytecodeHashMetadataNotTrimmed() external {
        bytes32 expectedCodeHash = bytes32(0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF);
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        // Use an account that does not have Solidity CBOR metadata and is
        // therefore not trimmed.
        // This is a deployed rain interpreter contract.
        address accountWithoutMetadata = address(0x1Bd4F25881B5A82302Edc07FCa994faa21baec7F);

        // The code hash does not matter because the error for trimming happens
        // before the hash is checked.
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(accountWithoutMetadata, expectedCodeHash);
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

        address target = address(0xBEEF);
        vm.etch(target, code);

        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(target, anyHash);
    }
}
