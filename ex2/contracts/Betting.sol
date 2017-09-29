pragma solidity ^0.4.15;

contract Betting {
	/* Standard state variables */
	address public owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;
	uint numGambler;
	mapping(address => uint) winAmount;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {if (msg.sender == owner) _; }
	modifier OracleOnly() {if (msg.sender == oracle) _; }

	/* Constructor function, where owner and outcomes are set */
	function Betting(uint[] _outcomes) {
	    owner = msg.sender;
	    outcomes = _outcomes;
	    numGambler = 0;

	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
	    oracle = _oracle;
	    return oracle;
	}

	function checkBetValid(uint _outcome) returns (bool) {
	    bool valid = false;
	    for(uint i = 0; i < outcomes.length; i++) {
	        if (outcomes[i] == _outcome) {
	            valid = true;
	            break;
	        }
	    }
	    return valid;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {

	    if (msg.sender == gamblerA || msg.sender == gamblerB || msg.sender == owner || numGambler == 2
	        || !checkBetValid(_outcome)) {
	        revert();
	        return false;
	    }
        if (numGambler == 0) {
            gamblerA = msg.sender;
            bets[gamblerA] = Bet(_outcome, msg.value, false);
        } else {
            gamblerB = msg.sender;
            bets[gamblerB] = Bet(_outcome, msg.value, false);
        }
        winnings[msg.sender] = 0;
        numGambler += 1;
        return true;

	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
	    uint gamblerAAmount = bets[gamblerA].amount;
	    uint gamblerBAmount = bets[gamblerB].amount;
	    if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
	        winAmount[gamblerA] = gamblerAAmount;
	        winAmount[gamblerB] = gamblerBAmount;
	    } else if (bets[gamblerA].outcome == _outcome) {
	        winAmount[gamblerA] = gamblerAAmount + gamblerBAmount;
	        winnings[gamblerA] +=1;
	    } else if (bets[gamblerB].outcome == _outcome) {
	        winAmount[gamblerB] = gamblerAAmount + gamblerBAmount;
	        winnings[gamblerB] +=1;
	    } else {
	        winAmount[oracle] = gamblerAAmount + gamblerBAmount;
	        winnings[oracle] +=1;
	    }
	    contractReset();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
	    if (withdrawAmount <= winAmount[msg.sender]) {
	        winAmount[msg.sender] -= withdrawAmount;
	        msg.sender.transfer(withdrawAmount);
	        return msg.sender.balance;
	    } else {
	        revert();
	    }
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
	    return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
	    return winnings[msg.sender];

	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
	    delete gamblerA;
	    delete gamblerB;
	    delete numGambler;
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
