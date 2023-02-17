// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ISablierV2Lockup } from "@sablier/v2-core/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupLinear } from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "@sablier/v2-core/interfaces/ISablierV2LockupPro.sol";
import { LockupLinear, LockupPro } from "@sablier/v2-core/types/DataTypes.sol";

import { ISablierV2ProxyTarget } from "./interfaces/ISablierV2ProxyTarget.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { CreateLinear, CreatePro } from "./types/DataTypes.sol";

contract SablierV2ProxyTarget is ISablierV2ProxyTarget {
    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2ProxyTarget
    function cancel(ISablierV2Lockup lockup, uint256 streamId) external {
        lockup.cancel(streamId);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function cancelMultiple(ISablierV2Lockup lockup, uint256[] calldata streamIds) external {
        lockup.cancelMultiple(streamIds);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function renounce(ISablierV2Lockup lockup, uint256 streamId) external {
        lockup.renounce(streamId);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function withdraw(ISablierV2Lockup lockup, uint256 streamId, address to, uint128 amount) external {
        lockup.withdraw(streamId, to, amount);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function withdrawMax(ISablierV2Lockup lockup, uint256 streamId, address to) external {
        lockup.withdrawMax(streamId, to);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithDurations(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithDurations calldata params
    ) external override returns (uint256 streamId) {
        streamId = linear.createWithDurations(params);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithRange(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithRange calldata params
    ) external override returns (uint256 streamId) {
        streamId = linear.createWithRange(params);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithDurationsMultiple(
        ISablierV2LockupLinear linear,
        CreateLinear.DurationsParams[] calldata params,
        IERC20 asset,
        uint128 totalAmount
    ) external override returns (uint256[] memory streamIds) {
        uint128 amountsSum;
        uint256 count = params.length;
        uint256 i;

        // Calculate the params amounts summed up.
        for (i = 0; i < count; ) {
            amountsSum += params[i].amount;
            unchecked {
                i += 1;
            }
        }

        // Checks: validate the arguments.
        Helpers.checkCreateMultipleParams(count, totalAmount, amountsSum);

        // Interactions: perform the ERC-20 transfer and approve the sablier contract to spend the amount of assets.
        Helpers.transferAndApprove(address(linear), asset, totalAmount);

        // Declare an array of `count` length to avoid "Index out of bounds error".
        uint256[] memory _streamIds = new uint256[](count);
        for (i = 0; i < count; ) {
            // Interactions: make the external call.
            _streamIds[i] = Helpers.callCreateWithDurations(params[i], asset, linear);

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }

        streamIds = _streamIds;
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithRangeMultiple(
        ISablierV2LockupLinear linear,
        CreateLinear.RangeParams[] calldata params,
        IERC20 asset,
        uint128 totalAmount
    ) external override returns (uint256[] memory streamIds) {
        uint128 amountsSum;
        uint256 count = params.length;
        uint256 i;

        // Calculate the params amounts summed up.
        for (i = 0; i < count; ) {
            amountsSum += params[i].amount;
            unchecked {
                i += 1;
            }
        }

        // Checks: validate the arguments.
        Helpers.checkCreateMultipleParams(count, totalAmount, amountsSum);

        // Interactions: perform the ERC-20 transfer and approve the sablier contract to spend the amount of assets.
        Helpers.transferAndApprove(address(linear), asset, totalAmount);

        // Declare an array of `count` length to avoid "Index out of bounds error".
        uint256[] memory _streamIds = new uint256[](count);
        for (i = 0; i < count; ) {
            // Interactions: make the external call.
            _streamIds[i] = Helpers.callCreateWithRange(params[i], asset, linear);

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }

        streamIds = _streamIds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-LOCKUP-PRO
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithDelta(
        ISablierV2LockupPro pro,
        LockupPro.CreateWithDeltas calldata params
    ) external override returns (uint256 streamId) {
        streamId = pro.createWithDeltas(params);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithMilestones(
        ISablierV2LockupPro pro,
        LockupPro.CreateWithMilestones calldata params
    ) external override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(params);
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithDeltasMultiple(
        ISablierV2LockupPro pro,
        CreatePro.DeltasParams[] calldata params,
        IERC20 asset,
        uint128 totalAmount
    ) external override returns (uint256[] memory streamIds) {
        uint128 amountsSum;
        uint256 count = params.length;
        uint256 i;

        // Calculate the params amounts summed up.
        for (i = 0; i < count; ) {
            amountsSum += params[i].amount;
            unchecked {
                i += 1;
            }
        }

        // Checks: validate the arguments.
        Helpers.checkCreateMultipleParams(count, totalAmount, amountsSum);

        // Interactions: perform the ERC-20 transfer and approve the sablier contract to spend the amount of assets.
        Helpers.transferAndApprove(address(pro), asset, totalAmount);

        // Declare an array of `count` length to avoid "Index out of bounds error".
        uint256[] memory _streamIds = new uint256[](count);
        for (i = 0; i < count; ) {
            // Interactions: make the external call.
            _streamIds[i] = Helpers.callCreateWithDeltas(params[i], asset, pro);

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }

        streamIds = _streamIds;
    }

    /// @inheritdoc ISablierV2ProxyTarget
    function createWithMilestonesMultiple(
        ISablierV2LockupPro pro,
        CreatePro.MilestonesParams[] calldata params,
        IERC20 asset,
        uint128 totalAmount
    ) external override returns (uint256[] memory streamIds) {
        uint128 amountsSum;
        uint256 count = params.length;
        uint256 i;

        // Calculate the params amounts summed up.
        for (i = 0; i < count; ) {
            amountsSum += params[i].amount;
            unchecked {
                i += 1;
            }
        }

        // Checks: validate the arguments.
        Helpers.checkCreateMultipleParams(count, totalAmount, amountsSum);

        // Interactions: perform the ERC-20 transfer and approve the sablier contract to spend the amount of assets.
        Helpers.transferAndApprove(address(pro), asset, totalAmount);

        // Declare an array of `count` length to avoid "Index out of bounds error".
        uint256[] memory _streamIds = new uint256[](count);
        for (i = 0; i < count; ) {
            // Interactions: make the external call.
            _streamIds[i] = Helpers.callCreateWithMilestones(params[i], asset, pro);

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }

        streamIds = _streamIds;
    }
}
