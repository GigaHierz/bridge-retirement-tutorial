// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IInterchainGasPaymaster.sol";
import "./interfaces/IInterchainAccountRouter.sol";
import "./RetirementHelper.sol";

contract CarbonRetirementBridge {
    // InterchainAccountRouter Addresses
    address interchainAccountAddress =
        0x6f393F8Dfb327d99c946e0Dd2f39F51B1aB446bf;
    // DomainIdentifier
    uint32 destinationDomain = 44787; // alfajores

    // init Router instance. this should be done in the constructor
    IInterchainAccountRouter public router =
        IInterchainAccountRouter(interchainAccountAddress);

    // get interchain Account to be able to prefund it
    function getRemoteInterchainAccount()
        public
        view
        returns (address _remoteAccount)
    {
        _remoteAccount = router.getRemoteInterchainAccount(
            destinationDomain, // destination
            address(this)
        );
    }

    function bridgeRetirement(
        address _retirementHelper,
        uint256 _amount,
        address[] memory _path,
        address _account,
        address _dexRouter
    ) public payable {
        // init instance of RetirementHelper
        RetirementHelper retirementHelper = RetirementHelper(_retirementHelper);

        // create function that you want to call in the destination
        Call[] memory offsetCall = new Call[](1);
        offsetCall[0] = Call({
            to: _retirementHelper,
            data: abi.encodeWithSignature(
                "retireFromAddress(uint256,address[],address,address)",
                _amount,
                _path,
                _account,
                _dexRouter
            ),
            value: 0
        });

        // call function on remote chain
        bytes32 messageId = router.callRemote(
            destinationDomain, // destination
            offsetCall
        );

        uint32 gasAmount = 150000;

        // The InterchainGasPaymaster
        IInterchainGasPaymaster igp = IInterchainGasPaymaster(
            0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a
        );
        // Pay with the msg.value
        igp.payForGas{value: msg.value}(
            // The ID of the message
            messageId,
            // Destination domain
            destinationDomain,
            // The total gas amount. This should be the
            // overhead gas amount + gas used by the call being made
            gasAmount,
            // Refund the msg.sender
            msg.sender
        );
    }
}
