// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {HALTING_BITMAP, METAMORPHIC_OPS, EVM_OP_JUMPDEST} from "src/lib/EVMOpcodes.sol";
import {ERC1167_PREFIX_HASH, ERC1167_SUFFIX_HASH} from "src/lib/LibExtrospectERC1167Proxy.sol";

library LibExtrospectionSlow {
    /// KISS implementation of isEOFBytecode.
    //forge-lint: disable-next-line(mixed-case-function)
    function isEOFBytecodeSlow(bytes memory bytecode) internal pure returns (bool) {
        bool isEOF = false;
        if (bytecode.length >= 2) {
            bytes1 b0 = bytecode[0];
            bytes1 b1 = bytecode[1];
            isEOF = (b0 == 0xEF && b1 == 0x00);
        }
        return isEOF;
    }

    /// KISS implementation of a presence scan.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesPresentInBytecodeSlow(bytes memory data) internal pure returns (uint256) {
        uint256 scan = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 op = uint8(data[i]);
            scan = scan | (uint256(1) << uint256(op));

            if (0x60 <= op && op < 0x80) {
                i += op - 0x5f;
            }
        }
        return scan;
    }

    /// KISS implementation of a reachability scan.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesReachableInBytecodeSlow(bytes memory data) internal pure returns (uint256) {
        uint256 scan = 0;
        bool halted = false;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 op = uint8(data[i]);
            if (0x60 <= op && op < 0x80) {
                i += op - 0x5f;
            }
            if (!halted) {
                scan = scan | (uint256(1) << uint256(op));
                if ((HALTING_BITMAP & (uint256(1) << uint256(op))) > 0) {
                    halted = true;
                }
            } else if (op == EVM_OP_JUMPDEST) {
                halted = false;
                scan = scan | (uint256(1) << uint256(op));
            }
        }
        return scan;
    }

    /// KISS implementation of metamorphic risk scan.
    function scanMetamorphicRiskSlow(bytes memory data) internal pure returns (uint256) {
        return scanEVMOpcodesReachableInBytecodeSlow(data) & METAMORPHIC_OPS;
    }

    /// KISS implementation of ERC1167 proxy detection.
    function isERC1167ProxySlow(bytes memory bytecode)
        internal
        pure
        returns (bool result, address implementationAddress)
    {
        if (bytecode.length != 45) {
            return (false, address(0));
        }

        bytes memory bytecodePrefix = new bytes(10);
        for (uint256 i = 0; i < 10; i++) {
            bytecodePrefix[i] = bytecode[i];
        }
        bytes memory bytecodeSuffix = new bytes(15);
        for (uint256 i = 0; i < 15; i++) {
            bytecodeSuffix[i] = bytecode[30 + i];
        }

        if (keccak256(bytecodePrefix) != ERC1167_PREFIX_HASH) {
            return (false, address(0));
        }

        if (keccak256(bytecodeSuffix) != ERC1167_SUFFIX_HASH) {
            return (false, address(0));
        }

        bytes memory implementationAddressBytes = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            implementationAddressBytes[i] = bytecode[10 + i];
        }
        uint256 implementationAddressMask = type(uint160).max;
        assembly {
            implementationAddress := and(mload(add(implementationAddressBytes, 20)), implementationAddressMask)
        }
        return (true, implementationAddress);
    }
}
