// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";

/// @dev Abstract base for the per-function equivalence tests under
/// `test/src/concrete/Extrospect.<fn>.t.sol`. Each concrete test
/// inherits this for the shared `Extrospect` instance and `setUp`.
abstract contract ExtrospectEquivalence is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    /// Invokes `selector` with `args` against `target` as a raw low-level call,
    /// returning the success flag and the raw returndata (the ABI-encoded return
    /// values on success, or the ABI-encoded revert payload on failure).
    /// Capturing the returndata in both branches lets the equivalence tests
    /// compare the concrete and library outputs byte-for-byte regardless of
    /// whether the call succeeded or reverted — a regression that remapped one
    /// revert selector/payload to another is caught, not just "both reverted".
    function rawCall(address target, bytes4 selector, bytes memory args)
        internal
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = target.call(abi.encodePacked(selector, args));
    }

    /// Asserts that the concrete `Extrospect` instance and the library wrapper
    /// (both addressed via `address(this)` self-calls where the test contract
    /// re-exposes the library) produce byte-identical outcomes for `args`: the
    /// same success flag and the same raw returndata. On the success path this
    /// compares the encoded return values; on the revert path it compares the
    /// revert selector and every encoded argument byte-for-byte.
    function assertEquivalence(bytes4 extSelector, bytes4 libSelector, bytes memory args) internal {
        (bool extSuccess, bytes memory extReturndata) = rawCall(address(extrospect), extSelector, args);
        (bool libSuccess, bytes memory libReturndata) = rawCall(address(this), libSelector, args);
        assertEq(extSuccess, libSuccess, "success flag mismatch");
        assertEq(extReturndata, libReturndata, "returndata mismatch");
    }
}
