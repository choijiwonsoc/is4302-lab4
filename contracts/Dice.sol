pragma solidity ^0.5.0;

contract Dice {
    
    struct dice {
        uint8 numberOfSides;
        uint8 color;
        uint8 currentNumber;
        diceState state;
        uint256 creationValue;
        address owner;
        address prevOwner;
        uint256 luckyTimes;
        bool locked;
    }
    
    enum diceState { stationary, rolling }
    event rolling (uint256 diceId);
    event rolled (uint256 diceId, uint8 newNumber);

    uint256 public numDices = 0;
    mapping(uint256 => dice) public dices;


    event luckytimesEvent (uint256 diceId);
    event diceDeleted(uint256 diceId);
    
    function add(
        uint8 numberOfSides,
        uint8 color
    ) public payable returns(uint256) {
        require(numberOfSides > 0);
        require(msg.value > 0.01 ether, "creating a new dice needs at least 0.01 ETH");
        
        dice memory newDice = dice(
            numberOfSides,
            color,
            (uint8)(block.timestamp % numberOfSides) + 1, 
            diceState.stationary,
            msg.value,
            msg.sender,  //owner
            address(0),
            0, // Lucky Times
            false
        );
        
        uint256 newDiceId = numDices++;
        dices[newDiceId] = newDice; //commit to state variable
        return newDiceId;   //return new diceId
    }
  
    modifier ownerOnly(uint256 diceId) {
        require(dices[diceId].owner == msg.sender, "Sender is not the owner of the dice");
        _;
    }
    
    modifier validDiceId(uint256 diceId) {
        //require(diceId < numDices);
        require(dices[diceId].owner != address(0), "DiceID is invalid.");
        _;
    }
  
    function roll(uint256 diceId) public ownerOnly(diceId) validDiceId(diceId) {
            dices[diceId].state = diceState.rolling;    
            dices[diceId].currentNumber = 0;   
            emit rolling(diceId);   
    }

    function stopRoll(uint256 diceId) public ownerOnly(diceId) validDiceId(diceId) {
            dices[diceId].state = diceState.stationary; //set state to stationary
            
            //this is not a secure randomization
            uint8 newNumber = (uint8)((block.timestamp*(diceId+1)) % dices[diceId].numberOfSides) + 1;
            if(newNumber == dices[diceId].numberOfSides){
                dices[diceId].luckyTimes += 1;
                emit luckytimesEvent(diceId); //emit luckytimesEvent
            }
            dices[diceId].currentNumber = newNumber;
            emit rolled(diceId, newNumber); //emit rolled
    }
    
    function transfer(uint256 diceId, address newOwner) public ownerOnly(diceId) validDiceId(diceId) {
        dices[diceId].prevOwner = dices[diceId].owner;
        dices[diceId].owner = newOwner;
    }
  
    function getDiceSides(uint256 diceId) public view validDiceId(diceId) returns (uint8) {
        return dices[diceId].numberOfSides;
    }

    function getDiceColor(uint256 diceId) public view validDiceId(diceId) returns (uint8) {
        return dices[diceId].color;
    }

    function getDiceNumber(uint256 diceId) public view validDiceId(diceId) returns (uint8) {
        return dices[diceId].currentNumber;
    }

    function getDiceValue(uint256 diceId) public view validDiceId(diceId) returns (uint256) {
        return dices[diceId].creationValue;
    }

    function getLuckyTimes(uint256 diceId) public view validDiceId(diceId) returns (uint256) {
        return dices[diceId].luckyTimes;
    }

    function getPreviousOwner(uint256 diceId) public view validDiceId(diceId) returns (address) {
        return dices[diceId].prevOwner;
    }

    function destroyDice(uint256 diceId) public payable validDiceId(diceId) ownerOnly(diceId) {
        require(!dices[diceId].locked, "Failed to Acquire Lock");

        dices[diceId].locked = true;

        (bool sent, ) = dices[diceId].owner.call.value(dices[diceId].creationValue)("");
        require(sent, "Failed to Return Value");

        delete dices[diceId];

        dices[diceId].locked = false;

        emit diceDeleted(diceId); //emit diceDeleted
    }

    function getDiceOwner(uint256 diceId) public view validDiceId(diceId) returns (address) {
        return dices[diceId].owner;
    }
    
}