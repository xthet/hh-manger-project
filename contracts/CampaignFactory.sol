// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Campaign } from "./Campaign.sol";

contract CampaignFactory {
  struct cmpInput {
    string  _title; 
    string  _description;
    string  _category;
    string  _tags; 
    uint256 _goalAmount;
    uint256 _duration;
    string _imageURI;
  }

  function createCampaign(address _crf, address payable _creator, address _rwdFactory, cmpInput memory _cmp) public returns (address) {
    Campaign cmp = new Campaign(
      _crf,
      _creator,
      _rwdFactory,
      _cmp._title,
      _cmp._description,
      _cmp._category,
      _cmp._tags,
      _cmp._goalAmount,
      _cmp._duration,
      _cmp._imageURI
    );

    return address(cmp);
  }
}