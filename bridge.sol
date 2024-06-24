// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bridge {
    address public owner;
    mapping(address => mapping(string => uint256)) public lockedFunds;

    event TransferInitiated(address indexed from, address indexed token, uint256 amount, string destinationChain, address to);
    event TransferCompleted(address indexed to, address indexed token, uint256 amount, string sourceChain);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function initiateTransfer(address token, uint256 amount, string memory destinationChain, address to) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        lockedFunds[token][destinationChain] += amount;
        emit TransferInitiated(msg.sender, token, amount, destinationChain, to);
    }

    function completeTransfer(address token, uint256 amount, string memory sourceChain, address to) public onlyOwner {
        require(lockedFunds[token][sourceChain] >= amount, "Insufficient locked funds");
        lockedFunds[token][sourceChain] -= amount;
        IERC20(token).transfer(to, amount);
        emit TransferCompleted(to, token, amount, sourceChain);
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
