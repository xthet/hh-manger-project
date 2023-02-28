// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source,
    address sender
  ) external;
}

contract UpkeepIDConsumer {
  LinkTokenInterface public immutable i_link;
  address public immutable registrar;
  AutomationRegistryInterface public immutable i_registry;
  bytes4 registerSig = KeeperRegistrarInterface.register.selector;

  constructor(
    address _link,
    address _registrar,
    address _registry
  ) {
    i_link = LinkTokenInterface(_link);
    registrar = _registrar;
    i_registry = AutomationRegistryInterface(_registry);
  }

  function registerAndPredictID(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source
  ) public returns(uint){
    (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
    uint256 oldNonce = state.nonce;
    bytes memory payload = abi.encode(
      name,
      encryptedEmail,
      upkeepContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source,
      address(this)
    );

    i_link.transferAndCall(
      registrar,
      amount,
      bytes.concat(registerSig, payload)
    );
    (state, _c, _k) = i_registry.getState();
    uint256 newNonce = state.nonce;
    if (newNonce == oldNonce + 1) {
      uint256 upkeepID = uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            address(i_registry),
            uint32(oldNonce)
          )
        )
      );
      // DEV - Use the upkeepID however you see fit
      return upkeepID;
    } else {
      revert("auto-approve disabled");
    }
  }
}
