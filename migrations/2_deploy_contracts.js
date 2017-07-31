var SlotMachineStorage = artifacts.require("./sns/SlotMachineStorage.sol");
var SlotMachineManager = artifacts.require("./sns/SlotMachineManager.sol");
var SlotLib = artifacts.require("./sns/SlotLib.sol");
var SlotLib2 = artifacts.require("./sns/SlotLib2.sol");
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

    // deployer.deploy(SlotMachine,'0x98808f0a61c3d5618732d494e0fbcd21ee8ff04a',
    //   150,200,200000,2000,(new Array
    //     ('0xc0042351a19001e47b684b011bbe080c813001678192085bd6202a2d85058805',
    //       '0x1f73f4000021b23e8000241a07d00026ae08fa001c430625800a5c4c87d')),11);
};
