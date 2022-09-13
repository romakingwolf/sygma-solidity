// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISwapRouterV3 {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

}