// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Campaign } from "../../Campaign.sol";
import "../../Reward.sol";

library Refunder {
  function changeTitle (Campaign.CampaignObject storage _cmp, string memory _newTitle) public {
    _cmp.s_title = _newTitle;

  }

  // function _refund(address _donator, address _campaignAddress) public {
  //   if(msg.sender != Campaign(_campaignAddress).i_crf()){revert();}
  //   if(Campaign(_campaignAddress).c_state() == Campaign.C_State.Expired){revert();}
  //   if(Campaign(_campaignAddress).aggrDonations(_donator) == 0 ){revert();}

  //   uint256 amountToRefund = Campaign(_campaignAddress).aggrDonations(_donator);

  //   if(Campaign(_campaignAddress).currentBalance() < amountToRefund){revert();}
  //   Campaign(_campaignAddress).currentBalance = Campaign(_campaignAddress).currentBalance - amountToRefund;

  //   (bool success, ) = payable(_donator).call{value: amountToRefund}("");
  //   if(!success){revert();}

  //   delete Campaign(_campaignAddress).aggrDonations[_donator];

  //   if(Campaign(_campaignAddress).entDonations[_donator].length > 0){    
  //     for(uint i=0; i<Campaign(_campaignAddress).entDonations[_donator].length; i++){
  //       if(!(Campaign(_campaignAddress).rewards[Campaign(_campaignAddress).entDonations[_donator][i]] != address(0))){
  //         Reward(Campaign(_campaignAddress).rewards[Campaign(_campaignAddress).entDonations[_donator][i]]).removeDonator(_donator);
  //       }
  //     }
  //   }
    
  //   delete Campaign(_campaignAddress).entDonations[_donator];
  // }

}