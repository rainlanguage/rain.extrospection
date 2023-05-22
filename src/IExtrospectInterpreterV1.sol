// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title IExtrospectBytecodeV1
/// @notice External functions for offchain processing to conveniently access the
/// view on contract code that is exposed to EVM opcodes. Generally this is NOT
/// useful onchain as all contracts have access to the same opcodes, so would be
/// more gas efficient and convenient calling the opcodes internally than an
/// external call to an extrospection contract.
interface IExtrospectInterpreterV1 {

}
