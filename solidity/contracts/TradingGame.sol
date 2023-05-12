// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";

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

    struct Player {
        bool hasBet;
        uint bet;
        uint amount;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;
    uint public totalPool;
    uint public winnersPool;
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
        console.log("Owner contract deployed by:", msg.sender);
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

    function placeBet(uint _bet) public payable {
        require(msg.value > 0, "Must bet more than 0.");
        require(!outcomeSet, "Betting period has ended.");
        require(_bet >= 0 && _bet <= 4, "Bet must be between 0 and 4.");
        Player storage player = players[msg.sender];
        require(!player.hasBet, "Player has already placed a bet.");

        player.hasBet = true;
        player.bet = _bet;
        player.amount = msg.value;
        playerAddresses.push(msg.sender);

        totalPool += msg.value;
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
            if (player.bet == gambleOutcome) {
                totalWinners++;
            } else {
                winnersPool += player.amount * loserPercentage / 100;
            }
        }

        winnersPool = totalPool - winnersPool;
    }

    function redeem() public {
        require(outcomeSet, "Outcome has not been set yet.");

        Player storage player = players[msg.sender];

        require(player.hasBet, "No bet to redeem.");

        uint payout;
        if (player.bet == gambleOutcome) {
            payout = winnersPool * player.amount / totalWinners;
        } else {
            payout = player.amount * loserPercentage / 100;
        }

        require(payout <= address(this).balance, "Contract does not have enough funds to pay out.");

        player.hasBet = false;
        payable(msg.sender).transfer(payout);
    }
}

