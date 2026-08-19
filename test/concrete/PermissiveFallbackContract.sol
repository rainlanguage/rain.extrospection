// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Test fixture that implements no beacon function at all, and
/// answers every selector from a catch-all fallback with the same 32
/// bytes: `answer` left-padded with 12 zero bytes. That return is
/// byte-identical to what a real `implementation()` or `owner()`
/// returning `answer` would produce, so a `staticcall` cannot tell
/// this apart from a beacon. Constructing with `address(0)` gives the
/// all-zero answer. The fallback is the contract's only external
/// surface.
contract PermissiveFallbackContract {
    address private immutable answer;

    constructor(address initialAnswer) {
        answer = initialAnswer;
    }

    fallback(bytes calldata) external returns (bytes memory) {
        return abi.encode(answer);
    }
}
