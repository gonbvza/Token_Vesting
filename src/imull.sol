// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ImULL is ERC20 {
    uint256 private initialSupply = 10000000000 ether;

    constructor() ERC20("imull", "ImULL") {
        _mint(msg.sender, initialSupply);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function mint( address to, uint256 amount) public {
        _mint(to, amount);
    }
}
