// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {EtherWallet} from "../EtherWallet.sol";

contract EtherWalletTest is DSTestPlus {
    EtherWallet private wallet;
    address payable private _to;

    // Must make this test contract payable
    receive() external payable {}

    function setUp() public {
        wallet = new EtherWallet();
        _to = payable(address(wallet));
    }

    function testReceiveNothing() public {
        SafeTransferLib.safeTransferETH(_to, 0 ether);
        assertEq(_to.balance, 0 ether);
        assertEq(wallet.getBalance(), 0 ether);
    }

    function testReceiveSomething() public {
        SafeTransferLib.safeTransferETH(_to, 1 ether);
        assertEq(_to.balance, 1 ether);
        assertEq(wallet.getBalance(), 1 ether);
    }

    function testWithdrawNothing() public {
        SafeTransferLib.safeTransferETH(_to, 1 ether);
        uint256 preWithdrawBalance = address(this).balance;
        wallet.withdraw(0 ether);
        assertEq(_to.balance, 1 ether);
        assertEq(address(this).balance, preWithdrawBalance);
    }

    function testWithdrawHalf() public {
        SafeTransferLib.safeTransferETH(_to, 1 ether);
        uint256 preWithdrawBalance = address(this).balance;
        wallet.withdraw(0.5 ether);
        assertEq(_to.balance, 0.5 ether);
        assertEq(address(this).balance, preWithdrawBalance + 0.5 ether);
    }

    function testWithdrawAll() public {
        SafeTransferLib.safeTransferETH(_to, 1 ether);
        uint256 preWithdrawBalance = address(this).balance;
        wallet.withdraw(1 ether);
        assertEq(_to.balance, 0 ether);
        assertEq(address(this).balance, preWithdrawBalance + 1 ether);
    }

    function testWithdrawMoreThanAll() public {
        SafeTransferLib.safeTransferETH(_to, 1 ether);
        vm.expectRevert(bytes("not enough value in wallet"));
        wallet.withdraw(2 ether);
    }
}
