// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";
import {BogusBeacon} from "test/concrete/BogusBeacon.sol";
import {WrongLengthBeacon} from "test/concrete/WrongLengthBeacon.sol";
import {PermissiveFallbackContract} from "test/concrete/PermissiveFallbackContract.sol";
import {
    RevertingWithAddressBeacon,
    REVERTING_WITH_ADDRESS_BEACON_PAYLOAD
} from "test/concrete/RevertingWithAddressBeacon.sol";
import {ReturndataBombBeacon, RETURNDATA_BOMB_GAS_BUDGET} from "test/concrete/ReturndataBombBeacon.sol";
import {ExpensiveBeacon} from "test/concrete/ExpensiveBeacon.sol";
import {
    StrictCalldataBeacon,
    STRICT_CALLDATA_BEACON_IMPLEMENTATION,
    STRICT_CALLDATA_BEACON_OWNER
} from "test/concrete/StrictCalldataBeacon.sol";
import {
    LibEIP7702Designator,
    EIP7702_DELEGATION_PREFIX,
    EIP7702_DESIGNATOR_LENGTH
} from "test/lib/LibEIP7702Designator.sol";

/// @title LibExtrospectERC1967BeaconProxyIsBeaconOwnerTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
contract LibExtrospectERC1967BeaconProxyIsBeaconOwnerTest is Test {
    /// Returns true when the beacon's reported owner matches.
    function testMatches(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), own));
    }

    /// Returns false on a mismatch.
    function testMismatches(address impl, address own, address wrong) external {
        vm.assume(wrong != own);
        MockBeacon beacon = new MockBeacon(impl, own);
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), wrong));
    }

    /// A target with no `owner()` function and no fallback reverts the
    /// staticcall, so it fails the predicate. Returns false rather than
    /// reverting so integrators can collapse the check to a single
    /// boolean assertion.
    function testReturnsFalseOnNonOwnable(address expected) external {
        EmptyContract notOwnable = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(notOwnable), expected));
    }

    /// Non-fuzz pin at `expected = address(0)`: that value matches
    /// the zero address `_tryGetAddress` returns alongside `ok=false`,
    /// catching any code path that would compare `own == expected`
    /// without first checking `ok`.
    function testReturnsFalseOnNonOwnableWithZeroAddress() external {
        EmptyContract notOwnable = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(notOwnable), address(0)));
    }

    /// A beacon whose `owner()` reverts is also a failure for the
    /// predicate, returning false rather than propagating.
    function testReturnsFalseOnBeaconRevert(address expected) external {
        RevertingBeacon beacon = new RevertingBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), expected));
    }

    /// A beacon whose `owner()` returns bytes that don't decode as an
    /// `address` is also a failure for the predicate. High-level
    /// `try IOwnable(...).owner() returns (address)` lets the
    /// dirty-address Panic escape past `catch`, so the wrapper goes
    /// through a low-level staticcall and rejects 32-byte returndata
    /// whose upper 12 bytes are non-zero.
    function testReturnsFalseOnInvalidReturnEncoding(address expected) external {
        BogusBeacon beacon = new BogusBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), expected));
    }

    /// `address(type(uint160).max)` is the largest valid 160-bit
    /// address — the strict upper-bits check (`raw > type(uint160).max`)
    /// must accept it, not reject it.
    function testMatchesAtMaxAddressBoundary() external {
        address maxAddr = address(type(uint160).max);
        MockBeacon beacon = new MockBeacon(address(this), maxAddr);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), maxAddr));
    }

    /// A beacon whose `owner()` returns more than 32 bytes must also
    /// fail the predicate, even if the first 32 bytes happen to
    /// decode as a valid address. The expected owner here is
    /// `address(0x20)`, which is what the first 32 bytes of an empty
    /// `string memory` (the offset, `0x20`) would resolve to under a
    /// length-stripped impl — pinning the length check separately
    /// from the dirty-bits check.
    function testReturnsFalseOnWrongLengthReturn() external {
        WrongLengthBeacon beacon = new WrongLengthBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), address(uint160(0x20))));
    }

    /// A beacon whose `owner()` reverts with exactly 32 bytes that
    /// decode cleanly as an address must still fail the predicate. The
    /// revert data is byte-identical to a successful `address` return,
    /// so only the staticcall's `success` flag separates the two: a
    /// wrapper that ignored `success` would report
    /// `REVERTING_WITH_ADDRESS_BEACON_PAYLOAD` as the owner and return
    /// true here.
    function testReturnsFalseOnRevertWithAddressSizedData() external {
        RevertingWithAddressBeacon beacon = new RevertingWithAddressBeacon();
        assertFalse(
            LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), REVERTING_WITH_ADDRESS_BEACON_PAYLOAD)
        );
    }

    /// A target with no `owner()` function, but a fallback answering
    /// every selector with 32 clean bytes, passes the predicate. The
    /// fallback's return is byte-identical to a real `owner()` return,
    /// so the staticcall cannot separate the two. A comparison against
    /// any other address still fails, so the predicate is comparing
    /// the fallback's answer rather than ignoring it.
    function testAcceptsPermissiveFallbackAsOwner(address answer, address other) external {
        vm.assume(other != answer);
        PermissiveFallbackContract target = new PermissiveFallbackContract(answer);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(target), answer));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(target), other));
    }

    /// Non-fuzz pin at `answer = address(0)`: a fallback answering with
    /// 32 zero bytes reports `address(0)` as the owner, which the
    /// predicate accepts as a match for an `expectedOwner` of
    /// `address(0)`. The result is the same one a beacon that reports
    /// `address(0)` from a real `owner()` produces.
    function testAcceptsZeroReturningFallbackAsOwner() external {
        PermissiveFallbackContract target = new PermissiveFallbackContract(address(0));
        MockBeacon beacon = new MockBeacon(address(this), address(0));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(target), address(0)));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), address(0)));
    }

    /// An account whose code is an EIP-7702 delegation designator runs
    /// the delegate's code, so `owner()` is answered by the delegate
    /// and the predicate returns true for the delegating account. The
    /// predicate never reads the target's own code, so the designator
    /// is not distinguished from beacon-contract code.
    function testMatchesForDelegatedAccount(address own) external {
        MockBeacon delegate = new MockBeacon(address(this), own);
        address delegating = address(uint160(uint256(keccak256("delegating account"))));
        vm.etch(delegating, LibEIP7702Designator.designator(address(delegate)));

        assertEq(delegating.code.length, EIP7702_DESIGNATOR_LENGTH);
        assertEq(bytes3(delegating.code), EIP7702_DELEGATION_PREFIX);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(delegating, own));
    }

    /// Repointing an EIP-7702 delegation designator at a delegate that
    /// reports a different owner flips the predicate for the same
    /// address, with no change to the code of either delegate.
    function testDelegatedAccountRepointChangesResult(address own, address otherOwn) external {
        vm.assume(own != otherOwn);
        MockBeacon delegate = new MockBeacon(address(this), own);
        MockBeacon otherDelegate = new MockBeacon(address(this), otherOwn);
        address delegating = address(uint160(uint256(keccak256("delegating account"))));

        vm.etch(delegating, LibEIP7702Designator.designator(address(delegate)));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(delegating, own));

        vm.etch(delegating, LibEIP7702Designator.designator(address(otherDelegate)));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(delegating, own));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(delegating, otherOwn));
    }

    /// The predicate sends the bare 4 selector bytes with nothing after
    /// them, so a beacon that rejects any other calldata length still
    /// resolves.
    function testMatchesStrictCalldataBeacon() external {
        StrictCalldataBeacon beacon = new StrictCalldataBeacon();
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), STRICT_CALLDATA_BEACON_OWNER));
    }

    /// The staticcall forwards all the gas the predicate has, so a
    /// beacon whose `owner()` costs far more than a minimal getter
    /// still resolves.
    function testMatchesExpensiveBeacon() external {
        ExpensiveBeacon beacon = new ExpensiveBeacon(address(this), address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), address(this)));
    }

    /// A hostile beacon returning a blob sized to the caller's own gas
    /// budget still resolves to false through an external call boundary
    /// that caps the gas. Only `returndatasize()` is read to reject the
    /// wrong length; the blob itself is never copied into the caller's
    /// memory, so the caller never pays its memory expansion.
    function testReturnsFalseOnReturndataBomb() external {
        ReturndataBombBeacon beacon = new ReturndataBombBeacon();
        (bool success, bytes memory returnData) = address(this).staticcall{gas: RETURNDATA_BOMB_GAS_BUDGET}(
            abi.encodeCall(this.externalIsBeaconOwner, (address(beacon), address(this)))
        );
        assertTrue(success, "hostile beacon reverted the caller");
        assertFalse(abi.decode(returnData, (bool)));
    }

    /// External call boundary for `testReturnsFalseOnReturndataBomb`, so
    /// the predicate runs under a capped gas budget.
    function externalIsBeaconOwner(address beacon, address expectedOwner) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, expectedOwner);
    }
}
