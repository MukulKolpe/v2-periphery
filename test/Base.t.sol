// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IPRBProxy } from "@prb/proxy/interfaces/IPRBProxy.sol";
import { PRBProxyRegistry } from "@prb/proxy/PRBProxyRegistry.sol";
import { SablierV2Comptroller } from "@sablier/v2-core/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "@sablier/v2-core/SablierV2LockupLinear.sol";
import { SablierV2LockupDynamic } from "@sablier/v2-core/SablierV2LockupDynamic.sol";
import { SablierV2Lockup } from "@sablier/v2-core/abstracts/SablierV2Lockup.sol";
import { SablierV2NFTDescriptor } from "@sablier/v2-core/SablierV2NFTDescriptor.sol";
import { LockupLinear, LockupDynamic } from "@sablier/v2-core/types/DataTypes.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { AllowanceTransfer } from "permit2/AllowanceTransfer.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";
import { PermitHash } from "permit2/libraries/PermitHash.sol";

import { SablierV2ProxyTarget } from "src/SablierV2ProxyTarget.sol";
import { Permit2Params } from "src/types/DataTypes.sol";

import { Assertions } from "./helpers/Assertions.t.sol";
import { Defaults } from "./helpers/Defaults.t.sol";
import { Users } from "./helpers/Types.t.sol";
import { WETH } from "./mockups/WETH.t.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Assertions, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal immutable DOMAIN_SEPARATOR;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI");
    AllowanceTransfer internal permit2 = new AllowanceTransfer();
    WETH internal weth = new WETH();

    PRBProxyRegistry internal registry = new PRBProxyRegistry();
    IPRBProxy internal proxy;

    SablierV2Comptroller internal comptroller;
    SablierV2NFTDescriptor internal descriptor = new SablierV2NFTDescriptor();
    SablierV2LockupDynamic internal dynamic;
    SablierV2LockupLinear internal linear;
    SablierV2ProxyTarget internal target = new SablierV2ProxyTarget();

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users.admin = createUser("Admin");
        users.broker = createUser("Broker");
        users.recipient = createUser("Recipient");
        users.sender = createUser("Sender");

        // Deploy the Sablier V2 Core contracts.
        deployCore();

        // Deploy the sender's proxy contract.
        proxy = registry.deployFor(users.sender.addr);

        // Label all deployed contracts.
        vm.label({ account: address(dai), newLabel: "Dai" });
        vm.label({ account: address(permit2), newLabel: "Permit2" });
        vm.label({ account: address(proxy), newLabel: "Proxy" });
        vm.label({ account: address(registry), newLabel: "ProxyRegistry" });
        vm.label({ account: address(target), newLabel: "Target" });

        // Approve Permit2 to spend funds from the recipient.
        vm.startPrank({ msgSender: users.recipient.addr });
        dai.approve({ spender: address(permit2), amount: MAX_UINT256 });

        // Make the sender the default caller in the rest of test suite.
        changePrank({ msgSender: users.sender.addr });

        // Approve Permit2 to spend funds from the sender.
        dai.approve({ spender: address(permit2), amount: MAX_UINT256 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a user, labels its address, and funds it with 100k ETH and 1M dai units.
    function createUser(string memory name) internal returns (Account memory user) {
        user = makeAccount(name);
        vm.deal({ account: user.addr, newBalance: 100_000 ether });
        deal({ token: address(dai), to: user.addr, give: 1_000_000e18 });
    }

    /// @dev Deploys and labels the Sablier V2 Core contracts.
    function deployCore() internal {
        comptroller = new SablierV2Comptroller({ initialAdmin: users.admin.addr });
        linear = new SablierV2LockupLinear({
            initialAdmin: users.admin.addr,
            initialComptroller: comptroller,
            initialNFTDescriptor: descriptor
        });
        dynamic = new SablierV2LockupDynamic({
            initialAdmin: users.admin.addr,
            initialComptroller: comptroller,
            initialNFTDescriptor: descriptor,
            maxSegmentCount: Defaults.MAX_SEGMENT_COUNT
        });
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(dynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    function batchCreateWithDeltas() internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithDeltas,
            (dynamic, dai, Defaults.batchCreateWithDeltas(users, proxy), permit2Params(Defaults.TRANSFER_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function batchCreateWithDurations() internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithDurations,
            (linear, dai, Defaults.batchCreateWithDurations(users, proxy), permit2Params(Defaults.TRANSFER_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function batchCreateWithMilestones() internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithMilestones,
            (dynamic, dai, Defaults.batchCreateWithMilestones(users, proxy), permit2Params(Defaults.TRANSFER_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function batchCreateWithMilestones(uint48 nonce) internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithMilestones,
            (
                dynamic,
                dai,
                Defaults.batchCreateWithMilestones(users, proxy),
                permit2Params(Defaults.TRANSFER_AMOUNT, nonce)
            )
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function batchCreateWithRange() internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithRange,
            (linear, dai, Defaults.batchCreateWithRange(users, proxy), permit2Params(Defaults.TRANSFER_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function batchCreateWithRange(uint48 nonce) internal returns (uint256[] memory streamIds) {
        bytes memory data = abi.encodeCall(
            target.batchCreateWithRange,
            (linear, dai, Defaults.batchCreateWithRange(users, proxy), permit2Params(Defaults.TRANSFER_AMOUNT, nonce))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamIds = abi.decode(response, (uint256[]));
    }

    function createWithDeltas() internal returns (uint256 streamId) {
        bytes memory data = abi.encodeCall(
            target.createWithDeltas,
            (dynamic, Defaults.createWithDeltas(users, proxy, dai), permit2Params(Defaults.PER_STREAM_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamId = abi.decode(response, (uint256));
    }

    function createWithDurations() internal returns (uint256 streamId) {
        bytes memory data = abi.encodeCall(
            target.createWithDurations,
            (linear, Defaults.createWithDurations(users, proxy, dai), permit2Params(Defaults.PER_STREAM_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamId = abi.decode(response, (uint256));
    }

    function createWithMilestones() internal returns (uint256 streamId) {
        bytes memory data = abi.encodeCall(
            target.createWithMilestones,
            (dynamic, Defaults.createWithMilestones(users, proxy, dai), permit2Params(Defaults.PER_STREAM_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamId = abi.decode(response, (uint256));
    }

    function createWithRange() internal returns (uint256 streamId) {
        bytes memory data = abi.encodeCall(
            target.createWithRange,
            (linear, Defaults.createWithRange(users, proxy, dai), permit2Params(Defaults.PER_STREAM_AMOUNT))
        );
        bytes memory response = proxy.execute(address(target), data);
        streamId = abi.decode(response, (uint256));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL EXPECTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {SablierV2Lockup.cancel}.
    function expectCallToCancel(address lockup, uint256 streamId) internal {
        vm.expectCall({ callee: lockup, data: abi.encodeCall(SablierV2Lockup.cancel, (streamId)) });
    }

    /// @dev Expects a call to {SablierV2Lockup.cancelMultiple}.
    function expectCallToCancelMultiple(address lockup, uint256[] memory streamIds) internal {
        vm.expectCall({ callee: lockup, data: abi.encodeCall(SablierV2Lockup.cancelMultiple, (streamIds)) });
    }

    /// @dev Expects a call to {SablierV2LockupDynamic.createWithDeltas}.
    function expectCallToCreateWithDeltas(LockupDynamic.CreateWithDeltas memory params) internal {
        vm.expectCall({
            callee: address(dynamic),
            data: abi.encodeCall(SablierV2LockupDynamic.createWithDeltas, (params))
        });
    }

    /// @dev Expects a call to {SablierV2LockupLinear.createWithDurations}.
    function expectCallToCreateWithDurations(LockupLinear.CreateWithDurations memory params) internal {
        vm.expectCall({
            callee: address(linear),
            data: abi.encodeCall(SablierV2LockupLinear.createWithDurations, (params))
        });
    }

    /// @dev Expects a call to {SablierV2LockupDynamic.createWithMilestones}.
    function expectCallToCreateWithMilestones(LockupDynamic.CreateWithMilestones memory params) internal {
        vm.expectCall({
            callee: address(dynamic),
            data: abi.encodeCall(SablierV2LockupDynamic.createWithMilestones, (params))
        });
    }

    /// @dev Expects a call to {SablierV2LockupLinear.createWithRange}.
    function expectCallToCreateWithRange(LockupLinear.CreateWithRange memory params) internal {
        vm.expectCall({ callee: address(linear), data: abi.encodeCall(SablierV2LockupLinear.createWithRange, (params)) });
    }

    /// @dev Expects multiple calls to {SablierV2LockupDynamic.createWithMilestones}.
    function expectMultipleCallsToCreateWithDeltas(LockupDynamic.CreateWithDeltas memory params) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToCreateWithDeltas(params);
        }
    }

    /// @dev Expects multiple calls to {SablierV2LockupLinear.createWithDurations}.
    function expectMultipleCallsToCreateWithDurations(LockupLinear.CreateWithDurations memory params) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToCreateWithDurations(params);
        }
    }

    /// @dev Expects multiple calls to {SablierV2LockupDynamic.createWithMilestones}.
    function expectMultipleCallsToCreateWithMilestones(LockupDynamic.CreateWithMilestones memory params) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToCreateWithMilestones(params);
        }
    }

    /// @dev Expects multiple calls to {SablierV2LockupLinear.createWithRange}.
    function expectMultipleCallsToCreateWithRange(LockupLinear.CreateWithRange memory params) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToCreateWithRange(params);
        }
    }

    /// @dev Expects multiple calls to the `transfer` function of the default ERC-20 contract.
    function expectMultipleCallsToTransfer(address to, uint256 amount) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToTransfer(to, amount);
        }
    }

    /// @dev Expects multiple calls to the `transferFrom` function of the default ERC-20 contract.
    function expectMultipleCallsToTransferFrom(address from, address to, uint256 amount) internal {
        for (uint256 i = 0; i < Defaults.BATCH_SIZE; ++i) {
            expectCallToTransferFrom(from, to, amount);
        }
    }

    /// @dev Expects a call to the `transfer` function of the default ERC-20 contract.
    function expectCallToTransfer(address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(ERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to the `transferFrom` function of the default ERC-20 contract.
    function expectCallToTransferFrom(address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(ERC20.transferFrom, (from, to, amount)) });
    }

    /// @dev Expects a call to the `transferFrom` function of the provided ERC-20 contract.
    function expectCallToTransferFrom(address asset, address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: asset, data: abi.encodeCall(ERC20.transferFrom, (from, to, amount)) });
    }
    /*//////////////////////////////////////////////////////////////////////////
                                      PERMIT2
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to get the signature.
    function getPermit2Signature(
        IAllowanceTransfer.PermitDetails memory details,
        uint256 privateKey,
        address spender
    )
        internal
        view
        returns (bytes memory sig)
    {
        bytes32 permitHash = keccak256(abi.encode(PermitHash._PERMIT_DETAILS_TYPEHASH, details));
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(PermitHash._PERMIT_SINGLE_TYPEHASH, permitHash, spender, Defaults.PERMIT2_SIG_DEADLINE)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        sig = bytes.concat(r, s, bytes1(v));
    }

    function permit2Params(uint160 amount) internal view returns (Permit2Params memory) {
        return Permit2Params({
            expiration: Defaults.PERMIT2_EXPIRATION,
            permit2: permit2,
            sigDeadline: Defaults.PERMIT2_SIG_DEADLINE,
            signature: getPermit2Signature({
                details: Defaults.permitDetails(dai, amount),
                privateKey: users.sender.key,
                spender: address(proxy)
            })
        });
    }

    function permit2Params(uint160 amount, uint48 nonce) internal view returns (Permit2Params memory) {
        return Permit2Params({
            expiration: Defaults.PERMIT2_EXPIRATION,
            permit2: permit2,
            sigDeadline: Defaults.PERMIT2_SIG_DEADLINE,
            signature: getPermit2Signature({
                details: Defaults.permitDetails(dai, amount, nonce),
                privateKey: users.sender.key,
                spender: address(proxy)
            })
        });
    }
}
