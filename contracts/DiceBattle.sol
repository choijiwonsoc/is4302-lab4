pragma solidity ^0.5.0;
import "./Dice.sol";

contract DiceBattle {
    Dice diceContract;
    mapping(address => address) battle_pair;

    event add_enemy(address player, address enemy);
    event battlewin(address winner);

    constructor(Dice diceAddress) public {
        diceContract = diceAddress;
    }

    function setBattlePair(address enemy) public {
        // Require that only prev owner can allow an enemy
        require(msg.sender!=enemy, "Cannot Select Yourself as Enemy");
        // Each player can only select one enemy
        require(battle_pair[msg.sender] == address(0), "Player Already has an Enemy");
        battle_pair[msg.sender] = enemy;

        emit add_enemy(msg.sender, enemy);
    }

    function battle(uint256 myDice, uint256 enemyDice) public {
        // Require that battle_pairs align, ie each player has accepted a battle with the other
        
        // Check that Sender is the Prev Owner of MyDice
        require(diceContract.getPreviousOwner(myDice) == msg.sender, "Sender is not the Previous Owner of MyDice");

        // Check that Enemy is the Prev Owner of EnemyDice
        require(diceContract.getPreviousOwner(enemyDice) == battle_pair[msg.sender], "Enemy is not the Previous Owner of Enemy Dice");
        
        address enemyAddress = battle_pair[msg.sender];

        // Check that Enemy's opponent is Sender
        require(battle_pair[enemyAddress] == msg.sender, "Enemy Address is not Sender");

        // Run battle
        diceContract.roll(myDice);
        diceContract.stopRoll(myDice);

        diceContract.roll(enemyDice);
        diceContract.stopRoll(enemyDice);

        if(diceContract.getDiceNumber(myDice)==diceContract.getDiceNumber(enemyDice)){
            //Return to Previous Owner
            diceContract.transfer(myDice,msg.sender);
            diceContract.transfer(enemyDice,enemyAddress);
            emit battlewin(address(0));
        }
        else if(diceContract.getDiceNumber(myDice)>diceContract.getDiceNumber(enemyDice)){
            //Sender Won
            diceContract.transfer(enemyDice,msg.sender);
            diceContract.transfer(myDice,msg.sender);
            emit battlewin(msg.sender);
        }
        else {
            //Enemy Won
            diceContract.transfer(enemyDice,enemyAddress);
            diceContract.transfer(myDice,enemyAddress);
            emit battlewin(enemyAddress);
        }

        delete battle_pair[enemyAddress];
        delete battle_pair[msg.sender];
    }

    //Add relevant getters and setters
}