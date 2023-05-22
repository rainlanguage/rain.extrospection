// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./EVMOpcodes.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-214#specification
uint256 constant NON_STATIC_OPS = (1 << uint256(EVM_OP_CREATE)) | (1 << uint256(EVM_OP_CREATE2))
    | (1 << uint256(EVM_OP_LOG0)) | (1 << uint256(EVM_OP_LOG1)) | (1 << uint256(EVM_OP_LOG2)) | (1 << uint256(EVM_OP_LOG3))
    | (1 << uint256(EVM_OP_LOG4)) | (1 << uint256(EVM_OP_SSTORE)) | (1 << uint256(EVM_OP_SELFDESTRUCT))
    | (1 << uint256(EVM_OP_CALL));

/// @dev The interpreter ops allowlist is stricter than the static ops list.
uint256 constant INTERPRETER_DISALLOWED_OPS = NON_STATIC_OPS
// Interpreter cannot store so it has no reason to load from storage.
| (1 << uint256(EVM_OP_SLOAD))
// Interpreter MUST NOT delegate call as we have no idea what could run and
// it could easily mutate the interpreter if allowed.
| (1 << uint256(EVM_OP_DELEGATECALL))
// Interpreter MUST use static call only.
| (1 << uint256(EVM_OP_CALLCODE))
// Interpreter MUST use static call only.
// Redundant with static list for clarity as static list allows 0 value calls.
| (1 << uint256(EVM_OP_CALL));

/// @title IExtrospectInterpreterV1
/// @notice External functions for offchain processing to
interface IExtrospectInterpreterV1 {
    function scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool);
}
