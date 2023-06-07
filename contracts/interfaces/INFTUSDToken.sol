// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTUSDToken is  IERC20 {
//
//  /**
//   * @dev Initializes the NFTUSD
//
//   */
//  function initialize(
//    address stabilitypool,
//    uint8 NFTUSDDecimals,
//    string calldata NFTUSDName,
//    string calldata NFTUSDSymbol
//  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   **/
  event Mint(address indexed from, uint256 value);

  /**
   * @dev Mints `amount` NFTUSDs to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   */
  function mint(
    address user,
    uint256 amount
  ) external ;

  /**
   * @dev Emitted after NFTUSDs are burned
   * @param from The owner of the NFTUSDs, getting them burned
   * @param value The amount being burned
   **/
  event Burn(address indexed from, uint256 value);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred

   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Burns NFTUSDs from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the NFTUSDs, getting them burned
   * @param amount The amount being burned
   **/
  function burn(
    address user,
    uint256 amount
  ) external;

  function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

  function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

}
