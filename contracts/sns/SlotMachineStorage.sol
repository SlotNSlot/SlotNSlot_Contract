pragma solidity ^0.4.0;


import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import "./SlotMachine.sol";
import './PaytableStorage.sol';

contract SlotMachineStorage is Ownable {
    address public payStorage;
    address[] public bankeraddress;
    mapping (address => address[]) public slotMachines;


    uint public totalNumOfSlotMachine;

    function SlotMachineStorage (){
        totalNumOfSlotMachine = 0;
    }

    function setPaytableStorage(address _payStorage) {
        payStorage = _payStorage;
    }

    function addBanker(address _banker, uint _slotnum) private {
        if (slotMachines[_banker].length == 0){
          bankeraddress.push(_banker);
        }
    }

    function getNumOfBanker() constant returns (uint) {
        return bankeraddress.length;
    }

    function createSlotMachine (address _banker,  uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize)
        onlyOwner
        returns (address)
    {
        uint[2] memory payTable = PaytableStorage(payStorage).getPayline(_maxPrize,_decider);
        uint8 numOfPayLine = PaytableStorage(payStorage).getNumOfPayline(_maxPrize,_decider);

        address newslot = address(new SlotMachine(_banker, _decider, _minBet, _maxBet, _maxPrize, payTable, numOfPayLine));
        addBanker(_banker, 1);
        slotMachines[_banker].push(newslot);
        totalNumOfSlotMachine++;
        return newslot;
    }

    function removeSlotMachine(address _banker, address _slotaddr)
        onlyOwner
    {
        SlotMachine(_slotaddr).shutDown();
        slotMachines[_banker].length--;
        totalNumOfSlotMachine--;
    }

    function deleteSlotMachineinArray(address _banker, uint _idx)

    {
        delete slotMachines[_banker][_idx];
    }

    function setSlotMachine(address _banker, uint _idx, address _newslotMachine)
        onlyOwner
    {
        slotMachines[_banker][_idx] = _newslotMachine;
    }

    function getNumOfSlotMachine(address _banker)
        constant returns (uint)
    {
        return slotMachines[_banker].length;
    }

    function getSlotMachine(address _banker, uint _idx)
        constant returns(address)
    {
        if (_idx < slotMachines[_banker].length) {
          return slotMachines[_banker][_idx];
        }
        else {
          return 0x0;
        }
    }


}
