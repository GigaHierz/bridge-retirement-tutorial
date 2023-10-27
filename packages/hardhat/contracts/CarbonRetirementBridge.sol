//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import {IInterchainAccountRouter, Call} from "./IInterchainAccountRouter.sol";
import {IInterchainGasPaymaster} from "./IInterchainGasPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRetirementHelper {
    function retireFromAddress(
        uint256 amount,
        address[] memory path,
        address account,
        address dexRouter
    ) external returns (address[] memory tco2s, uint256[] memory amounts);
}

contract CarbonRetirementBridge {
    using SafeERC20 for IERC20;

    // InterchainAccountRouter Addresses
    address optimismGoerliHyperlaneRouter =
        0x6f393F8Dfb327d99c946e0Dd2f39F51B1aB446bf;

    address retirementHelperAddress =
        0x0CcB0071e8B8B716A2a5998aB4d97b83790873Fe; // alfajores

    address weth = 0x32307adfFE088e383AFAa721b06436aDaBA47DBE; // optimism

    // gaslimit
    uint32 gasAmount = 150000;

    // DomainIdentifier
    uint32 destinationDomain = 44787; // alfajores

    IInterchainAccountRouter public router;
    IOffsetHelper public offsetHelper;

    constructor() {}

    // get interchain Account to be able to prefund it
    function getRemoteInterchainAccount()
        public
        view
        returns (address _remoteAccount)
    {
        _remoteAccount = IInterchainAccountRouter(optimismGoerliHyperlaneRouter)
            .getRemoteInterchainAccount(
                destinationDomain, // destination
                address(this)
            );
    }

    function bridgeRetirement(
        address _retirementHelper,
        uint256 amount,
        address[] memory path,
        address account,
        address dexRouter
    ) public payable {
        // Call the "approve" function of the ERC20 token contract
        require(
            IERC20(_depositedToken).approve(address(this), _amount),
            "Approval failed"
        );

        // create function that you want to call in the destination
        Call[] memory offsetCall = new Call[](1);
        offsetCall[0] = Call({
            to: addressToBytes32(address(_retirementHelper)),
            data: abi.encodeWithSignature(
                "retireFromAddress(uint256,address[],address,address)",
                _depositedToken,
                _poolAddress,
                _amount
            ),
            value: 0
        });

        // call function on remote chain
        router.callRemote(
            destinationDomain, // destination
            offsetCall
        );

        // Then, pay for gas

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

    function addressToBytes32(
        address _address
    ) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            mstore(result, _address)
        }
        return result;
    }
}
