pragma solidity ^0.4.0;

//import "./SlotLib.sol";
import "./SlotMachineStorage.sol";

import "./LibInterface.sol";

contract SlotMachineManager {
    using LibInterface for address;
    address private slotmachineStorage;
    address private admin;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event slotMachineCreated(address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, uint _totalnum, address _slotaddr);
    event slotMachineRemoved(address _banker, address _slotaddr, uint _totalnum);

    function SlotMachineManager (address _storageaddr) {
        slotmachineStorage = _storageaddr;
        admin = msg.sender;
    }

    function setStorage(address _storageaddr) onlyAdmin {
        slotmachineStorage = _storageaddr;
    }

    function getStorageAddr() constant returns (address) {
        return slotmachineStorage;
    }


    function createSlotMachine(uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, bytes32 _name)
        returns (address)
    {
        address newslot;
        newslot = slotmachineStorage.createSlotMachine(msg.sender, _decider, _minBet, _maxBet, _maxPrize, _name);
        return newslot;
    }

    function removeSlotMachine(address _slotaddr) {
        slotmachineStorage.removeSlotMachine(msg.sender, _slotaddr);
    }



}
