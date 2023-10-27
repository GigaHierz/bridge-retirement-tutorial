// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

struct Call {
    // not supporting non-EVM targets
    address to;
    bytes data;
}

interface IInterchainAccountRouter {
    function callRemote(
        uint32 _destinationDomain,
        Call[] calldata calls
    ) external returns (bytes32);

    function getRemoteInterchainAccount(
        uint32 _destination,
        address _owner
    ) external view returns (address);
}
