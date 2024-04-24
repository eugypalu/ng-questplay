// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Doubloon.sol";

contract MintableDoubloon is Doubloon {
    address owner;

    constructor(uint256 _supply) Doubloon(_supply) {
        owner = msg.sender;
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Only the owner can mint new tokens");
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

}
