// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;


import "../interfaces/INDLToken.sol";
import "../dependencies/SafeMath.sol";
contract LockupContract  {
    using SafeMath for uint;

    // --- Data ---
    string constant public NAME = "LockupContract";

    uint constant public SECONDS_IN_ONE_YEAR = 31536000;

    address public immutable beneficiary;

    INDLToken public ndlToken;

    // Unlock time is the Unix point in time at which the beneficiary can withdraw.
    uint public unlockTime;

    // --- Events ---

    event LockupContractCreated(address _beneficiary, uint _unlockTime);
    event LockupContractEmptied(uint _LQTYwithdrawal);

    // --- Functions ---

    constructor
    (
        address _ndlTokenAddress,
        address _beneficiary,
        uint _unlockTime
    )
    {
        ndlToken = INDLToken(_ndlTokenAddress);

        /*
        * Set the unlock time to a chosen instant in the future, as long as it is at least 1 year after
        * the system was deployed
        */
//        _requireUnlockTimeIsAtLeastOneYearAfterSystemDeployment(_unlockTime);
        unlockTime = _unlockTime;

        beneficiary =  _beneficiary;
        emit LockupContractCreated(_beneficiary, _unlockTime);
    }

    function withdrawNDL() external {
        _requireCallerIsBeneficiary();
        _requireLockupDurationHasPassed();

        INDLToken ndlTokenCached = ndlToken;
        uint NDLBalance = ndlTokenCached.balanceOf(address(this));
        ndlTokenCached.transfer(beneficiary, NDLBalance);
        emit LockupContractEmptied(NDLBalance);
    }

    // --- 'require' functions ---

    function _requireCallerIsBeneficiary() internal view {
        require(msg.sender == beneficiary, "LockupContract: caller is not the beneficiary");
    }

    function _requireLockupDurationHasPassed() internal view {
        require(block.timestamp >= unlockTime, "LockupContract: The lockup duration must have passed");
    }

    function _requireUnlockTimeIsAtLeastOneYearAfterSystemDeployment(uint _unlockTime) internal view {
        uint systemDeploymentTime = ndlToken.getDeploymentStartTime();
        require(_unlockTime >= systemDeploymentTime.add(SECONDS_IN_ONE_YEAR), "LockupContract: unlock time must be at least one year after system deployment");
    }
}