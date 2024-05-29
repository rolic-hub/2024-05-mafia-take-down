// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Module, Kernel } from "src/Kernel.sol";

abstract contract Shelf is Module {
    mapping(address => uint256) private bank;
    // IERC20 private immutable token;

    constructor(Kernel kernel_) Module(kernel_) { }

    //since the policy must be a contract then only a contract can call the deposit and withdraw functions (and the contract must inherit policy and calll request permissions).

    //q what is this supposed to do, it only updates a mapping?
    function deposit(address account, uint256 amount) public permissioned {
        //modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig)
        //the msg.sign gets the func. selector
        bank[account] += amount;
    }
    //@audit - high: Users can only deposit, but the deposit function keeps track of users deposit and uses this during withdrawals, as such users funds are stuck in the contract as only the user can withdraw them.
    function withdraw(address account, uint256 amount) public permissioned {
        bank[account] -= amount;
    }

    function getAccountAmount(address account) external view returns (uint256) {
        return bank[account];
    }
}
