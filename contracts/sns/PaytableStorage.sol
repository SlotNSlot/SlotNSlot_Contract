pragma solidity ^0.4.0;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract PaytableStorage is Ownable {

    mapping (uint16 => mapping (uint16 => uint[2])) private payTable;
    /*

    payTable[prize][prob][0] (256 bits)

    ----------------------------------------- 256 ----------------------------------
    | numOfPayLine | paylinevalue[6] | paylinevalue[5] | ******** | paylinevalue[1] |
    ---- 4 -----	  ----- 42 -----    ----- 42 -----    - 42*3 -     ----- 42 -----


    payTable[prize][prob][1] (256 bits)

    ----------------------------------------- 256 -----------------------------------
    | remained bits | paylinevalue[12] | paylinevalue[11] | ******** | paylinevalue[7] |
    ---- 4 -----	  ----- 42 -----    ----- 42 -----      - 42*3 -    ----- 42 -----


    each paylinevalue (42 bits)

    | occupation |  prize  |
    ---- 31 ----   -- 11 --

    occupation = probability * 10^10

    */

    function PaytableStorage() {

        payTable[1000][100][0] = 0xb769dd258191d8cdea984b7581fd6e0c9d0528788196f2d62b002958739a9805;
        payTable[1000][100][1] = 0x1dcd64fdbe87733d0c67d1dcb70a98fa7718f4ec259db952f187d;

        payTable[1000][125][0] = 0xb9498ed7a192512135d84b93ba7bc80ca4a008740198db67f7a029c3246b4005;
        payTable[1000][125][1] = 0x2540be3d3e89502183e7d253fab068fa94f1541225a5333d1787d;

        payTable[1000][150][0] = 0xbb2a947e0192ca1abd304bb2430e440cac6546bb019ae2a78ea02a4517e7f805;
        payTable[1000][150][1] = 0x2cb4177d3e8b2d034887d2cb3d9100fab2cb4cf825acaf766c07d;

        payTable[1500][100][0] = 0xc76663358191d77103c04b74fc522a0c9cd043508196db0ae480294e9fd70805;
        payTable[1500][100][1] = 0x773593f7771dcd08ad3e8773147c47d1dca06c10fa770a9fb2259db13bda07d;

        payTable[1500][125][0] = 0xc9492a17819250f8ae404b93aa526c0ca499356f0198d7e8018029c15ea45005;
        payTable[1500][125][1] = 0x9502f8f5772540a273be89501951a7d253f79850fa94efb3ee25a532559d87d;

        payTable[1500][150][0] = 0xcb2a499de192c9f9d3904bb234a0780cac5e573c019ade205cc02a41d4c16005;
        payTable[1500][150][1] = 0xb2d05df5772cb4129dbe8b2d019047d2cb3c9910fab2ca7e8225acaedd2787d;

        payTable[2000][100][0] = 0xc765d6828191d738cf704b74e6aaf60c9cc7bc1d8196d74a4e40294d23bc3005;
        payTable[2000][100][1] = 0x773593f7f41dcd276f3e877318e227d1dc9f41b0fa7708d086259db003c707d;

        payTable[2000][125][0] = 0xc948b779019250c90a784b9396fdde0ca490f9ef0198d3afea2029bf41e29805;
        payTable[2000][125][1] = 0x9502f8f5f42540ac72be89501a3447d253f67bd8fa94ee5a3c25a531604907d;

        payTable[2000][150][0] = 0xcb27e165e192c8ef85104bb1c2c26a0cac29c118819abe6fec402a2d85058805;
        payTable[2000][150][1] = 0xb2d05df3f42cb40fa03e8b2cfb7b87d2cb35d860fab2c3ca9625aca9e1e407d;

    }

    function getPayline(uint16 _prize, uint16 _prob) constant returns (uint[2]) {
        return payTable[_prize][_prob];
    }

    function getNumOfPayline(uint16 _prize, uint16 _prob) constant returns (uint8) {
        uint targetPayline = payTable[_prize][_prob][0];
        return uint8(targetPayline>>252);
    }

    function addPayline(uint16 _maxPrize, uint16 _targetProb, uint _a, uint _b) onlyOwner {
        payTable[_maxPrize][_targetProb][0] = _a;
        payTable[_maxPrize][_targetProb][1] = _b;
    }

}
