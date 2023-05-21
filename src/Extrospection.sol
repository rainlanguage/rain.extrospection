// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

/// @title Extrospection
/// @notice Exposes certain information available to evm opcodes as public
/// functions that are world callable.
contract Extrospection {
    event BytecodeHash(address sender, address account, bytes32 bytecodeHash);

    event SupportsInterface(address sender, address account, bytes4 interfaceId, bool supportsInterface);

    /// https://eips.ethereum.org/EIPS/eip-214#specification
    uint256 constant NON_STATIC_OPS =
    // CREATE
    (1 << 0xF0)
    // CREATE2
    | (1 << 0xF5)
    // LOG0
    | (1 << 0xA0)
    // LOG1
    | (1 << 0xA1)
    // LOG2
    | (1 << 0xA2)
    // LOG3
    | (1 << 0xA3)
    // LOG4
    | (1 << 0xA4)
    // SSTORE
    | (1 << 0x55)
    // SELFDESTRUCT
    | (1 << 0xFF)
    // CALL
    | (1 << 0xF1);

    uint256 constant INTERPRETER_DISALLOWED_OPS = NON_STATIC_OPS
    // SLOAD
    | (1 << 0x54)
    // DELEGATECALL
    | (1 << 0xF4)
    // CALLCODE
    | (1 << 0xF2)
    // CALL
    | (0xF1);

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

    function bytecodeOpScanner(address account) public view returns (uint256) {
        Pointer cursor;
        uint256 length;
        assembly ("memory-safe") {
            length := extcodesize(account)
            cursor := mload(0x40)
            extcodecopy(account, cursor, 0, length)
        }
        return LibExtrospection.scanBytesPresent(Pointer.wrap(cursor), length);
    }

    function interpreterAllowedOps(address interpreter) public view returns (bool) {
        return bytecodeOpScanner(interpreter) & INTERPRETER_DISALLOWED_OPS == 0;
    }
}
