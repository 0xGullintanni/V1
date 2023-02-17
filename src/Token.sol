// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './ERC20.sol';

contract Token is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 amount) ERC20(name_, symbol_) {
        _mint(msg.sender, amount);
    }
}