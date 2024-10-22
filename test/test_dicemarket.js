const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");

var Dice = artifacts.require("../contracts/Dice.sol");
var DiceBattle = artifacts.require("../contracts/DiceBattle.sol");
var DiceMarket = artifacts.require("../contracts/DiceMarket.sol");

contract("DiceMarket", function (accounts) {
  before(async () => {
    diceInstance = await Dice.deployed();
    diceMarketInstance = await DiceMarket.deployed();
  });

  it("Test Create Dice", async () => {
    const numberOfSides = 6;
    const color = 1;
    const value = 1000000000000000000;
    let makeD1 = await diceInstance.add(numberOfSides, color, {
      from: accounts[5],
      value: value,
    });

    assert.notStrictEqual(makeD1, undefined);
    assert.equal(await diceInstance.getDiceSides(0), numberOfSides);
    assert.equal(await diceInstance.getDiceColor(0), color);
    assert.equal(await diceInstance.getDiceValue(0), value);

    let makeD2 = await diceInstance.add(numberOfSides, color, {
      from: accounts[7],
      value: value,
    });

    assert.notStrictEqual(makeD2, undefined);
    assert.equal(await diceInstance.getDiceSides(1), numberOfSides);
    assert.equal(await diceInstance.getDiceColor(1), color);
    assert.equal(await diceInstance.getDiceValue(1), value);
  });

  it("Test Ether Applied", async () => {
    const numberOfSides = 6;
    const color = 1;
    try {
      let makeD1 = await diceInstance.add(numberOfSides, color, {
        from: accounts[5],
        value: 0,
      });
    } catch (error) {
      assert.equal(
        error.reason,
        "at least 0.01 ETH is needed to spawn a new dice",
        "Error message mismatch"
      );
    }
  });

  it("Test Transfer Dice", async () => {
    await diceInstance.transfer(0, diceMarketInstance.address, {
      from: accounts[5],
    });

    assert.equal(await diceInstance.getPreviousOwner(0), accounts[5]);
    assert.equal(
      await diceInstance.getDiceOwner(0),
      diceMarketInstance.address
    );

    await diceInstance.transfer(1, diceMarketInstance.address, {
      from: accounts[7],
    });

    assert.equal(await diceInstance.getPreviousOwner(1), accounts[7]);
    assert.equal(
      await diceInstance.getDiceOwner(1),
      diceMarketInstance.address
    );
  });

  it("Test Dice Price", async () => {
    try {
      await diceMarketInstance.list(0, 1000000000000, {
        from: accounts[5],
      });
    } catch (error) {
      assert.equal(
        error.reason,
        "Price is lesser than Commission + Dice value",
        "Error message mismatch"
      );
    }
  });

  it("Test Dice List", async()=>{
    let price1 = "1100000000000000000";
    let price2 = "1200000000000000000";
    await diceMarketInstance.list(0, price1, {
        from: accounts[5],
    });

    assert.equal(await diceMarketInstance.checkPrice(0), price1);
    assert.equal(await diceInstance.getPreviousOwner(0), accounts[5]);
    assert.equal(await diceInstance.getDiceOwner(0), diceMarketInstance.address);

    await diceMarketInstance.list(1, price2, {
        from: accounts[7],
    });

    assert.equal(await diceMarketInstance.checkPrice(1), price2);
    assert.equal(await diceInstance.getPreviousOwner(1), accounts[7]);
    assert.equal(await diceInstance.getDiceOwner(1), diceMarketInstance.address);
  })

  it("Test Dice Unlist", async()=>{
    await diceMarketInstance.unlist(0, {
        from: accounts[5],
    });
    assert.equal(await diceInstance.getPreviousOwner(0), accounts[5]);
    assert.equal(await diceInstance.getDiceOwner(0), diceMarketInstance.address);
    
  })

  it("Test Buy Dice", async()=>{
    await diceMarketInstance.buy(1, {
        from: accounts[5],
        value: "1200000000000000000",
    });
    assert.equal(await diceInstance.getPreviousOwner(1), diceMarketInstance.address);
    assert.equal(await diceInstance.getDiceOwner(1), accounts[5]);
  })
});
