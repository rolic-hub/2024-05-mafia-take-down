// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CrimeMoney } from "src/CrimeMoney.sol";

import { Kernel, Keycode } from "src/Kernel.sol";

import { Shelf } from "src/modules/Shelf.sol";

contract MoneyShelf is Shelf {
    IERC20 private usdc;
    CrimeMoney private crimeMoney;

    constructor(Kernel kernel_, IERC20 _usdc, CrimeMoney _crimeMoney) Shelf(kernel_) {
        usdc = _usdc;
        crimeMoney = _crimeMoney;
    }

    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("MONEY");
    }

    // "permissioned" already used by Shelf functions
    // @audit - high : Uses Arbitrary from address (account).
    //@audit - low: Return value of transferFrom ignored.
    function depositUSDC(address account, address to, uint256 amount) external {
        //uses permissioned modifier 
        deposit(to, amount);
        usdc.transferFrom(account, address(this), amount);
        crimeMoney.mint(to, amount);
    }

     //@audit - low: Return value of transfer ignored.
    function withdrawUSDC(address account, address to, uint256 amount) external {
        withdraw(account, amount);
        crimeMoney.burn(account, amount);
        usdc.transfer(to, amount);
    }
}
