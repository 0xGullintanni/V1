// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './ERC20.t.sol';
import './IERC20.sol';

contract Exchange {
    address immutable tokenAddress;
    /* The exchange needs to:
      1. swapEthForToken
      2. swapTokenForEth 
      3. addLiquidity
      4. removeLiquidity
      5. getTokenPrice
      6. getTokenBalance
    
      To maintain our invariant x * y = k, we need to keep track of the ETH balance
      of the Exchange contract and the token balance of the Exchange contract. 

      In order to add liquidity, we need to first know if a pool exists for the token,
        - If it does not exist, we need to accept the ETH and the token  
        - If it does exist, we need to determine how much of their token balance can be supplied
          to contract based on msg.value.
    */

   constructor() {
    
   }

   function getReserves() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
   }
}