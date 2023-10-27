# Carbon Retirement Bridge

Retiring Carbon Credits on Celo from any EVM-chain

---

Make your dApp carbon neutral and retire carbon credits on the climate-positive chain Celo using Hyperlane.

Creating a carbon-neutral dApp is increasingly common, and it should be as seamless as possible. We've received numerous requests from developers looking to integrate carbon offsetting into their applications. However, some face the challenge of deploying their dApps on chains where Toucan Protocol isn't available. Currently, Toucan Protocol is deployed on Celo and Polygon.

In this tutorial, we will explore how to retire carbon credits on Celo, a carbon-neutral chain and a leader in advocating for the ReFi movement. By the end of this tutorial, you'll be able to implement carbon retirement into your dApp, regardless of the EVM-compatible chain it's deployed on. Additionally, Hyperlane offers bridging capabilities for non-EVM-compatible chains; consult their documentation for further details.

In case you are new to retiring carbon credits with Toucan, please refer to these articles:

- [How to Retire Carbon Credits with Toucan Protocol - An Overview](#)
- [How to retire Carbon Credits using the OffsetHelper](#)

## What's the Process in Detail?

This tutorial will use the following tools:

- Celo-Composer
- Hyperlane V3
- OffsetHelper

Now, let's delve into the specifics of this tutorial. We'll guide you through these key steps:

1. **Using Hyperlane's Accounts API**: You'll learn how to employ Hyperlane's Accounts API to execute a function on a remote chain.
2. **Deploying a Warp Route with Hyperlane**: This section will walk you through the process of setting up a Warp Route with Hyperlane. This is a critical step to pre-fund the account on the remote chain.
3. **Calling a Function to Retire Carbon Credits**: You'll gain the knowledge and tools needed to call a function for retiring carbon credits on Celo from any EVM-compatible chain.

By following these steps, you'll be well-prepared to implement carbon offsetting and retirement of carbon credits for your dApp on various EVM-compatible chains, ensuring it aligns with your sustainability goals.

## Step 1: Utilize Hyperlane's Account API

When it comes to invoking a payable function on a different blockchain, you can harness the power of Hyperlane's Accounts API. It enables you to:

- Create Interchain Accounts: Set up Interchain Accounts, a fundamental requirement for executing cross-chain transactions.
- Create a Warp route: Ensuring that your Interchain Accounts are adequately funded is necessary to facilitate seamless cross-chain operations. As we call a function on a remote chain, we need to fund the account that will be calling the function on the remote chain.
- Call Functions Across Chains: Once you've established and pre-funded your Interchain Accounts, you can confidently call functions on remote chains as needed.

[Read more about Hyperlane's Accounts API in their documentation.](#)

### Configuring Interchain Account Addresses

To initiate a function call on a remote blockchain using Hyperlane, you'll work with the InterchainAccountRouter. It serves as the bridge to perform cross-chain functions. This key component consists of the following elements:

- The Interface of the Router: You'll define your interactions with the InterchainAccountRouter through its interface, specifying how data is exchanged between the chains.
- The Call Struct: In the context of cross-chain calls, the Call struct includes essential information, such as the destination address and the function data, necessary to execute functions on a remote blockchain.

```solidity
struct Call {
    address to;
    bytes data;
}

interface IInterchainAccountRouter {
    function callRemote(uint32 _destinationDomain, Call[] calldata calls) external returns (bytes32);

    function getRemoteInterchainAccount(uint32 _destination, address _owner) external view returns (address);
}
```

### Getting the Remote Interchain Account Addresses

Next, we will start writing our smart contract. Create a file called `CarbonRetirementBridge.sol` in your contracts folder. As mentioned before, we will need to call `callRemote()` from the Interchain Account Router instance to call a function on a remote chain. But before we can do that, we need to pre-fund the remote Interchain Account (ICA). We can call `getRemoteInterchainAccount()` to get the address of the remote ICA to pre-fund so we can pay for the transaction on the remote chain.

Sure, here is the provided text formatted in markdown:

## Step 2: Create Warp Route to Pre-Fund Remote IA

Now that we have the address of the remote ICA, we will have to set up a warp route to pre-fund it. For this part, we are following the "Deploy a Warp Route" tutorial.

But of course, first of all, we need to get some test tokens:

- Get test ETH from an Optimism Faucet to pay for gas fees.
- Get WETH from a faucet contract to bridge from OptimismGoerli to Alfajores.

To deploy the warp route, we use the hyperlane-deploy repository provided by Hyperlane. It includes a script to configure and deploy a Warp Route for your desired token. It is super easy to use, but don't follow the docs on GitHub as they are not up to date.

In the `hyperlane-deploy/config/warp_tokens.ts`, add the following info:

**Base:**

Your WarpRouteConfig must have exactly one base entry. Here, you will configure details about the token for which you are creating a warp route.

- `chainName`: Set this equal to the chain on which your token exists.
- `type`: Set this to `TokenType.collateral` to create a warp route for an ERC20/ERC721 token, or `TokenType.native` to create a warp route for a native token (e.g., Ether).
- `address`: If using `TokenType.collateral`, the address of the ERC20/ERC721 contract for which to create a route.
- `isNft`: If using `TokenType.collateral` for an ERC721 contract set to true.

**Synthetics:**

Your WarpRouteConfig must have at least one synthetics entry. Here, you will configure details about the remote chains supported by your warp route.

- `chainName`: Set this equal to the chain on which you want a wrapped version of your token.

```javascript
import { TokenType } from "@hyperlane-xyz/hyperlane-token";
import type { WarpRouteConfig } from "../src/warp/config";

// A config for deploying Warp Routes to a set of chains
// Not required for Hyperlane core deployments
export const warpRouteConfig: WarpRouteConfig = {
  base: {
    // Chain name must be in the Hyperlane SDK or in the chains.ts config
    chainName: "optimismgoerli",
    type: TokenType.collateral, //  TokenType.native or TokenType.collateral
    // If type is collateral, a token address is required:
    address: "0x32307adfFE088e383AFAa721b06436aDaBA47DBE", // weth - optimism

    // If the token is an NFT (ERC721), set to true:
    // isNft: boolean

    // Optionally, specify owner, mailbox, and interchainGasPaymaster addresses
    // If not specified, the Permissionless Deployment artifacts or the SDK's defaults will be used
  },
  synthetics: [
    {
      chainName: "alfajores",

      // Optionally specify a name, symbol, and totalSupply
      // If not specified, the base token's properties will be used

      // Optionally, specify owner, mailbox, and interchainGasPaymaster addresses
      // If not specified, the Permissionless Deployment artifacts or the SDK's defaults will be used
    },
  ],
};
```

This is all the information that we need to add. Now, we can deploy our warp route.

### Deployment of Core Contracts

We start by deploying all core contracts:

- `local`: The local chain on which Hyperlane is being deployed.
- `remotes`: The chains with which 'local' will be able to send and receive messages.
- `key`: A hexadecimal private key for transaction signing.

```bash
yarn ts-node scripts/deploy-hyperlane.ts --local optimismgoerli \
  --remotes  alfajores \
  --key <PRIVATE_KEY>
```

When the command finishes, it will output the list of contracts addresses to `hyperlane-deploy/artifacts/warp-token-addresses.json`.

The deployer will also output a token list file to `hyperlane-deploy/artifacts/warp-ui-token-list.ts` which can be used to Deploy a UI for your Warp Route.

### Deploy the Warp Route

Now we are ready to deploy the warp route by running the `deploy-warp-routes.ts` script:

- `key`: A hexadecimal private key for transaction signing.

```bash
yarn ts-node scripts/deploy-warp-routes.ts --key <PRIVATE_KEY>
```

Next, we can send funds to the remote Interchain Account:

- `origin`: The name of the chain that you are sending tokens from.
- `destination`: The name of the chain that you are sending tokens to.
- `wei`: The value of tokens to transfer, in wei.
- `recipient`: The address to send the tokens to on the destination chain, in our case the remote Interchain Account.
- `key`: A hexadecimal private key for transaction signing.

```bash
yarn ts-node scripts/test-warp-transfer.ts \
  --origin optimismgoerli --destination alfajores --wei 1 \
  --recipient 0x8a89B5fBDfE08A9EDEEA422114F2492e58e3804a \ ICA on alfajores
  --key <PRIVATE_KEY>
```

```

---

Step 3: Create a retirement contract
One important part of retiring carbon credits is that you want to have the retirement related to your address to claim the retirement. 
We are using the Toucan Quickstart Repo to create our function. 
We will have to create two new functions.
Call a swapper function so we can pay with an ERC20 token. 
Create an auto redeem function to redeem pool tokens for TCO2s
Create a retirement function that retires for another address.

Carbon Credit Retirement
In the receiver contract, we will
exchange WETH for NCT
exchange NCT for TCO2
retire TCO2

the first function we will create is called autoOffsetExactInToken():
This function allows users to offset carbon emissions using specific ERC20 tokens (WETH).
It swaps the provided ERC20 token for a Toucan pool token (NCT), redeems the pool token for TCO2 tokens, and retires the TCO2 tokens. Okay okay okay. This sounds maybe new to you. Check out this article that goes into detail on how the OffsetHelper works.

Swap ERC20 tokens
The swapExactOutToken() function, allows the swapping of eligible ERC20 tokens for pool tokens (BCT/NCT) on SushiSwap. Prior approval on the client side is required to use this function. It takes the following parameters:
_path: An array of token addresses that describe the swap path, indicating the tokens involved in the exchange.
_toAmount: The desired amount of the pool token (NCT/BCT) to be obtained through the swap.

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Swapper {
    using SafeERC20 for IERC20;

    // Dex Router Address
    address public dexRouterAddress;

   function swapExactOutToken(
        address[] memory _path,
        uint256 _toAmount
    ) public returns (uint256 amountIn) {
        // calculate path & amounts
        uint256[] memory expAmounts = calculateExactOutSwap(_path, _toAmount);
        amountIn = expAmounts[0];

        // transfer tokens
        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        // approve router
        IERC20(_path[0]).approve(dexRouterAddress, amountIn);

        // swap
        uint256[] memory amounts = IUniswapV2Router02(dexRouterAddress)
            .swapTokensForExactTokens(
                _toAmount,
                amountIn, // max. input amount
                _path,
                address(this),
                block.timestamp
            );

        // remove remaining approval if less input token was consumed
        if (amounts[0] < amountIn) {
            IERC20(_path[0]).approve(dexRouterAddress, 0);
        }
    }
}
Redeem pool tokens for TCO2s
The autoRedeem() function is responsible for redeeming a specified amount of NCT (or BCT) for TCO2 tokens. It requires prior approval on the client side. The function takes the following parameters:
_fromToken: The address of the token to be used for redemption, which could be NCT.
_amount: The amount of tokens to be redeemed.
The function returns two arrays: "tco2s," which contains the TCO2 addresses that were redeemed, and "amounts," an array specifying the amounts of each TCO2 token that was redeemed.

   function autoRedeem(
        address _fromToken,
        uint256 _amount
    ) public returns (address[] memory tco2s, uint256[] memory amounts) {
        require(
            IERC20(_fromToken).balanceOf(address(this)) >= _amount,
            "Insufficient NCT/BCT balance"
        );

        // instantiate pool token (NCT)
        IToucanPoolToken PoolTokenImplementation = IToucanPoolToken(_fromToken);

        // auto redeem pool token for TCO2; will transfer automatically picked TCO2 to this contract
        (tco2s, amounts) = PoolTokenImplementation.redeemAuto2(_amount);
    }
Retire from another address
We want the remote ICA to call the function and use our wallet address as the retirement address. This can be done with retireFrom() from the ToucanCarbonOffset contract. 
The function enables users to retire specific TCO2 tokens from another address. It takes the following parameters:
_tco2s: An array containing the addresses of the TCO2 tokens that the user intends to retire.
_amounts: An array specifying the amounts of ERC20 tokens to be swapped into the Toucan pool.
_account: The address with which the retirement is associated, related to the TCO2 addresses provided.

  function retireFrom(
        address[] memory _tco2s,
        uint256[] memory _amounts,
        address _account
    ) internal {
        uint256 tco2sLen = _tco2s.length;
        require(tco2sLen != 0, "Array empty");

        require(tco2sLen == _amounts.length, "Arrays unequal");

        for (uint i = 0; i < tco2sLen; i++) {
            if (_amounts[i] == 0) {
                continue;
            }
            require(
                IERC20(_tco2s[i]).balanceOf(address(this)) >= _amounts[i],
                "Insufficient TCO2 balance"
            );

            IToucanCarbonOffsets(_tco2s[i]).retireFrom(_account, _amounts[i]);
        }
    }

---

Okay. Now we have everything together and we can create our function, retireFromAddress() , which allows users to retire carbon credits and associate a specific address with the retirement. It follows these steps:
Acquire a pool token, for example, NCT, by performing a token swap on a decentralized exchange (DEX).
Redeem the obtained pool token for the oldest TCO2 tokens.
Retire the TCO2 tokens on behalf of a specified address.

Parameters:
_amount: The amount of ERC20 tokens to swap into the Toucan pool.
_path: An array of token addresses that outlines the swap path, e.g., [<WETH.address, cUSD.address, NCT.address>.
_account: The address that should be associated with the retirement.
_dexRouter: The address of the DEX Router used for the token swap.

Returns:
tco2s: An array of the TCO2 token addresses that were redeemed.
amounts: An array indicating the amounts of each TCO2 token that were redeemed.

    function retireFromAddress(
        uint256 _amount,
        address[] memory _path,
        address _account,
        address _dexRouter
    ) public returns (address[] memory tco2s, uint256[] memory amounts) {
        // deposit pool token from user to this contract
        Swapper(_dexRouter).swapExactInToken(_path, _amount);

        // redeem NCT for a sepcific TCO2
        (tco2s, amounts) = autoRedeem(_path[0], _amount);

        // retire the TCO2s to achieve offset from a different address
        retireFrom(tco2s, amounts, _account);
    }


    ---

Step 4: Create the remote call function
We now have everything to call a function on a remote chain.
RetirementHelper Interface
We are adding an interface for the RetirementHelper for the retireFromAddress() function. 

interface IRetirementHelper {
    function retireFromAddress(
        uint256 amount,
        address[] memory path,
        address account,
        address dexRouter
    ) external returns (address[] memory tco2s, uint256[] memory amounts);
}

contract CarbonRetirementBridge {

 // contract

}
So, now let's call the function with the Account API from Optimism on Celo. We also need to create a new function called addressToBytes32 because the to value of the Call takes bytes32 as input, so we need to cast the type of the RetirementHelper address to bytes32.
_retirementHelper: The address  of the RetirementHelper on the destination chain that you want to call a function from
_depositedToken: The address of the ERC20 token that the user sends
 (e.g., WETH)
_poolAddress: The address of the pool that the user wants to retire tokens from, e.g., NCT
_amount: The amount of ERC20 token to swap into pool token. The full amount will be used for the retirement.

function bridgeRetirement(
    address _retirementHelper,
    uint256 amount,
    address[] memory path,
    address account,
    address dexRouter
    ) public payable {
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

Pay for bridging with the InterchainGasPaymaster
Now, we are almost done. We still need to pay for gas for the bridging so that we will add the IInterchainGasPaymaster and we are done.
Create a new file called IInterchainGasPaymaster.sol and add this code:
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
In our bridgeRetirement function, we will have to store the return value of the remote call in a value that we call messageId. Then, we initialize an instance of the IInterchainGasPaymaster with the DefaultIsmInterchainGasPaymaster Address
messageId: The return value of the remote function call 
destinationDomain: The domain ID of the chain that you are sending tokens to
gasAmount: The total gas amount. This should be the overhead gas amount + gas used by the call being made. Overhead gasAmount should be 150.000 if the ICA doesn't exist yet and 30.000 if it does. 
msg.sender: Refund the message sender

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import {IInterchainAccountRouter, Call} from "./IInterchainAccountRouter.sol";
import {IInterchainGasPaymaster} from "./IInterchainGasPaymaster.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CarbonRetirementBridge {

uint32 destinationDomain = 44787; // alfajores


    function bridgeRetirement(
        address _offsetter,
        address _depositedToken,
        address _poolAddress,
        uint256 _amount
    ) public payable {

      // call function on remote chain
      bytes32 messageId = router.callRemote(
          destinationDomain, // destination
          offsetCall
      );

      // Then, pay for gas...

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

---

Now, deploy the contract, and you can finally retire carbon credits from any EVM chain you can think of. 

Implementing a Frontend
Hyperlane already comes with a UI for Warp Routes that you can use. 

Congratulations! You've successfully learned how to retire carbon credits from another EVM chain. 
Let's build!
Well, let's get your hands dirty and start building with Toucan
Toucan's Quickstart Repo
Toucan's docs
Toucan's SDK
Toucan's blog
```
