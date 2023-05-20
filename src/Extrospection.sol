// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

/// @title Extrospection
/// @notice Exposes certain information available to evm opcodes as public
/// functions that are world callable.
contract Extrospection {
    event BytecodeHash(address sender, address account, bytes32 bytecodeHash);

    event SupportsInterface(address sender, address account, bytes4 interfaceId, bool supportsInterface);

    /// This is probably only useful in general for offchain processing/indexing
    /// as the bytes MAY be large and cost much gas to retrieve onchain.
    /// @param account_ The account to get bytecode for.
    /// @return The bytecode.
    function bytecode(address account_) external view returns (bytes memory) {
        return account_.code;
    }

    function bytecodeHash(address account_) public view returns (bytes32) {
        bytes32 hash_;
        assembly ("memory-safe") {
            hash_ := extcodehash(account_)
        }
        return hash_;
    }

    function emitBytecodeHash(address account_) external {
        emit BytecodeHash(msg.sender, account_, bytecodeHash(account_));
    }

    function emitSupportsInterface(address account_, bytes4 interfaceId_) external {
        emit SupportsInterface(
            msg.sender, account_, interfaceId_, ERC165Checker.supportsInterface(account_, interfaceId_)
        );
    }

    function bytecodeOpScanner(address account) public view returns (uint256 ops) {
        assembly ("memory-safe") {
            let length := extcodesize(account)
            let m := mod(length, 0x40)
            let cursor := mload(0x40)
            extcodecopy(account, cursor, 0, length)
            for { let end := sub(length, m) } lt(cursor, end) { cursor := add(cursor, 0x20) } {
                let a := mload(cursor)
                ops :=
                    or(
                        shl(and(a, 0xFF), 1),
                        or(
                            shl(and(shr(8, a), 0xFF), 1),
                            or(
                                shl(and(shr(16, a), 0xFF), 1),
                                or(
                                    shl(and(shr(24, a), 0xFF), 1),
                                    or(
                                        shl(and(shr(32, a), 0xFF), 1),
                                        or(
                                            shl(and(shr(40, a), 0xFF), 1),
                                            or(
                                                shl(and(shr(48, a), 0xFF), 1),
                                                or(
                                                    shl(and(shr(56, a), 0xFF), 1),
                                                    or(
                                                        shl(and(shr(64, a), 0xFF), 1),
                                                        or(
                                                            shl(and(shr(72, a), 0xFF), 1),
                                                            or(
                                                                shl(and(shr(80, a), 0xFF), 1),
                                                                or(
                                                                    shl(and(shr(88, a), 0xFF), 1),
                                                                    or(
                                                                        shl(and(shr(96, a), 0xFF), 1),
                                                                        or(
                                                                            shl(and(shr(104, a), 0xFF), 1),
                                                                            or(
                                                                                shl(and(shr(112, a), 0xFF), 1),
                                                                                or(
                                                                                    shl(and(shr(120, a), 0xFF), 1),
                                                                                    or(
                                                                                        shl(and(shr(128, a), 0xFF), 1),
                                                                                        or(
                                                                                            shl(and(shr(136, a), 0xFF), 1),
                                                                                            or(
                                                                                                shl(
                                                                                                    and(shr(144, a), 0xFF),
                                                                                                    1
                                                                                                ),
                                                                                                or(
                                                                                                    shl(
                                                                                                        and(
                                                                                                            shr(152, a),
                                                                                                            0xFF
                                                                                                        ),
                                                                                                        1
                                                                                                    ),
                                                                                                    or(
                                                                                                        shl(
                                                                                                            and(
                                                                                                                shr(160, a),
                                                                                                                0xFF
                                                                                                            ),
                                                                                                            1
                                                                                                        ),
                                                                                                        or(
                                                                                                            shl(
                                                                                                                and(
                                                                                                                    shr(
                                                                                                                        168,
                                                                                                                        a
                                                                                                                    ),
                                                                                                                    0xFF
                                                                                                                ),
                                                                                                                1
                                                                                                            ),
                                                                                                            or(
                                                                                                                shl(
                                                                                                                    and(
                                                                                                                        shr(
                                                                                                                            176,
                                                                                                                            a
                                                                                                                        ),
                                                                                                                        0xFF
                                                                                                                    ),
                                                                                                                    1
                                                                                                                ),
                                                                                                                or(
                                                                                                                    shl(
                                                                                                                        and(
                                                                                                                            shr(
                                                                                                                                184,
                                                                                                                                a
                                                                                                                            ),
                                                                                                                            0xFF
                                                                                                                        ),
                                                                                                                        1
                                                                                                                    ),
                                                                                                                    or(
                                                                                                                        shl(
                                                                                                                            and(
                                                                                                                                shr(
                                                                                                                                    192,
                                                                                                                                    a
                                                                                                                                ),
                                                                                                                                0xFF
                                                                                                                            ),
                                                                                                                            1
                                                                                                                        ),
                                                                                                                        or(
                                                                                                                            shl(
                                                                                                                                and(
                                                                                                                                    shr(
                                                                                                                                        200,
                                                                                                                                        a
                                                                                                                                    ),
                                                                                                                                    0xFF
                                                                                                                                ),
                                                                                                                                1
                                                                                                                            ),
                                                                                                                            or(
                                                                                                                                shl(
                                                                                                                                    and(
                                                                                                                                        shr(
                                                                                                                                            208,
                                                                                                                                            a
                                                                                                                                        ),
                                                                                                                                        0xFF
                                                                                                                                    ),
                                                                                                                                    1
                                                                                                                                ),
                                                                                                                                or(
                                                                                                                                    shl(
                                                                                                                                        and(
                                                                                                                                            shr(
                                                                                                                                                216,
                                                                                                                                                a
                                                                                                                                            ),
                                                                                                                                            0xFF
                                                                                                                                        ),
                                                                                                                                        1
                                                                                                                                    ),
                                                                                                                                    or(
                                                                                                                                        shl(
                                                                                                                                            and(
                                                                                                                                                shr(
                                                                                                                                                    224,
                                                                                                                                                    a
                                                                                                                                                ),
                                                                                                                                                0xFF
                                                                                                                                            ),
                                                                                                                                            1
                                                                                                                                        ),
                                                                                                                                        or(
                                                                                                                                            shl(
                                                                                                                                                and(
                                                                                                                                                    shr(
                                                                                                                                                        232,
                                                                                                                                                        a
                                                                                                                                                    ),
                                                                                                                                                    0xFF
                                                                                                                                                ),
                                                                                                                                                1
                                                                                                                                            ),
                                                                                                                                            or(
                                                                                                                                                shl(
                                                                                                                                                    and(
                                                                                                                                                        shr(
                                                                                                                                                            240,
                                                                                                                                                            a
                                                                                                                                                        ),
                                                                                                                                                        0xFF
                                                                                                                                                    ),
                                                                                                                                                    1
                                                                                                                                                ),
                                                                                                                                                shl(
                                                                                                                                                    shr(
                                                                                                                                                        248,
                                                                                                                                                        a
                                                                                                                                                    ),
                                                                                                                                                    1
                                                                                                                                                )
                                                                                                                                            )
                                                                                                                                        )
                                                                                                                                    )
                                                                                                                                )
                                                                                                                            )
                                                                                                                        )
                                                                                                                    )
                                                                                                                )
                                                                                                            )
                                                                                                        )
                                                                                                    )
                                                                                                )
                                                                                            )
                                                                                        )
                                                                                    )
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
            }
            cursor := sub(cursor, 0x20)
            end := add(cursor, m)
            for {} lt(cursor, end) {cursor := add(cursor, 1)} {
                ops := or(ops, shl(and(mload(cursor), 0xFF), 1))
            }
        }
    }
}

// export function checkIfIncludesNonStaticOps(bytecode: string) {
//   const ops = Buffer.from(ethers.utils.hexlify(bytecode).split("x")[1], "hex");

//   const disallowedOps = [
//     // https://eips.ethereum.org/EIPS/eip-214#specification
//     // CREATE
//     0xf0,
//     // CREATE2
//     0xf5,
//     // LOG0
//     0xa0,
//     // LOG1
//     0xa1,
//     // LOG2
//     0xa2,
//     // LOG3
//     0xa3,
//     // LOG4
//     0xa4,
//     // SSTORE
//     0x55,
//     // SELFDESTRUCT
//     0xff,
//     // CALL
//     0xf1,

//     // Additional disallowed.
//     // SLOAD
//     // If SSTORE is disallowed then SLOAD makes no sense
//     0x54,
//     // DELEGATECALL
//     // Not allowing other contracts to modify storage either
//     0xf4,
//     // CALLCODE
//     // Use static call instead
//     0xf2,
//     // CALL
//     // Use static call instead
//     0xf1,
//   ];

//   const pushOps = [
//     0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b,
//     0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
//     0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,
//   ];

//   for (let i = 0; i < ops.length; i++) {
//     const byte = ops[i];
//     if (disallowedOps.includes(byte)) {
//       // https://docs.soliditylang.org/en/v0.8.13/metadata.html#encoding-of-the-metadata-hash-in-the-bytecode
//       // This is a hack that assumes the exact format of the metadata which is
//       // NOT correct in all cases. In future we should handle this better by
//       // parsing CBOR instead of just skipping a fixed number of bytes.
//       if (byte === 0xa2 && i === ops.length - 53) {
//         return true;
//       }
//       return false;
//     }
//     if (pushOps.includes(byte)) {
//       const jump = byte - 0x5f;
//       i += jump;
//     }
//   }
//   return true;
// }
