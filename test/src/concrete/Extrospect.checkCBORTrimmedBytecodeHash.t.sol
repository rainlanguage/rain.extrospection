// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {SOLIDITY_CBOR_RUNTIME_FIXTURE} from "test/concrete/SolidityCBORFixture.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectCheckCBORTrimmedBytecodeHashTest is ExtrospectEquivalence {
    //forge-lint: disable-next-line(mixed-case-function)
    function libCheckCBORTrimmedBytecodeHashExternal(address account, bytes32 expected) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expected);
    }

    function testCheckCBORTrimmedBytecodeHashEquivalencePass() external {
        bytes memory withMeta = SOLIDITY_CBOR_RUNTIME_FIXTURE;
        address deployed = address(0xbeef);
        vm.etch(deployed, withMeta);

        // Compute the expected trimmed hash.
        bytes memory copy = bytes.concat(withMeta);
        LibExtrospectBytecode.tryTrimSolidityCBORMetadata(copy);
        bytes32 expected = keccak256(copy);

        extrospect.checkCBORTrimmedBytecodeHash(deployed, expected);
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(deployed, expected);
    }

    function testCheckCBORTrimmedBytecodeHashEquivalenceRevertNotTrimmed() external {
        address deployed = address(0xbeef);
        vm.etch(deployed, hex"6080604052600080fd"); // no metadata
        bytes32 expected = keccak256(hex"00");

        vm.expectRevert(LibExtrospectBytecode.MetadataNotTrimmed.selector);
        extrospect.checkCBORTrimmedBytecodeHash(deployed, expected);
        vm.expectRevert(LibExtrospectBytecode.MetadataNotTrimmed.selector);
        this.libCheckCBORTrimmedBytecodeHashExternal(deployed, expected);
    }

    function testCheckCBORTrimmedBytecodeHashEquivalenceRevertHashMismatch() external {
        bytes memory withMeta = SOLIDITY_CBOR_RUNTIME_FIXTURE;
        address deployed = address(0xbeef);
        vm.etch(deployed, withMeta);
        bytes32 wrong = bytes32(uint256(0xdead));

        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector, wrong, keccak256(_trim(withMeta))
            )
        );
        extrospect.checkCBORTrimmedBytecodeHash(deployed, wrong);
        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector, wrong, keccak256(_trim(withMeta))
            )
        );
        this.libCheckCBORTrimmedBytecodeHashExternal(deployed, wrong);
    }

    function _trim(bytes memory raw) internal pure returns (bytes memory trimmed) {
        trimmed = bytes.concat(raw);
        LibExtrospectBytecode.tryTrimSolidityCBORMetadata(trimmed);
    }
}
