// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title IExtrospectERC165V1
/// @notice Exposes `supportsInterface` defined by `ERC165`.
/// https://eips.ethereum.org/EIPS/eip-165
/// This interface is similar to the interface extrospection provided by the
/// `ERC1820` registry contract.
/// https://eips.ethereum.org/EIPS/eip-1820
interface IExtrospectERC165V1 {
    /// Emitted by `emitAccountSupportsInterface`.
    /// @param sender `msg.sender` calling to emit `AccountSupportsInterfaceV1`.
    /// @param account Account being checked for interface support.
    /// @param interfaceId The interface ID as per `ERC165`.
    /// @param supportsInterface `true` if `account` implements `interfaceId`.
    event AccountSupportsInterfaceV1(address sender, address account, bytes4 interfaceId, bool supportsInterface);

    /// Check if an account supports an interface as per `ERC165`.
    /// @param account Account being checked for interface support.
    /// @param interfaceId The interface ID as per `ERC165`.
    /// @return supportsInterface `true` if `account` implements `interfaceId`.
    function accountSupportsInterface(address account, bytes4 interfaceId)
        external
        view
        returns (bool supportsInterface);

    /// Emits whether an account supports an interface as per `ERC165`.
    /// The event MUST be equivalent to calling `accountSupportsInterface`.
    /// @param account Account being checked for interface support.
    /// @param interfaceId The interface ID as per `ERC165`.
    function emitAccountSupportsInterface(address account, bytes4 interfaceId) external;
}
