// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";

import { Exchange } from "../src/Exchange.sol";
import { Token } from '../src/Token.sol';

contract ExchangeTest is Test {
    Exchange internal exchange;
    Token internal token;
    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);

    function setUp() public virtual {
        token = new Token("Dai Stablecoin", "DAI", 100);
        exchange = new Exchange(address(token));

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.label(alice, "alice");
        vm.label(bob, "bob");
    }

    function testSetUp() external {
        assertEq("UNI-V1", exchange.name());
        assertEq("UNI-V1", exchange.symbol());
        assertEq(exchange.getReserves(), 0);
        assertEq(address(exchange).balance, 0);

        assertEq("Dai Stablecoin", token.name());
        assertEq("DAI", token.symbol());
        assertEq(token.totalSupply(), 100);
    }

    function testGetAmount() public {
        assertEq(exchange.getAmount(1 ether, 1 ether, 1000), 499);    
        assertEq(exchange.getAmount(1 ether, 1 ether, 100), 49);
        assertEq(exchange.getAmount(1, 1, 1), 0);
    }

    function testAddLiquidityAsFirstLP() public {
        token.transfer(alice, 50);
        assertEq(token.balanceOf(alice), 50);
        
        vm.prank(alice);
        token.approve(address(exchange), 10);
        
        vm.prank(alice);
        exchange.addLiquidity{ value: 1 ether}(10);

        assertEq(alice.balance, 9 ether);
        assertEq(address(exchange).balance, 1 ether);
        assertEq(exchange.getReserves(), 10);
        assertEq(exchange.balanceOf(alice), 1 ether);
        assertEq(exchange.totalSupply(), 1 ether);
    }

    function testAddLiquidityAsSecondLP() public {
        token.transfer(alice, 50);
        token.transfer(bob, 50);

        assertEq(token.balanceOf(alice), 50);
        assertEq(token.balanceOf(bob), 50);
        
        vm.prank(alice);
        token.approve(address(exchange), 50);
        vm.prank(bob);
        token.approve(address(exchange), 50);

        assertEq(token.allowance(alice, address(exchange)), 50);
        assertEq(token.allowance(bob, address(exchange)), 50);

        
        vm.prank(alice);
        exchange.addLiquidity{ value: 1 ether}(10);

        assertEq(alice.balance, 9 ether);
        assertEq(address(exchange).balance, 1 ether);
        assertEq(exchange.getReserves(), 10);
        assertEq(exchange.balanceOf(alice), 1 ether);
        assertEq(exchange.totalSupply(), 1 ether);

        vm.prank(bob);
        exchange.addLiquidity{ value: 1 ether }(10);
        
        assertEq(bob.balance, 9 ether);
        assertEq(address(exchange).balance, 2 ether);
        assertEq(exchange.getReserves(), 20);
        assertEq(exchange.balanceOf(bob), 1 ether);
        assertEq(exchange.totalSupply(), 2 ether);
    }

    function testRemoveLiquidity() public {
        token.transfer(alice, 50);
        token.transfer(bob, 50);

        assertEq(token.balanceOf(alice), 50);
        assertEq(token.balanceOf(bob), 50);
        
        vm.prank(alice);
        token.approve(address(exchange), 50);
        vm.prank(bob);
        token.approve(address(exchange), 50);

        assertEq(token.allowance(alice, address(exchange)), 50);
        assertEq(token.allowance(bob, address(exchange)), 50);

        
        vm.prank(alice);
        exchange.addLiquidity{ value: 1 ether}(10);

        assertEq(alice.balance, 9 ether);
        assertEq(address(exchange).balance, 1 ether);
        assertEq(exchange.getReserves(), 10);
        assertEq(exchange.balanceOf(alice), 1 ether);
        assertEq(exchange.totalSupply(), 1 ether);

        vm.prank(bob);
        exchange.addLiquidity{ value: 1 ether }(10);
        
        assertEq(bob.balance, 9 ether);
        assertEq(address(exchange).balance, 2 ether);
        assertEq(exchange.getReserves(), 20);
        assertEq(exchange.balanceOf(bob), 1 ether);
        assertEq(exchange.totalSupply(), 2 ether);

        vm.prank(alice);
        exchange.removeLiquidity(1 ether);
        assertEq(address(exchange).balance, 1 ether);
        assertEq(exchange.getReserves(), 10);
        assertEq(exchange.balanceOf(alice), 0);
        assertEq(exchange.totalSupply(), 1 ether);
        assertEq(alice.balance, 10 ether);
        assertEq(token.balanceOf(alice), 50);
    }
}