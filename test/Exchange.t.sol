// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";

import { Exchange } from "../src/Exchange.sol";
import { Token } from '../src/Token.sol';

contract ExchangeTest is Test {
    Exchange internal exchange;
    Exchange internal otherExchange;

    Token internal token;
    Token internal otherToken;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);

    function setUp() public virtual {
        token = new Token("Dai Stablecoin", "DAI", 100);
        otherToken = new Token("OtherCoin", "OC", 100);

        exchange = new Exchange(address(token));
        otherExchange = new Exchange(address(otherToken));

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

        assertEq("UNI-V1", otherExchange.name());
        assertEq("UNI-V1", otherExchange.symbol());
        assertEq(otherExchange.getReserves(), 0);
        assertEq(address(otherExchange).balance, 0);

        assertEq("Dai Stablecoin", token.name());
        assertEq("DAI", token.symbol());
        assertEq(token.totalSupply(), 100);

        assertEq("OtherCoin", otherToken.name());
        assertEq("OC", otherToken.symbol());
        assertEq(otherToken.totalSupply(), 100);
    }

    function testGetAmount() public {
        assertEq(exchange.getAmount(1 ether, 1 ether, 1000), 499);    
        assertEq(exchange.getAmount(1 ether, 1 ether, 100), 49);
        assertEq(exchange.getAmount(1, 1, 1), 0);
        assertEq(exchange.getAmount(5 ether, 5 ether, 10), 4);
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

    function testTokenForEthSwap() public {
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
        exchange.tokenForEthSwap(5, .49 ether);

        assertGe(bob.balance, 10.49 ether);
        assertLe(token.balanceOf(bob), 45);
    }

    function testEthForTokenSwap() public {
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
        exchange.ethForTokenSwap{ value: .5 ether }(3);
        assertLe(bob.balance, 9.5 ether);
        assertEq(token.balanceOf(bob), 53);
    }

    function testTokenForTokenSwap() public {
        token.transfer(alice, 50);
        otherToken.transfer(bob, 50);

        assertEq(token.balanceOf(alice), 50);
        assertEq(otherToken.balanceOf(alice), 0);

        assertEq(token.balanceOf(bob), 0);
        assertEq(otherToken.balanceOf(bob), 50);
        
        vm.prank(alice);
        token.approve(address(exchange), 10);
    
        vm.prank(bob);
        otherToken.approve(address(otherExchange), 10);
        
        vm.prank(alice);
        exchange.addLiquidity{ value: 1 ether}(10);

        vm.prank(bob);
        otherExchange.addLiquidity{ value: 1 ether}(10);

        assertEq(alice.balance, 9 ether);
        assertEq(token.balanceOf(alice), 40);
        assertEq(address(exchange).balance, 1 ether);
        assertEq(exchange.getReserves(), 10);
        assertEq(exchange.balanceOf(alice), 1 ether);
        assertEq(exchange.totalSupply(), 1 ether);

        assertEq(bob.balance, 9 ether);
        assertEq(otherToken.balanceOf(bob), 40);
        assertEq(address(otherExchange).balance, 1 ether);
        assertEq(otherExchange.getReserves(), 10);
        assertEq(otherExchange.balanceOf(bob), 1 ether);
        assertEq(otherExchange.totalSupply(), 1 ether);

        vm.prank(alice);
        exchange.tokenForTokenSwap(5, 3, address(otherToken));

        //assertEq(otherToken.balanceOf(alice), 3);
    }

}