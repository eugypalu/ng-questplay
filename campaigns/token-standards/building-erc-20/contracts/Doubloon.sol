// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";

/**
 * @dev ERC-20 token contract.
 */
contract Doubloon is IERC20 {

    string _name;
    string _symbol;
    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 _supply) {
        _name = "Doubloon";
        _symbol = "DBL";
        _totalSupply = _supply;
        _balances[msg.sender] = _supply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowances[from][spender];
        if (spenderAllowance < value) {
            revert("ERC20InsufficientAllowance");
        }
        _transfer(from, to, value);
        _approve(from, spender, spenderAllowance - value, false);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert("ERC20InvalidSender");
        }
        if (to == address(0)) {
            revert("ERC20InvalidReceiver");
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert("ERC20InsufficientBalance");
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert("ERC20InvalidApprover");
        }
        if (spender == address(0)) {
            revert("ERC20InvalidSpender");
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

}