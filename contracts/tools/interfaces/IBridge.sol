// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBridge {

    function withdrawFee(bytes32 resourceID, address payable recipient, uint256 amount) external;

    function getFeeBalance(bytes32 resourceID) external view returns(uint256);

    function getFeeTokenContractAddress(bytes32 resourceID) external view returns(address);

}