// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uniswap router
contract Swapper {
    using SafeERC20 for IERC20;

    // Dex Router Address
    address public dexRouterAddress;

    /**
     * @notice Contract constructor. Takes the DEX router address
     * @param _dexRouterAddress The address of the DEX (Uniswap V2) used to swap tokens
     */
    constructor(address _dexRouterAddress) {
        dexRouterAddress = _dexRouterAddress;
    }

    // ----------------------------------------
    //      Public write functions
    // ----------------------------------------

    /**
     * @notice Swap eligible ERC20 tokens for pool tokens (BCT/NCT) on SushiSwap
     * @dev Needs to be approved on the client side
     * @param _path an Array of token addresses that describe the swap path.
     * @param _toAmount The required amount of the pool token (NCT/BCT)
     */
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

    /**
     * @notice Swap eligible ERC20 tokens for pool tokens (BCT/NCT) on
     * SushiSwap. All provided ERC20 tokens will be swapped.
     * @dev Needs to be approved on the client side.
     * @param _path an Array of token addresses that describe the swap path.
     * @param _fromAmount The amount of ERC20 token to swap
     * @return amountOut Resulting amount of pool token that got acquired for the
     * swapped ERC20 tokens.
     */
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

    // ----------------------------------------
    //      Public view functions
    // ----------------------------------------

    /**
     * @notice Return how much of the specified ERC20 token is required in
     * order to swap for the desired amount of a pool token, for
     * example,  e.g., NCT.
     *
     * @param _path an Array of token addresses that describe the swap path.
     * @param _toAmount The desired amount of pool token to receive
     * @return amountIn The amount of the ERC20 token required in order to
     * swap for the specified amount of the pool token
     */
    function calculateNeededTokenAmount(
        address[] memory _path,
        uint256 _toAmount
    ) public view returns (uint256 amountIn) {
        uint256[] memory amounts = calculateExactOutSwap(_path, _toAmount);
        amountIn = amounts[0];
    }

    /**
     * @notice Calculates the expected amount of pool token that can be
     * acquired by swapping the provided amount of ERC20 token.
     *
     * @param _path an Array of token addresses that describe the swap path.
     * @param _fromAmount The amount of ERC20 token to swap
     * @return amountOut The expected amount of Pool token that can be acquired
     */
    function calculateExpectedPoolTokenForToken(
        address[] memory _path,
        uint256 _fromAmount
    ) public view returns (uint256 amountOut) {
        uint256[] memory amounts = calculateExactInSwap(_path, _fromAmount);
        amountOut = amounts[amounts.length - 1];
    }

    // ----------------------------------------
    //      Internal functions
    // ----------------------------------------

    function calculateExactOutSwap(
        address[] memory _path,
        uint256 _toAmount
    ) internal view returns (uint256[] memory amounts) {
        // create path & calculate amounts
        uint256 len = _path.length;

        amounts = IUniswapV2Router02(dexRouterAddress).getAmountsIn(
            _toAmount,
            _path
        );

        // sanity check arrays
        require(len == amounts.length, "Arrays unequal");
        require(_toAmount == amounts[len - 1], "Output amount mismatch");
    }

    function calculateExactInSwap(
        address[] memory _path,
        uint256 _fromAmount
    ) internal view returns (uint256[] memory amounts) {
        // create path & calculate amounts
        uint256 len = _path.length;

        amounts = IUniswapV2Router02(dexRouterAddress).getAmountsOut(
            _fromAmount,
            _path
        );

        // sanity check arrays
        require(len == amounts.length, "Arrays unequal");
        require(_fromAmount == amounts[0], "Input amount mismatch");
    }
}
