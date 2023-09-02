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

  constructor() payable {
    IHederaTokenService.HederaToken memory token;
    token.name = "Reputation Tokens";
    token.symbol = "REP";
    token.memo = "REP Tokens By: Ozovehe";
    token.treasury = address(this);
    token.expiry = createAutoRenewExpiry(address(this), 7000000);

    (int responseCode, address tokenAddress) = HederaTokenService
      .createFungibleToken(token, 1000, 0);

    if (responseCode != HederaResponseCodes.SUCCESS) {
      revert();
    }

    ftAddress = tokenAddress;
    owner = msg.sender;
    emit CreatedToken(tokenAddress);
  }
}
