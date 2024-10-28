// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./Dice.sol";
contract DiceMarket {
    
    enum diceListingState { unlisted, listed, sold }

    Dice diceContract;
    address private marketOwner;
    uint256 commissionFee = 0;

    struct diceListing {
        uint256 diceId;
        uint256 commissionFee;
        address createdBy;
        diceListingState state;
        uint256 price;
    }

    mapping(uint256 => diceListing) public listings;
      
    modifier listingOwnerOnly(uint256 listingId) {
        require(listings[listingId].createdBy == msg.sender, "Not the Owner of Listing");
        _;
    }

    modifier validListingId(uint256 listingId) {
        require(listings[listingId].createdBy != address(0), "Not a Valid Listing");
        _;
    }


    constructor(Dice diceAddress, uint256 _commissionFee) public {
        diceContract = diceAddress;
        require(_commissionFee > 0, "Commission Fee should be more than 0.");
        commissionFee = _commissionFee;
        marketOwner = msg.sender;
    }


    function getListingState(uint256 diceId) public view validListingId(diceId) returns (diceListingState) {
        return listings[diceId].state;
    }


    function checkPrice(uint256 diceId) public view validListingId(diceId) returns (uint256) {
        return listings[diceId].price;
    }

    function buy(uint256 diceId) public payable validListingId(diceId) {
        require(listings[diceId].createdBy != msg.sender, "You have listed the dice, you can't buy it");
        require(listings[diceId].state == diceListingState.listed, "Dice is currently not listed");
        uint256 price = listings[diceId].price;
        require(msg.value >= price, "Insufficient payment");

        diceContract.transfer(diceId, msg.sender);
        listings[diceId].state = diceListingState.sold;


        uint256 finalPrice = listings[diceId].price;
        uint256 transactionCommission = listings[diceId].commissionFee;
        uint256 profit = finalPrice - transactionCommission;
        uint256 senderValue = msg.value;

        if(senderValue > finalPrice) {
            uint256 change = senderValue - finalPrice;
            (bool sent, ) = msg.sender.call.value(change)("");
            require(sent, "Failed to Return Change");
            senderValue -= change;
        }

        (bool sentCommission, ) = marketOwner.call.value(transactionCommission)("");
        require(sentCommission, "Failed to Send Commission");
        senderValue -= transactionCommission;
        

        (bool sentValue, ) = listings[diceId].createdBy.call.value(profit)("");
        require(sentValue, "Failed to Send Payment");
        senderValue -= profit;

        require(senderValue == 0, "Error sending money correctly");

    }

 
    function list(uint256 diceId, uint256 price) public returns (bool) {

        require(listings[diceId].createdBy == address(0) , "Listing for Dice exist!");

        uint256 currentDiceValue = diceContract.getDiceValue(diceId); 
        uint256 listingCommissionFee = commissionFee;
        require(price >= (currentDiceValue + listingCommissionFee), "Price must be more than or equal to commission + dice value");
        require(diceContract.getDiceOwner(diceId) == address(this), "This contract is not the owner of the dice");
        require(diceContract.getPreviousOwner(diceId) == msg.sender, "Sender is not the previous owner");

        diceListing memory newListing = diceListing(
            diceId,
            commissionFee,
            msg.sender, 
            diceListingState.listed,
            price
        );

        listings[diceId] = newListing; 
        return true;  
    }

    function unlist(uint256 diceId) public validListingId(diceId) listingOwnerOnly(diceId) {
        require(listings[diceId].state == diceListingState.listed, "Invalid state of dice to be unlisted.");
        listings[diceId].state = diceListingState.unlisted;
    }

}