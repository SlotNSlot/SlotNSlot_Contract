'use strict';

const Dispatcher = artifacts.require('Dispatcher.sol');
const DispatcherStorage = artifacts.require('DispatcherStorage.sol');
const SlotLib = artifacts.require("./sns/SlotLib.sol");
const SlotMachineManager = artifacts.require("./sns/SlotMachineManager.sol");
const SlotMachineStorage = artifacts.require("./sns/SlotMachineStorage.sol");
const PaytableStorage = artifacts.require("./sns/PaytableStorage.sol");
const SlotMachine = artifacts.require("./sns/SlotMachine.sol");

function makeseed(origin, iternum) {
  var seed = origin.toString(16);
  for (var i = 0; i < iternum; i++) {
    seed = web3.sha3(seed,{encoding:'hex'});
  }
  return seed;
}


contract('TestProxyLibrary', () => {
  describe('test', () => {

    it('works', () => {
      const maxGameNum = 1100;
      const initialBankerBalance = web3.toWei(10,"ether");
      const initialPlayerBalance = web3.toWei(10,"ether");
      const gameBetting = web3.toWei(0.001,"ether");
      const gamePlayNum = 200;
      const gamePlayLine = 20;

      var slotManager, slotStorage, slot, slotaddr;
      var dispatcherStorage;
      var bankerBalance, playerBalance;

      var gasforCreating = 0;
      var gasforPlayerSeedInitializing = 0;
      var gasforBankerSeedInitializing = 0;
      var gasforGameInitializing = 0;
      var gasforPlayerSeedSetting = 0;
      var gasforBankerSeedSetting = 0;

      var user1 = web3.eth.accounts[0];
      var user2 = web3.eth.accounts[1];
      var playerNumbers = [1,1,1].map(function(x){return Math.random()});
      var bankerNumbers = [1,1,1].map(function(x){return Math.random()});
      var playerSeeds = playerNumbers.map(function(x){return makeseed(x,maxGameNum)});
      var bankerSeeds = bankerNumbers.map(function(x){return makeseed(x,maxGameNum)});
      function printBalance() {
        return (slot.playerBalance()).then(playerbalance=>{
          console.log('playerBalance : ', playerbalance.valueOf().toString());
          return (slot.bankerBalance()).then(bankerbalance=>{console.log('bankerBalance : ', bankerbalance.valueOf().toString())})
        });
      }

      function playGame(gameidx, bet, line, idx, chainnum) {
        console.log('\n---------GAME ',gameidx,' START!---------');
        slot.initGameForPlayer(bet,line,idx,{from:user2});
        return slot.initGameForPlayer.estimateGas(bet,line,idx,{from:user2,gas:1000000}).then(result=>{
          console.log('Game initialized, gasUsed : ', result);
          gasforGameInitializing += result;
          slot.setBankerSeed(makeseed(bankerNumbers[idx],chainnum),idx,{gas:1000000});
          return slot.setBankerSeed.estimateGas(makeseed(bankerNumbers[idx],chainnum),idx);
        }).then(result => {
          console.log('Banker seed is set, gasUsed : ', result);
          gasforBankerSeedSetting += result;
          slot.setPlayerSeed(makeseed(playerNumbers[idx],chainnum),idx,{from:user2,gas:1000000});
          return slot.setPlayerSeed.estimateGas(makeseed(playerNumbers[idx],chainnum),idx,{from:user2,gas:1000000});
        }).then(result => {
          console.log('Player seed is set, gasUsed : ', result);
          gasforPlayerSeedSetting += result;
          return slot.mGame(idx);
        }).then(result => {
          console.log('player initial betting : ', bet * line, 'player reward : ',result[0].valueOf().toString());
          console.log('player final prize : ', result[0] - bet * line);
          return printBalance();
        })
      }

      async function letsplay(bet, line, gamenum) {
        for(let i=0;i<gamenum;i++){
          await playGame(i+1,bet,line,i%3,maxGameNum-(Math.floor(i/3)+1));
        }
        console.log('\n-----AVERAGE GAS USAGE ON SLOTMACHINE-----');
        console.log('gasforCreating : ',gasforCreating);
        console.log('gasforGameInitializing : ',gasforGameInitializing/gamenum);
        console.log('gasforBankerSeedSetting : ',gasforBankerSeedSetting/gamenum);
        console.log('gasforPlayerSeedSetting : ',gasforPlayerSeedSetting/gamenum);
        console.log('\ngasforInitializing : ',(gasforCreating + gasforPlayerSeedInitializing + gasforBankerSeedInitializing));
        console.log('gasforPlaying(per a spin) : ',(gasforGameInitializing + gasforBankerSeedSetting + gasforPlayerSeedSetting)/gamenum);

      }
      SlotMachineManager.deployed().then(function(instance) {
        slotManager = instance;
        return SlotMachineStorage.deployed().then(function(instance) {
          slotStorage = instance;
          slotStorage.transferOwnership(slotManager.address,{gas:1000000});
          console.log('SlotMachineStorage Owner changed to ', slotManager.address);
          return;
        });
      })
      .then(() => {
        console.log('Initializing test start')
        return slotStorage.totalNumOfSlotMachine();
      })
      .then(result => {
        assert.equal(result, 0, 'There are already some slotmachines in storage');
        console.log('Initializing test completed successfully');
        console.log('Creating test start');
        slotManager.createSlotMachine(100, 1, web3.toWei(1,"ether"), 1000, 'test1',{gas:4000000});
        return slotStorage.totalNumOfSlotMachine();
      })
      .then(result => {
        assert.equal(result, 1, 'creating test1 failed');
        console.log('Slotmachine1 is created successfully');
        slotManager.createSlotMachine(125, 1, web3.toWei(1,"ether"), 2000, 'test2',{gas:4000000});
        return slotManager.createSlotMachine.estimateGas(125, 1, web3.toWei(1,"ether"), 2000, 'test2',{gas:4000000});
      })
      .then(result => {
        console.log('Creating test completed successfully, gasUsed : ', result);
        gasforCreating += result;
        return slotStorage.totalNumOfSlotMachine();
      }).then(result => {
        console.log('Total num of slotmachine : ', result.valueOf().toString());
        return slotStorage.getSlotMachine(user1,1);
      }).then(result => {
        slotaddr = result;
        console.log('slot address : ',slotaddr);
        slot = SlotMachine.at(slotaddr);
        web3.eth.sendTransaction({from:user1,to:slotaddr,value:initialBankerBalance,gas:1000000});
        return slot.getInfo();
      }).then(slotinfo => {
        console.log(slotinfo);
        slot.occupy(playerSeeds,{from:user2,value:initialPlayerBalance,gas:1000000});
        return slot.occupy.estimateGas(playerSeeds,{from:user2,value:10000000});
      }).then(result => {
        console.log('slot occupied by player : ', user2, ' gasUsed : ',result);
        gasforPlayerSeedInitializing += result;
        slot.initBankerSeed(bankerSeeds,{gas:1000000});
        return slot.initBankerSeed.estimateGas(bankerSeeds);
      }).then(result => {
        console.log('Bankerseeds are initialized, gasUsed: ',result);
        gasforBankerSeedInitializing += result;
        return letsplay(gameBetting,gamePlayLine,gamePlayNum);
      }).then(() => {
        console.log('Player leaving.....');
        console.log('banker wallet balance : ', web3.fromWei(web3.eth.getBalance(user1),"ether"));
        console.log('player wallet balance : ',web3.fromWei(web3.eth.getBalance(user2),"ether"));
        slot.leave({from:user2,gas:1000000});
        return slot.leave.estimateGas({from:user2,gas:1000000});
      }).then(result => {
        console.log('player left the slot, gasUsed : ', result);
        slot.shutDown({gas:1000000});
        return slot.shutDown.estimateGas({gas:1000000});
      }).then(result => {
        console.log('banker closed the slot, gasUsed : ', result);
        console.log('banker wallet balance : ', web3.fromWei(web3.eth.getBalance(user1),"ether"));
        console.log('player wallet balance : ',web3.fromWei(web3.eth.getBalance(user2),"ether"));

      })


    });
  });
});
