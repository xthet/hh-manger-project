// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Campaign } from "../../Campaign.sol";
import { Reward } from "../../Reward.sol";
import "../../../node_modules/hardhat/console.sol";

library RefunderLib {
  function refund (
    address _i_crf,
    Campaign.refunder_pckg storage _refP, 
    mapping (uint256 => address) storage _rewards, 
    mapping (address => uint256) storage _aggrDons, 
    mapping (address => uint256[]) storage _entDons, 
    address _donator
    ) external {
    if(msg.sender != _i_crf){revert();}
    if(_refP.c_state == Campaign.C_State.Expired){revert();}
    if(_aggrDons[_donator] == 0 ){revert();}

    uint256 amountToRefund = _aggrDons[_donator];
    console.log(_refP.currentBalance);

    if(_refP.currentBalance < amountToRefund){revert();}
    _refP.currentBalance = _refP.currentBalance - amountToRefund;

    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert();}

    delete _aggrDons[_donator];

    if(_entDons[_donator].length > 0){    
      for(uint i=0; i<_entDons[_donator].length; i++){
        if(!(_rewards[_entDons[_donator][i]] != address(0))){
          Reward(_rewards[_entDons[_donator][i]]).removeDonator(_donator);
        }
      }
    }

    delete _entDons[_donator];
  }
}