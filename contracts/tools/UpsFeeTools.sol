// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './interfaces/IBridge.sol';
import './interfaces/ISwapRouterV3.sol';

contract UpsFeeTools {

    ISwapRouterV3 public swapRouter;
    IBridge public bridge;
    address public WETH;

    uint24 public constant poolFee = 3000;

    constructor(ISwapRouterV3 _swapRouter, IBridge _bridge, address _WETH) payable {
        swapRouter = _swapRouter;
        bridge = _bridge;
        WETH = _WETH;
    }

    function setSwapRouter(ISwapRouterV3 _swapRouter) external {
        swapRouter = _swapRouter;
    }

    function setBridge(IBridge _bridge) external {
        bridge = _bridge;
    }

    function setWETH(address _WETH) external {
        WETH = _WETH;
    }

    function withdraw(bytes32 _resourceID, address payable _receipt, uint256 _amount) external {
        uint256 feeBalance = balanceOfFee(_resourceID);
        require(feeBalance >= _amount, "out of fee balance");
        bridge.withdrawFee(_resourceID, _receipt, _amount);
    }

    function withdrawAndSwapETH(bytes32 _resourceID, address payable _receipt, uint256 _amount) external {
        uint256 feeBalance = balanceOfFee(_resourceID);
        require(feeBalance >= _amount, "out of fee balance");
        bridge.withdrawFee(_resourceID, payable(address(this)), _amount);
        address tokenIn = bridge.getFeeTokenContractAddress(_resourceID);
        require(tokenIn != address(0), "swap token address must not be 0x0");
        swapExactInputSingleToETH(_amount, tokenIn, WETH, address(this));
    }

    function balanceOfFee(bytes32 _resourceID) public view returns(uint256) {
        return bridge.getFeeBalance(_resourceID);
    }

    function swapExactInputSingleToETH(uint256 amountIn, address tokenIn, address tokenOut, address receipt) public returns (uint256 amountOut) {
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
        amountOut = swapRouter.exactInputSingle(params);

        swapRouter.unwrapWETH9(amountOut, receipt);
    }

}