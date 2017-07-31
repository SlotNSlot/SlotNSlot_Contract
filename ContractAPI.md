#SlotMachine API 0.2v

---
0.2

SlotMachineManager
  - createSlotMachine(uint _decider, uint _minBet, uint _maxBet, uint _maxPrize) => createSlotMachine(uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, bytes32 _name)

  - removeSlotMachine(uint _idx) => removeSlotMachine(address _slotaddr)  

SlotMachineStorage  

  - variable slotMachinesArray added
  - method *getLengthOfSlotMachinesArray* added

SlotMachine

  - variable mName added
---
0.12

General

  - provider => banker
  - Provider => Banker
  - of => Of, for => For (applying camelcase)

SlotMachineStorage

  - getNumofSlotMachine => getNumOfSlotMachine
  - totalNumofSlotMachine => totalNumOfSlotMachine
  - getNumofProvider => getNumOfProvider => getNumOfBanker


SlotMachine

  - initGameforPlayer => initGameForPlayer
  - game struct  
    numofLines => numOfLines
---
0.11

General
  - event gameOccupied, bankerSeedInitialized, gameInitialized, setBankerSeed, setPlayerSeed, gameConfirmed parameters changed

  - game struct changed

SlotMachine
  - Game[3] mGames => Game[3] mGame
  - mAvailable : true if slot is not occupied by player, false if slot is occupied

---
0.10

General

  - removing slotmachine bug fixed


SlotMachine
  - event gameOccupied changed  
    gameOccupied(address player, uint playerBalance) => (address player, uint playerSeed)

  - *getInfo*() added

  - *occupy*(bytes32 _playerSeed) =>  *occupy*(bytes32[3] _playerSeed)

  - *initBankerSeed*(bytes32 _bankerSeed) => *initBankerSeed*(bytes32[3] _bankerSeed)

  - *initGameForPlayer*(uint _bet, uint _lines) => *initGameForPlayer*(uint _bet, uint _lines, uint _idx)

  - *setBankerSeed*(bytes32 _bankerSeed) => *setBankerSeed*(bytes32 _bankerSeed, uint _idx)

  - *setPlayerSeed*(bytes32 _playerSeed) => *setPlayerSeed*(bytes32 _playerSeed, uint _idx)


---
## SlotMachineManager

###methods

- createSlotMachine(uint _decider, uint _minBet, uint _maxBet, uint _maxPrize, bytes32 _name) returns (address)

  create slotmachine with following parameters  
  return address of created slotmachine  
  event : slotMachineCreated  

- removeSlotMachine(address _slotaddr)

  remove slotmachine (address : _slotaddr) from slotMachine mapping
  refund slotmachine's deposit to banker
  event : slotMachineRemoved

- getStorageAddr() returns (address)

  return slotmachineStorage address


###events
  - slotMachineCreated (address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, uint _totalnum, address _slotaddr)    
    - _banker : address of banker  
    - _decider, _minBet, _maxBet, _maxPrize : given parameters  
    - _totalnum : number of user's slotmachine after creation  
    - _slotaddr : address of created slotmachine


   - slotMachineRemoved(address _banker, address _slotaddr, uint _totalnum)  

      - _banker : address of banker  
      - _slotaddr : address of removed slotmachine  
      - _totalnum : number of user's slotmachine after removal  
---

## SlotMachineStorage

### variable
  - address[] bankeraddress

    array of banker addresses

  - mapping (address => address[]) slotMachines

    mapping (banker => array of slotmachines)

  - uint totalNumOfSlotMachine;

    total number of slotmachines regardless of banker

  - address[] slotMachinesArray;

    array of slotmachines regardless of banker
    removeSlotMachine through SlotMachineManager sets target slotmachine with '0x0000000000000000000000000000000000000000'  
    total length of slotMachinesArray can be achieved by *getLengthOfSlotMachinesArray()*

    ```js
    manager.createSlotMachine(150,100,100000,2000);

    storage.totalNumOfSlotMachine();
    //1
    storage.getLengthOfSlotMachinesArray();
    //1
    storage.slotMachinesArray(0);
    //'0x14bcf7a5a63310d7f72a4d6fabd4a0104e20822d'

    manager.removeSlotMachine('0x14bcf7a5a63310d7f72a4d6fabd4a0104e20822d');

    storage.totalNumOfSlotMachine();
    //0
    storage.getLengthOfSlotMachinesArray();
    //1
    storage.slotMachinesArray(0);
    //'0x0000000000000000000000000000000000000000'


    ```


### methods
  - isValidBanker (address _banker) constant returns (bool)

    return if _banker has at least 1 slotmachine

  - getNumOfBanker () constant returns (uint)

    return number of bankers

  - getNumOfSlotMachine (address _banker) constant returns (uint)

    return number of slomachines provided by _banker

  - getSlotMachine (address _banker, uint _idx) constant  returns (address)

    return slotmachine address of _banker, index with _idx

  - getLengthOfSlotMachinesArray() constant returns (uint)

    return length of slotMachinesArray


---

## SlotMachine

### variable

  - bytes32 mName

    name of SlotMachine


  - bool mAvailable

    true if slot is not occupied by player  
    false if slot is occupied


  - bool public mBankrupt

  - address mPlayer

    address of current player  
    if slot is not occupied, mPlayer = '0x0'    

  - uint mDecider

    hit rate of slotmachine * 1000  
    e.g) hit rate : 15%(0.15) => mDecider : 150

  - uint mMinBet

    minBet of slotmachine(wei)

  - uint mMaxBet

    maxBet of slotmachine(wei)

  - uint mMaxPrize

  - uint bankerBalance

    banker's balance in slotmachine (wei)

  - uint playerBalance

    player's balance in slotmachine (wei)


  - bool public initialPlayerSeedReady

    true if initial player seed is set by *occupy*

  - bool public initialBankerSeedReady

    true if initial banker seed is set by *setBankerSeed*

  - bytes32[3] previousPlayerSeed

    stores playerseed of the previous game

  - bytes32[3] previousBankerSeed

    stores bankerseed of the previous game


  - Game[3] mGame;

    stores game information for each round  

    ```solidity
    struct Game {
        uint bet;
        bool betReady;
        bool bankerSeedReady;
        bool playerSeedReady;
        uint numOfLines;
        uint reward;
    }
    ```

  - all public variables have getter function
    ```js
      //get game informations in struct Game
      slot.mGames(0);

      //get player balance
      slot.playerBalance();

      ...
    ```


### methods

  - getInfo() constant returns (uint16, uint, uint, uint16, uint)  

    return (mDecider, mMinBet, mMaxBet, mMaxPrize, bankerBalance);


  - occupy(bytes32[3] _playerSeed)

    player enters the game  
    send ether  
    set mPlayer with address of player  
    set initial player seed with _playerSeed  
    event : gameOccupied

  - initBankerSeed(bytes32[3] _bankerSeed)  

    set initial banker seed  
    event : bankerSeedInitialized

  - initGameForPlayer(uint _bet, uint _lines, uint _idx)

    start slot game with parameters  
    event : gameInitialized

    if game is set properly, trigger event : gameConfirmed

  - setBankerSeed(bytes32 _bankerSeed, uint _idx)

    onlyBanker  
    set current game seed for banker  
    event : bankerSeedSet

    if game is set properly, trigger event : gameConfirmed

  - setPlayerSeed(bytes32 _playerSeed, uint _idx)

    onlyPlayer  
    set current game seed for player  
    event : playerSeedSet

    if game is set properly, trigger event : gameConfirmed

  - leave()  

    onlyPlayer  
    access : onlyPlayer  
    player leaves the game  
    give back the balance to player  
    event : playerLeft


### events


  - playerLeft(address player, uint playerBalance)  
    - player : address of player
    - playerBalance : balance of initial balance


  - bankerLeft(address banker)
    - banker : address of banker


  - gameOccupied(address player, bytes32[3] playerSeed)
    - player : address of player
    - playerSeed : initial playerSeed


  - bankerSeedInitialized(bytes32[3] bankerSeed)
    - bankerSeed : initial seed for banker


  - gameInitialized(address player, uint bet, uint lines, uint idx)
    - player : address of player
    - bet : current game bet
    - lines : current game lines
    - idx : index of sha3chain


  - bankerSeedSet(bytes32 bankerSeed, uint idx)
    - bankerSeed : current game seed for banker
    - idx : index of sha3chain


  - playerSeedSet(bytes32 playerSeed, uint idx)
    - playerSeed : current game seed for banker
    - idx : index of sha3chain


  - gameConfirmed(uint reward, uint idx)
    - reward : final reward for player  
    - idx : index of sha3chain



### playing example

```javascript
//get slotmachine instance
var slot = SlotMachine(slotaddr)

//send banker's ether to slotmachine
web3.eth.sendTransaction({from:banker, to:slotaddr, value : web3.toWei(1,"ether")})

//shows banker's ether
slot.bankerBalance()

//player occupies the slotmachine, send ether
var playerseeds = new Array(seed1,seed2,seed3)
slot.occupy(playerseeds,{from:player,value:web3.toWei(2,"ether")})

//set initial banker seed
var bankerseeds = new Array(seed4,seed5,seed6)
slot.initBankerSeed(bankerseeds)

//player press button 'play' with chain_0;
slot.initGameForPlayer(500,20,0,{from:user2})

//banker sets seed for current game
slot.setBankerSeed(seed,0,{from:banker})

//player sets seed for current game, caculate reward
slot.setPlayerSeed(seed,0,{from:player})

//player press button 'play' with chain_1, order of transaction does not matter;
slot.initGameForPlayer(500,20,1,{from:user2})

slot.setPlayerSeed(seed,1,{from:player})

slot.setBankerSeed(seed,1,{from:banker})



//player leaves the game, get back his/her ether
slot.leave({from:player})
```
