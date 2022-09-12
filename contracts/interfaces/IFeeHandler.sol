// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFeeHandler {

    function setFeeResource(bytes32 resourceID, address contractAddress) external;

    function setFee(bytes32 resourceID, uint256 amount) external;

    function setFeeRate(bytes32 resourceID, uint256 rate) external;

    function setUserFee(address user, bytes32 resourceID, uint256 amount, uint256 rate, bool isSet) external;

    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external;

}