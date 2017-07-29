#SlotMachine API 0.11v


---
0.11

General
  - event gameOccupied, providerSeedInitialized, gameInitialized, setProviderSeed, setPlayerSeed, gameConfirmed parameters changed

  - game struct changed

SlotMachine
  - Game[3] mGames => Game[3] mGame
  - mAvailable : true if slot is not occupied by player, false if slot is occupied

---
0.1

General

  - removing slotmachine bug fixed


SlotMachine
  - event gameOccupied changed  
    gameOccupied(address player, uint playerBalance) => (address player, uint playerSeed)

  - *getInfo*() added

  - *occupy*(bytes32 _playerSeed) =>  *occupy*(bytes32[3] _playerSeed)

  - *initProviderSeed*(bytes32 _providerSeed) => *initProviderSeed*(bytes32[3] _providerSeed)

  - *initGameforPlayer*(uint _bet, uint _lines) => *initGameforPlayer*(uint _bet, uint _lines, uint _idx)

  - *setProviderSeed*(bytes32 _providerSeed) => *setProviderSeed*(bytes32 _providerSeed, uint _idx)

  - *setPlayerSeed*(bytes32 _playerSeed) => *setPlayerSeed*(bytes32 _playerSeed, uint _idx)


---
## SlotMachineManager

###methods

- createSlotMachine(uint _decider, uint _minBet, uint _maxBet, uint _maxPrize) returns (address)

  create slotmachine with following parameters  
  return address of created slotmachine  
  event : slotMachineCreated  

- removeSlotMachine(uint _idx)

  remove slotmachine[_idx] from slotmachine array, rest of arrays will be sorted automatically
  refund slotmachine's deposit to provider
  event : slotMachineRemoved

- getStorageAddr() returns (address)

  return slotmachineStorage address


###events
  - slotMachineCreated (address _provider, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, uint _totalnum, address _slotaddr)  

    arguments :  

    >_provider : address of provider  
    _decider, _minBet, _maxBet, _maxPrize : given parameters  
    _totalnum : number of user's slotmachine after creation  
    _slotaddr : address of created slotmachine

   - slotMachineRemoved(address _provider, address _slotaddr, uint _totalnum)  

      arguments :
      >_provider : address of provider  
      _slotaddr : address of removed slotmachine  
      _totalnum : number of user's slotmachine after removal  
---

## SlotMachineStorage

### variable
  - address[] provideraddress

    array of provider addresses

  - mapping (address => address[]) slotMachines

    mapping (provider => array of slotmachines)

  - uint totalNumofSlotMachine;

    total number of slotmachines regardless of provider

### methods
  - isValidProvider (address _provider) constant returns (bool)

    return if _provider has at least 1 slotmachine

  - getNumofProvider () constant returns (uint)

    return number of providers

  - getNumofSlotMachine (address _provider) constant returns (uint)

    return number of slomachines provided by _provider

  - getSlotMachine (address _provider, uint _idx) constant  returns (address)

    return slotmachine address of _provider, index with _idx

---

## SlotMachine

### variable
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

  - uint providerBalance

    provider's balance in slotmachine (wei)

  - uint playerBalance

    player's balance in slotmachine (wei)


  - bool public initialPlayerSeedReady

    true if initial player seed is set by *occupy*

  - bool public initialProviderSeedReady

    true if initial provider seed is set by *setProviderSeed*

  - bytes32[3] previousPlayerSeed

    stores playerseed of the previous game

  - bytes32[3] previousProviderSeed

    stores providerseed of the previous game


  - Game[3] mGame;

    stores game information for each round  

    ```solidity
    struct Game {
        uint bet;
        bool betReady;
        bool providerSeedReady;
        bool playerSeedReady;
        uint numofLines;
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

    return (mDecider, mMinBet, mMaxBet, mMaxPrize, providerBalance);


  - occupy(bytes32[3] _playerSeed)

    player enters the game  
    send ether  
    set mPlayer with address of player  
    set initial player seed with _playerSeed  
    event : gameOccupied

  - initProviderSeed(bytes32[3] _providerSeed)  

    set initial provider seed  
    event : providerSeedInitialized

  - initGameforPlayer(uint _bet, uint _lines, uint _idx)

    start slot game with parameters  
    event : gameInitialized

    if game is set properly, trigger event : gameConfirmed

  - setProviderSeed(bytes32 _providerSeed, uint _idx)

    onlyProvider  
    set current game seed for provider  
    event : providerSeedSet

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


  - providerLeft(address provider)
    - provider : address of provider


  - gameOccupied(address player, bytes32[3] playerSeed)
    - player : address of player
    - playerSeed : initial playerSeed


  - providerSeedInitialized(bytes32[3] providerSeed)
    - providerSeed : initial seed for provider


  - gameInitialized(address player, uint bet, uint lines, uint idx)
    - player : address of player
    - bet : current game bet
    - lines : current game lines
    - idx : index of sha3chain


  - providerSeedSet(bytes32 providerSeed, uint idx)
    - providerSeed : current game seed for provider
    - idx : index of sha3chain


  - playerSeedSet(bytes32 playerSeed, uint idx)
    - playerSeed : current game seed for provider
    - idx : index of sha3chain


  - gameConfirmed(uint reward, uint idx)
    - reward : final reward for player  
    - idx : index of sha3chain



### playing example

```javascript
//get slotmachine instance
var slot = SlotMachine(slotaddr)

//send provider's ether to slotmachine
web3.eth.sendTransaction({from:provider, to:slotaddr, value : web3.toWei(1,"ether")})

//shows provider's ether
slot.providerBalance()

//player occupies the slotmachine, send ether
var playerseeds = new Array(seed1,seed2,seed3)
slot.occupy(playerseeds,{from:player,value:web3.toWei(2,"ether")})

//set initial provider seed
var providerseeds = new Array(seed4,seed5,seed6)
slot.initProviderSeed(providerseeds)

//player press button 'play' with chain_0;
slot.initGameforPlayer(500,20,0,{from:user2})

//provider sets seed for current game
slot.setProviderSeed(seed,0,{from:provider})

//player sets seed for current game, caculate reward
slot.setPlayerSeed(seed,0,{from:player})

//player press button 'play' with chain_1, order of transaction does not matter;
slot.initGameforPlayer(500,20,1,{from:user2})

slot.setPlayerSeed(seed,1,{from:player})

slot.setProviderSeed(seed,1,{from:provider})



//player leaves the game, get back his/her ether
slot.leave({from:player})
```
