// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IToucanPoolToken.sol";
import "./interfaces/IToucanCarbonOffsets.sol";
import "./Swapper.sol";

contract RetirementHelper {
    using SafeERC20 for IERC20;

    // ADD YOUR FUNCTIONS HERE

    constructor() {}

    /**
     * @notice Retire carbon credits choosing a specific project
     * from the specified Toucan token pool. All provided token is consumed for
     * retirement.
     *
     * This function:
     * 1. Redeems the pool token for the choosen TCO2 tokens.
     * 2. Retires the TCO2 tokens.
     *
     * Note: The client must approve the ERC20 token that is sent to the contract.
     *
     * @dev When choosing to redeeming pool tokens for a specific
     * TCO2s there are fees which will be calculated in the reddem function.
     * You can learn more about Toucan's Protocol fee in their
     * docs: https://docs.toucan.earth/toucan/pool/protocol-fees
     * @param _poolToken The address of the Toucan pool token that the
     * user wants to use, e.g., NCT or BCT
     * @param _tco2s The addresses of the TCO2 token that the wants to retire
     * @param _amounts The amounts of ERC20 token to swap into Toucan pool
     * token. Full amount will be used for offsetting.
     *
     * @return tco2s An array of the TCO2 addresses that were redeemed
     * @return amounts An array of the amounts of each TCO2 that were redeemed
     */

    function retireSpecificProject(
        address _poolToken,
        address[] memory _tco2s,
        uint256[] memory _amounts
    ) public returns (address[] memory tco2s, uint256[] memory amounts) {
        // deposit pool token from user to this contract
        IERC20(_poolToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amounts[0]
        );

        tco2s = _tco2s;
        amounts = _amounts;

        // redeem BCT / NCT for a sepcific TCO2
        (tco2s, amounts) = redeemProject(_poolToken, tco2s, amounts);

        // retire the TCO2s to achieve offset
        retireProjects(tco2s, amounts);
    }

    /**
     * @notice Redeems the specified amount of NCT / BCT for TCO2.
     * @dev Needs to be approved on the client side.
     * @param _poolToken Could be the address of NCT or BCT
     * @param _tco2s The addresses of the TCO2 token that the wants to retire
     * @param _amounts The amounts of ERC20 token to swap into Toucan pool
     * @return tco2s An array of the amounts of each TCO2 that were redeemed
     * @return amounts An array of the amounts of each TCO2 that were redeemed
     */
    function redeemProject(
        address _poolToken,
        address[] memory _tco2s,
        uint256[] memory _amounts
    ) internal returns (address[] memory tco2s, uint256[] memory amounts) {
        require(
            IERC20(_poolToken).balanceOf(address(this)) >= _amounts[0],
            "Insufficient NCT/BCT balance"
        );

        // instantiate pool token (NCT or BCT)
        IToucanPoolToken PoolTokenImplementation = IToucanPoolToken(_poolToken);

        tco2s = _tco2s;
        amounts = _amounts;

        // redeem pool token for TCO2 with that address; will transfer the TCO2 to this contract
        PoolTokenImplementation.redeemMany(tco2s, amounts);

        // the amount that we return needs to be the actuall amount of TCO2s that
        // is received after taking away the reddem fee
        amounts[0] =
            amounts[0] -
            PoolTokenImplementation.calculateRedeemFees(tco2s, amounts);
    }

    /**
     * @notice Retire the specified TCO2 tokens.
     * @param _tco2s The addresses of the TCO2 token that the user wants to retire
     * @param _amounts The amounts of ERC20 token to swap into Toucan pool
     * TCO2 addresses
     */
    function retireProjects(
        address[] memory _tco2s,
        uint256[] memory _amounts
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

            IToucanCarbonOffsets(_tco2s[i]).retire(_amounts[i]);
        }
    }

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
}
