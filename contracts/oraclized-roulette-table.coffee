# Liquidity book is a mechanism for posting collateral for an array
# of different contracts.

module.exports = "

contract LiquidityBook {
    string public standard = 'kerning-liquidity-book-0.0.1';

    address public owner;
    mapping(address => uint) public available_values;
    mapping(address => uint) public amount_wagered;
    mapping(address => uint) public odds;
    mapping(address => uint) pays;

    modifier only_by(address _account) {
        if (msg.sender != _account) {
            throw;
        }
        _;
    }

    function issueCollateral (address target)
        payable
    {
        if (odds[target] == 0) {
            odds[target] = 1000;
        }
        available_values[target] += msg.value;
    }

    function removeCollateral (uint value, address target)
        only_by(owner)
    {
        available_values[target] -= value;
        if (!this.send(value)) throw;
    }

    function setOdds (address target, uint new_odds)
    {
        odds[target] = new_odds;
    }

    function disburse() {
        if (pays[msg.sender] > 0) {
            uint amount = pays[msg.sender];
            pays[msg.sender] = 0;
            if (!msg.sender.send(amount)) throw;
        } else throw;
    }
}

contract RouletteResolver {
    function resolveStraightUp(uint _outcome, bool _pick) returns (bool);
    function resolveBetBlack(uint _outcome, bool _pick) returns (bool);
    function resolveBetOdd(uint _outcome, bool _pick) returns (bool);
    function resolveBetLow(uint _outcome, bool _pick) returns (bool);
}

contract OracledIssuableBet {

    function openBetWithBool(address bettor, bool pick) payable;
    function openBetWithUint(address bettor, uint pick) payable;

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool);
    function getWager(address bettor) returns (uint);

}

contract OpenableBet {   

    address public controller;
    address public owner;
    mapping(address => bool) public open_picks;
    mapping(address => uint) public open_wagers;

    function getWager(address bettor) returns (uint) {
        return open_wagers[bettor];
    }
}

contract LowBet is OpenableBet {

    function LowBet() {
        owner = msg.sender;
    }

    function openBetWithBool(address bettor, bool pick)
        payable
    {
        open_picks[bettor] = pick;
        open_wagers[bettor] += msg.value;
    }

    function openBetWithUint(address bettor, bool pick) payable {
        throw;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool low_result = RouletteResolver(resolver).resolveBetLow(outcome, true);
        return low_result;
    }
}

contract StraightUpBet is OpenableBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function openBetWithUint(address bettor, bool pick)
        payable
    {
        open_picks[bettor] = pick;
        open_wagers[bettor] += msg.value;
    }

    function openBetWithBool(address bettor, bool pick) payable {
        throw;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveStraightUp(outcome, open_picks[bettor]);
        return result;
    }
}

contract RouletteTable is LiquidityBook {

    address public resolver;
    address public oracle;
    address public owner;

    address public straight_up_bet;
    address public odd_bet;
    address public black_bet;
    address public low_bet;

    mapping(address => bool) children;

    modifier only_children() {
        if (!children[msg.sender]) throw;
        _;
    }
    modifier only_oracle() {
        if (msg.sender != oracle) throw;
        _;
    }

    modifier from_pool(address target) {
        uint _potential_amount_wagered = amount_wagered[target] + msg.value;
        uint potential_payout = _potential_amount_wagered * odds[target]/1000;
        if (available_values[target] < potential_payout) throw;
        _;
        available_values[target] -= potential_payout;
        amount_wagered[target] = _potential_amount_wagered;
    }

    function RouletteTable(address _resolver, address _s_u_bet, address _l_bet) {
        resolver = _resolver;
        straight_up_bet = _s_u_bet;
        low_bet = _l_bet;
        owner = msg.sender;
    }

    function takeBetWithBool (address target, bool pick)
        payable
    {
        OracledIssuableBet(target).openBetWithBool(msg.sender, pick);
    }

    function takeBetWithUint (address target, uint pick)
        payable
    {
        OracledIssuableBet(target).openBetWithUint(msg.sender, pick);
    }

    function betStraightUp(uint pick)
        payable
        from_pool(straight_up_bet)
    {
        takeBetWithUint(straight_up_bet, pick);
    }

    function betOdd(bool pick)
        payable
        from_pool(odd_bet)
    {
        takeBetWithBool(odd_bet, pick);
    }

    function betBlack(bool pick)
        payable
        from_pool(black_bet)
    {
        takeBetWithBool(black_bet, pick);
    }

    function betLow(bool pick)
        payable
        from_pool(low_bet)
    {
        takeBetWithBool(odd_bet, pick);
    }

    function handleOutcome(address bettor, uint outcome)
        only_oracle
    {
        resolveLow(bettor, outcome);
        resolveStraightUp(bettor, outcome);
    }

    function resolveLow(address bettor, uint outcome) {
        resolveBet(low_bet, bettor, outcome);
    }

    function resolveStraightUp(address bettor, uint outcome) {
        resolveBet(straight_up_bet, bettor, outcome);
    }

    function issueCollateral(address target)
        payable
        only_by(owner)
    {
        super.issueCollateral(target);
    }

    function setOdds (address target, uint new_odds)
        only_by(owner)
    {
        super.setOdds(target, new_odds);
    }

    function resolveBet(address target, address bettor, uint outcome) {

        OracledIssuableBet _bet = OracledIssuableBet(target);
        uint wager = _bet.getWager(bettor);

        if (wager > 0) {
            if(_bet.resolveOutcome(bettor, outcome, resolver)) {
                handleWinner(target, bettor, wager);
            } else {
                handleLoser(target, bettor, wager);
            }
        }
    }

    function handleWinner (address target, address bettor, uint wager) only_children {
        amount_wagered[target] -= wager;
        uint payout = wager * odds[target]/1000;
        available_values[target] -= payout;
        pays[bettor] += payout;
    }

    function handleLoser (address target, address bettor, uint wager) private {
        amount_wagered[target] -= wager;
        pays[owner] += wager;
    }
}

"