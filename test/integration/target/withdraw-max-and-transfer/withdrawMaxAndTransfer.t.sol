// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "@sablier/v2-core/src/interfaces/ISablierV2Lockup.sol";
import { LockupDynamic, LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Target_Integration_Test } from "../Target.t.sol";

abstract contract WithdrawMaxAndTransfer_Integration_Test is Target_Integration_Test {
    function setUp() public virtual override { }

    function test_RevertWhen_NotDelegateCalled() external {
        vm.expectRevert(Errors.CallNotDelegateCall.selector);
        target.withdrawMaxAndTransfer({ lockup: lockupLinear, streamId: 0, newRecipient: users.recipient0.addr });
    }

    modifier whenDelegateCalled() {
        _;
    }

    function test_WithdrawMaxAndTransfer_LockupDynamic() external whenDelegateCalled {
        LockupDynamic.CreateWithMilestones memory params = defaults.createWithMilestones();
        params.recipient = address(aliceProxy);
        uint256 streamId = createWithMilestones(params);
        test_WithdrawMaxAndTransfer(lockupDynamic, streamId);
    }

    function test_WithdrawMaxAndTransfer_LockupLinear() external whenDelegateCalled {
        LockupLinear.CreateWithRange memory params = defaults.createWithRange();
        params.recipient = address(aliceProxy);
        uint256 streamId = createWithRange(params);
        test_WithdrawMaxAndTransfer(lockupLinear, streamId);
    }

    function test_WithdrawMaxAndTransfer(ISablierV2Lockup lockup, uint256 streamId) internal {
        // Simulate the passage of time.
        vm.warp(defaults.CLIFF_TIME());

        // Asset flow: Sablier → recipient
        expectCallToTransfer({ to: address(aliceProxy), amount: defaults.WITHDRAW_AMOUNT() });

        // Make the max withdrawal and transfer the NFT.
        bytes memory data = abi.encodeCall(target.withdrawMaxAndTransfer, (lockup, streamId, users.recipient0.addr));
        aliceProxy.execute(address(target), data);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has been transfered.
        address actualOwner = lockup.ownerOf(streamId);
        address expectedOwner = users.recipient0.addr;
        assertEq(actualOwner, expectedOwner, "owner");
    }
}
