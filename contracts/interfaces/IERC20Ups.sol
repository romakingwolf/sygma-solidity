// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20Ups {

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}