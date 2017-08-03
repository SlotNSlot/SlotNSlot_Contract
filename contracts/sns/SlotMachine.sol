pragma solidity ^0.4.1;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract SlotMachine is Ownable {
    bool public mAvailable;
    bool public mBankrupt;
    address public mPlayer;
    uint16 public mDecider;
    uint public mMinBet;
    uint public mMaxBet;
    uint16 public mMaxPrize;
    bytes16 public mName;

    bool public mIsGamePlaying;

    uint public bankerBalance;
    uint public playerBalance;

    bytes32[3] public previousPlayerSeed;
    bytes32[3] public previousBankerSeed;
    bool public initialPlayerSeedReady;
    bool public initialBankerSeedReady;

    uint[2] public payTable;
    uint8 public numOfPayLine;

    struct Game {
        uint reward;
        uint bet;
        bytes1 readyChecker;
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
    event bankerLeft(address banker);

    event gameOccupied(address player, bytes32[3] playerSeed);
    event bankerSeedInitialized(bytes32[3] bankerSeed);

    event gameInitialized(address player, uint bet, uint8 lines, uint8 idx);
    event bankerSeedSet(bytes32 bankerSeed, uint8 idx);
    event playerSeedSet(bytes32 playerSeed, uint8 idx);

    event gameConfirmed(uint reward, uint8 idx);

    function () payable {
      if (msg.sender == owner || tx.origin == owner) {
        bankerBalance += msg.value;
      } else if(msg.sender == mPlayer) {
        playerBalance += msg.value;
      }

    }

    function SlotMachine(address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize,
      uint[2] _payTable, uint8 _numOfPayLine, bytes16 _mName)
        payable
    {
        transferOwnership(_banker);
        mName = _mName;
        mDecider = _decider;
        mPlayer = 0x0;
        mAvailable = true;
        mBankrupt = false;
        mMinBet = _minBet;
        mMaxBet = _maxBet;
        mMaxPrize = _maxPrize;
        mIsGamePlaying = false;

        bankerBalance = msg.value;

        payTable = _payTable;
        numOfPayLine = _numOfPayLine;
        initialBankerSeedReady = false;
        initialPlayerSeedReady = false;
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

        mGame[0].readyChecker = 0x0f;
        mGame[1].readyChecker = 0x0f;
        mGame[2].readyChecker = 0x0f;
        initialPlayerSeedReady = true;
        gameOccupied(mPlayer, _playerSeed);
    }

    function initBankerSeed(bytes32[3] _bankerSeed)
        onlyOwner
    {
        previousBankerSeed[0] = _bankerSeed[0];
        previousBankerSeed[1] = _bankerSeed[1];
        previousBankerSeed[2] = _bankerSeed[2];

        initialBankerSeedReady = true;
        bankerSeedInitialized(_bankerSeed);
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
        initialBankerSeedReady = false;
        initialPlayerSeedReady = false;
    }

    function shutDown()
        notOccupied
        onlyAvailable
        notPlaying
    {
        selfdestruct(owner);
    }

    function initGameForPlayer(uint _bet, uint8 _lines, uint8 _idx)
        onlyPlayer
        notBankrupt
    {
        require(_bet >= mMinBet && _bet <= mMaxBet && (_bet % 100 == 0) && _lines <= 20);
        require(_bet * _lines <= playerBalance);

        mGame[_idx].bet = _bet + _lines;
        mGame[_idx].readyChecker = mGame[_idx].readyChecker >> 1;

        gameInitialized(mPlayer, _bet, _lines, _idx);

        if (mGame[_idx].readyChecker == 0x01){
          confirmGame(_idx);
        }
    }

    function setBankerSeed(bytes32 _bankerSeed, uint8 _idx)
        onlyOwner
    {
        require (previousBankerSeed[_idx] == sha3(_bankerSeed));

        previousBankerSeed[_idx] = _bankerSeed;
        mGame[_idx].readyChecker = mGame[_idx].readyChecker >> 1;

        bankerSeedSet(_bankerSeed, _idx);

        if (mGame[_idx].readyChecker == 0x01){
          confirmGame(_idx);
        }
    }


    function setPlayerSeed(bytes32 _playerSeed, uint8 _idx)
        onlyPlayer
    {
        require (previousPlayerSeed[_idx] == sha3(_playerSeed));

        previousPlayerSeed[_idx] = _playerSeed;
        mGame[_idx].readyChecker = mGame[_idx].readyChecker >> 1;

        playerSeedSet(_playerSeed, _idx);

        if (mGame[_idx].readyChecker == 0x01){
          confirmGame(_idx);
        }
    }


    function getPayline(uint8 _idx, uint8 _indicator) constant returns (uint) {
        uint targetPayline;
        uint8 ptr = (_idx <= 6) ? 0 : 1;
        targetPayline = payTable[ptr];

        uint8 leftwalker = ((_idx <= 6) ? (_idx * 42) : ((_idx - 6) * 42)) - (-_indicator + 2) * 31;
        uint8 rightwalker = ((_idx - 6 * ptr) - 1) * 42 + (_indicator - 1) * 11;

        return (targetPayline << (256 - leftwalker)) >> (256 - leftwalker + rightwalker);
  	}

    function confirmGame(uint8 _idx) private
    {
        uint reward = 0;
        uint divider = 10000000000;
        bytes32 rnseed = sha3(previousBankerSeed[_idx] ^ previousPlayerSeed[_idx]);
        uint randomNumber = uint(rnseed) % divider;
        uint8 numOfLines = uint8(mGame[_idx].bet % 100);
        uint bet = mGame[_idx].bet - numOfLines;
        uint[][] memory cmp = new uint[][](12);
        uint bankerbalance = bankerBalance;

        for(uint8 k=0; k<12; k++){
            cmp[k] = new uint[](2);
            cmp[k][0] = getPayline(k+1,1);
            cmp[k][1] = getPayline(k+1,2);
        }

        for(uint8 j=0; j<numOfLines; j++){
            randomNumber = uint(rnseed<<j) % divider;
            for(uint8 i=1; i<numOfPayLine; i++){
                if(randomNumber < cmp[i-1][1]){
                    reward += cmp[i-1][0];
                    break;
                }
            }
        }
        reward = reward * bet;

        if (reward >= bankerbalance) {
            reward = bankerbalance;
        }

        mGame[_idx].reward = reward;

        bankerBalance = bankerbalance - reward + bet * numOfLines;
        playerBalance = playerBalance + reward - bet * numOfLines;

        gameConfirmed(reward, _idx);

        mGame[_idx].readyChecker = 0x0f;

    }

    function getInfo() constant returns (uint16, uint, uint, uint16, uint) {
      //todo : add return values
        return (mDecider, mMinBet, mMaxBet, mMaxPrize, bankerBalance);
    }
}
