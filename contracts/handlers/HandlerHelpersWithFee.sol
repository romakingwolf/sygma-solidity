// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IFeeHandler.sol";
import "../interfaces/IERC20Ups.sol";
import "./HandlerHelpers.sol";

contract HandlerHelpersWithFee is HandlerHelpers, IFeeHandler {

    // resourceID => token contract address
    mapping (bytes32 => address) public _resourceIDToFeeTokenContractAddress;

    // resourceID => fee amount
    mapping (bytes32 => uint256) public _resourceIDToFeeAmount;
    // resourceID => fee prorated from the amount, eg 50% => 5000
    mapping (bytes32 => uint256) public _resourceIDToFeeRate;

    struct UserFeeSet {
        bool _isSetAmount;
        uint256 _amount;
        bool _isSetRate;
        uint256 _rate;
    }
    // resourceID => user address => user fee amount record
    mapping (bytes32 => mapping(address => UserFeeSet)) public _resourceIDToUserFeeAmount;

    // resourceID => amount in pool
    mapping (bytes32 => uint256) public _resourceIDToAmount;

    event FeeCollected(
        address indexed sender,
        uint8 destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 fee,
        address tokenAddress
    );

    event FeeWithdraw(
        bytes32 indexed resourceID,
        address indexed tokenAddress,
        address indexed recipient,
        uint256 amount
    );

    /**
        @notice Sets token contract address for a resource.
        @notice Only callable by an address that currently has the admin role.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @notice in ERC20Handler, fee token must be the deposit token
     */
    function setFeeToken(bytes32 resourceID, address contractAddress) external override onlyBridge {
        require(_resourceIDToAmount[resourceID] == 0, "fee pool is not empty");
        _resourceIDToFeeTokenContractAddress[resourceID] = contractAddress;
    }

    /**
        @notice Sets fee amount for handler contracts that will pay when deposit.
        @notice Only callable by an address that currently has either the admin role or the fee setter role.
        @param resourceID ResourceID to be used when making deposits.
        @param amount Fee amount that pay when deposit.
     */
    function setFee(bytes32 resourceID, uint256 amount) external override onlyBridge {
        _resourceIDToFeeAmount[resourceID] = amount;
        emit SetFee(resourceID, amount);
    }

    /**
        @notice Sets fee rate for handler contracts that will pay when deposit.
        @notice Only callable by an address that currently has either the admin role or the fee setter role.
        @param resourceID ResourceID to be used when making deposits.
        @param rate Fee rate that pay when deposit.
     */
    function setFeeRate(bytes32 resourceID, uint256 rate) external override onlyBridge {
        _resourceIDToFeeRate[resourceID] = rate;
        emit SetFeeRate(resourceID, rate);
    }

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
    function setUserFee(address userAddress, bytes32 resourceID, bool isSetAmount, uint256 amount, bool isSetRate, uint256 rate) external override onlyBridge {
        _resourceIDToUserFeeAmount[resourceID][userAddress] = UserFeeSet(isSetAmount, amount, isSetRate, rate);
        emit SetUserFee(userAddress, resourceID, isSetAmount, amount, isSetRate, rate);
    }

    /**
        @notice Used to collect the deposit fee.
        @param sender Address of account making the deposit in the Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param destinationChainID Chain ID of chain tokens are expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param amount Deposit amount.
        @param paid Whether has paid in IERCHandler.
    */
    function collectFee(address sender, bytes32 resourceID, uint8 destinationChainID, uint64 depositNonce, uint256 amount, bool paid) internal {
        if (amount == 0) {
            return;
        }

        address tokenContractAddress = _resourceIDToFeeTokenContractAddress[resourceID];

        if (!paid) {
            if (tokenContractAddress == address(0)) {
                require(msg.value >= amount, "invalid fee amount");
            } else {
                IERC20Ups erc20 = IERC20Ups(tokenContractAddress);
                bool success = erc20.transferFrom(sender, address(this), amount);
                require(success, "erc20 transferFrom failed");
            }
        }

        _resourceIDToAmount[resourceID] = _resourceIDToAmount[resourceID] + amount;

        emit FeeCollected(sender, destinationChainID, resourceID, depositNonce, amount, tokenContractAddress);
    }

    /**
        @notice Used to calculate the deposit fee and get the fee token contract address.
        @param sender The user address that do the deposit.
        @param resourceID ResourceID to be used when making deposits.
        @param amount Deposit amount.
    */
    function calculateFee(address sender, bytes32 resourceID, uint256 amount) internal view returns(address, uint256) {
        address tokenContractAddress = _resourceIDToFeeTokenContractAddress[resourceID];
        uint256 fee;
        uint256 feeAmount = _resourceIDToFeeAmount[resourceID];
        uint256 feeRate = _resourceIDToFeeRate[resourceID];

        if (_resourceIDToUserFeeAmount[resourceID][sender]._isSetAmount) {
            feeAmount = _resourceIDToUserFeeAmount[resourceID][sender]._amount;
        }

        if (_resourceIDToUserFeeAmount[resourceID][sender]._isSetRate) {
            feeRate = _resourceIDToUserFeeAmount[resourceID][sender]._rate;
        }

        fee = feeAmount + amount * feeRate / 10000;

        return (tokenContractAddress, fee);
    }

    /**
        @notice Used to manually withdraw fee funds.
        @param resourceID ResourceID to be used when making deposits.
        @param to Address to withdraw fee to.
        @param amount The amount of fee to withdraw.
     */
    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external override onlyBridge {
        require(_resourceIDToAmount[resourceID] >= amount, "not enough fee to withdraw");

        address tokenContractAddress = _resourceIDToFeeTokenContractAddress[resourceID];

        if (tokenContractAddress == address(0)) {
            require(address(this).balance >= amount, "out of balance");
            to.transfer(amount);
        } else {
            IERC20Ups erc20 = IERC20Ups(tokenContractAddress);
            bool success = erc20.transfer(to, amount);
            require(success, "erc20 transferFrom failed");
        }

        _resourceIDToAmount[resourceID] = _resourceIDToAmount[resourceID] - amount;

        emit FeeWithdraw(resourceID, tokenContractAddress, to, amount);
    }

    /**
        @notice Get fee balance of resource fee pool.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
     */
    function getFeeBalance(bytes32 resourceID) external view returns(uint256) {
        return _resourceIDToAmount[resourceID];
    }

}