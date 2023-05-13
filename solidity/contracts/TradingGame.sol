// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;



import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract TradingGame {

    address private owner;
    
    address payable public chairperson;
    uint public gambleOutcome;
    bool public outcomeSet = false;
    bool public bettingStopped = false;

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
        bool addressSaved;
    }

    struct AlgoProvider {
        uint stakedAmount;
        bool isAlgoProvider;
        uint managementAmount;
        uint usedManagementAmount;
        uint swappedTotalOutstanding;
        uint totalAmountReturned;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    uint public constant MAX_ALGOPROVIDERS = 5;
    mapping(address => AlgoProvider) public algoProviders;
    address[] public algoProviderAddresses;

    // minimum staked amount to become an algo provider, which cannot be overridden
    uint public constant MINIMUM_STAKE = 1000000000000000000;
    // the required stake from Algo providers, must be greater or equal to MINIMUM_STAKE
    uint public requiredAlgoProviderStake = MINIMUM_STAKE;

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
    event BettingOpen();
    event OutcomeSet(uint indexed gambleOutcome, uint indexed totalPool, uint indexed winnersPool, uint totalWinners);
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

    function fundAccount(uint _amount) public payable {
        require(msg.value == _amount, "Sent value does not match the bet amount.");
        Player storage player = players[msg.sender];
        player.previousRedeemableAmount += _amount;

        if (!player.addressSaved) {
            playerAddresses.push(msg.sender);
            player.addressSaved = true;
        }
    }


    function placeBet(uint _outcome, uint _amount) public {
        require(!outcomeSet, "Betting period has ended, outcome already set.");
        require(!bettingStopped, "Betting period has ended, outcome already set.");
        require(_outcome >= 0 && _outcome < algoProviderAddresses.length, "Outcome must be between 0 and number of algo providers.");

        Player storage player = players[msg.sender];

        require(player.previousRedeemableAmount >= _amount, "Account balance is less than bet size.");
        player.previousRedeemableAmount -= _amount;

        player.bets.push(Bet(_outcome, _amount));
        player.totalBetAmount += _amount;

        if (player.bets.length == 1 && !player.addressSaved) {
            // If this is the player's first bet, add them to the playerAddresses array
            playerAddresses.push(msg.sender);
            player.addressSaved = true;
        }

        totalPool += _amount;
        outcomePool[_outcome] += _amount;
    }

    function stopBetting() public {
        require(msg.sender == chairperson, "Only the chairperson can stop the betting.");
        require(!bettingStopped, "Betting has already been stopped.");
        bettingStopped = true;
        for (uint i=0; i<algoProviderAddresses.length; i++){
            AlgoProvider storage algoProvider = algoProviders[algoProviderAddresses[i]];
            algoProvider.managementAmount = outcomePool[i];
        }
    }

    function setOutcome(uint _outcome, int[] memory _loserPercentages) public {
        require(msg.sender == chairperson, "Only the chairperson can set the outcome.");
        require(!outcomeSet, "Outcome has already been set.");
        require(_outcome >= 0 && _outcome < algoProviderAddresses.length, "Outcome must be between 0 and number of algo providers.");

        for (uint i = 0; i < MAX_ALGOPROVIDERS; i++) {
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
        emit OutcomeSet(gambleOutcome, totalPool, winnersPool, totalWinners);

    }

    function redeemableAmount(address _playerAddress) public view returns (uint) {
        Player storage player = players[_playerAddress];
        return player.previousRedeemableAmount;
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
                payout += bet.amount;
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
        require(msg.sender == chairperson, "Only the chairperson can start a new game.");
        require(outcomeSet, "Outcome has not been set yet, the previous game is still on.");
        
        // make unclaimed bets redeemable
        for (uint j = 0; j < playerAddresses.length; j++) {
            Player storage player = players[playerAddresses[j]];
            if (player.bets.length > 0){
                // TODO refactor to function, reused in redeem()
                uint payout = 0;
                for (uint i = player.bets.length; i > 0; i--) {
                    uint index = i - 1;
                    Bet storage bet = player.bets[index];
                    if (bet.outcome == gambleOutcome) {
                        payout += winnersPool * bet.amount / totalWinners;
                        payout += bet.amount;
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
                    player.bets.pop();
                }
                player.previousRedeemableAmount += payout;
                player.totalBetAmount = 0;
            }
            
        }

        for (uint i=0; i<algoProviderAddresses.length; i++){
            AlgoProvider storage algoProvider = algoProviders[algoProviderAddresses[i]];
            algoProvider.managementAmount = 0;
        }
        
        totalPool = 0;
        winnersPool = 0;
        totalWinners = 0;

        // reset outcome specific information
        for (uint i = 0; i < algoProviderAddresses.length; i++) {
            loserPercentages[i] = 0;
            outcomePool[i] = 0;
        }

        gambleOutcome = 0;

        outcomeSet = false;
        bettingStopped = false;

        emit BettingOpen();

    }

    function addAlgoProvider(address _algoProvider) public {
        require(msg.sender == chairperson, "Only the chairperson can add algo provider.");
        require(algoProviderAddresses.length<=MAX_ALGOPROVIDERS, "Maximum algo providers already st.");
        require(!algoProviders[_algoProvider].isAlgoProvider, "Algo provider already set");
        AlgoProvider memory newProvider;
        newProvider.isAlgoProvider = true;
        algoProviders[_algoProvider] = newProvider;
        algoProviderAddresses.push(_algoProvider);
    }

    function removeAlgoProvider(address _algoProvider) public {
        require(msg.sender == chairperson, "Only the chairperson can remove algo prodivder.");
        require(!bettingStopped, "Algo provider can be removed only when betting is stopped");
        delete algoProviders[_algoProvider];
        address[] memory tempArray = new address[](algoProviderAddresses.length-1);
        uint adjustPosition = 0;
        for (uint i=0; i<algoProviderAddresses.length; i++){
            if (algoProviderAddresses[i]!=_algoProvider){
                tempArray[i - adjustPosition] = _algoProvider;
            } else {
                adjustPosition = 1;
            }
        }
        algoProviderAddresses = tempArray;
    }


    function setMinimumAlgoProviderStake(uint _stakeAmount) public {
        require(msg.sender == chairperson, "Only the chairperson can set the stake.");
        require(_stakeAmount >= MINIMUM_STAKE, "The stake amount must equal to or exceed minimum stake.");
        requiredAlgoProviderStake = _stakeAmount;

    }

    function stake() public payable {
        require(algoProviders[msg.sender].isAlgoProvider, "Only algo providers can stake");
        require(msg.value > 0, "Stake amount must be greater than 0.");
        AlgoProvider storage algoProvider = algoProviders[msg.sender];
        algoProvider.stakedAmount += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint amount) public {
        require(algoProviders[msg.sender].isAlgoProvider, "Only algo providers can stake");
        AlgoProvider storage algoProvider = algoProviders[msg.sender];
        require(algoProvider.stakedAmount >= amount, "Insufficient balance to redeem.");
        algoProvider.stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Redeemed(msg.sender, amount);
    }

    


    address private constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //goerli
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; //goerli


    ISwapRouter public immutable swapRouter = ISwapRouter(SWAP_ROUTER);
    
    IERC20 private wethToken;
    IERC20 private uniToken;


    function swapExactInputSingle(uint256 _amountIn, uint256 _minAmountOut, bool _liquidate) external returns (uint256 _amountOut) {
        require(algoProviders[msg.sender].isAlgoProvider, "Only algo providers can swap");
        require(!bettingStopped, "Algo provider can start swapping only when betting is stopped");
        require(algoProviders[msg.sender].stakedAmount>=requiredAlgoProviderStake, "Algo provider stake must satisfy minimum required stake constraint");
        AlgoProvider storage algoProvider = algoProviders[msg.sender];
        if (!_liquidate){
            require(algoProvider.usedManagementAmount + _amountIn <= algoProvider.managementAmount, "Algo provider management amount exceeded, transaction not allowed");
            algoProvider.usedManagementAmount += _amountIn;
        } else {
            require(algoProvider.swappedTotalOutstanding - _amountIn >= algoProvider.swappedTotalOutstanding, "Algo provider management amount exceeded, transaction not allowed");
            algoProvider.swappedTotalOutstanding -= _amountIn;            
        }
        // only predifined tokens allowed for swap, can later be set in the constructor, currently hardcoded
        address _tokenIn = WETH;
        address _tokenOut = UNI;

        if (_liquidate){
            _tokenIn = UNI;
            _tokenOut = WETH;
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp+60,
                amountIn: _amountIn,
                amountOutMinimum: _minAmountOut,
                sqrtPriceLimitX96: 0
            });

        _amountOut = swapRouter.exactInputSingle{value: address(this).balance}(params);
        if (!_liquidate){
            algoProvider.swappedTotalOutstanding += _amountOut;
        } else {
            algoProvider.usedManagementAmount -= _amountOut;
        }
        
    }



}

