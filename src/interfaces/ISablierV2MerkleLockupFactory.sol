// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";

import { ISablierV2MerkleLockupLL } from "./ISablierV2MerkleLockupLL.sol";
import { MerkleLockup } from "../types/DataTypes.sol";

/// @title ISablierV2MerkleLockupFactory
/// @notice Deploys new Lockup Linear Merkle lockups via CREATE2.
interface ISablierV2MerkleLockupFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Sablier V2 Lockup Linear Merkle Lockup is created.
    event CreateMerkleLockupLL(
        ISablierV2MerkleLockupLL indexed merkleLockupLL,
        MerkleLockup.ConstructorParams indexed baseParams,
        ISablierV2LockupLinear lockupLinear,
        LockupLinear.Durations streamDurations,
        uint256 aggregateAmount,
        uint256 recipientsCount
    );

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Merkle Lockup that uses Lockup Linear.
    /// @dev Emits a {CreateMerkleLockupLL} event.
    /// @param baseParams Struct encapsulating the {SablierV2MerkleLockup} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupLinear The address of the {SablierV2LockupLinear} contract.
    /// @param streamDurations The durations for each stream due to the recipient.
    /// @param aggregateAmount Total amount of ERC-20 assets to be streamed to all recipients.
    /// @param recipientsCount Total number of recipients eligible to claim.
    /// @return merkleLockupLL The address of the newly created Merkle Lockup contract.
    function createMerkleLockupLL(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierV2LockupLinear lockupLinear,
        LockupLinear.Durations memory streamDurations,
        uint256 aggregateAmount,
        uint256 recipientsCount
    )
        external
        returns (ISablierV2MerkleLockupLL merkleLockupLL);
}
