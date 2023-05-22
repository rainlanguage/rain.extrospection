// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import "sol.lib.memory/LibPointer.sol";

import "./LibExtrospectBytecode.sol";
import "./IExtrospectBytecodeV1.sol";
import "./IExtrospectERC165V1.sol";

/// @title Extrospection
/// @notice Exposes certain information available to evm opcodes as public
/// functions that are world callable.
contract Extrospection is IExtrospectBytecodeV1, IExtrospectERC165V1 {
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

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecode(address account_) external view returns (bytes memory) {
        return account_.code;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecodeHash(address account_) public view returns (bytes32) {
        bytes32 hash_;
        assembly ("memory-safe") {
            hash_ := extcodehash(account_)
        }
        return hash_;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function emitBytecodeHash(address account_) external {
        emit BytecodeHashV1(msg.sender, account_, bytecodeHash(account_));
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function scanEVMOpcodesPresentInAccount(address account_) public view returns (uint256) {
        Pointer cursor_;
        uint256 length_;
        assembly ("memory-safe") {
            length_ := extcodesize(account_)
            cursor_ := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(cursor_, and(add(length_, 0x1f), not(0x1f))))
            extcodecopy(account_, cursor_, 0, length_)
        }
        return LibExtrospectBytecode.scanEVMOpcodesPresentInMemory(cursor_, length_);
    }

    function interpreterAllowedOps(address interpreter_) public view returns (bool) {
        return scanEVMOpcodesPresentInAccount(interpreter_) & INTERPRETER_DISALLOWED_OPS == 0;
    }

    /// @inheritdoc IExtrospectERC165V1
    function accountSupportsInterface(address account_, bytes4 interfaceId_) public view returns (bool) {
        return ERC165Checker.supportsInterface(account_, interfaceId_);
    }

    /// @inheritdoc IExtrospectERC165V1
    function emitAccountSupportsInterface(address account_, bytes4 interfaceId_) external {
        emit AccountSupportsInterfaceV1(
            msg.sender, account_, interfaceId_, accountSupportsInterface(account_, interfaceId_)
        );
    }
}
