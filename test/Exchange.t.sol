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
}