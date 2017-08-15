pragma solidity ^0.4.11;


import "./MultiSigWallet.sol";


contract SlotNSlotICOWallet is MultiSigWallet {
    /**
     *  Ether which is funded from ICO can be withdrawn 2,400 ETH every 90 days for 4 years.
     */
    uint public constant LOCKUP_LIMIT_PERIOD = 4 years;
    uint public constant LOCKUP_RESET_DURATION = 90 days;

    uint public mYearlyLimit;
    uint public mStartYear;
    uint public mAllowThisYear;
    uint public mLastYear;

    event YearlyLimitChange(uint _yearlyLimit);

    function SlotNSlotICOWallet(address[] _owners, uint _required, uint _yearlyLimit)
    public
    MultiSigWallet(_owners, _required)
    {
        mYearlyLimit = _yearlyLimit;
        mAllowThisYear = mYearlyLimit;
        mLastYear = now;
        mStartYear = mLastYear;
    }

    function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
    {
        Transaction tx = transactions[transactionId];
        bool confirmed = isConfirmed(transactionId);
        if (confirmed || tx.data.length == 0 && isUnderLimit(tx.value)) {
            tx.executed = true;
            if (!confirmed) {
                mAllowThisYear -= tx.value;
            }
            if (tx.destination.call.value(tx.value)(tx.data)) {
                Execution(transactionId);
            } else {
                ExecutionFailure(transactionId);
                tx.executed = false;
                if (!confirmed) {
                    mAllowThisYear += tx.value;
                }
            }
        }
    }

    function isUnderLimit(uint _value)
    internal
    returns (bool)
    {
        if (lockupOver()) {
            return true;
        }

        if (now > mLastYear + LOCKUP_RESET_DURATION) {
            mLastYear = now;
            mAllowThisYear = mYearlyLimit;
        }

        if (mAllowThisYear - _value > mAllowThisYear || _value > mAllowThisYear) {
            return false;
        }
        return true;
    }

    function lockupOver() private returns (bool) {
        return now - mStartYear >= LOCKUP_LIMIT_PERIOD;
    }
}
