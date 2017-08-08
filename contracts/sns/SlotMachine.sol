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

    uint[24] public payTable;
    uint8 public numOfPayLine;

    struct Game {
        uint reward;
        uint info;

        /*
          structure of uint info

          info = bet + lines + readyChecker

          Base Condition
          1. bet >= 100 wei
          2. bet % 100 == 0
          3. 1 <= lines <= 20
          4. each method initGameForPlayer, setBankerSeed, setPlayerSeed
            sets (readyChecker += 20)

          If parameters are properly given,
            info shoud be in form of
            100000000000000 (bet)
          +              10 (lines)
          +              20 (readyChecker for initGameForPlayer)
          +              20 (readyChecker for setBankerSeed)
          +              20 (readyChecker for setPlayerSeed)
          ------------------
            100000000000070 => info
        */
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
    /*
        CONSTRUCTOR
    */
    function SlotMachine(address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize,
      uint[24] _payTable, uint8 _numOfPayLine, bytes16 _mName)
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

        numOfPayLine = _numOfPayLine;
        initialBankerSeedReady = false;
        initialPlayerSeedReady = false;

        for(uint8 k=0; k<_numOfPayLine; k++){
            payTable[k*2] = _payTable[k*2];
            payTable[k*2+1] = _payTable[k*2+1];
        }

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
        require(mGame[0].info == 0 && mGame[1].info == 0 && mGame[2].info == 0);

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

        mGame[_idx].info += (_bet + _lines + 20);
        uint betlines = mGame[_idx].info;

        gameInitialized(mPlayer, _bet, _lines, _idx);

        if ((betlines % 100) >= 61 && (betlines % 100) <= 80) {
          confirmGame(_idx);
        }

    }

    function setBankerSeed(bytes32 _bankerSeed, uint8 _idx)
        onlyOwner
    {
        require (previousBankerSeed[_idx] == sha3(_bankerSeed));

        previousBankerSeed[_idx] = _bankerSeed;

        bankerSeedSet(_bankerSeed, _idx);

        mGame[_idx].info += 20;
        uint betlines = mGame[_idx].info;

        if ((betlines % 100) >= 61 && (betlines % 100) <= 80) {
          confirmGame(_idx);
        }

    }


    function setPlayerSeed(bytes32 _playerSeed, uint8 _idx)
        onlyPlayer
    {
        require (previousPlayerSeed[_idx] == sha3(_playerSeed));

        previousPlayerSeed[_idx] = _playerSeed;

        playerSeedSet(_playerSeed, _idx);

        mGame[_idx].info += 20;
        uint betlines = mGame[_idx].info;

        if ((betlines % 100) >= 61 && (betlines % 100) <= 80) {
          confirmGame(_idx);
        }

    }



    function confirmGame(uint8 _idx) private
    {
        uint reward = 0;
        bytes32 rnseed = sha3(previousBankerSeed[_idx] ^ previousPlayerSeed[_idx]);
        uint randomNumber = uint(rnseed) % 10000000000;
        uint8 numOfLines = uint8((mGame[_idx].info % 100) - 60);
        uint bet = mGame[_idx].info - numOfLines - 60;
        uint8 numOfPayLines = numOfPayLine;
        uint bankerbalance = bankerBalance;
        uint[] memory cmp = new uint[](numOfPayLines*2);

        for(uint8 k=0; k<numOfPayLines; k++){
            cmp[k*2] = payTable[k*2];
            cmp[k*2+1] = payTable[k*2+1];
        }

        for(uint8 j=0; j<numOfLines; j++){
            randomNumber = uint(rnseed<<j) % 10000000000;
            for(uint8 i=1; i<numOfPayLines; i++){
                if(randomNumber < cmp[(i-1)*2+1]) {
                    reward += cmp[(i-1)*2];
                    break;
                }
            }
        }
        reward = reward * bet;

        if (reward >= bankerbalance) {
            reward = bankerbalance;
        }

        mGame[_idx].reward = reward;
        mGame[_idx].info = 0;

        bankerBalance = bankerbalance - reward + bet * numOfLines;
        playerBalance = playerBalance + reward - bet * numOfLines;

        gameConfirmed(reward, _idx);

    }

    function getInfo() constant returns (address, address, bytes16, uint16, uint, uint, uint16, uint) {
        return (mPlayer, owner, mName, mDecider, mMinBet, mMaxBet, mMaxPrize, bankerBalance);
    }
}
