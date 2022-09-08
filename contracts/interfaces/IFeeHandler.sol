// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFeeHandler {

    function setResource(bytes32 resourceID, address contractAddress) external;

    function collectFee(address sender, bytes32 resourceID, uint8 destinationChainID, uint64 depositNonce, uint256 amount) payable external;

    function calculateFee(address sender, bytes32 resourceID) external view returns(address, uint256);

    function setFee(bytes32 resourceID, uint256 amount) external;

    function setUserFee(address user, bytes32 resourceID, uint256 amount, bool isSet) external;

    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external;

    function setAdmin(bytes32 resourceID, address adminAddress) external;

}