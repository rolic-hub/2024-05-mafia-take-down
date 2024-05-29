// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { BaseTest, console } from "test/Base.t.sol";
import { Role, Keycode } from "src/Kernel.sol";

import { EmergencyMigration } from "script/EmergencyMigration.s.sol";
import { MoneyShelf } from "src/modules/MoneyShelf.sol";
import { MoneyVault } from "src/modules/MoneyVault.sol";

contract EmergencyMigrationTest is BaseTest {
    address user2 = makeAddr("User2");

    function test_migrate() public {
        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyShelf));

        EmergencyMigration migration = new EmergencyMigration();
        MoneyVault moneyVault = migration.migrate(kernel, usdc, crimeMoney);

        assertNotEq(address(moneyShelf), address(moneyVault));
        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyVault));
    }

    function test_moveFundsWhenMigrating() public {
        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyShelf));

        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        assertEq(usdc.balanceOf(user), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(user), 100e6);
        vm.stopPrank();

        EmergencyMigration migration = new EmergencyMigration();
        MoneyVault moneyVault = migration.migrate(kernel, usdc, crimeMoney);

        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyVault));
        assertEq(usdc.balanceOf(address(moneyVault)), 100e6);
    }

    //check if funds can be withdrawn from the moneyshelf after upgrade
    function test_moveFundsWhenMigrating2() public {
        joinGang(address(0));
        uint256 godFatherStartingBal = usdc.balanceOf(godFather);
        vm.startPrank(godFather);
        //uint godFatherStartingBal = usdc.balanceOf(godFather);
        usdc.approve(address(moneyShelf), 500e6);
        laundrette.depositTheCrimeMoneyInATM(godFather, godFather, 250e6);
        laundrette.depositTheCrimeMoneyInATM(godFather, godFather, 250e6);
        assertEq(usdc.balanceOf(godFather), godFatherStartingBal - 500e6);
        assertEq(usdc.balanceOf(address(moneyShelf)), 500e6);
        assertEq(crimeMoney.balanceOf(godFather), 500e6);
        vm.stopPrank();

        EmergencyMigration migration = new EmergencyMigration();
        MoneyVault moneyVault = migration.migrate(kernel, usdc, crimeMoney);

        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyVault));
        assertNotEq(usdc.balanceOf(address(moneyVault)), 500e6);

        vm.startPrank(godFather);
        laundrette.withdrawMoney(godFather, godFather, 500e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(godFather), godFatherStartingBal);
    }
     //money vault does not work
      function test_withdrawFromMoneyVault() public {
        joinGang(address(0));
        uint256 godFatherStartingBal = usdc.balanceOf(godFather);
        vm.startPrank(godFather);
        //uint godFatherStartingBal = usdc.balanceOf(godFather);
        usdc.approve(address(moneyShelf), 500e6);
        laundrette.depositTheCrimeMoneyInATM(godFather, godFather, 250e6);
        laundrette.depositTheCrimeMoneyInATM(godFather, godFather, 250e6);
        assertEq(usdc.balanceOf(godFather), godFatherStartingBal - 500e6);
        assertEq(usdc.balanceOf(address(moneyShelf)), 500e6);
        assertEq(crimeMoney.balanceOf(godFather), 500e6);
        vm.stopPrank();

        EmergencyMigration migration = new EmergencyMigration();
        MoneyVault moneyVault = migration.migrate(kernel, usdc, crimeMoney);

        assertEq(address(kernel.getModuleForKeycode(Keycode.wrap("MONEY"))), address(moneyVault));
        assertNotEq(usdc.balanceOf(address(moneyVault)), 500e6);

        vm.startPrank(godFather);
        //-------------Reverts-------------
        moneyVault.withdrawUSDC(godFather, godFather, 500e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(godFather), godFatherStartingBal);
    }
}
