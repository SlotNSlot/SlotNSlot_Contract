pragma solidity ^0.4.0;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract SlotMachine is Ownable {
    bool public mAvailable;
    bool public mBankrupt;
    address public mPlayer;
    uint16 public mDecider;
    uint public mMinBet;
    uint public mMaxBet;
    uint16 public mMaxPrize;

    bool public mIsGamePlaying;

    uint public providerBalance;
    uint public playerBalance;

    /*bool[3] public betReady;
    bool[3] public providerSeedReady;
    bool[3] public playerSeedReady;*/

    bytes32[3] public previousPlayerSeed;
    bytes32[3] public previousProviderSeed;
    bool public initialPlayerSeedReady;
    bool public initialProviderSeedReady;

    uint[2] public payTable;
    uint8 public numofPayLine;

    struct Game {
        uint bet;
        /*bytes32 providerSeed;
        bytes32 playerSeed;*/
        /*uint randomNumber;*/
        bool betReady;
        bool providerSeedReady;
        bool playerSeedReady;
        uint numofLines;
        uint reward;
    }

    Game[3] public mGame;
    /*
        MODIFIERS
    */
    modifier onlyAvailable() {
        require(mAvailable);
        _;
    }

    modifier notBankrupt() {
        require(!mBankrupt);
        _;
    }

    modifier notOccupied() {
        require(mPlayer == 0x0);
        _;
    }

    modifier onlyPlayer() {
        require(mPlayer != 0x0 && msg.sender == mPlayer);
        _;
    }

    modifier notPlaying() {
        require(!mIsGamePlaying);
        _;
    }
    /*
        EVENTS
    */
    event playerLeft(address player, uint playerBalance);
    event providerLeft(address provider);

    event gameOccupied(address player, bytes32[3] playerSeed);
    event providerSeedInitialized(bytes32[3] providerSeed);

    event gameInitialized(address player, uint bet, uint lines, uint idx);
    event providerSeedSet(bytes32 providerSeed, uint idx);
    event playerSeedSet(bytes32 playerSeed, uint idx);

    event gameConfirmed(uint reward, uint idx);

    function () payable {
      if (msg.sender == owner || tx.origin == owner) {
        providerBalance += msg.value;
      } else if(msg.sender == mPlayer) {
        playerBalance += msg.value;
      }

    }

    function SlotMachine(address _provider, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize,
      uint[2] _payTable, uint8 _numofPayLine)
        payable
    {
        transferOwnership(_provider);

        mDecider = _decider;
        mPlayer = 0x0;
        mAvailable = true;
        mBankrupt = false;
        mMinBet = _minBet;
        mMaxBet = _maxBet;
        mMaxPrize = _maxPrize;
        mIsGamePlaying = false;

        providerBalance = msg.value;

        payTable = _payTable;
        numofPayLine = _numofPayLine;
        initialProviderSeedReady = false;
        initialPlayerSeedReady = false;

        /*payTable = PaytableStorage(payStorage).getPayline(mMaxPrize,mDecider);
        numofPayLine = PaytableStorage(payStorage).getNumofPayline(mMaxPrize,mDecider);*/

    }

    function occupy(bytes32[3] _playerSeed)
        payable
        onlyAvailable
        notOccupied
    {

        require(msg.sender != owner);

        mPlayer = msg.sender;
        playerBalance += msg.value;
        mAvailable = false;
        previousPlayerSeed[0] = _playerSeed[0];
        previousPlayerSeed[1] = _playerSeed[1];
        previousPlayerSeed[2] = _playerSeed[2];

        initialPlayerSeedReady = true;
        gameOccupied(mPlayer, _playerSeed);
    }

    function initProviderSeed(bytes32[3] _providerSeed)
        onlyOwner
        /*onlyAvailable*/
    {
        /*require(initialPlayerSeedReady);*/
        previousProviderSeed[0] = _providerSeed[0];
        previousProviderSeed[1] = _providerSeed[1];
        previousProviderSeed[2] = _providerSeed[2];

        initialProviderSeedReady = true;
        providerSeedInitialized(_providerSeed);
    }

    function leave()
        onlyPlayer
    {

        msg.sender.transfer(playerBalance);
        playerLeft(mPlayer, playerBalance);
        playerBalance = 0;
        mAvailable = true;
        mBankrupt = false;
        mPlayer = 0x0;
        mIsGamePlaying = false;
        initialProviderSeedReady = false;
        initialPlayerSeedReady = false;

    }

    function shutDown()
        notOccupied
        onlyAvailable
        notPlaying
    {
        selfdestruct(owner);
    }

    function initGameforPlayer(uint _bet, uint _lines, uint _idx)
        /*onlyAvailable*/
        onlyPlayer
        notBankrupt
    {
        require(_bet >= mMinBet && _bet <= mMaxBet);
        require(_bet * _lines <= playerBalance);

        if(_bet * _lines > providerBalance) {
            mBankrupt = true;
            throw;
        }

        mGame[_idx].numofLines = _lines;
        mGame[_idx].bet = _bet;

        playerBalance -= _bet * _lines;
        providerBalance += _bet * _lines;

        mGame[_idx].betReady = true;
        gameInitialized(mPlayer, _bet, _lines, _idx);

        if (mGame[_idx].betReady && mGame[_idx].providerSeedReady && mGame[_idx].playerSeedReady){
          confirmGame(_idx);
        }

    }

    function setProviderSeed(bytes32 _providerSeed, uint _idx)
        onlyOwner
        /*onlyAvailable*/
    {
        /*require(previousProviderSeed[_idx] == _providerSeed);*/
        require (previousProviderSeed[_idx] == sha3(_providerSeed));

        previousProviderSeed[_idx] = _providerSeed;
        /*mGame[_idx].providerSeed = _providerSeed;*/
        mGame[_idx].providerSeedReady = true;
        providerSeedSet(_providerSeed, _idx);

        if (mGame[_idx].betReady && mGame[_idx].providerSeedReady && mGame[_idx].playerSeedReady){
          confirmGame(_idx);
        }

    }


    function setPlayerSeed(bytes32 _playerSeed, uint _idx)
        onlyPlayer
        /*onlyAvailable*/
    {
        /*require(previousPlayerSeed[_idx] == _playerSeed);*/
        require (previousPlayerSeed[_idx] == sha3(_playerSeed));
        previousPlayerSeed[_idx] = _playerSeed;

        /*mGame[_idx].playerSeed = _playerSeed;*/
        mGame[_idx].playerSeedReady = true;
        playerSeedSet(_playerSeed, _idx);

        if (mGame[_idx].betReady && mGame[_idx].providerSeedReady && mGame[_idx].playerSeedReady){
          confirmGame(_idx);
        }
    }


    function getPayline(uint8 _idx, uint8 _indicator) constant returns (uint) {
        uint targetPayline;
        uint8 ptr = (_idx <= 6) ? 0 : 1;
        targetPayline = payTable[ptr];

        uint8 leftwalker = (_idx <= 6) ? (_idx * 42) : ((_idx - 6) * 42);
        uint8 rightwalker = (-_indicator + 2) * 31;
        uint8 additionalwalker = ((_idx - 6 * ptr) - 1) * 42 + (_indicator - 1) * 11;

        return (targetPayline << (256 - leftwalker + rightwalker)) >> (256 - leftwalker + rightwalker + additionalwalker);

  	}

    function confirmGame(uint _idx)
    {
        /*if(previousProviderSeed[_idx] != sha3(mGame[_idx].providerSeed) || previousPlayerSeed[_idx] != sha3(mGame[_idx].playerSeed)) {
            return;
        }*/
        uint reward = 0;
        uint factor = 0;
        uint divider = 10000000000;
        /*bytes32 rnseed = sha3(mGame[_idx].providerSeed ^ mGame[_idx].playerSeed);*/
        bytes32 rnseed = sha3(previousProviderSeed[_idx] ^ previousPlayerSeed[_idx]);
        uint randomNumber = uint(rnseed) % divider;

        for(uint j=0; j<mGame[_idx].numofLines; j++){
          factor = 0;
          rnseed = rnseed<<1;
          randomNumber = uint(rnseed) % divider;
          for(uint8 i=1; i<numofPayLine; i++){
            if(factor <= randomNumber && randomNumber < factor + getPayline(i,2)){
              reward += getPayline(i,1);
              break;
            }
            factor += getPayline(i,2);
          }
        }
        reward = reward * mGame[_idx].bet;

        /*mGame[_idx].randomNumber = randomNumber;*/
        mGame[_idx].reward = reward;

        providerBalance -= reward;
        playerBalance += reward;

        /*previousProviderSeed[_idx] = mGame[_idx].providerSeed;
        previousPlayerSeed[_idx] = mGame[_idx].playerSeed;*/
        gameConfirmed(reward, _idx);

        mGame[_idx].betReady = false;
        mGame[_idx].providerSeedReady = false;
        mGame[_idx].playerSeedReady = false;

    }

    function getInfo() constant returns (uint16, uint, uint, uint16, uint) {
        return (mDecider, mMinBet, mMaxBet, mMaxPrize, providerBalance);
    }
}
