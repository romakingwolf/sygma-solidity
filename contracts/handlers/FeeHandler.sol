// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IFeeHandler.sol";
import "../interfaces/IERC20Ups.sol";

contract FeeHandler is IFeeHandler {
    address public _bridgeAddress;

    // resourceID => token contract address
    mapping (bytes32 => address) public _resourceIDToTokenContractAddress;

    // resourceID => admin address
    mapping (bytes32 => address) public _resourceIDToAdminAddress;
    // resourceID => white list of fee withdraw handler contract address
    mapping (bytes32 => address) public _resourceIDToFeeWithdrawWhitelist;

    // resourceID => fee amount
    mapping (bytes32 => uint256) public _resourceIDToFeeAmount;

    struct UserFeeAmountRecord {
        bool _isSet;
        uint256 _amount;
    }
    // resourceID => user address => user fee amount record
    mapping (bytes32 => mapping(address => UserFeeAmountRecord)) public _resourceIDToUserFeeAmount;

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

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    modifier onlyAdmin(bytes32 resourceID) {
        _onlyAdmin(resourceID);
        _;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    function _onlyAdmin(bytes32 resourceID) private view {
        address adminAddress = _resourceIDToAdminAddress[resourceID];
        require(msg.sender == adminAddress, "sender must be resource admin");
    }

    constructor(
        address          bridgeAddress,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses
    ) public {
        require(initialResourceIDs.length == initialContractAddresses.length,
            "initialResourceIDs and initialContractAddresses len mismatch");

        _bridgeAddress = bridgeAddress;

        for (uint256 i = 0; i < initialResourceIDs.length; i++) {
            _setResource(initialResourceIDs[i], initialContractAddresses[i]);
        }
    }

    function setResource(bytes32 resourceID, address contractAddress) external onlyBridge {
        _setResource(resourceID, contractAddress);
    }

    function collectFee(address sender, bytes32 resourceID, uint8 destinationChainID, uint64 depositNonce, uint256 amount) payable external {
        address tokenContractAddress = _resourceIDToTokenContractAddress[resourceID];

        if (tokenContractAddress == address(0)) {
            require(msg.value >= amount, "invalid fee amount");
        } else {
            IERC20Ups erc20 = IERC20Ups(tokenContractAddress);
            bool success = erc20.transferFrom(sender, address(this), amount);
            require(success, "erc20 transferFrom failed");
        }

        _resourceIDToAmount[resourceID] = _resourceIDToAmount[resourceID] + amount;

        emit FeeCollected(sender, destinationChainID, resourceID, depositNonce, amount, tokenContractAddress);
    }

    function calculateFee(address sender, bytes32 resourceID) external view returns(address, uint256) {
        address tokenContractAddress = _resourceIDToTokenContractAddress[resourceID];
        uint256 amount;
        if (_resourceIDToUserFeeAmount[resourceID][sender]._isSet) {
            amount = _resourceIDToUserFeeAmount[resourceID][sender]._amount;
        } else {
            amount = _resourceIDToFeeAmount[resourceID];
        }
        return (tokenContractAddress, amount);
    }

    function setFee(bytes32 resourceID, uint256 amount) external onlyBridge {
        _resourceIDToFeeAmount[resourceID] = amount;
    }

    function setUserFee(address user, bytes32 resourceID, uint256 amount, bool isSet) external onlyBridge {
        _resourceIDToUserFeeAmount[resourceID][user] = UserFeeAmountRecord(isSet, amount);
    }

    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external {
        require(msg.sender == _resourceIDToAdminAddress[resourceID] || msg.sender == _resourceIDToFeeWithdrawWhitelist[resourceID],
            "caller is neither fee admin nor whiterlist address");

        require(_resourceIDToAmount[resourceID] >= amount, "not enough fee to withdraw");

        address tokenContractAddress = _resourceIDToTokenContractAddress[resourceID];

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

    function setFeeWithdrawWhitelist(bytes32 resourceID, address contractAddress) external onlyAdmin(resourceID) {
        _resourceIDToFeeWithdrawWhitelist[resourceID] = contractAddress;
    }

    function setAdmin(bytes32 resourceID, address adminAddress) external onlyBridge {
        _resourceIDToAdminAddress[resourceID] = adminAddress;
    }

    function _setResource(bytes32 resourceID, address contractAddress) internal {
        require(_resourceIDToAmount[resourceID] == 0, "fee pool is not empty");
        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
    }
}