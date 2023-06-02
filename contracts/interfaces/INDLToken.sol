// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../dependencies/IERC20.sol";
import "../dependencies/IERC2612.sol";

interface INDLToken is IERC20, IERC2612 {

  // --- Events ---


  event NDLStakingAddressSet(address _ndlStakingAddress);
  event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

  // --- Functions ---

  function sendToNDLStaking(address _sender, uint256 _amount) external;

  function getDeploymentStartTime() external view returns (uint256);

  function getLpRewardsEntitlement() external view returns (uint256);
}
