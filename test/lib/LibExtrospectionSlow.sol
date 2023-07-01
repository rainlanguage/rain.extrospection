// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "src/lib/EVMOpcodes.sol";
import "src/lib/LibExtrospectERC1167Proxy.sol";

library LibExtrospectionSlow {
    /// KISS implementation of a presence scan.
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
    function scanEVMOpcodesReachableInBytecodeSlow(bytes memory data) internal pure returns (uint256) {
        uint256 scan = 0;
        bool halted = false;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 op = uint8(data[i]);
            if (!halted) {
                scan = scan | (uint256(1) << uint256(op));
                if ((HALTING_BITMAP & (uint256(1) << uint256(op))) > 0) {
                    halted = true;
                } else if (0x60 <= op && op < 0x80) {
                    i += op - 0x5f;
                }
            } else if (op == EVM_OP_JUMPDEST) {
                halted = false;
                scan = scan | (uint256(1) << uint256(op));
            }
        }
        return scan;
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
