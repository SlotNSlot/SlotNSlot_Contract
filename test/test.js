'use strict';

const Dispatcher = artifacts.require('Dispatcher.sol');
const DispatcherStorage = artifacts.require('DispatcherStorage.sol');
const SlotLib = artifacts.require("./sns/SlotLib.sol");
const SlotMachineManager = artifacts.require("./sns/SlotMachineManager.sol");
const SlotLib2 = artifacts.require("./sns/SlotLib2.sol");
const SlotMachineStorage = artifacts.require("./sns/SlotMachineStorage.sol");
const PaytableStorage = artifacts.require("./sns/PaytableStorage.sol");

contract('TestProxyLibrary', () => {
  describe('test', () => {
    it('works', () => {
      var slotManager, slotStorage;
      var dispatcherStorage;
      var creationevent, removalevent, numberevent;

      SlotMachineManager.deployed().then(function(instance) {
        slotManager = instance;
        SlotMachineStorage.deployed().then(function(instance) {
          slotStorage = instance;
          slotStorage.transferOwnership(slotManager.address);
          console.log('SlotMachineStorage Owner changed to ', slotManager.address);
          return PaytableStorage.deployed().then(function(instance) {
            slotStorage.setPaytableStorage(instance.address);
            console.log('PaytableStorage address : ', instance.address);
          });
        });
      })
      .then(() => {
        console.log('setting up event watcher...');
        creationevent = slotManager.slotMachineCreated();
        creationevent.watch(function(error, result){
          if (!error){
            console.log('Event Log : \n \tslotMachine created in storage, provider : ', result.args._provider,
              'decider : ', result.args._decider,
              'minBet : ', result.args._minBet,
              'maxBet : ', result.args._maxBet,
              'maxPrize : ', result.args._maxPrize,
              'slot totalnum : ', result.args._totalnum,
              'slot address : ', result.args._slotaddr);
          }
        })
      })
      .then(() => {
        removalevent = slotManager.slotMachineRemoved();
        removalevent.watch(function(error, result){
          if(!error){
            console.log('Event Log : \n \tslotMachine removed in storage, provider : ', result.args._provider,
            'removed slot addr : ', result.args._slotaddr,
            'totalnum : ', result.args._totalnum);
          }
        });
      })
      .then(() => {
        console.log('event watcher setting completed');
        return  slotManager.getNumofSlotMachine();
      })
      .then(result => {
        console.log('initializing test, # of slotmachine should be 0');
        assert.equal(result,0,'initializing test failed');
        console.log('initializing test completed successfully');
        slotManager.createSlotMachine(100, 1000, 10000, 1000);
        slotManager.createSlotMachine(100, 2000, 20000, 1500);
        slotManager.createSlotMachine(125, 3000, 30000, 1500);
        slotManager.createSlotMachine(150, 4000, 40000, 2000);
        slotManager.createSlotMachine(150, 5000, 50000, 2000);
        return slotManager.getNumofSlotMachine();
      })
      .then(result => {
        console.log('creating test, # of slotmachine should be 5');
        assert.equal(result, 5, 'creating test failed');
        console.log('creating test completed successfully');

        console.log('removing test, # of slotmachine should be 4');
        slotManager.removeSlotMachine(0);
        return slotManager.getNumofSlotMachine();
      })
      .then(result => {
        assert.equal(result, 4, 'removing test failed');
        console.log('removing test completed successfully');
        
      })

      .then(() => {
        return DispatcherStorage.deployed().then(function (instance) {
          dispatcherStorage = instance;
          return dispatcherStorage.getLib();
        })
        .then(libaddr => {
          console.log('current lib address : ', libaddr);
        });
      })
      .then(() => {
        return SlotLib2.deployed().then(function (instance) {
          dispatcherStorage.replace(instance.address);

          console.log('hihi', instance.address);
          return dispatcherStorage.getLib();
        })
        .then(newlibaddr => {
          console.log('changed lib address : ', newlibaddr);
        });
      })
      .then(() => {
        console.log('new library linking test start');
        return slotManager.getSlotMachineDecider(0);
      })
      .then(result => {
        console.log('new result is ', result);
        assert.equal(result, 20, 'Decider should be 20, new library linking failed');
        console.log('new library linking test completed successfully');
       return slotManager.getSlotMachineDecider(0);
      })
      .then(result => {
        console.log('first slot of user : ', result);
      })
      .then(() => {
        console.log('test completed');
      });

      });
  });
});
