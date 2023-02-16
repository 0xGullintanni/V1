// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";

import { ERC20 } from "../src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 internal token;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);

    function setUp() public virtual {
        token = new ERC20("Test", "TST");
    }

    function testSetUp() external {
        assertEq("Test", token.name());
        assertEq("TST", token.symbol());
    }

    function testMint() public {
        token._mint(alice, 100);
        assertEq(100, token.balanceOf(alice));
        assertEq(token.totalSupply(), token.balanceOf(alice));
    }   

    function testBurn() public {
        token._mint(alice, 100);
        assertEq(token.totalSupply(), token.balanceOf(alice));
        assertEq(token.totalSupply(), 100);

        token.burn(alice, 100);
        assertEq(token.totalSupply(), token.balanceOf(alice));
        assertEq(token.totalSupply(), 0);
    }

    function testTransferToken() public {
        token._mint(alice, 100);
        assertEq(token.totalSupply(), token.balanceOf(alice));
        assertEq(token.totalSupply(), 100);

        vm.prank(alice);
        token.transfer(bob, 100);
        assertEq(token.totalSupply(), token.balanceOf(bob));
        assertEq(token.totalSupply(), 100);
        assertEq(token.balanceOf(bob), 100);
         assertEq(token.balanceOf(alice), 0);
    }
}