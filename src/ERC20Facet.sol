// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./LibDiamond.sol";

contract ERC20Facet {
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.erc20.storage");

    struct ERC20Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function erc20Storage() internal pure returns (ERC20Storage storage s) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function name() external view returns (string memory) {
        return erc20Storage().name;
    }

    function symbol() external view returns (string memory) {
        return erc20Storage().symbol;
    }

    function decimals() external view returns (uint8) {
        return erc20Storage().decimals;
    }

    function totalSupply() external view returns (uint256) {
        return erc20Storage().totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return erc20Storage().balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return erc20Storage().allowances[owner][spender];
    }

    function initERC20(string calldata _name, string calldata _symbol, uint256 _initialSupply) external {
        LibDiamond.enforceIsContractOwner();
        ERC20Storage storage s = erc20Storage();
        require(bytes(_name).length > 0, "ERC20Facet: Name is empty");
        require(bytes(s.name).length == 0, "ERC20Facet: Already initialized");
        s.name = _name;
        s.symbol = _symbol;
        s.decimals = 18;
        s.totalSupply = _initialSupply;
        s.balances[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        erc20Storage().allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        ERC20Storage storage s = erc20Storage();
        uint256 allowed = s.allowances[from][msg.sender];
        require(allowed >= amount, "ERC20Facet: Allowance too low");
        s.allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20Facet: Transfer to zero address");
        ERC20Storage storage s = erc20Storage();
        require(s.balances[from] >= amount, "ERC20Facet: Balance too low");
        s.balances[from] -= amount;
        s.balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}
