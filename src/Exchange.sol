// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './ERC20.sol';
import './IERC20.sol';
import './IFactory.sol';
import './IExchange.sol';

contract Exchange is ERC20 {
    address immutable tokenAddress;
    address immutable factoryAddress;

   constructor(address _tokenAddress) ERC20("UNI-V1", "UNI-V1") {
        require(_tokenAddress != address(0), "Token address cannot be 0x0");
        require(msg.sender != address(0), "Factory address cannot be 0x0");
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;
   }

   function getReserves() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
   }

   function getTokenAmount(uint ethSold) public view returns (uint256) {
       // return the amount of tokens to be expected for a given swap
       require(ethSold > 0, "Eth sold must be greater than 0");
       uint outputReserve = getReserves();
       return getAmount(ethSold, address(this).balance - ethSold, outputReserve);
   }

   function getEthAmount(uint tokensSold) public view returns (uint256) {
       // return the amount of ETH to be expected for a given swap
       require(tokensSold > 0, "Tokens sold must be greater than 0"); 
       uint inputReserve = getReserves();

       return getAmount(tokensSold, inputReserve - tokensSold, address(this).balance);
   }

   function getAmount(uint inputAmount, uint inputReserve, uint outputReserve) public pure returns (uint256) {
        // invariant = address(this).balance * getReserves() = k
        /* 

        y0 = Output Amount
        y = Output Reserves
        x0 = Input Amount
        x = Input Reserves

        x * y = k => 
        (x + x0) * (y - y0) = k =>
        (x + x0) * (y - y0) = x * y =>
        y - y0 = (x * y) / (x + x0) =>
        -y0 = (x * y) / (x + x0) - y =>
        y0 = y - (x * y) / (x + x0) =>
        y0 = y(x + x0) / (x + x0) - (x * y) / (x + x0) =>
        y0 = y(x + x0) - (x * y) / (x + x0) =>
        y0 = (yx + yx0 - xy) / (x + x0) => 
        y0 = yx0 / (x + x0) 

        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
        */
       require(inputReserve > 0 && inputAmount > 0, "Reserves must be greater than 0");

        // Taking a .3% fee on the input amount
        // Due to weirdness around floating point division we need to do a thing:
        // Normally we should take => (inputAmount) * (100 - fee) / 100 => but here 
        // we have to do => (inputAmount * (1000 - fee)) / 1000 to avoid floating point errors

        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;

       return numerator / denominator; // Solidity truncates uint256 towards 0
   }

    function ethForTokenTransfer(uint minTokens, address recipient) public payable returns (uint) {
        uint tokenAmount = getTokenAmount(msg.value);
        require(tokenAmount >= minTokens, "Token amount must be greater than minTokens");

        IERC20(tokenAddress).transfer(recipient, tokenAmount);

        return tokenAmount;
    }

    function tokenForEthSwap(uint tokensSold, uint minEth) public returns(uint) {
        uint ethAmount = getEthAmount(tokensSold);
        require(ethAmount >= minEth, "Eth amount must be greater than minEth");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensSold);
        payable(msg.sender).transfer(ethAmount);

        return ethAmount;
    }

    function tokenForTokenSwap(uint tokensSold, uint minTokens, address targetToken) public returns(uint) {
        address exchangeDesired = IFactory(factoryAddress).getExchangeForToken(targetToken);
        require(exchangeDesired != address(0) && exchangeDesired != address(this), "targetToken leads to invalid exchange.");

        // Swap for ETH first
        uint ethSwapped = getEthAmount(tokensSold);

        // Swap eth for target token
        uint tokensAcq = IExchange(exchangeDesired).getTokenAmount(ethSwapped);
        require(tokensAcq >= minTokens, "Token amount must be greater than minTokens");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensSold);
        IExchange(exchangeDesired).ethForTokenTransfer{ value: ethSwapped }(minTokens, _msgSender());

        return tokensAcq; 
    }

    function addLiquidity(uint tokensAdded) public payable returns (uint256) {
        require(msg.value > 0, "Must send ETH to add liquidity");
        require(tokensAdded > 0, "Must send tokens to add liquidity");
        // x * y = k => x = ethBalance, y = tokenBalance
        // (x + msg.value) * (y + tokensAdded) = k' 
        // shares to mint = (msg.value * token.totalSupply() / ethBalance) 
        uint ethBalance = address(this).balance;
        uint tokenBalance = getReserves();

        if(tokenBalance == 0) {
            // Pool does not exist, so we need to accept the ETH and the token
            IERC20 token = IERC20(tokenAddress);
            uint liquidity = address(this).balance; // for payable functions, contract balance is updated before function is called
            require(token.balanceOf(msg.sender) >= tokensAdded, "Sender must have enough tokens to add liquidity");
            token.transferFrom(msg.sender, address(this), tokensAdded);
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            // Pool exists, so we need to determine how much of their token balance can be supplied
            // to contract based on msg.value.
            IERC20 token = IERC20(tokenAddress);
            uint liquidity = (msg.value * totalSupply()) / (ethBalance - msg.value);
            require(liquidity >= tokensAdded, "Token amount must be less than liquidity sent back to user as LP tokens.");
            require(token.balanceOf(msg.sender) >= tokensAdded, "Sender must have enough tokens to add liquidity");
            token.transferFrom(msg.sender, address(this), tokensAdded);

            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function removeLiquidity(uint256 tokenAmount) public returns(uint, uint) {
        // Check that invariant is maintained
        require(tokenAmount > 0, "Token amount must be greater than 0");

        uint ethAmount = (address(this).balance * tokenAmount) / totalSupply();
        uint tokenAmt = (getReserves() * tokenAmount) / totalSupply();
        // Invariant maintenance => y / x = dy / dx
        require((getReserves() / address(this).balance) == ((getReserves() + tokenAmt) / (address(this).balance + ethAmount)), "Invariant must be maintained");
        _burn(msg.sender, tokenAmount);
        
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmt);

        return (ethAmount, tokenAmount);
    }
}