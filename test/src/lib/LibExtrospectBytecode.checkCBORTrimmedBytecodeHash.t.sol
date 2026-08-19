// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {
    SOLIDITY_CBOR_RUNTIME_FIXTURE,
    SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED
} from "test/concrete/SolidityCBORFixture.sol";
import {LibExtrospectTestEtch} from "test/lib/LibExtrospectTestEtch.sol";

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

        // Compute the expected trimmed hash (hash of code without metadata).
        bytes32 expectedHash = keccak256(code);

        // Etch the bytecode onto an address.
        address target = address(0xBEEF);
        LibExtrospectTestEtch.assumeEtch(vm, target, withMetadata);

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
        LibExtrospectTestEtch.assumeEtch(vm, target, code);

        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(target, anyHash);
    }

    /// `expected` covers only the bytecode left after trimming. Two accounts
    /// whose code differs only in the 37 unconstrained trailer bytes satisfy
    /// the same `expected` hash, including when one of them fills those bytes
    /// with `JUMPDEST` and `SELFDESTRUCT`.
    function testCheckCBORTrimmedBytecodeHashIgnoresUnconstrainedTrailerBytes() external {
        bytes memory body = hex"6080604052600080fdfe";

        bytes memory ipfsZero = new bytes(34);
        bytes memory ipfsExecutable = new bytes(34);
        for (uint256 i = 0; i < 34; i++) {
            ipfsExecutable[i] = i % 2 == 0 ? bytes1(0x5B) : bytes1(0xFF);
        }

        bytes memory codeZero =
            bytes.concat(body, hex"a264697066735822", ipfsZero, hex"64736f6c6343", hex"000819", hex"0033");
        bytes memory codeExecutable =
            bytes.concat(body, hex"a264697066735822", ipfsExecutable, hex"64736f6c6343", hex"FFFFFF", hex"0033");
        assertTrue(keccak256(codeZero) != keccak256(codeExecutable), "distinct bytecode");

        address zero = address(0xA11CE);
        address executable = address(0xB0B);
        vm.etch(zero, codeZero);
        vm.etch(executable, codeExecutable);

        bytes32 expected = keccak256(body);
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(zero, expected);
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(executable, expected);
    }

    /// The hash this check matches is `keccak256` of the account's bytecode
    /// with the 53-byte Solidity CBOR trailer removed. The whole-runtime hash
    /// that `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`
    /// matches for the same account is a different value, and reverts here.
    function testCheckCBORTrimmedBytecodeHashRejectsWholeRuntimeHash() external {
        address target = address(0xBEEF);
        vm.etch(target, SOLIDITY_CBOR_RUNTIME_FIXTURE);

        assertEq(SOLIDITY_CBOR_RUNTIME_FIXTURE.length, SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED.length + 53);

        bytes32 trimmedHash = keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED);
        bytes32 wholeRuntimeHash = keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE);

        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(target, trimmedHash);

        vm.expectRevert(
            abi.encodeWithSelector(LibExtrospectBytecode.BytecodeHashMismatch.selector, wholeRuntimeHash, trimmedHash)
        );
        this.externalCheckCBORTrimmedBytecodeHash(target, wholeRuntimeHash);
    }
}
