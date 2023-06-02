// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin
    ) TimelockController(_minDelay, _proposers, _executors, _admin) {}
}
