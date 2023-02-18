// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IExchange {
    function ethForTokenSwap(uint256 _minTokens) external payable;

    function ethForTokenTransfer(uint256 _minTokens, address _recipient) external payable;

    function getTokenAmount(uint ethSold) external view returns (uint256);
}