pragma solidity ^0.4.0;
import "./LibInterface.sol";
import "./SlotMachineStorage.sol";

library SlotLib2 {

    event slotMachineCreated(address _banker, uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, uint _totalnum, address _slotaddr);
    event slotMachineRemoved(address _banker, address _slotaddr, uint _totalnum);


    //create new slotmachine
    function createSlotMachine (address _slotmachineStorage, address _banker,  uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize) returns (address) {
        address newslot = address(SlotMachineStorage(_slotmachineStorage).createSlotMachine(_banker, _decider, _minBet, _maxBet, _maxPrize));
        slotMachineCreated(_banker, _decider, _minBet, _maxBet, _maxPrize, SlotMachineStorage(_slotmachineStorage).getNumOfSlotMachine(_banker),newslot);
        return newslot;
    }

    function removeSlotMachine (address _slotmachineStorage, address _banker, uint _idx) {
        uint totalnum = SlotMachineStorage(_slotmachineStorage).getNumOfSlotMachine(_banker);
        address slottoremove = SlotMachineStorage(_slotmachineStorage).getSlotMachine(_banker, _idx);
        require(_idx < totalnum);

        for (uint i = _idx; i < totalnum-1 ; i++){
            SlotMachineStorage(_slotmachineStorage).setSlotMachine(_banker, i, SlotMachineStorage(_slotmachineStorage).getSlotMachine(_banker, i + 1));
        }

        SlotMachineStorage(_slotmachineStorage).setSlotMachine(_banker, totalnum-1, address(0x0));
        SlotMachineStorage(_slotmachineStorage).removeSlotMachine(_banker, slottoremove);
        slotMachineRemoved(_banker, slottoremove, totalnum-1);
    }


}
