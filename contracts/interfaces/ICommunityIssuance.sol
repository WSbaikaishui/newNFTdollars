// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ICommunityIssuance { 
    
    // --- Events ---
    
    event NFTUSDTokenAddressSet(address _lqtyTokenAddress);
    event StabilityPoolAddressSet(address _stabilityPoolAddress);
    event TotalNFTUSDIssuedUpdated(uint _totalLQTYIssued);

    // --- Functions ---

    function setAddresses(address _lqtyTokenAddress, address _stabilityPoolAddress) external;

    function issueNDL() external returns (uint);
    function sendNFTUSD(address _account, uint _LQTYamount) external;
    function sendNDL(address _account, uint _LQTYamount) external;


}
