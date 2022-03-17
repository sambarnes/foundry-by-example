// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Source:
// https://solidity-by-example.org/app/ether-wallet/

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "caller is not owner");
        require(this.getBalance() >= _amount, "not enough value in wallet");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
