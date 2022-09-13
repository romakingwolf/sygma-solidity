// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFeeHandler {

    event SetFee(bytes32 indexed resourceID, uint256 indexed amount);

    event SetFeeRate(bytes32 indexed resourceID, uint256 indexed rate);

    event SetUserFee(address indexed user, bytes32 indexed resourceID, bool isSetAmount, uint256 amount, bool isSetRate, uint256 rate);

    function setFeeResource(bytes32 resourceID, address contractAddress) external;

    function setFee(bytes32 resourceID, uint256 amount) external;

    function setFeeRate(bytes32 resourceID, uint256 rate) external;

    function setUserFee(address user, bytes32 resourceID, bool isSetAmount, uint256 amount, bool isSetRate, uint256 rate) external;

    function withdrawFee(bytes32 resourceID, address payable to, uint256 amount) external;

    function getFeeBalance(bytes32 resourceID) external view returns(uint256);

    function get

}