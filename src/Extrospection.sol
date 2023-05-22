// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import "sol.lib.memory/LibPointer.sol";
import "sol.lib.memory/LibBytes.sol";

import "./LibExtrospectBytecode.sol";
import "./IExtrospectBytecodeV1.sol";
import "./IExtrospectInterpreterV1.sol";

/// @title Extrospection
/// @notice Implements all extrospection interfaces.
contract Extrospection is IExtrospectBytecodeV1, IExtrospectInterpreterV1 {
    using LibBytes for bytes;

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecode(address account_) external view returns (bytes memory) {
        return account_.code;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function bytecodeHash(address account_) external view returns (bytes32) {
        return account_.codehash;
    }

    /// @inheritdoc IExtrospectBytecodeV1
    function scanEVMOpcodesPresentInAccount(address account_) public view returns (uint256) {
        bytes memory code_ = account_.code;
        return LibExtrospectBytecode.scanEVMOpcodesPresentInMemory(code_.dataPointer(), code_.length);
    }

    /// @inheritdoc IExtrospectInterpreterV1
    function scanOnlyAllowedInterpreterEVMOpcodes(address interpreter_) external view returns (bool) {
        return scanEVMOpcodesPresentInAccount(interpreter_) & INTERPRETER_DISALLOWED_OPS == 0;
    }
}
