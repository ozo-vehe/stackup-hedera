// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.9;

import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/HederaResponseCodes.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/IHederaTokenService.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/HederaTokenService.sol";
import "https://github.com/hashgraph/hedera-smart-contracts/blob/v0.2.0/contracts/hts-precompile/ExpiryHelper.sol";

contract MerchantBackend is ExpiryHelper {
    event CreatedToken(address tokenAddress);
    event MintedToken(int64[] serialNumbers);
    event Response(int256 response);

    address public ftAddress;
    address public owner;
    uint256 public lockupAmount = 100000000000;
    // Varibale to hold the number of Car Nft minted so far
    uint256 public nftCount;

    struct CarNft {
        address owner;
        address carAddress;
        string name;
        string symbol;
        int64 price;
    }

    constructor() payable {
        IHederaTokenService.HederaToken memory token;
        token.name = "Reputation Tokens";
        token.symbol = "REP";
        token.memo = "REP Tokens By: Ozovehe";
        token.treasury = address(this);
        token.expiry = createAutoRenewExpiry(address(this), 7000000);

        (int256 responseCode, address tokenAddress) = HederaTokenService
            .createFungibleToken(token, 1000, 0);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert();
        }

        ftAddress = tokenAddress;
        owner = msg.sender;
        emit CreatedToken(tokenAddress);
    }

    // Mapping to hold minted cr Nfts
    mapping(uint256 => mapping(address => CarNft)) public carNfts;
    // Mapping to hold previous owners
    mapping(address => mapping(int64 => address[])) public previousOwners;

    function createNFT(
        string memory name,
        string memory symbol,
        string memory _memo,
        int64 _price
    ) external payable {
        IHederaTokenService.TokenKey[]
            memory keys = new IHederaTokenService.TokenKey[](1);

        // Set this contract as supply
        keys[0] = getSingleKey(
            KeyType.SUPPLY,
            KeyValueType.CONTRACT_ID,
            address(this)
        );

        IHederaTokenService.HederaToken memory token;
        token.name = name;
        token.symbol = symbol;
        token.memo = _memo;
        token.treasury = address(this);
        token.tokenSupplyType = true; // set supply to FINITE
        token.maxSupply = 10;
        token.tokenKeys = keys;
        token.freezeDefault = false;
        token.expiry = createAutoRenewExpiry(address(this), 7000000);

        (int256 responseCode, address createdToken) = HederaTokenService
            .createNonFungibleToken(token);

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert("Failed to create non-fungible token");
        }
        // Create a new car
        CarNft memory car = CarNft(msg.sender, createdToken, name, symbol, _price);
        // Add car to the carNfts mapping
        carNfts[nftCount][msg.sender] = car;

        // Increment the nftCount
        nftCount ++;

        // Emit the CreatedToken event
        emit CreatedToken(createdToken);
    }

    function mintNFT(address token, bytes[] memory metadata) external {
        (int256 response, , int64[] memory serial) = HederaTokenService
            .mintToken(token, 0, metadata);

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Failed to mint non-fungible token");
        }

        emit MintedToken(serial);
    }

    function borrowing(address nftAddress, int64 serial) external payable {
        // Check if customer transfers the lockup amount
        require(msg.value == lockupAmount, "Incorrect amount");

        // Transfer NFT to customer
        int256 response = HederaTokenService.transferNFT(
            nftAddress,
            address(this),
            msg.sender,
            serial
        );

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Failed to transfer non-fungible token");
        }

        // Add borrower to previous owner
        previousOwners[nftAddress][serial].push(msg.sender);

        emit Response(response);
    }

    function returning(address nftAddress, int64 serial) external payable {
        // Return NFT from customer
        int256 response = HederaTokenService.transferNFT(
            nftAddress,
            msg.sender,
            address(this),
            serial
        );

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Failed to transfer non-fungible token");
        }

        // Return HBAR to customer
        payable(msg.sender).transfer(lockupAmount);
        emit Response(response);
    }

    function scoring(address receiver, int64 amount) external {
        require(msg.sender == owner, "Not owner");
        require(amount <= 5, "Only can allocate up to 5 REP tokens");

        int256 response = HederaTokenService.transferToken(
            ftAddress,
            address(this),
            receiver,
            amount
        );

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Transfer Failed");
        }

        emit Response(response);
    }
}
