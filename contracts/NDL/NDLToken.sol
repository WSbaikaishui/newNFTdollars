// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgrade;
//import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract NDLToken is
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable
{
  address private _pool;
  constructor()  {}

  function initialize() public initializer {
    __ERC20_init("NDLToken", "NDL");
    __ERC20Permit_init("NDLToken");

    __Ownable_init();
    _mint(msg.sender, 1000000000 * 10 ** decimals());
  }


  //function initialize pool;
  function initializePool(address pool) public onlyOwner {
    _pool = pool;
    renounceOwnership();
  }

  //modify only pool
  modifier onlyPool() {
    require(_pool == msg.sender, "Ownable: caller is not the pool");
    _;
  }
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._burn(account, amount);
  }
  function mint(address to, uint256 amount) public onlyPool {
    _mint(to, amount);
  }


}