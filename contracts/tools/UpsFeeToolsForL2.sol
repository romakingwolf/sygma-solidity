// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import './interfaces/IBridge.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract UpsFeeToolsForL2 {

    IBridge public bridge;
    uint8 public destinationChainID;

    constructor(IBridge _bridge, uint8 _destChainID) payable {
        bridge = _bridge;
        destinationChainID = _destChainID;
    }

    function setBridge(IBridge _bridge) external {
        bridge = _bridge;
    }

    function setDestinationChainID(uint8 _destChainId) external {
        destinationChainID = _destChainId;
    }

    function withdraw(bytes32 _resourceID, address payable _receipt, uint256 _amount) external {
        uint256 feeBalance = bridge.getFeeBalance(_resourceID);
        require(feeBalance >= _amount, "out of fee balance");
        bridge.withdrawFee(_resourceID, _receipt, _amount);
    }

    function withdrawToL1(bytes32 _resourceID, address payable _receipt, uint256 _amount) external {
        uint256 feeBalance = bridge.getFeeBalance(_resourceID);
        require(feeBalance >= _amount, "out of fee balance");
        bridge.withdrawFee(_resourceID, payable(address(this)), _amount);

        address tokenAddress = bridge._resourceIDToFeeTokenContractAddress(_resourceID);
        if (tokenAddress != address(0)) {
            address handlerAddress = bridge._resourceIDToHandlerAddress(_resourceID);
            TransferHelper.safeApprove(tokenAddress, handlerAddress, _amount);
        }

        // call bridge.deposit function to do cross chain
        bytes memory data;
        // TODO construct deposit parameter: data
        if (tokenAddress == address(0)) {
            bridge.deposit{value: _amount}(destinationChainID, _resourceID, data);
        } else {
            bridge.deposit{value: 0}(destinationChainID, _resourceID, data);
        }
    }

}