// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Minimal Solidity runtime bytecode with the standard 53-byte CBOR
/// metadata trailer appended. Used across the CBOR-related tests both in
/// `test/src/lib/LibExtrospectBytecode.*` and in
/// `test/src/concrete/Extrospect.*` to exercise the trim and reject paths.
///
/// Layout: `6080604052600080fd` (push 0x80, push 0x40, mstore, push 0,
/// dup1, revert) followed by the 53-byte CBOR trailer
/// `a26469706673...000819 0033` (ipfs hash + solc 0.8.25 marker + length).
bytes constant SOLIDITY_CBOR_RUNTIME_FIXTURE =
    hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
