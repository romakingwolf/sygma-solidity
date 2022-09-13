// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './interfaces/ISwapRouterV3.sol';

contract UpsFeeTools {

    ISwapRouterV3 public swapRouter;
    address public WETH;

    uint24 public constant poolFee = 3000;

    constructor(ISwapRouterV3 _swapRouter, address _WETH) payable {
        swapRouter = _swapRouter;
        WETH = _WETH;
    }

    function setSwapRouter(ISwapRouterV3 _swapRouter) external {
        swapRouter = _swapRouter;
    }

    function setWETH(address _WETH) external {
        WETH = _WETH;
    }

    function withdraw(address _token, address _receipt, uint256 _amount) external {
        IERC20 token = IERC20(_token);
        token.transfer(_receipt, _amount);
    }

    function withdrawETH(address payable _receipt, uint256 _amount) external {
        _receipt.transfer(_amount);
    }

    function withdrawAndSwapETH(address _token, address _receipt, uint256 _amount) external {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "out of balance");

        swapExactInputSingleToETH(_amount, _token, WETH, _receipt);
    }

    function swapExactInputSingleToETH(uint256 amountIn, address tokenIn, address tokenOut, address receipt) internal {
        // address(this) must own the amountIn of tokenIn

        // Approve the router to spend tokenIn.
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouterV3.ExactInputSingleParams memory params = ISwapRouterV3.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);

        swapRouter.unwrapWETH9(amountOut, receipt);
    }

}