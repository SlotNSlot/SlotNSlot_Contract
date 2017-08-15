pragma solidity ^0.4.11;


import './SLOTToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/**
 * @title SLOTCrowdsale
 * The contract which is used in SlotNSlot ICO
 */
contract SLOTCrowdsale {

    /**
     *  The funding hard cap is 40000 ETH
     */
    uint public constant FUNDING_HARD_CAP = 40000 ether;

    /**
     *  Start and end date of ICO
     *  Start date : Aug 20th, 2017, AM 08:00 (1503216000)
     *  End date : Sep 17th, 2017, AM 08:00 (1505635200)
     */
    uint public constant START_DATE_TIMESTAMP = 1503216000;
    uint public constant END_DATE_TIMESTAMP = 1505635200;

    /**
     *  If a investor funds until (START_DATE_TIMESTAMP + EARLY_BIRD_DURATION),
     *  he/she will get 12000 SLOT / 1 eth.
     */
    uint public constant EARLY_BIRD_DURATION = 1 days;

    uint public constant PRICE_EARLY_BIRD = 12000;

    /**
     *  1 eth = 10000 SLOT
     */
    uint public constant PRICE_NORMAL = 10000;

    /**
     *  The multisig address which stores fundraised ether.
     */
    address public mMultisigAddr;

    /**
     *  Crowdsale owner
     */
    address public mOwnerAddr;

    /**
     *  Address of SLOT token contract
     */
    SLOTToken public mSLOTToken;

    /**
     *  The amount of ether raised and SLOT sold
     */
    uint public mEtherRaised;
    uint public mSLOTSold;

    bool public mPaused;

    modifier afterCroudfundPeriod() {
        require(now > END_DATE_TIMESTAMP);
        _;
    }

    modifier isCrowdsaleGoesOn() {
        require(now >= START_DATE_TIMESTAMP && now < END_DATE_TIMESTAMP);
        require(mEtherRaised <= FUNDING_HARD_CAP);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == mOwnerAddr);
        _;
    }

    modifier notPaused() {
        require(!mPaused);
        _;
    }

    event Fund(address indexed _recipient, uint _amount);
    event CrowdsaleEnd();

    function SLOTCrowdsale(address _multisigAddr, address _SLOTToken) {
        mMultisigAddr = _multisigAddr;
        mOwnerAddr = msg.sender;

        mSLOTToken = SLOTToken(_SLOTToken);

        mEtherRaised = 0;
        mSLOTSold = 0;
        mPaused = false;
    }

    function togglePause(bool _paused)
    onlyOwner
    {
        mPaused = _paused;
        mSLOTToken.transferOwnership(msg.sender);
    }


    function transferOwnership(address _newOwner)
    onlyOwner
    {
        if (_newOwner != address(0)) {
            mOwnerAddr = _newOwner;
        }
    }

    function getPrice()
    constant
    returns (uint o_rate)
    {
        if (now <= START_DATE_TIMESTAMP + EARLY_BIRD_DURATION) {
            return PRICE_EARLY_BIRD;
        }

        if (now <= END_DATE_TIMESTAMP) {
            return PRICE_NORMAL;
        } else {
            return 0;
        }
    }

    function processPurchase(uint _rate)
    internal
    returns (uint o_amount)
    {
        o_amount = SafeMath.mul(msg.value, _rate);

        mMultisigAddr.transfer(msg.value);
        assert(mSLOTToken.mint(msg.sender, o_amount));

        mSLOTSold += o_amount;
        mEtherRaised += msg.value;
    }

    function()
    payable
    isCrowdsaleGoesOn
    notPaused
    {
        require(msg.value != 0);

        uint amount = processPurchase(getPrice());
        Fund(msg.sender, amount);
    }

    function finalize()
    onlyOwner
    afterCroudfundPeriod
    {
        uint tokenRemainedAmount = SafeMath.div(mSLOTSold, 4);
        assert(mSLOTToken.mint(mMultisigAddr, tokenRemainedAmount));
        assert(mSLOTToken.finishMinting());
        mSLOTToken.transferOwnership(msg.sender);
        mOwnerAddr.transfer(this.balance);
        
        CrowdsaleEnd();
    }
}
