// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import './interfaces/IBridge.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract UpsFeeToolsForL2  is AccessControl {

    IBridge public bridge;
    uint8 public destinationChainID;
    address public l1Receipt;

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

    constructor(IBridge _bridge, uint8 _destChainID, address _l1Receipt) payable {
        bridge = _bridge;
        destinationChainID = _destChainID;
        l1Receipt = _l1Receipt;
    }

    function setBridge(IBridge _bridge) external onlyAdmin {
        bridge = _bridge;
    }

    function setDestinationChainID(uint8 _destChainId) external onlyAdmin {
        destinationChainID = _destChainId;
    }

    function setL1Receipt(address _l1Receipt) external onlyAdmin {
        l1Receipt = _l1Receipt;
    }

    function withdraw(bytes32 _resourceID, address payable _receipt, uint256 _amount) external onlyAccountant {
        uint256 feeBalance = bridge.getFeeBalance(_resourceID);
        require(feeBalance >= _amount, "out of fee balance");
        bridge.withdrawFee(_resourceID, _receipt, _amount);
    }

    function withdrawToL1(bytes32 _resourceID, uint256 _amount) external onlyTxExecutor {
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