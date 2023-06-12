// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//import "../dependencies/IERC2612.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
interface INDLToken  {

  // --- Events ---


  event NDLStakingAddressSet(address _ndlStakingAddress);
  event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

  // --- Functions ---

  function sendNDLToPool(address _sender, uint256 _amount) external;
  function returnFromPool(address _sender, uint256 _amount) external;

}
