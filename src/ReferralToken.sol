// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract ReferralToken is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 private _decimals;
    uint256 public maxSupply;

    constructor(string memory name, string memory symbol, uint8 tokenDecimals, uint256 _maxSupply, address admin)
        ERC20(name, symbol)
    {
        require(admin != address(0), "Admin address cannot be zero");

        _decimals = tokenDecimals;
        maxSupply = _maxSupply;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "Cannot mint to the zero address");
        require(totalSupply() + amount <= maxSupply, "Exceeds maximum token supply");

        _mint(to, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function updateMaxSupply(uint256 newMaxSupply) external onlyRole(ADMIN_ROLE) {
        require(newMaxSupply >= totalSupply(), "New max supply must be >= current total supply");
        maxSupply = newMaxSupply;
    }

    function addMinter(address minter) external onlyRole(ADMIN_ROLE) {
        require(minter != address(0), "Minter address cannot be zero");
        grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyRole(ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
