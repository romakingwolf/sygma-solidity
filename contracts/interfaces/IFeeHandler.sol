// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFeeHandler {

    /**
        @dev Emitted when a new fee amount is set.
     */
    event SetFee(bytes32 indexed resourceID, uint256 indexed amount);

    /**
        @dev Emitted when a new fee rate is set.
     */
    event SetFeeRate(bytes32 indexed resourceID, uint256 indexed rate);

    /**
        @dev Emitted when a new fee config is set for the specified user.
     */
    event SetUserFee(address indexed user, bytes32 indexed resourceID, bool isSetAmount, uint256 amount, bool isSetRate, uint256 rate);

    /**
        @notice Sets token contract address for a resource.
        @notice Only callable by an address that currently has the admin role.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @notice in ERC20Handler, fee token must be the deposit token
     */
    function setFeeToken(bytes32 resourceID, address contractAddress) external;

    /**
        @notice Sets fee amount for handler contracts that will pay when deposit.
        @notice Only callable by an address that currently has either the admin role or the fee setter role.
        @param resourceID ResourceID to be used when making deposits.
        @param amount Fee amount that pay when deposit.
     */
    function setFee(bytes32 resourceID, uint256 amount) external;

    /**
        @notice Sets fee rate for handler contracts that will pay when deposit.
        @notice Only callable by an address that currently has either the admin role or the fee setter role.
        @param resourceID ResourceID to be used when making deposits.
        @param rate Fee rate that pay when deposit.
     */
    function setFeeRate(bytes32 resourceID, uint256 rate) external;

    /**
        @notice Sets fee rate for handler contracts that will pay when deposit for a specified user.
        @notice Only callable by an address that currently has either the admin role or the fee setter role.
        @param userAddress User Address which user to be set for a specified fee config.
        @param resourceID ResourceID to be used when making deposits.
        @param isSetAmount Whether to set a specified fee amount for the user.
        @param amount Fee amount that pay when deposit for the user.
        @param isSetRate Whether to set a specified fee rate for the user.
        @param rate Fee rate that pay when deposit for the user.
     */
    function setUserFee(address userAddress, bytes32 resourceID, bool isSetAmount, uint256 amount, bool isSetRate, uint256 rate) external;

    /**
        @notice Used to manually withdraw fee funds.
        @param resourceID ResourceID to be used when making deposits.
        @param to Address to withdraw fee to.
        @param amount The amount of fee to withdraw.
     */
    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external;

    /**
        @notice Get fee balance of resource fee pool.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
     */
    function getFeeBalance(bytes32 resourceID) external view returns(uint256);

}