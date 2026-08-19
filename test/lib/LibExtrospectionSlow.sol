// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev The 10 bytes before the implementation address in the ERC1167 minimal
/// proxy runtime bytecode published at
/// https://eips.ethereum.org/EIPS/eip-1167#specification
bytes constant SLOW_ERC1167_PREFIX = hex"363d3d373d3d3d363d73";

/// @dev The 15 bytes after the implementation address in the ERC1167 minimal
/// proxy runtime bytecode published at
/// https://eips.ethereum.org/EIPS/eip-1167#specification
bytes constant SLOW_ERC1167_SUFFIX = hex"5af43d82803e903d91602b57fd5bf3";

/// @dev The implementation address in an ERC1167 minimal proxy is 20 bytes.
uint256 constant SLOW_ERC1167_ADDRESS_LENGTH = 20;

/// @dev `JUMPDEST` opcode byte.
uint8 constant SLOW_OP_JUMPDEST = 0x5B;

/// @dev The first `PUSH*` opcode byte, `PUSH1`.
uint8 constant SLOW_OP_PUSH1 = 0x60;

/// @dev The last `PUSH*` opcode byte, `PUSH32`.
uint8 constant SLOW_OP_PUSH32 = 0x7F;

/// @dev Opcode bytes that halt the current execution path: `STOP`, `JUMP`,
/// `RETURN`, `REVERT`, `INVALID`, `SELFDESTRUCT`.
uint256 constant SLOW_HALTING_BITMAP =
//forge-lint: disable-next-line(incorrect-shift)
 (uint256(1) << 0x00)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0x56)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xF3)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xFD)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xFE)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xFF);

/// @dev The lead byte EIP-3541 reserves: since the London hard fork no
/// ordinary deployment can produce code whose first byte is `0xEF`, so any
/// account code beginning with it was placed there by a protocol feature —
/// an EOF container, an EIP-7702 delegation designator, or whatever the
/// prefix is assigned next — that a legacy opcode scan cannot reason about.
uint8 constant SLOW_EIP3541_LEAD_BYTE = 0xEF;

/// @dev Opcode bytes that indicate metamorphic risk: `SELFDESTRUCT`,
/// `DELEGATECALL`, `CALLCODE`, `CREATE`, `CREATE2`.
uint256 constant SLOW_METAMORPHIC_BITMAP =
//forge-lint: disable-next-line(incorrect-shift)
 (uint256(1) << 0xFF)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xF4)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xF2)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xF0)
    //forge-lint: disable-next-line(incorrect-shift)
    | (uint256(1) << 0xF5);

/// @title LibExtrospectionSlow
/// @notice Reference implementations used as differential oracles for
/// `src`. Every opcode byte, bitmap and bytecode literal used here is
/// declared in this file from the published EVM and ERC specifications, so
/// `src` and the oracle share no state.
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

    /// Decodes `data` to the sequence of opcode bytes it contains, dropping
    /// the inline data bytes that follow each `PUSH*`. A `PUSH*` whose inline
    /// data runs past the end of `data` contributes only itself.
    /// @param data The bytecode to decode.
    /// @return ops The opcode bytes in the order they appear.
    function decodeOpcodesSlow(bytes memory data) internal pure returns (bytes memory ops) {
        bytes memory buffer = new bytes(data.length);
        uint256 count = 0;
        uint256 i = 0;
        while (i < data.length) {
            uint8 op = uint8(data[i]);
            buffer[count] = bytes1(op);
            count++;
            if (SLOW_OP_PUSH1 <= op && op <= SLOW_OP_PUSH32) {
                i += uint256(op) - uint256(SLOW_OP_PUSH1) + 1;
            }
            i++;
        }
        ops = new bytes(count);
        for (uint256 j = 0; j < count; j++) {
            ops[j] = buffer[j];
        }
    }

    /// KISS implementation of a presence scan. Every decoded opcode is
    /// present.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesPresentInBytecodeSlow(bytes memory data) internal pure returns (uint256) {
        bytes memory ops = decodeOpcodesSlow(data);
        uint256 scan = 0;
        for (uint256 i = 0; i < ops.length; i++) {
            scan = scan | opcodeBit(uint8(ops[i]));
        }
        return scan;
    }

    /// KISS implementation of a reachability scan. Decoded opcodes are
    /// reachable until a halting opcode, and reachable again from the next
    /// `JUMPDEST`.
    //forge-lint: disable-next-line(mixed-case-function)
    function scanEVMOpcodesReachableInBytecodeSlow(bytes memory data) internal pure returns (uint256) {
        bytes memory ops = decodeOpcodesSlow(data);
        uint256 scan = 0;
        bool reachable = true;
        for (uint256 i = 0; i < ops.length; i++) {
            uint8 op = uint8(ops[i]);
            if (reachable) {
                scan = scan | opcodeBit(op);
                if ((SLOW_HALTING_BITMAP & opcodeBit(op)) != 0) {
                    reachable = false;
                }
            } else if (op == SLOW_OP_JUMPDEST) {
                reachable = true;
                scan = scan | opcodeBit(op);
            }
        }
        return scan;
    }

    /// KISS implementation of metamorphic risk scan. Fails closed on the
    /// EIP-3541 reserved prefix: bytecode whose first byte is `0xEF` reports
    /// that byte's bit alone, before any opcode scan.
    function scanMetamorphicRiskSlow(bytes memory data) internal pure returns (uint256) {
        if (data.length > 0 && uint8(data[0]) == SLOW_EIP3541_LEAD_BYTE) {
            //forge-lint: disable-next-line(incorrect-shift)
            return uint256(1) << SLOW_EIP3541_LEAD_BYTE;
        }
        return scanEVMOpcodesReachableInBytecodeSlow(data) & SLOW_METAMORPHIC_BITMAP;
    }

    /// KISS implementation of ERC1167 proxy detection. Compares the bytecode
    /// byte for byte against the published minimal proxy runtime.
    function isERC1167ProxySlow(bytes memory bytecode)
        internal
        pure
        returns (bool result, address implementationAddress)
    {
        bytes memory prefix = SLOW_ERC1167_PREFIX;
        bytes memory suffix = SLOW_ERC1167_SUFFIX;

        if (bytecode.length != prefix.length + SLOW_ERC1167_ADDRESS_LENGTH + suffix.length) {
            return (false, address(0));
        }

        for (uint256 i = 0; i < prefix.length; i++) {
            if (bytecode[i] != prefix[i]) {
                return (false, address(0));
            }
        }

        for (uint256 i = 0; i < suffix.length; i++) {
            if (bytecode[prefix.length + SLOW_ERC1167_ADDRESS_LENGTH + i] != suffix[i]) {
                return (false, address(0));
            }
        }

        uint160 accumulator = 0;
        for (uint256 i = 0; i < SLOW_ERC1167_ADDRESS_LENGTH; i++) {
            accumulator = (accumulator << 8) | uint160(uint8(bytecode[prefix.length + i]));
        }
        return (true, address(accumulator));
    }

    /// The bit representing `op` in an opcode bitmap.
    /// @param op The opcode byte.
    /// @return The bitmap with only the bit for `op` set.
    function opcodeBit(uint8 op) internal pure returns (uint256) {
        return uint256(1) << uint256(op);
    }
}
