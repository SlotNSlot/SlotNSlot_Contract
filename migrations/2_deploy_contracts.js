var SlotMachineStorage = artifacts.require("./sns/SlotMachineStorage.sol");
var SlotMachineManager = artifacts.require("./sns/SlotMachineManager.sol");
var SlotLib = artifacts.require("./sns/SlotLib.sol");
var Dispatcher = artifacts.require("./Dispatcher.sol");
var DispatcherStorage = artifacts.require("./DispatcherStorage.sol");
var SlotMachine = artifacts.require("./sns/SlotMachine.sol");
var PaytableStorage = artifacts.require("./sns/PaytableStorage.sol");

module.exports = function(deployer) {
    var slotstorage, paystorage;
    deployer.deploy(SlotLib).then(function() {
      console.log('SlotLib address : ', SlotLib.address);
      return deployer.deploy(DispatcherStorage, SlotLib.address);
    })
    .then(function () {
      console.log('DispatcherStorage address : ', DispatcherStorage.address);
      console.log('unlinked_binary : ', Dispatcher.unlinked_binary);
    })
    .then(() => {
      Dispatcher.unlinked_binary = Dispatcher.unlinked_binary
        .replace('1111222233334444555566667777888899990000',
        DispatcherStorage.address.slice(2));
      return deployer.deploy(PaytableStorage);
    })
    .then(() => {
      console.log('unlinked_binary : ', Dispatcher.unlinked_binary);
      console.log('PaytableStorage address : ',PaytableStorage.address);
      return deployer.deploy(SlotMachineStorage, PaytableStorage.address);
    })
    .then(() => {
        console.log('SlotMachineStorage address : ', SlotMachineStorage.address);
    })
    .then(function () {
      return deployer.deploy(Dispatcher).then(function (){
        console.log('Dispatcher address : ', Dispatcher.address);
        SlotMachineManager.link('LibInterface', Dispatcher.address);
        return deployer.deploy(SlotMachineManager, SlotMachineStorage.address).then(function (instance) {
          console.log('SlotMachineManager address : ', SlotMachineManager.address);
          return;
        })
      });
    });

};
