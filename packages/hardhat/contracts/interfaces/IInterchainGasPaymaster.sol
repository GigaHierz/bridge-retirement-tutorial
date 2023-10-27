// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 messageId,
        uint32 _destination,
        uint32 gasAmount,
        address sender
    ) external payable returns (address);
}
