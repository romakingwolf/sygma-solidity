// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC721UpsBurnable {

    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

}