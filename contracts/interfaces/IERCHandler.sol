// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author ChainSafe Systems.
 */
interface IERCHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;
    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;
    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
     */
    function withdraw(address tokenAddress, address recipient, uint256 amountOrTokenID) external;

    /**
        @notice Used to manually release ETH from ERC20Safe.
        @param recipient Address to release tokens to.
        @param amount The amount of ETH to release.
     */
    function withdrawETH(address recipient, uint256 amount) external;

    /**
        @notice Used to set token which is ETH or not.
        @param tokenAddress Token contract address.
        @param isETH Whether the token is ETH or not.
     */
    function setETH(address tokenAddress, bool isETH) external;
}
