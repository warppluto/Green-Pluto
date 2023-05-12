// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract TradingGame {

    address private owner;
    
    address payable public chairperson;
    uint public gambleOutcome;
    bool public outcomeSet = false;
    uint public loserPercentage; // percentage of original bet that losers get back

    struct Bet {
        uint outcome;
        uint amount;
    }

    struct Player {
        Bet[] bets;
        uint totalBetAmount;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    // The total amount of money that has been bet by all players. 
    // Every time a player places a bet, the amount they bet is added to totalPool.
    uint public totalPool;

    // The amount of money that will be split among the winners. 
    // It's calculated as the totalPool minus the total amount that will be returned to the losers.
    uint public winnersPool;

    // The total amount of money that has been bet on the winning outcome. 
    // It's used to calculate how much each winner gets when they redeem their bet. 
    // The payout for each winning bet is proportional to the amount of that bet relative to totalWinners.
    uint public totalWinners;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        chairperson = payable(msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function placeBet(uint _outcome, uint _amount) public payable {
        require(msg.value == _amount, "Sent value does not match the bet amount.");
        require(!outcomeSet, "Betting period has ended.");
        require(_outcome >= 0 && _outcome <= 4, "Outcome must be between 0 and 4.");

        Player storage player = players[msg.sender];
        player.bets.push(Bet(_outcome, _amount));
        player.totalBetAmount += _amount;

        if (player.bets.length == 1) {
            // If this is the player's first bet, add them to the playerAddresses array
            playerAddresses.push(msg.sender);
        }

        totalPool += _amount;
    }

    function setOutcome(uint _outcome, uint _loserPercentage) public {
        require(msg.sender == chairperson, "Only the chairperson can set the outcome.");
        require(!outcomeSet, "Outcome has already been set.");
        require(_outcome >= 0 && _outcome <= 4, "Outcome must be between 0 and 4.");
        require(_loserPercentage >= 0 && _loserPercentage <= 100, "Loser percentage must be between 0 and 100.");

        gambleOutcome = _outcome;
        outcomeSet = true;
        loserPercentage = _loserPercentage;

        // Calculate total winners and winners pool
        for (uint i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            for (uint j = 0; j < player.bets.length; j++) {
                Bet storage bet = player.bets[j];
                if (bet.outcome == gambleOutcome) {
                    totalWinners += bet.amount;
                } else {
                    winnersPool += bet.amount * loserPercentage / 100;
                }
            }
        }

        winnersPool = totalPool - winnersPool;
    }

    function redeem() public {
        require(outcomeSet, "Outcome has not been set yet.");

        Player storage player = players[msg.sender];

        require(player.bets.length > 0, "No bets to redeem.");

        uint payout = 0;
        for (uint i = 0; i < player.bets.length; i++) {
            Bet storage bet = player.bets[i];
            if (bet.outcome == gambleOutcome) {
                payout += winnersPool * bet.amount / totalWinners;
            } else {
                payout += bet.amount * loserPercentage / 100;
            }
        }

        require(payout <= address(this).balance, "Contract does not have enough funds to pay out.");

        delete players[msg.sender];
        payable(msg.sender).transfer(payout);
    }

}

