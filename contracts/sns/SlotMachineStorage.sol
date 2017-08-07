pragma solidity ^0.4.1;


import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import "./SlotMachine.sol";
import './PaytableStorage.sol';

contract SlotMachineStorage is Ownable {
    address public payStorage;
    address[] public bankerAddress;
    mapping (address => address[]) public slotMachines;
    address[] public slotMachinesArray;

    uint public totalNumOfSlotMachine;

    function SlotMachineStorage (address _payStorage) {
        totalNumOfSlotMachine = 0;
        payStorage = _payStorage;
    }

    function setPaytableStorage(address _payStorage) {
        payStorage = _payStorage;
    }

    function addBanker(address _banker, uint _slotnum) private {
        if (slotMachines[_banker].length == 0){
          bankerAddress.push(_banker);
        }
    }

    function getNumOfBanker() constant returns (uint) {
        return bankerAddress.length;
    }

    function createSlotMachine (address _banker,  uint16 _decider, uint _minBet, uint _maxBet, uint16 _maxPrize, bytes16 _name)
        onlyOwner
        returns (address)
    {
        uint[2] memory payTableBase = PaytableStorage(payStorage).getPayline(_maxPrize,_decider);
        uint8 numOfPayLine = PaytableStorage(payStorage).getNumOfPayline(_maxPrize,_decider);
        uint[24] memory payTable;

        for(uint8 i=0; i<numOfPayLine; i++){
            payTable[i*2] = getPayline(payTableBase,i+1,1);
            payTable[i*2+1] = getPayline(payTableBase,i+1,2);
        }

        address newslot = address(new SlotMachine(_banker, _decider, _minBet, _maxBet, _maxPrize, payTable, numOfPayLine, _name));
        addBanker(_banker, 1);

        addSlotMachine(_banker, newslot);
        addSlotMachineInArray(newslot);

        totalNumOfSlotMachine++;
        return newslot;
    }

    function getPayline(uint[2] _payTableBase, uint8 _idx, uint8 _indicator) constant returns (uint) {
        uint8 ptr = (_idx <= 6) ? 0 : 1;
        uint8 leftwalker = ((_idx <= 6) ? (_idx * 42) : ((_idx - 6) * 42)) - (-_indicator + 2) * 31;
        uint8 rightwalker = ((_idx - 6 * ptr) - 1) * 42 + (_indicator - 1) * 11;

        return (_payTableBase[ptr] << (256 - leftwalker)) >> (256 - leftwalker + rightwalker);
    }

    function addSlotMachine(address _banker, address _slotaddr) private {
        slotMachines[_banker].push(_slotaddr);
    }


    function removeSlotMachine(address _banker, address _slotaddr)
        onlyOwner
    {
        SlotMachine(_slotaddr).shutDown();
        slotMachines[_banker].length--;
        totalNumOfSlotMachine--;
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

    function getIdxOfSlotMachine(address _banker, address _slotaddr)
        constant returns (uint)
    {
        uint totalnum = getNumOfSlotMachine(_banker);
        for (uint i=0;i<totalnum;i++) {
            if(slotMachines[_banker][i] == _slotaddr) return i;
        }
    }

    function getLengthOfSlotMachinesArray() constant returns (uint) {
        return slotMachinesArray.length;
    }

    function addSlotMachineInArray(address _slotaddr) private {
        slotMachinesArray.push(_slotaddr);
    }

    function getAllSlotMachinesArray() constant returns (address[]) {
        return slotMachinesArray;
    }

    function getSlotMachines(address _banker) constant returns (address[]) {
        return slotMachines[_banker];
    }

    function getSlotMachinesArray(uint from, uint to) constant returns (address[]) {
        address[] memory ret = new address[](to - from + 1);
        for (uint i=from; i<=to; i++){
            ret[i-from] = slotMachinesArray[i];
        }
        return ret;
    }

    function setSlotMachineInArray(uint _idx, address _slotaddr)
        onlyOwner
    {
        slotMachinesArray[_idx] = _slotaddr;
    }

    function getIdxOfSlotMachinesArray(address _slotaddr)
        constant returns (uint)
    {
        uint totalnum = slotMachinesArray.length;
        for (uint i=0;i<totalnum;i++) {
            if(slotMachinesArray[i] == _slotaddr) return i;
        }
    }
}
