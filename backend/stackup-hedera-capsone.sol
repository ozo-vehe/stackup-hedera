// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.9;

import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/HederaResponseCodes.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/IHederaTokenService.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/HederaTokenService.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/ExpiryHelper.sol";

contract MerchantBackend is ExpiryHelper {
  event CreatedToken(address tokenAddress);
  event MintedToken(int64[] serialNumbers);
  event Response(int response);

  address public ftAddress;
  address public owner;
  uint256 public lockupAmount = 100000000000;
}
