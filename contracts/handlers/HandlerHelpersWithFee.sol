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
        bool _isSet;
        uint256 _amount;
        uint256 _rate;
    }
    // resourceID => user address => user fee amount record
    mapping (bytes32 => mapping(address => UserFeeSet)) public _resourceIDToUserFeeAmount;

    // resourceID => amount in pool
    mapping (bytes32 => uint256) _resourceIDToAmount;

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

    function setFeeResource(bytes32 resourceID, address contractAddress) external override onlyBridge {
        require(_resourceIDToAmount[resourceID] == 0, "fee pool is not empty");
        _resourceIDToFeeTokenContractAddress[resourceID] = contractAddress;
    }

    function setFee(bytes32 resourceID, uint256 amount) external override onlyBridge {
        _resourceIDToFeeAmount[resourceID] = amount;
    }

    function setFeeRate(bytes32 resourceID, uint256 rate) external override onlyBridge {
        _resourceIDToFeeRate[resourceID] = rate;
    }

    function setUserFee(address user, bytes32 resourceID, uint256 amount, uint256 rate, bool isSet) external override onlyBridge {
        _resourceIDToUserFeeAmount[resourceID][user] = UserFeeSet(isSet, amount, rate);
    }

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

    function calculateFee(address sender, bytes32 resourceID, uint256 amount) internal view returns(address, uint256) {
        address tokenContractAddress = _resourceIDToFeeTokenContractAddress[resourceID];
        uint256 fee;
        if (_resourceIDToUserFeeAmount[resourceID][sender]._isSet) {
            fee = _resourceIDToUserFeeAmount[resourceID][sender]._amount + _resourceIDToUserFeeAmount[resourceID][sender]._rate / 10000 * amount;
        } else {
            fee = _resourceIDToFeeAmount[resourceID] + _resourceIDToFeeRate[resourceID] / 10000 * amount;
        }
        return (tokenContractAddress, fee);
    }

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

}