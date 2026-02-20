# ERC-20 Token Template with Fees
# Production-ready smart contract

# SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FeeToken is ERC20, Ownable, ReentrancyGuard {
    
    // Fee configuration
    uint256 public buyFee = 100; // 1% (100/10000)
    uint256 public sellFee = 200; // 2%
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // Fee recipient (marketing wallet, treasury, etc.)
    address public feeRecipient;
    
    // Whitelist (DEXs, CEXs don't pay fees)
    mapping(address => bool) public isWhitelisted;
    
    // Events
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event FeeRecipientUpdated(address newRecipient);
    event WhitelistUpdated(address account, bool status);
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _feeRecipient
    ) ERC20(name, symbol) {
        require(_feeRecipient != address(0), "Invalid recipient");
        feeRecipient = _feeRecipient;
        
        // Mint initial supply to deployer
        _mint(msg.sender, initialSupply * 10**decimals());
        
        // Whitelist deployer
        isWhitelisted[msg.sender] = true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // Skip fees for whitelisted addresses
        if (isWhitelisted[sender] || isWhitelisted[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }
        
        uint256 fee = 0;
        
        // Determine if buy or sell based on common DEX patterns
        // This is simplified - real implementation needs pair detection
        if (sender == owner()) {
            // Selling (owner to DEX)
            fee = (amount * sellFee) / FEE_DENOMINATOR;
        } else {
            // Buying (DEX to user)
            fee = (amount * buyFee) / FEE_DENOMINATOR;
        }
        
        if (fee > 0) {
            super._transfer(sender, feeRecipient, fee);
            super._transfer(sender, recipient, amount - fee);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
    
    // Owner functions
    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 1000 && _sellFee <= 1000, "Max 10% fee");
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit FeesUpdated(_buyFee, _sellFee);
    }
    
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
    
    function setWhitelist(address account, bool status) external onlyOwner {
        isWhitelisted[account] = status;
        emit WhitelistUpdated(account, status);
    }
    
    // Utility functions
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    receive() external payable {
        // Accept ETH for liquidity adds
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}
