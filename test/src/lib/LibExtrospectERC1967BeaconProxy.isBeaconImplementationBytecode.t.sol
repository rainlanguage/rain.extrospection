// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    SOLIDITY_CBOR_RUNTIME_FIXTURE,
    SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED
} from "test/concrete/SolidityCBORFixture.sol";
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
import {
    LibEIP7702Designator,
    EIP7702_DELEGATION_PREFIX,
    EIP7702_DESIGNATOR_LENGTH
} from "test/lib/LibEIP7702Designator.sol";

/// @title LibExtrospectERC1967BeaconProxyIsBeaconImplementationBytecodeTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
contract LibExtrospectERC1967BeaconProxyIsBeaconImplementationBytecodeTest is Test {
    /// Returns true when the beacon's implementation runtime hashes to
    /// the expected value.
    function testMatches() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(address(impl).code)
            )
        );
    }

    /// Returns false when the expected hash differs from the actual
    /// implementation runtime hash.
    function testMismatches(bytes32 wrongHash) external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        vm.assume(wrongHash != keccak256(address(impl).code));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrongHash));
    }

    /// A beacon whose `implementation()` returns `address(0)` resolves
    /// to an empty-code account; its hash is `keccak256("")`.
    function testImplementationZeroAddressHashesToEmpty(bytes32 wrongHash) external {
        bytes32 emptyHash = keccak256("");
        vm.assume(wrongHash != emptyHash);
        MockBeacon beacon = new MockBeacon(address(0), address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), emptyHash));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrongHash));
    }

    /// Every codeless implementation reads as empty bytecode, so
    /// `keccak256("")` is matched at a non-zero address the same way it
    /// is at `address(0)`. An unoccupied `CREATE2` target is codeless
    /// while the beacon already points at it, and deploying to that
    /// target turns the same call from true to false.
    function testCounterfactualImplementationMatchesEmptyHashUntilOccupied() external {
        bytes32 salt = bytes32(uint256(0x5eed));
        address counterfactual =
            vm.computeCreate2Address(salt, keccak256(type(EmptyContract).creationCode), address(this));
        assertEq(counterfactual.code.length, 0);
        assertTrue(counterfactual != address(0));

        MockBeacon beacon = new MockBeacon(counterfactual, address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));

        assertEq(address(new EmptyContract{salt: salt}()), counterfactual);
        assertGt(counterfactual.code.length, 0);

        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(counterfactual.code)
            )
        );
    }

    /// A target with no `implementation()` function and no fallback
    /// reverts the staticcall, so it fails the predicate. Returns false
    /// rather than reverting so integrators can collapse the check to a
    /// single boolean assertion.
    function testReturnsFalseOnNonBeacon(bytes32 expected) external {
        EmptyContract notABeacon = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(notABeacon), expected));
    }

    /// Non-fuzz pin at `expected = keccak256("")`: that value is also
    /// `keccak256(address(0).code)`, the value the predicate would
    /// compare against if it ever fell through to hashing
    /// `address(0).code` after a failed call.
    function testReturnsFalseOnNonBeaconWithEmptyHash() external {
        EmptyContract notABeacon = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(notABeacon), keccak256("")));
    }

    /// A beacon whose `implementation()` reverts is also a failure for
    /// the predicate, returning false rather than propagating.
    function testReturnsFalseOnBeaconRevert(bytes32 expected) external {
        RevertingBeacon beacon = new RevertingBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
    }

    /// A beacon whose `implementation()` returns bytes that don't
    /// decode as an `address` is also a failure for the predicate.
    /// High-level `try IBeacon(...).implementation() returns (address)`
    /// lets the dirty-address Panic escape past `catch`, so the
    /// wrapper goes through a low-level staticcall and rejects
    /// 32-byte returndata whose upper 12 bytes are non-zero.
    function testReturnsFalseOnInvalidReturnEncoding(bytes32 expected) external {
        BogusBeacon beacon = new BogusBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
    }

    /// `staticcall` to a no-code target (e.g. `address(0)`) returns
    /// success with empty returndata — distinct from a contract that
    /// reverts (success=false). Pins the length=0 path through the
    /// length check.
    function testReturnsFalseOnNoCodeTarget() external {
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(0), keccak256("")));
    }

    /// `address(type(uint160).max)` is the largest valid 160-bit
    /// address — the strict upper-bits check (`raw > type(uint160).max`)
    /// must accept it, not reject it.
    function testMatchesAtMaxAddressBoundary() external {
        address maxAddr = address(type(uint160).max);
        MockBeacon beacon = new MockBeacon(maxAddr, address(this));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256(maxAddr.code))
        );
    }

    /// A beacon whose `implementation()` returns more than 32 bytes
    /// must also fail the predicate, even if the first 32 bytes
    /// happen to decode as a valid address. Expected is `keccak256("")`
    /// — the value `keccak256(address(0x20).code)` resolves to (since
    /// `0x20` has no code), where `0x20` is the offset word at the
    /// start of an empty `string memory` encoding.
    function testReturnsFalseOnWrongLengthReturn() external {
        WrongLengthBeacon beacon = new WrongLengthBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));
    }

    /// A beacon whose `implementation()` reverts with exactly 32 bytes
    /// that decode cleanly as an address must still fail the predicate.
    /// The revert data is byte-identical to a successful `address`
    /// return, so only the staticcall's `success` flag separates the
    /// two: a wrapper that ignored `success` would decode
    /// `REVERTING_WITH_ADDRESS_BEACON_PAYLOAD`, whose (absent) code
    /// hashes to `keccak256("")`, and return true here.
    function testReturnsFalseOnRevertWithAddressSizedData() external {
        RevertingWithAddressBeacon beacon = new RevertingWithAddressBeacon();
        assertEq(keccak256(REVERTING_WITH_ADDRESS_BEACON_PAYLOAD.code), keccak256(""));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));
    }

    /// A target with no `implementation()` function, but a fallback
    /// answering every selector with 32 clean bytes, passes the
    /// predicate against the runtime hash of whatever address that
    /// fallback answers with. The fallback's return is byte-identical
    /// to a real `implementation()` return, so the staticcall cannot
    /// separate the two. A comparison against any other hash still
    /// fails, so the predicate is hashing the fallback's answer rather
    /// than ignoring it.
    function testAcceptsPermissiveFallbackAsImplementation(bytes32 wrongHash) external {
        EmptyContract impl = new EmptyContract();
        vm.assume(wrongHash != keccak256(address(impl).code));
        PermissiveFallbackContract target = new PermissiveFallbackContract(address(impl));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(target), keccak256(address(impl).code)
            )
        );
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(target), wrongHash));
    }

    /// Non-fuzz pin at `answer = address(0)`: a fallback answering with
    /// 32 zero bytes resolves to an empty-code account, so the
    /// predicate matches `keccak256("")` — the same result a beacon
    /// whose real `implementation()` returns `address(0)` produces.
    function testAcceptsZeroReturningFallbackAsImplementation() external {
        PermissiveFallbackContract target = new PermissiveFallbackContract(address(0));
        MockBeacon beacon = new MockBeacon(address(0), address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(target), keccak256("")));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));
    }

    /// An account whose code is an EIP-7702 delegation designator runs
    /// the delegate's code, so `implementation()` is answered by the
    /// delegate and the predicate returns true for the delegating
    /// account. The predicate never reads the target's own code, so the
    /// designator is not distinguished from beacon-contract code.
    function testMatchesForDelegatedAccountBeacon() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon delegate = new MockBeacon(address(impl), address(this));
        address delegating = address(uint160(uint256(keccak256("delegating beacon"))));
        vm.etch(delegating, LibEIP7702Designator.designator(address(delegate)));

        assertEq(delegating.code.length, EIP7702_DESIGNATOR_LENGTH);
        assertEq(bytes3(delegating.code), EIP7702_DELEGATION_PREFIX);
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(delegating, keccak256(address(impl).code))
        );
    }

    /// Repointing an EIP-7702 delegation designator at a delegate that
    /// reports a different implementation flips the predicate for the
    /// same address, with no change to the code of either delegate.
    function testDelegatedAccountBeaconRepointChangesResult() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon delegate = new MockBeacon(address(impl), address(this));
        MockBeacon otherDelegate = new MockBeacon(address(delegate), address(this));
        address delegating = address(uint160(uint256(keccak256("delegating beacon"))));

        vm.etch(delegating, LibEIP7702Designator.designator(address(delegate)));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(delegating, keccak256(address(impl).code))
        );

        vm.etch(delegating, LibEIP7702Designator.designator(address(otherDelegate)));
        assertFalse(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(delegating, keccak256(address(impl).code))
        );
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                delegating, keccak256(address(delegate).code)
            )
        );
    }

    /// When `implementation()` returns an account whose code is an
    /// EIP-7702 delegation designator, the hash compared is that of the
    /// 23-byte designator, not that of the delegate's runtime bytecode.
    function testDelegatedAccountImplementationHashesDesignator() external {
        MockBeacon delegate = new MockBeacon(address(this), address(this));
        address delegating = address(uint160(uint256(keccak256("delegating implementation"))));
        bytes memory designator = LibEIP7702Designator.designator(address(delegate));
        vm.etch(delegating, designator);
        MockBeacon beacon = new MockBeacon(delegating, address(this));

        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256(designator))
        );
        assertFalse(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(address(delegate).code)
            )
        );
    }

    /// The hash this predicate matches is `keccak256` of the
    /// implementation's whole runtime bytecode, CBOR metadata trailer
    /// included. The trimmed hash that
    /// `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash` matches for the
    /// same implementation is a different value, and is rejected here.
    function testRejectsCBORTrimmedHash() external {
        address impl = address(0xbeef);
        vm.etch(impl, SOLIDITY_CBOR_RUNTIME_FIXTURE);
        MockBeacon beacon = new MockBeacon(impl, address(this));

        assertEq(SOLIDITY_CBOR_RUNTIME_FIXTURE.length, SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED.length + 53);

        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE)
            )
        );
        assertFalse(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED)
            )
        );
    }
}
