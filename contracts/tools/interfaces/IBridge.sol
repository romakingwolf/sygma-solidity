// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBridge {
    
    function _resourceIDToFeeTokenContractAddress(bytes32) external returns (address);

    function _resourceIDToHandlerAddress(bytes32) external returns (address);

    function withdrawFee(bytes32 resourceID, address payable recipient, uint256 amount) external;

    function getFeeBalance(bytes32 resourceID) external view returns(uint256);

    function deposit(uint8 destinationChainID, bytes32 resourceID, bytes calldata data) external payable;

}