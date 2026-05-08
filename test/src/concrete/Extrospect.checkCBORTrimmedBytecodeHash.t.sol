// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectCheckCBORTrimmedBytecodeHashTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function libCheckCBORTrimmedBytecodeHashExternal(address account, bytes32 expected) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expected);
    }

    function testCheckCBORTrimmedBytecodeHashEquivalencePass() external {
        bytes memory withMeta =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
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
        bytes memory withMeta =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        address deployed = address(0xbeef);
        vm.etch(deployed, withMeta);
        bytes32 wrong = bytes32(uint256(0xdead));

        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector,
                wrong,
                keccak256(_trim(withMeta))
            )
        );
        extrospect.checkCBORTrimmedBytecodeHash(deployed, wrong);
        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector,
                wrong,
                keccak256(_trim(withMeta))
            )
        );
        this.libCheckCBORTrimmedBytecodeHashExternal(deployed, wrong);
    }

    function _trim(bytes memory raw) internal pure returns (bytes memory trimmed) {
        trimmed = bytes.concat(raw);
        LibExtrospectBytecode.tryTrimSolidityCBORMetadata(trimmed);
    }
}
