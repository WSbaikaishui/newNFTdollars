// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/INDLToken.sol";

contract NDLToken is
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable,
  INDLToken
{
  address private _pool;
  uint private _deploymentStartTime;
  constructor()  {
  }

  function initialize(address lockup) public initializer {
    __ERC20_init("NDLToken", "NDL");
    __ERC20Permit_init("NDLToken");
    __Ownable_init();
    _mint(lockup, 25000000*10 ** decimals());
    _mint(msg.sender, 75000000* 10 ** decimals());
  }


  //function initialize pool;
  function initializePool(address pool) public onlyOwner {

    _pool = pool;
    renounceOwnership();
  }

  function getDeploymentStartTime() external view override returns (uint256){
    return _deploymentStartTime;
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

//  function mint(address to, uint256 amount) public onlyPool {
//    _mint(to, amount);
//  }

  function sendNDLToPool(address _sender, uint256 _amount) external onlyPool{
    _transfer(_sender, _pool, _amount);
  }

  function returnFromPool(address _receiver, uint256 _amount) external onlyPool{
    _transfer(_pool, _receiver, _amount);
  }

}