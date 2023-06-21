
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;

import "./interfaces/INFTUSDToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTUSDToken is INFTUSDToken , ERC20, ERC20Permit, Ownable{
    address private _pool;

    constructor() ERC20("NFTUSDToken", "NFTUSD") ERC20Permit("NFTUSDToken") {}


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

    // The functions below are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20)
    {
        super._afterTokenTransfer(from, to, amount);
        emit BalanceTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
    internal
    override(ERC20)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
    internal
    override(ERC20)
    {
        super._burn(account, amount);
    }


    //function mint onlyOwner
    function mint(address user, uint256 amount) public  onlyPool {
        _mint(user, amount);
        emit Mint(user, amount);
    }

    //function burn onlyOwner
    function burn(address user, uint256 amount) public onlyPool{
        _burn(user, amount);
        emit Burn(user, amount);
    }
    function sendToPool(address _sender,  address _poolAddress, uint256 _amount) external override onlyPool {

        _transfer(_sender, _poolAddress, _amount);
    }

    function returnFromPool(address _poolAddress, address _receiver, uint256 _amount) external override onlyPool{
        _transfer(_poolAddress, _receiver, _amount);
    }

    function redeemedTransfer(address _sender, address _receiver, uint256 _amount) external override onlyPool{
        _transfer(_sender, _receiver, _amount);
    }
}
    //    /**
//     * @dev Returns the decimals of the token.
//   */
//    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
//        return _customDecimals;
//    }

