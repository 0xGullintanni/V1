// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IFactory {
    function createExchange(address _tokenAddress) external returns(address);
    function getTokenForExchange(address _exchangeAddress) external view returns (address);
    function getExchangeForToken(address _tokenAddress) external view returns (address);
}