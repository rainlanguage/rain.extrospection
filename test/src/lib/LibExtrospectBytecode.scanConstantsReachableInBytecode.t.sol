// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibDataContract} from "rain-datacontract-0.2.1/src/lib/LibDataContract.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectionSlow, SLOW_ERC1167_PREFIX, SLOW_ERC1167_SUFFIX} from "test/lib/LibExtrospectionSlow.sol";
import {REPORTED_FALSE_POSITIVE_BYTECODE, METAMORPHIC_METADATA} from "test/lib/LibExtrospectBytecode.testConstants.sol";
import {HasConstantAddress, CONSTANT_ADDRESS, NARROW_CONSTANT_ADDRESS} from "test/concrete/HasConstantAddress.sol";
import {HasImmutableAddress} from "test/concrete/HasImmutableAddress.sol";

contract LibExtrospectBytecodeScanConstantsReachableInBytecodeTest is Test {
    function scanConstantsReachableInBytecodeExternal(bytes memory bytecode) external pure returns (uint256[] memory) {
        return LibExtrospectBytecode.scanConstantsReachableInBytecode(bytecode);
    }

    function contains(uint256[] memory values, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] == value) {
                return true;
            }
        }
        return false;
    }

    /// `code` with its length cut to `length`, leaving the cut bytes in
    /// memory directly after the shortened array.
    function cut(bytes memory code, uint256 length) internal pure returns (bytes memory) {
        assembly ("memory-safe") {
            mstore(code, length)
        }
        return code;
    }

    function testScanConstantsReachableEmpty() external pure {
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"").length, 0);
    }

    function testScanConstantsReachableNoPushes() external pure {
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"0102035b5a").length, 0);
    }

    function testScanConstantsReachablePush0IsNotAConstant() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"5f60015f");
        assertEq(constants.length, 1);
        assertEq(constants[0], 1);
    }

    function testScanConstantsReachableSimpleInOrder() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
            hex"6080" hex"736B175474E89094C44Da98b954EedeAC495271d0F" hex"01"
            hex"7f0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20" hex"6c68F116a894984e2DB1123eB395"
            hex"730000000000000068F116a894984e2DB1123eB395" hex"61ABCD"
        );
        assertEq(constants.length, 6);
        assertEq(constants[0], 0x80);
        assertEq(constants[1], uint256(uint160(0x6B175474E89094C44Da98b954EedeAC495271d0F)));
        assertEq(constants[2], 0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20);
        assertEq(constants[3], uint256(uint160(0x0000000000000068F116a894984e2DB1123eB395)));
        assertEq(constants[4], uint256(uint160(0x0000000000000068F116a894984e2DB1123eB395)));
        assertEq(constants[5], 0xABCD);
    }

    function testScanConstantsReachableEveryPushWidth() external pure {
        for (uint256 width = 1; width <= 32; width++) {
            bytes memory code = new bytes(width + 2);
            code[0] = 0x01;
            //forge-lint: disable-next-line(unsafe-typecast)
            code[1] = bytes1(uint8(0x5f + width));
            uint256 expected = 0;
            for (uint256 i = 0; i < width; i++) {
                //forge-lint: disable-next-line(unsafe-typecast)
                code[i + 2] = bytes1(uint8(0xA0 + i));
                expected = (expected << 8) | (0xA0 + i);
            }
            uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(code);
            assertEq(constants.length, 1);
            assertEq(constants[0], expected);
        }
    }

    function testScanConstantsReachableTruncatedPush1() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(cut(hex"600160EE", 3));
        assertEq(constants.length, 2);
        assertEq(constants[0], 1);
        assertEq(constants[1], 0);
    }

    function testScanConstantsReachableTruncatedPush2Partial() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(cut(hex"61FFEEEE", 2));
        assertEq(constants.length, 1);
        assertEq(constants[0], 0xFF00);
    }

    function testScanConstantsReachableTruncatedPush32() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
            cut(hex"7fEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE", 1)
        );
        assertEq(constants.length, 1);
        assertEq(constants[0], 0);
    }

    function testScanConstantsReachableTruncatedPush32Partial() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
            cut(hex"7fAAEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE", 2)
        );
        assertEq(constants.length, 1);
        assertEq(constants[0], 0xAA << 248);
    }

    function testScanConstantsReachableTruncatedPush32OneShort() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
            cut(hex"7f0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1fEE", 32)
        );
        assertEq(constants.length, 1);
        assertEq(constants[0], 0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f00);
    }

    function testScanConstantsReachablePushDataLikePushNotWalked() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"6160016002");
        assertEq(constants.length, 2);
        assertEq(constants[0], 0x6001);
        assertEq(constants[1], 0x02);
    }

    function testScanConstantsReachablePushDataLikeHaltNotWalked() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"60F360006001");
        assertEq(constants.length, 3);
        assertEq(constants[0], 0xF3);
        assertEq(constants[1], 0x00);
        assertEq(constants[2], 0x01);
    }

    function testScanConstantsReachablePushDataLikeJumpdestWhileHaltedNotWalked() external pure {
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"00615b5b6001").length, 0);
    }

    function testScanConstantsReachableSkipsAfterEachHaltUntilJumpdest() external pure {
        bytes1[6] memory halts = [bytes1(0x00), 0x56, 0xF3, 0xFD, 0xFE, 0xFF];
        for (uint256 i = 0; i < halts.length; i++) {
            uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
                abi.encodePacked(hex"6001", halts[i], hex"6002736B175474E89094C44Da98b954EedeAC495271d0F5b6004")
            );
            assertEq(constants.length, 2);
            assertEq(constants[0], 1);
            assertEq(constants[1], 4);
        }
    }

    function testScanConstantsReachableJumpiDoesNotHalt() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"6001576002");
        assertEq(constants.length, 2);
        assertEq(constants[0], 1);
        assertEq(constants[1], 2);
    }

    function testScanConstantsReachableRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanConstantsReachableInBytecodeExternal(hex"EF006001");
    }

    function testScanConstantsReachableReference(bytes memory data) external pure {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(data));
        assertEq(
            LibExtrospectBytecode.scanConstantsReachableInBytecode(data),
            LibExtrospectionSlow.scanConstantsReachableInBytecodeSlow(data)
        );
    }

    function testScanConstantsReachableReferenceRealBytecode() external pure {
        uint256[] memory constants =
            LibExtrospectBytecode.scanConstantsReachableInBytecode(REPORTED_FALSE_POSITIVE_BYTECODE);
        assertTrue(constants.length > 0);
        assertEq(constants, LibExtrospectionSlow.scanConstantsReachableInBytecodeSlow(REPORTED_FALSE_POSITIVE_BYTECODE));
        assertEq(
            LibExtrospectBytecode.scanConstantsReachableInBytecode(METAMORPHIC_METADATA),
            LibExtrospectionSlow.scanConstantsReachableInBytecodeSlow(METAMORPHIC_METADATA)
        );
    }

    function testScanConstantsReachableReturnedArraySurvivesAllocation() external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"60016002");
        bytes memory clobber = new bytes(0x80);
        for (uint256 i = 0; i < clobber.length; i++) {
            clobber[i] = 0xEE;
        }
        assertEq(constants.length, 2);
        assertEq(constants[0], 1);
        assertEq(constants[1], 2);
    }

    function testScanConstantsReachableDirtyFreeMemory() external pure {
        assembly ("memory-safe") {
            let free := mload(0x40)
            for { let i := 0 } lt(i, 0x100) { i := add(i, 0x20) } { mstore(add(free, i), not(0)) }
        }
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"006001").length, 0);
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(hex"6001");
        assertEq(constants.length, 1);
        assertEq(constants[0], 1);
    }

    function testScanConstantsReachableConstantAddresses() external {
        HasConstantAddress fixture = new HasConstantAddress();
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(address(fixture).code);
        assertTrue(contains(constants, uint256(uint160(CONSTANT_ADDRESS))));
        assertTrue(contains(constants, uint256(uint160(NARROW_CONSTANT_ADDRESS))));
    }

    function testScanConstantsReachableImmutableAddress(address target) external {
        HasImmutableAddress fixture = new HasImmutableAddress(target);
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(address(fixture).code);
        assertTrue(contains(constants, uint256(uint160(target))));
    }

    function testScanConstantsReachableERC1167Proxy(address implementation) external pure {
        uint256[] memory constants = LibExtrospectBytecode.scanConstantsReachableInBytecode(
            abi.encodePacked(SLOW_ERC1167_PREFIX, implementation, SLOW_ERC1167_SUFFIX)
        );
        assertEq(constants.length, 2);
        assertEq(constants[0], uint256(uint160(implementation)));
        assertEq(constants[1], 0x2b);
    }

    function deployDataContract(bytes memory data) internal returns (address pointer) {
        bytes memory creationCode = LibDataContract.contractCreationCode(data);
        assembly ("memory-safe") {
            pointer := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        assertTrue(pointer != address(0));
    }

    function testScanConstantsReachableDataContractRowsNotReturned() external {
        bytes memory rows = abi.encodePacked(
            hex"73",
            CONSTANT_ADDRESS,
            hex"7f",
            bytes32(uint256(uint160(NARROW_CONSTANT_ADDRESS))),
            hex"6c68F116a894984e2DB1123eB395",
            hex"6001"
        );
        address pointer = deployDataContract(rows);
        assertEq(LibDataContract.read(pointer), rows);
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(pointer.code).length, 0);
    }

    /// Rows that are each one whole PUSH instruction, whatever their operand
    /// bytes, including 0x5b.
    function testScanConstantsReachableDataContractPushRowsNotReturned(bytes32[] memory operands, uint8[] memory widths)
        external
    {
        bytes memory rows;
        for (uint256 i = 0; i < operands.length && i < widths.length; i++) {
            uint256 width = uint256(widths[i]) % 32 + 1;
            bytes memory operand = abi.encodePacked(operands[i]);
            assembly ("memory-safe") {
                mstore(operand, width)
            }
            //forge-lint: disable-next-line(unsafe-typecast)
            rows = abi.encodePacked(rows, bytes1(uint8(0x5f + width)), operand);
        }
        vm.assume(rows.length > 0);
        address pointer = deployDataContract(rows);
        assertEq(LibExtrospectBytecode.scanConstantsReachableInBytecode(pointer.code).length, 0);
    }

    function testScanConstantsReachableDataContractCreationCode() external pure {
        bytes memory rows = abi.encodePacked(hex"73", CONSTANT_ADDRESS, hex"6001");
        uint256[] memory constants =
            LibExtrospectBytecode.scanConstantsReachableInBytecode(LibDataContract.contractCreationCode(rows));
        assertEq(constants.length, 4);
        assertEq(constants[0], rows.length + 1);
        assertEq(constants[1], 0x0c);
        assertEq(constants[2], 0);
        assertEq(constants[3], 0);
    }
}
