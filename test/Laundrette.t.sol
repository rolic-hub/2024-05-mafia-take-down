// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { BaseTest, console } from "test/Base.t.sol";
import { Role } from "src/Kernel.sol";

contract LaundretteTest is BaseTest {
    address attacker = makeAddr("Attacker");

    function test_joinAndQuitGang() public {
        joinGang(address(this));
        assertEq(kernel.hasRole(address(this), Role.wrap("gangmember")), true);
        laundrette.quitTheGang(address(this));

        assertEq(kernel.hasRole(address(this), Role.wrap("gangmember")), false);
    }

    function test_depositAndWithdrawUSDC() public {
        vm.prank(godFather);
        usdc.transfer(address(this), 100e6);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(address(this), address(this), 100e6);
        assertEq(usdc.balanceOf(address(this)), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(address(this)), 100e6);

        joinGang(address(this));
        laundrette.withdrawMoney(address(this), address(this), 100e6);
        assertEq(usdc.balanceOf(address(this)), 100e6);
        assertEq(usdc.balanceOf(address(moneyShelf)), 0);
        assertEq(crimeMoney.balanceOf(address(this)), 0);
    }

    function test_UserCandeposit() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        assertEq(usdc.balanceOf(user), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(user), 100e6);
    }

    function test_godfatherCantWithdrawUserTokens() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();
        uint godFatherStartingBalance = usdc.balanceOf(godFather);
        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        vm.stopPrank();
        assertEq(usdc.balanceOf(user), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(user), 100e6);

        joinGang(address(0));
        vm.startPrank(godFather);
        // --------------Reverts----------------------
        laundrette.withdrawMoney(godFather, godFather, 100e6);
        assertEq(usdc.balanceOf(godFather), godFatherStartingBalance);
        assertEq(usdc.balanceOf(address(moneyShelf)), 0);
        assertEq(crimeMoney.balanceOf(godFather), 0);
    }

    function testFail_UserCantWithdraw() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        assertEq(usdc.balanceOf(user), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(user), 100e6);

        laundrette.withdrawMoney(user, user, 100e6);
        assertEq(usdc.balanceOf(user), 100e6);
    }

    function test_canHijackUserFunds() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        vm.stopPrank();

        vm.startPrank(attacker);
        laundrette.depositTheCrimeMoneyInATM(user, attacker, 100e6);
        assertEq(usdc.balanceOf(user), 0);
        assertEq(usdc.balanceOf(address(moneyShelf)), 100e6);
        assertEq(crimeMoney.balanceOf(attacker), 100e6);
        assertEq(crimeMoney.balanceOf(user), 0);
    }

    function test_canJoinGang() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        vm.stopPrank();
        joinGang(user);
        assertEq(kernel.hasRole(user, Role.wrap("gangmember")), true);
        vm.startPrank(user);
        laundrette.withdrawMoney(user, user, 100e6);
        assertEq(usdc.balanceOf(user), 100e6);
        assertEq(usdc.balanceOf(address(moneyShelf)), 0);
        assertEq(crimeMoney.balanceOf(user), 0);
    }

    function test_canGangMemberHijack() public {
        vm.startPrank(godFather);
        usdc.transfer(user, 100e6);
        vm.stopPrank();

        vm.startPrank(user);
        usdc.approve(address(moneyShelf), 100e6);
        laundrette.depositTheCrimeMoneyInATM(user, user, 100e6);
        vm.stopPrank();

        joinGang(attacker);
        //assertEq(kernel.hasRole(user, Role.wrap("gangmember")), true);
        assertEq(kernel.hasRole(attacker, Role.wrap("gangmember")), true);
        vm.startPrank(attacker);
        laundrette.withdrawMoney(user, attacker, 100e6);
        assertEq(usdc.balanceOf(attacker), 100e6);
        assertEq(usdc.balanceOf(address(moneyShelf)), 0);
        assertEq(crimeMoney.balanceOf(user), 0);
    }

    function joinGangOnly(address account) internal {
        vm.prank(godFather);
        laundrette.addToTheGang(account);
    }

    //takeGunsTest
    function test_canTakeOthersGuns() public {
        joinGang(user);
        joinGangOnly(attacker);

        vm.prank(godFather);
        laundrette.putGunsInTheSuspendedCeiling(user, 3);
        assertEq(weaponShelf.getAccountAmount(user), 3);

        vm.startPrank(attacker);
        vm.expectRevert();
        laundrette.takeGuns(user, 3);
        vm.stopPrank();
        assertEq(weaponShelf.getAccountAmount(user), 0);
    }

    function test_depositAndWithdrawWeapon() public {
        vm.prank(godFather);
        laundrette.putGunsInTheSuspendedCeiling(address(this), 3);
        assertEq(weaponShelf.getAccountAmount(address(this)), 3);

        joinGang(address(this));
        laundrette.takeGuns(address(this), 3);
        assertEq(weaponShelf.getAccountAmount(address(this)), 0);
    }
}
