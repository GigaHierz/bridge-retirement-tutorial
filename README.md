# Carbon Retirement Bridge

Retiring Carbon Credits on Celo from any EVM-chain.
Check out the whole tutorial on [Medium](https://medium.com/@hierzilena/retiring-carbon-credits-on-celo-from-any-evm-chain-e4966add6bd0)

---

# Make Your dApp Carbon Neutral and Retire Carbon Credits on Celo with Hyperlane

Create a carbon-neutral dApp and retire carbon credits on the climate-positive chain [Celo](https://celo.org/) using [Hyperlane](https://www.hyperlane.xyz/).

Creating a carbon-neutral dApp is increasingly common, and it should be as seamless as possible. We’ve received numerous requests from developers looking to integrate carbon offsetting into their applications. However, some face the challenge of deploying their dApps on chains where Toucan Protocol isn’t available. Currently, Toucan Protocol is deployed on Celo and Polygon.

In this tutorial, we will explore how to retire carbon credits on Celo, a carbon-neutral chain and a leader in advocating for the ReFi movement. By the end of this tutorial, you’ll be able to implement carbon retirement into your dApp, regardless of the EVM-compatible chain it’s deployed on. Additionally, Hyperlane offers bridging capabilities for non-EVM-compatible chains; consult their documentation for further details.

In case you are new to retiring carbon credits with Toucan, please refer to these articles:

- [How to Retire Carbon Credits with Toucan Protocol — An Overview](https://medium.com/@hierzilena/how-to-retire-carbon-credits-with-toucan-protocol-an-overview-b3af044a5b59)
- [How to retire Carbon Credits using the OffsetHelper](https://medium.com/@hierzilena/how-to-retire-carbon-credits-using-the-offsethelper-8bc02a61f48a)

## What’s the Process in Detail?

This tutorial will use the following tools:

- [Hyperlane V3](https://docs.hyperlane.xyz/docs/introduction/readme)
- [Toucan Quickstarter](https://github.com/GigaHierz?tab=repositories)

Now, let’s delve into the specifics of this tutorial. We’ll guide you through these key steps:

1. **Using [Hyperlane’s Accounts API](<(https://docs.hyperlane.xyz/docs/apis-and-sdks/accounts#overhead-gas-amounts)>):** You’ll learn how to employ Hyperlane’s Accounts API to execute a function on a remote chain.

2. **Deploying a [Warp Route](https://docs.hyperlane.xyz/docs/deploy/deploy-warp-route/deploy-a-warp-route) with Hyperlane:** This section will walk you through the process of setting up a Warp Route with Hyperlane. This is a critical step to pre-fund the account on the remote chain.

3. **Calling a Function to Retire Carbon Credits from another address:** You’ll gain the knowledge and tools needed to call a function for retiring carbon credits on Celo from another address.

By following these steps, you’ll be well-prepared to implement carbon offsetting and retirement of carbon credits for your dApp on various EVM-compatible chains, ensuring it aligns with your sustainability goals.

We will use the [Toucan Quickstarter](https://github.com/GigaHierz/toucan-quickstart), which is based on the [Celo-Composer](https://github.com/celo-org/celo-composer) as our starter template for this tutorial. Create a fork of the Toucan Quickstarter, and let’s get started with cloning it to your local machine.

```shell
git clone git@github.com:GigaHierz/toucan-quickstart.git
```

## Step 1: Utilize Hyperlane’s Account API

When it comes to invoking a payable function on a different blockchain, you use [Hyperlane’s Accounts API](https://docs.hyperlane.xyz/docs/apis-and-sdks/accounts). It enables you to:

- Create Interchain Accounts: Set up Interchain Accounts, a fundamental requirement for executing cross-chain transactions.
- Create a Warp route: Ensuring that your Interchain Accounts are adequately funded is necessary to facilitate seamless cross-chain operations. As we call a function on a remote chain, we need to fund the account that will be calling the function on the remote chain.
- Call Functions Across Chains: Once you’ve established and pre-funded your Interchain Accounts, you can confidently call functions on remote chains as needed.

Read more about Hyperlane's Account API in their [documentation](https://docs.hyperlane.xyz/docs/apis-and-sdks/accounts).

### Configuring Interchain Account Addresses

To initiate a function call on a remote blockchain using Hyperlane, you’ll work with the InterchainAccountRouter. It serves as the bridge to perform cross-chain functions. This key component consists of the following elements:

- The Interface of the Router: You’ll define your interactions with the InterchainAccountRouter through its interface, specifying how data is exchanged between the chains.
- The Call Struct: In the context of cross-chain calls, the Call struct includes essential information, such as the destination address and the function data, necessary to execute functions on a remote blockchain.

#### Interface

Add a file to your `packages/hardhat/contracts/interfaces` folder, called `IInterchainAccountRouter.sol`. In this file, we add the interface of the `IInterchainAccountRouter`.

We are also defining the `Call` struct here, where we define our call to the remote function. As input, it takes:

- `address`: the address of the contract we want to call
- `data`: takes the encoded function name and function input

```typescript
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

struct Call {
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
```

## User

### Getting the Remote Interchain Account Addresses

Next, we will start writing our smart contract. Create a file called `CarbonRetirementBridge.sol` in `packages/hardhat/contracts/`.

As mentioned before, we will need to call `callRemote()` from the Interchain Account Router instance to call a function on a remote chain. But before we can do that, we need to pre-fund the remote Interchain Account (ICA). We can call `getRemoteInterchainAccount()` to get the address of the remote ICA to pre-fund so we can pay for the transaction on the remote chain.

**Inputs are:**

- [`interchainAccountAddress`](https://docs.hyperlane.xyz/docs/resources/domains): Address of the API to create and control an account on a remote chain from their local chain.
- [`destinationDomain`](https://docs.hyperlane.xyz/docs/resources/domains): Reference Hyperlane supported chains.

```typescript
contract CarbonRetirementBridge {

  // InterchainAccountRouter Addresses
  address interchainAccountAddress =
      0x6f393F8Dfb327d99c946e0Dd2f39F51B1aB446bf;
  // DomainIdentifier
  uint32 destinationDomain = 44787; // alfajores

  // init Router instance. this should be done in the constructor
  IInterchainAccountRouter public router;
  router = IInterchainAccountRouter(interchainAccountAddress);

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
}
```

## Step 2: Create Warp Route to Pre-Fund Remote ICA

Now that we have the address of the remote ICA, we will have to set up a warp route to pre-fund it. For this part, we are following the “[Deploy a Warp Route](https://docs.hyperlane.xyz/docs/deploy/deploy-warp-route/deploy-a-warp-route” tutorial.

### First of all, we need to get some test tokens:

- Get test ETH from an [Optimism Faucet](https://community.optimism.io/docs/useful-tools/faucets/) to pay for gas fees.
- Get WETH from a [faucet contract](https://community.optimism.io/docs/useful-tools/faucets/) to bridge from OptimismGoerli to Alfajores.

### Puppy getting too much money

To deploy the warp route, we use the [hyperlane-deploy](https://github.com/hyperlane-xyz/hyperlane-deploy) repository provided by Hyperlane. It includes a script to configure and deploy a Warp Route for your desired token. It is super easy to use, but don’t follow the docs in GitHub, as they are not up to date. Start by forking the repository and cloning it to your local machine:

```bash
git clone git@github.com:hyperlane-xyz/hyperlane-deploy.git
```

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

```typescript
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

The deployer will also output a token list file to `hyperlane-deploy/artifacts/warp-ui-token-list.ts` which can be used to [Deploy a UI for your Warp Route](https://docs.hyperlane.xyz/docs/deploy/deploy-warp-route/deploy-the-ui-for-your-warp-route).

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

---

## Step 3: Create a Retirement Contract

One important part of retiring carbon credits is that you want to have the retirement related to your address to claim the retirement.

We are using the [Toucan Quickstart Repo](https://github.com/GigaHierz/toucan-quickstart) to create our function. There, we will have to create two new functions.

1. Call a swapper function so we can pay with an ERC20 token.
2. Create an auto-redeem function to redeem pool tokens for TCO2s.
3. Create a retirement function that retires for another address.

### Carbon Credit Retirement

In the receiver contract, we will perform the following actions:

1. Swap ERC20 tokens: exchange WETH for NCT.
2. Redeem pool tokens for TCO2s: redeem NCT for TCO2.
3. Retire from another address: retire TCO2 from our sender address.

We are not using the [OffsetHelper](https://github.com/ToucanProtocol/OffsetHelper), but the function we are writing is almost identical, except that we add the user's address to link it to the retirement.

This function also allows users to offset carbon emissions using specific ERC20 tokens (WETH). It swaps the provided ERC20 token for a Toucan pool token (NCT), redeems the pool token for TCO2 tokens, and retires the TCO2 tokens. Okay okay okay. This sounds maybe new to you. Check out this [article](https://medium.com/@hierzilena/how-to-retire-carbon-credits-using-the-offsethelper-8bc02a61f48a) that goes into detail on how the OffsetHelper works.

### Swap ERC20 Tokens

The `swapExactInToken()` function, which you can find in the Toucan Quickstarter under `packages/hardhat/contracts/Swapper.sol`, allows swapping eligible ERC20 tokens for pool tokens (NCT) on Ubeswap for Celo and Sushiswap for Polygon. Prior approval on the client side is required to use this function. It takes the following parameters:

- `_path`: An array of token addresses that describe the swap path, indicating the tokens involved in the exchange.
- `_fromAmount`: The amount of ERC20 tokens to swap.

```typescript
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Swapper {
    using SafeERC20 for IERC20;

    // Dex Router Address
    address public dexRouterAddress;

    function swapExactInToken(
        address[] memory _path,
        uint256 _fromAmount
    ) public returns (uint256 amountOut) {
        uint256 len = _path.length;

        // transfer tokens
        IERC20(_path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            _fromAmount
        );

        // approve router
        IERC20(_path[0]).approve(dexRouterAddress, _fromAmount);

        // swap
        uint256[] memory amounts = IUniswapV2Router02(dexRouterAddress)
            .swapExactTokensForTokens(
                _fromAmount,
                0, // min. output amount
                _path,
                address(this),
                block.timestamp
            );
        amountOut = amounts[len - 1];
    }
}
```

### Redeem Pool Tokens for TCO2s

The `autoRedeem()` function is responsible for redeeming a specified amount of NCT for TCO2 tokens. It requires prior approval on the client side. The function takes the following parameters:

- `fromToken`: The pool token address to be used for redemption, like NCT.
- `amount`: The amount of tokens to be redeemed.

```typescript
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
```

### Retire from Another Address

To enable the remote ICA to call the function and use your wallet address as the retirement address, you can utilize the `retireFrom()` function from the `ToucanCarbonOffset` contract. This function allows users to retire TCO2 tokens from another address and takes the following parameters:

- `tco2s`: An array containing the addresses of the TCO2 tokens that the user intends to retire. This will be a return value of autoRedeem().
- `amounts`: An array specifying the amounts of ERC20 tokens to be swapped into the Toucan pool. This will also be a return value of autoRedeem().
- `account`: The address with which the retirement is associated, related to the TCO2 addresses provided.

```typescript
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
```

This function ensures that the specified TCO2 tokens are retired on behalf of the provided address, allowing for carbon credit retirement from another wallet.

### Create the Function With a Swap and Retire For Another Entity

Okay. Now we have everything together and we can create our function, `retireFromAddress()`, which allows users to retire carbon credits and associate a specific address with the retirement. It follows these steps:
Acquire a pool token, for example, NCT, by performing a token swap on a decentralized exchange (DEX).

1. Redeem the obtained pool token for the oldest TCO2 tokens.
2. Retire the TCO2 tokens on behalf of a specified address.

Parameters:

- `_amount`: The amount of ERC20 tokens to swap into the Toucan pool.
- `_path`: An array of token addresses that outlines the swap path, e.g., `[<WETH.address, cUSD.address, NCT.address>`.
- `_account`: The address that should be associated with the retirement.
- `_dexRouter`: The address of the DEX Router used for the token swap.

Returns:

- `tco2s`: An array of the TCO2 token addresses that were redeemed.
- `amounts`: An array indicating the amounts of each TCO2 token that were redeemed.

```typescript
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

```

---

## Step 4: Create the Remote Call Function

We now have everything in place to call a function on a remote chain. In `packages/hardhat/contracts/CarbonRetirementBridge.sol`, we call `RetirementHelper.retireFromAddress()` on Celo with the Account API from Optimism. Additionally, we need to create a new function called `addressToBytes32()` because the `to` value of the `Call` takes `bytes32` as input, so we need to cast the type of the `RetirementHelper` address to `bytes32`.

### Parameters:

- `_retirementHelper`: The address of the `RetirementHelper` on the destination chain that you want to call a function from.
- `_depositedToken`: The address of the ERC20 token that the user sends (e.g., WETH).
- `_poolAddress`: The address of the pool that the user wants to retire tokens from (e.g., NCT).
- `_amount`: The amount of ERC20 token to swap into pool token. The full amount will be used for the retirement.

```typescript
import "./RetirementHelper.sol";

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
        to: addressToBytes32(address(_retirementHelper)),
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
```

### Pay for Bridging with the InterchainGasPaymaster

To complete the process, you'll need to pay for gas during the bridging step. This involves adding the `IInterchainGasPaymaster` interface.

Create a new file called `IInterchainGasPaymaster.sol` and add the following code:

```typescript
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
```

In your `bridgeRetirement` function, you'll need to store the return value of the remote call in a variable that we'll call `messageId`. Then, initialize an instance of the `IInterchainGasPaymaster` with the [DefaultIsmInterchainGasPaymaster](https://docs.hyperlane.xyz/docs/resources/addresses#defaultisminterchaingaspaymaster-1) Address. The function parameters include:

- `messageId`: The return value of the remote function call.
- `_destination`: The domain ID of the chain you're sending tokens to.
- `gasAmount`: The total gas amount, which should include the overhead gas amount and the gas used by the call being made. The overhead gasAmount should be 150,000 if the ICA doesn't exist yet and 30,000 if it does.
- `sender`: Refund the message `msg.sender`.
  This step ensures that you cover the gas expenses for the bridging process using the `IInterchainGasPaymaster` interface.

```typescript
//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import {IInterchainGasPaymaster} from "./interfaces/IInterchainGasPaymaster.sol";


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
```

Now, deploy the contract, and you can finally retire carbon credits from any EVM chain you can think of. The whole code should now look like this:

```typescript
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

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
            to: addressToBytes32(address(_retirementHelper)),
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

```

---

Now, deploy the contract, and you can finally retire carbon credits from any EVM chain you can think of.

### Implementing a Frontend

Hyperlane already comes with a [UI for Warp Routes](https://github.com/hyperlane-xyz/hyperlane-warp-ui-template) that you can use.

### Congratulations! You've successfully learned how to retire carbon credits from another EVM chain. 

### Let's build!

Well, let's get your hands dirty and start building with Toucan
Toucan's [Quickstarter](https://github.com/GigaHierz/toucan-quickstart)
Toucan's [docs](https://docs.toucan.earth/toucan/dev-resources/toucan-developer-resources)
Toucan's [SDK](https://github.com/ToucanProtocol/toucan-sdk)
Toucan's [blog](https://blog.toucan.earth/)

```

```
