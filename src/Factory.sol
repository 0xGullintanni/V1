// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './ERC20.sol';
import './IERC20.sol';
import './Token.sol';
import './Exchange.sol';

contract Factory {
    address[] public exchanges;
    address[] public tokens;

    mapping(address => address) public tokenToExchange;
    mapping(address => address) public exchangeToToken;

    function createExchange(address _tokenAddress) public returns(address) {
        require(_tokenAddress != address(0), "Token address cannot be 0x0");
        require(tokenToExchange[_tokenAddress] == address(0), "Exchange already exists for this token");

        Exchange exchange = new Exchange(_tokenAddress);
        exchanges.push(address(exchange));
        tokens.push(_tokenAddress);

        tokenToExchange[_tokenAddress] = address(exchange);
        exchangeToToken[address(exchange)] = _tokenAddress;

        return address(exchange);
    }

    function getTokenForExchange(address _exchangeAddress) public view returns (address) {
        return exchangeToToken[_exchangeAddress];
    }

    function getExchangeForToken(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}