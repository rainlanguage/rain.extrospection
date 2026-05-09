// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IExtrospectV1} from "../interface/IExtrospectV1.sol";
import {LibExtrospectBytecode} from "../lib/LibExtrospectBytecode.sol";
import {LibExtrospectMetamorphic} from "../lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectERC1167Proxy} from "../lib/LibExtrospectERC1167Proxy.sol";
import {LibExtrospectERC1967BeaconProxy} from "../lib/LibExtrospectERC1967BeaconProxy.sol";

/// @dev Deterministic address that `Extrospect`'s creation code lands at when
/// deployed via the Zoltu factory (CREATE2, salt = 0). Pinned so the deploy
/// script can verify the broadcast hits the expected address. If this drifts
/// the source has changed and the new address must be substituted; a single
/// test (`testExtrospectZoltuAddress`) fails loud at that point.
address constant EXTROSPECT_ZOLTU_ADDRESS_V1 = address(0x1BE878af679C1a0A6AC15108b0F4398de1f94506);

/// @dev Expected runtime codehash of `Extrospect` after deploy. Pinned for
/// post-deploy verification by the rain.deploy library.
bytes32 constant EXTROSPECT_RUNTIME_CODEHASH_V1 = 0x6f34c52c30411783d48eb81ac33c9cf7c108e61f86b2c5403ad49c8680cc71cf;

/// @dev Pinned creation bytecode of `Extrospect`. The deploy script and
/// downstream consumers broadcast these exact bytes via the Zoltu factory so
/// the deterministic address `EXTROSPECT_ZOLTU_ADDRESS_V1` is reached on every
/// chain regardless of which compiler / optimizer settings the consumer uses
/// to import this contract. `testExtrospectCreationBytecode` pins this
/// against `type(Extrospect).creationCode` so a source change forces a
/// constant update.
bytes constant EXTROSPECT_CREATION_BYTECODE_V1 = hex"6080604052348015600e575f80fd5b50610bc78061001c5f395ff3fe608060405234801561000f575f80fd5b50600436106100cf575f3560e01c8063b0f6344e1161007d578063e84ac49c11610058578063e84ac49c146101cf578063e8584930146101f0578063ec42dbb114610203575f80fd5b8063b0f6344e1461016a578063b5bf101e146101a9578063b8470cda146101bc575f80fd5b80637c2ac141116100ad5780637c2ac141146101315780639f4a3a2c14610144578063a759327c14610157575f80fd5b80632b597859146100d35780635875b34d146100e8578063708d44971461010e575b5f80fd5b6100e66100e13660046109f7565b610216565b005b6100fb6100f63660046109f7565b610222565b6040519081526020015b60405180910390f35b61012161011c3660046109f7565b610232565b6040519015158152602001610105565b6100fb61013f3660046109f7565b61023c565b610121610152366004610ae3565b610246565b6100fb6101653660046109f7565b610258565b61017d6101783660046109f7565b610262565b60408051921515835273ffffffffffffffffffffffffffffffffffffffff909116602083015201610105565b6100e66101b7366004610b0b565b610276565b6101216101ca366004610b24565b61027f565b6101e26101dd3660046109f7565b61028a565b604051610105929190610b55565b6100e66101fe3660046109f7565b61029c565b6100e6610211366004610ae3565b6102a5565b61021f816102b3565b50565b5f61022c826102f3565b92915050565b5f61022c82610361565b5f61022c82610382565b5f61025183836103b4565b9392505050565b5f61022c82610432565b5f8061026d836104e2565b91509150915091565b61021f816105ed565b5f610251838361066b565b5f6060610296836106dd565b93915050565b61021f81610790565b6102af82826107dc565b5050565b6102bc81610361565b1561021f576040517f6facd91b00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b5f6102fd826102b3565b815182908082015b80831015610359576001928301805160ff1693841b9490941793927fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa001602081101561035357928301600101925b50610305565b505050919050565b5f600282511061037d5761ffff60028301511661ef0081149150505b919050565b5f7f80350000000000000000000000000000000000000000000000000000000000006103ad83610432565b1692915050565b5f80806103e1857f5c60da1b000000000000000000000000000000000000000000000000000000006108a5565b915091508180156104295750838173ffffffffffffffffffffffffffffffffffffffff16803b806020016040519081016040528181525f908060200190933c80519060200120145b95945050505050565b5f61043c826102b3565b81518290605b7fe0080000000000000000000000000000000000000040000000000000000000018284015f5b818610156104d75760018601955060ff86511660608103602081101561049057968701600101965b508180156104a457600181146104bf575f80fd5b6001821b988917988516156104b857600192505b5050610468565b8582036104b857506001901b9690961795505f610468565b505050505050919050565b80515f908190602d146104f957505f928392509050565b604080518082018252600a8082527f363d3d373d3d3d363d73000000000000000000000000000000000000000000006020928301528582018190208351808501909452600f8085527f5af43d82803e903d91602b57fd5bf3000000000000000000000000000000000094840194909452603e8701939093207f63d391efc3119310b9796819854d0555ea77fb380e9ef5190c2359a8094c1f3c9384147f11a195f66c9175f46895bae2006d40848a680c7068b9fc4af248ff9a54a47e45909114166001169450909184156105e557601e86015173ffffffffffffffffffffffffffffffffffffffff1693505b505050915091565b5f8173ffffffffffffffffffffffffffffffffffffffff16803b806020016040519081016040528181525f908060200190933c90505f61062c826106dd565b90508015610666576040517f5b529f0900000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b505050565b5f8080610698857f8da5cb5b000000000000000000000000000000000000000000000000000000006108a5565b9150915081801561042957508373ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16149250505092915050565b5f6106e7826102b3565b81516035811061078a578083017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe081015174ffffffffffffffff000000000000000000000000009081165f90815291516affffffffffff000000ffff90811660205260409092207f0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c628082149550919291908515610785576035850387525b505050505b50919050565b5f61079a82610382565b905080156102af576040517f7a92f35a000000000000000000000000000000000000000000000000000000008152600481018290526024015b60405180910390fd5b5f8273ffffffffffffffffffffffffffffffffffffffff16803b806020016040519081016040528181525f908060200190933c90505f61081b826106dd565b905080610854576040517f2e2af59600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b8151602083012083811461089e576040517fdfb87a5300000000000000000000000000000000000000000000000000000000815260048101859052602481018290526044016107d3565b5050505050565b60408051600481526024810182526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff00000000000000000000000000000000000000000000000000000000851617905290515f9182918291829173ffffffffffffffffffffffffffffffffffffffff88169161092891610bb1565b5f60405180830381855afa9150503d805f8114610960576040519150601f19603f3d011682016040523d82523d5f602084013e610965565b606091505b509150915081158061097957508051602014155b1561098b575f809350935050506109c3565b602081015173ffffffffffffffffffffffffffffffffffffffff8111156109ba575f80945094505050506109c3565b60019450925050505b9250929050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b5f60208284031215610a07575f80fd5b813567ffffffffffffffff80821115610a1e575f80fd5b818401915084601f830112610a31575f80fd5b813581811115610a4357610a436109ca565b604051601f82017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0908116603f01168101908382118183101715610a8957610a896109ca565b81604052828152876020848701011115610aa1575f80fd5b826020860160208301375f928101602001929092525095945050505050565b803573ffffffffffffffffffffffffffffffffffffffff8116811461037d575f80fd5b5f8060408385031215610af4575f80fd5b610afd83610ac0565b946020939093013593505050565b5f60208284031215610b1b575f80fd5b61025182610ac0565b5f8060408385031215610b35575f80fd5b610b3e83610ac0565b9150610b4c60208401610ac0565b90509250929050565b8215158152604060208201525f82518060408401528060208501606085015e5f6060828501015260607fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0601f8301168401019150509392505050565b5f82518060208501845e5f92019182525091905056";

/// @title Extrospect
/// @notice Concrete implementation of `IExtrospectV1`. Parameterless
/// constructor for deterministic Zoltu deployment across EVM networks.
/// Consumers should depend on `IExtrospectV1` rather than importing this
/// contract directly.
contract Extrospect is IExtrospectV1 {
    /// @inheritdoc IExtrospectV1
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expected);
    }

    /// @inheritdoc IExtrospectV1
    function checkNoSolidityCBORMetadata(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// @inheritdoc IExtrospectV1
    function checkNotEOFBytecode(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function checkNotMetamorphic(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(beacon, expectedRuntimeHash);
    }

    /// @inheritdoc IExtrospectV1
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, expectedOwner);
    }

    /// @inheritdoc IExtrospectV1
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool) {
        return LibExtrospectBytecode.isEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address) {
        // False positive: tuple pass-through — both components re-emitted as this
        // function's own return, nothing discarded.
        // slither-disable-next-line unused-return
        return LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode)
    {
        didTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode);
        return (didTrim, bytecode);
    }
}
