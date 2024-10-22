// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./Dice.sol";
contract DiceMarket {
    
    enum diceListingState { unlisted, listed, sold }

    uint256 commissionFee = 0;
    address private marketOwner;
    Dice diceContract;

    struct diceListing {
        uint256 diceId;
        uint256 commissionFee; // Assuming Commission Fee is already in DT
        address createdBy;
        diceListingState state;
        uint256 price;
    }

    mapping(uint256 => diceListing) public listings;
    
    //modifier to ensure a function is callable only by its owner    
    modifier listingOwnerOnly(uint256 listingId) {
        require(listings[listingId].createdBy == msg.sender, "Not the Owner of Listing");
        _;
    }

    //modifier to ensure listing Exists 
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

    //Unlist Listing
    function unlist(uint256 diceId) public validListingId(diceId) listingOwnerOnly(diceId) {
        require(listings[diceId].state == diceListingState.listed, "Dice cannot be unlisted due to invalid state.");
        listings[diceId].state = diceListingState.unlisted;
    }

    function getListingState(uint256 diceId) public view validListingId(diceId) returns (diceListingState) {
        return listings[diceId].state;
    }


    function checkPrice(uint256 diceId) public view validListingId(diceId) returns (uint256) {
        return listings[diceId].price;
    }

    function buy(uint256 diceId) public payable validListingId(diceId) {
        require(listings[diceId].createdBy != msg.sender, "You have listed the dice, you can't buy it");
        require(listings[diceId].state == diceListingState.listed, "Dice is not for sale");
        require(msg.value >= listings[diceId].price, "Not enough tokens provided to buy dice");

        diceContract.transfer(diceId,msg.sender);
        listings[diceId].state = diceListingState.sold;

        uint256 transactionCommission = listings[diceId].commissionFee;
        uint256 finalPrice = listings[diceId].price;
        uint256 profit = finalPrice - transactionCommission;
        uint256 senderValue = msg.value;

        if(senderValue > finalPrice) {
            //Send Leftover amount
            uint256 change = senderValue - finalPrice;
            (bool sent, ) = msg.sender.call.value(change)("");
            require(sent, "Failed to Return Change");
            senderValue -= change;
        }

        
        //Send Commission to Contract Owner
        (bool sent, ) = marketOwner.call.value(transactionCommission)("");
        // bool sent = diceToken.transferFrom(msg.sender,address(this),transactionCommission);
        require(sent, "Failed to Send Commission");
        senderValue -= transactionCommission;
        
        // uint256 profit = finalPrice - transactionCommission;
        //Send Value to Prev Owner
        (bool sent2, ) = listings[diceId].createdBy.call.value(profit)("");
        // bool sent2 = diceToken.transferFrom(msg.sender,listings[diceId].createdBy,profit);
        require(sent2, "Failed to Send Payment");
        senderValue -= profit;

        require(senderValue == 0, "Error Allocating Money to Appropriate Parties");

    }

 
    //Listing dice for sale
    function list(uint256 diceId, uint256 price) public returns (bool) {

        require(listings[diceId].createdBy == address(0) ,"Listing for Dice exist!");

        //Price must be >= commission Fee + Dice Value
        uint256 diceWeiValue = diceContract.getDiceValue(diceId); //This would trigger error if dice doesn't exist
        uint256 listingCommissionFee = commissionFee;
        // uint256 dtValue = convertWeiToDT(originalWeivalue);
        require(price >= (diceWeiValue + listingCommissionFee), "Price is lesser than Commission + Dice value");
        require(diceContract.getDiceOwner(diceId) == address(this), "Unable to List because Owner of dice is not this Contract");
        require(diceContract.getPreviousOwner(diceId) == msg.sender, "Sender not the Previous Owner");

        //new Listing object
        diceListing memory newListing = diceListing(
            diceId,
            commissionFee,
            msg.sender, //Created By
            diceListingState.listed,
            price
        );

        listings[diceId] = newListing; //commit to state variable
        return true;   //return new ListID
    }




}