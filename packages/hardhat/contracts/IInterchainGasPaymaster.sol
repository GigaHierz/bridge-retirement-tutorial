// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IInterchainGasPaymaster {
    function payForGas(
        uint32 messageId,
        uint32 _destination,
        uint32 gasAmount,
        address sender
    ) external view returns (address);
}
