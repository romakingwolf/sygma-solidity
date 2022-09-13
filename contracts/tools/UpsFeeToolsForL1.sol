// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './interfaces/ISwapRouterV3.sol';

contract UpsFeeToolsForL1 is AccessControl {

    ISwapRouterV3 public swapRouter;
    address public WETH;
    address public gasFeeReceipt;
    address public feeReceipt;

    uint24 public constant poolFee = 3000;

    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
    bytes32 public constant TX_EXECUTOR_ROLE = keccak256("TX_EXECUTOR_ROLE");

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyAccountant() {
        _onlyAccountant();
        _;
    }

    modifier onlyTxExecutor() {
        _onlyTxExecutor();
        _;
    }

    function _onlyAdmin() private {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
    }

    function _onlyAccountant() private {
        require(hasRole(ACCOUNTANT_ROLE, msg.sender), "sender doesn't have accountant role");
    }

    function _onlyTxExecutor() private {
        require(hasRole(TX_EXECUTOR_ROLE, msg.sender), "sender doesn't have tx executor role");
    }

    constructor(ISwapRouterV3 _swapRouter, address _WETH, address _gasFeeReceipt, address _feeReceipt) payable {
        swapRouter = _swapRouter;
        WETH = _WETH;
        gasFeeReceipt = _gasFeeReceipt;
        feeReceipt = _feeReceipt;
    }

    function setSwapRouter(ISwapRouterV3 _swapRouter) external onlyAdmin {
        swapRouter = _swapRouter;
    }

    function setWETH(address _WETH) external onlyAdmin {
        WETH = _WETH;
    }

    function setGasFeeReceipt(address _gasFeeReceipt) external onlyAdmin {
        gasFeeReceipt = _gasFeeReceipt;
    }

    function setFeeReceipt(address _feeReceipt) external onlyAdmin {
        feeReceipt = _feeReceipt;
    }

    function withdraw(address _token, address _receipt, uint256 _amount) external onlyAccountant {
        IERC20 token = IERC20(_token);
        token.transfer(_receipt, _amount);
    }

    function withdrawETH(address payable _receipt, uint256 _amount) external onlyAccountant {
        _receipt.transfer(_amount);
    }

    // refund fee, eg cpay
    function refund(address _token, uint256 _amount) external onlyTxExecutor {
        IERC20 token = IERC20(_token);
        token.transfer(feeReceipt, _amount);
    }

    // transfer to relayer to refund ETH gas fee
    function withdrawAndSwapETH(address _token, uint256 _amount) external onlyTxExecutor {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "out of balance");

        swapExactInputSingleToETH(_amount, _token, WETH, gasFeeReceipt);
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