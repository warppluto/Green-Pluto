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

    // percentage of original bet that losers get back for each outcome
    // set as a return on the trading strategy and is larger than 0 if the respective strategy was profitable
    // if the strategy lost money, this amount will be subtracted from the winnersPool
    mapping(uint => int) public loserPercentages; 


    struct Bet {
        uint outcome;
        uint amount;
    }

    struct Player {
        Bet[] bets;
        uint totalBetAmount;
        uint previousRedeemableAmount;
    }

    struct AlgoProvider {
        uint stakedAmount;
        bool isAlgoProvider;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    mapping(address => AlgoProvider) public algoProviders;
    address[] public algoProviderAddresses;

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

    mapping(uint => uint) public outcomePool;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Staked(address indexed user, uint amount);
    event Redeemed(address indexed user, uint amount);

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
        outcomePool[_outcome] += _amount;
    }

    function setOutcome(uint _outcome, int[5] memory _loserPercentages) public {
        require(msg.sender == chairperson, "Only the chairperson can set the outcome.");
        require(!outcomeSet, "Outcome has already been set.");
        require(_outcome >= 0 && _outcome <= 4, "Outcome must be between 0 and 4.");

        for (uint i = 0; i < 5; i++) {
            require(_loserPercentages[i] >= -100, "Loser percentages must be larger than -100");
            loserPercentages[i] = _loserPercentages[i];
        }

        gambleOutcome = _outcome;
        outcomeSet = true;

        // Calculate total winners and winners pool
        for (uint i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            for (uint j = 0; j < player.bets.length; j++) {
                Bet storage bet = player.bets[j];
                // if the bet is a correct one, add bet amount to totalWinners as total winning bet pool
                if (bet.outcome == gambleOutcome) {
                    totalWinners += bet.amount;
                // if the bet is a losing one, add bet amount to the pool that will be divided by the winners  
                } else {
                    // if the bet algo return percentage is negative, decrease the winners pool by that amount
                    if (loserPercentages[bet.outcome]<0) {
                        winnersPool += bet.amount * (uint(100 + loserPercentages[bet.outcome])) / 100;
                    // if the bet algo return is positive, add the whole bet amoutn to winners pool
                    } else {
                        winnersPool += bet.amount;
                    }
                    
                }
            }
        }

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
                // if bet algo return was positive, increase payout by that amount
                if (loserPercentages[bet.outcome]>0) {
                    payout += bet.amount * uint(loserPercentages[bet.outcome]) / 100;
                }
            // losing bets get back the algo return if it is positive
            } else {
                // if bet algo return was positive, payout that amount to losers
                if (loserPercentages[bet.outcome]>0) {
                    payout += bet.amount * uint(loserPercentages[bet.outcome]) / 100;
                }
            }
        }
        payout += player.previousRedeemableAmount;

        require(payout <= address(this).balance, "Contract does not have enough funds to pay out.");
        player.previousRedeemableAmount = 0;
        delete players[msg.sender];
        payable(msg.sender).transfer(payout);
    }

    function startNewGame() public {
        require(msg.sender == chairperson, "Only the chairperson can set the outcome.");
        require(outcomeSet, "Outcome has not been set yet, the previous game is still on.");
        
        // make unclaimed bets redeemable
        for (uint j = 0; j < playerAddresses.length; j++) {
            Player storage player = players[playerAddresses[j]];
            if (player.bets.length > 0){
                // TODO refactor to function, reused in redeem()
                uint payout = 0;
                for (uint i = 0; i < player.bets.length; i++) {
                    Bet storage bet = player.bets[i];
                    if (bet.outcome == gambleOutcome) {
                        payout += winnersPool * bet.amount / totalWinners;
                        // if bet algo return was positive, increase payout by that amount
                        if (loserPercentages[bet.outcome]>0) {
                            payout += bet.amount * uint(loserPercentages[bet.outcome]) / 100;
                        }
                    // losing bets get back the algo return if it is positive
                    } else {
                        // if bet algo return was positive, payout that amount to losers
                        if (loserPercentages[bet.outcome]>0) {
                            payout += bet.amount * uint(loserPercentages[bet.outcome]) / 100;
                        }
                    }
                }
                player.previousRedeemableAmount += payout;
            }
            
        }
        outcomeSet = false;
        totalPool = 0;
        winnersPool = 0;
        totalWinners = 0;

        // reset outcome specific information
        for (uint i = 0; i < 5; i++) {
            loserPercentages[i] = 0;
            outcomePool[i] = 0;
        }

        gambleOutcome = 0;

    }

    function addAlgoProvider(address _algoProvider) public {
        require(msg.sender == chairperson, "Only the chairperson can add algo provider.");
        AlgoProvider memory newProvider;
        newProvider.isAlgoProvider = true;
        algoProviders[_algoProvider] = newProvider;
    }

    function removeAlgoProvider(address _algoProvider) public {
        require(msg.sender == chairperson, "Only the chairperson can remove algo prodivder.");
        delete algoProviders[_algoProvider];
    }

    function stake() public payable {
        require(algoProviders[msg.sender].isAlgoProvider, "Only algo providers can stake");
        require(msg.value > 0, "Stake amount must be greater than 0.");
        AlgoProvider storage algoProvider = algoProviders[msg.sender];
        algoProvider.stakedAmount += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function redeem(uint amount) public {
        require(algoProviders[msg.sender].isAlgoProvider, "Only algo providers can stake");
        AlgoProvider storage algoProvider = algoProviders[msg.sender];
        require(algoProvider.stakedAmount >= amount, "Insufficient balance to redeem.");
        algoProvider.stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Redeemed(msg.sender, amount);
    }
}

