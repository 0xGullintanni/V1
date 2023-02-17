// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { stdStorage, StdStorage, Test } from "forge-std/Test.sol";

import { ERC20 } from "../src/ERC20.sol";

contract ERC is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        super._burn(account, amount);
    }
}

contract ERC20Test is Test {
    ERC20 internal token;
    ERC internal erc;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);

    function setUp() public virtual {
        token = new ERC20("Test", "TST");
        erc = new ERC("Tester", "TEST");
    }

    function testSetUp() external {
        assertEq("Test", token.name());
        assertEq("TST", token.symbol());
        assertEq("Tester", erc.name());
        assertEq("TEST", erc.symbol());
    }

    function testMint() public {
        erc.mint(alice, 100);
        assertEq(100, erc.balanceOf(alice));
        assertEq(erc.totalSupply(), erc.balanceOf(alice));
    }   

    
    function testBurn() public {
        erc.mint(alice, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(alice));
        assertEq(erc.totalSupply(), 100);

        erc.burn(alice, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(alice));
        assertEq(erc.totalSupply(), 0);
    }
    
    function testTransferToken() public {
        erc.mint(alice, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(alice));
        assertEq(erc.totalSupply(), 100);

        vm.prank(alice);
        erc.transfer(bob, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(bob));
        assertEq(erc.totalSupply(), 100);
        assertEq(erc.balanceOf(bob), 100);
         assertEq(erc.balanceOf(alice), 0);
    }

    function testTransferFromToken() public {
        erc.mint(alice, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(alice));
        assertEq(erc.totalSupply(), 100);

        vm.prank(alice);
        erc.approve(bob, 100);
        assertEq(erc.allowance(alice, bob), 100);

        vm.prank(bob);
        erc.transferFrom(alice, bob, 100);
        assertEq(erc.totalSupply(), erc.balanceOf(bob));
        assertEq(erc.totalSupply(), 100);
        assertEq(erc.balanceOf(bob), 100);
        assertEq(erc.balanceOf(alice), 0);
    }
}