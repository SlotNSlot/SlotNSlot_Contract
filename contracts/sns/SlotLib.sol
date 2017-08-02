pragma solidity ^0.4.0;
import "./LibInterface.sol";
import "./SlotMachineStorage.sol";

library SlotLib {

    event slotMachineCreated(address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, uint _totalnum, address _slotaddr);
    event slotMachineRemoved(address _banker, address _slotaddr, uint _totalnum);

    //create new slotmachine
    function createSlotMachine (address _slotmachineStorage, address _banker,  uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, bytes16 _name) returns (address) {
        address newslot = address(SlotMachineStorage(_slotmachineStorage).createSlotMachine(_banker, _decider, _minBet, _maxBet, _maxPrize, _name));
        slotMachineCreated(_banker, _decider, _minBet, _maxBet, _maxPrize, SlotMachineStorage(_slotmachineStorage).getNumOfSlotMachine(_banker),newslot);
        return newslot;
    }

    function removeSlotMachine (address _slotmachineStorage, address _banker, address _slotaddr) {
        uint totalnum = SlotMachineStorage(_slotmachineStorage).getNumOfSlotMachine(_banker);
        bool startRemove = false;
        for (uint i = 0; i < totalnum ; i++){
            if (startRemove) {
                SlotMachineStorage(_slotmachineStorage).setSlotMachine(_banker, i, SlotMachineStorage(_slotmachineStorage).getSlotMachine(_banker, i + 1));
            }
            else if (SlotMachineStorage(_slotmachineStorage).getSlotMachine(_banker, i) == _slotaddr) {
                startRemove = true;
                SlotMachineStorage(_slotmachineStorage).setSlotMachine(_banker, i, SlotMachineStorage(_slotmachineStorage).getSlotMachine(_banker, i + 1));
            }
        }

        SlotMachineStorage(_slotmachineStorage).removeSlotMachine(_banker, _slotaddr);
        SlotMachineStorage(_slotmachineStorage).setSlotMachineInArray(SlotMachineStorage(_slotmachineStorage).getIdxOfSlotMachinesArray(_slotaddr),0x0);
        slotMachineRemoved(_banker, _slotaddr, totalnum-1);


    }


}
