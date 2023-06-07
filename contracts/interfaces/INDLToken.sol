// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//import "../dependencies/IERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface INDLToken  {

  // --- Events ---


  event NDLStakingAddressSet(address _ndlStakingAddress);
  event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

  // --- Functions ---

  function sendToNDLStaking(address _sender, uint256 _amount) external;

}
