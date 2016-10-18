# Liquidity book is a mechanism for posting collateral for an array
# of different contracts.

module.exports = "

contract LiquidityBook {
    string public standard = 'kerning-liquidity-book-0.0.1';

    address public owner;
    mapping(address => uint) public available_values;
    mapping(address => uint) public amount_wagered;
    mapping(address => uint) public odds;
    mapping(address => uint) public pays;

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
    function resolveStraightUpBet(uint _outcome, uint _pick) returns (bool);
    function resolveStreetBet(uint _outcome, uint _pick) returns (bool);
    function resolveSixLineBet(uint _outcome, uint _pick) returns (bool);
    function resolveDozenBet(uint _outcome, uint _pick) returns (bool);
    function resolveColumnBet(uint _outcome, uint _pick) returns (bool);
    function resolveBlackBet(uint _outcome, bool _pick) returns (bool);
    function resolveOddBet(uint _outcome, bool _pick) returns (bool);
    function resolveLowBet(uint _outcome, bool _pick) returns (bool);
}

contract OpenableBet {   

    address public controller;
    address public owner;
    mapping(address => uint) public open_wagers;

    function getWager(address bettor) returns (uint) {
        return open_wagers[bettor];
    }

    function setWager(address bettor, uint balance){
        open_wagers[bettor] = balance;
    }
}

contract OpenableUintBet is OpenableBet {
    mapping(address => uint) public open_picks;

    function openBetWithUint(address bettor, uint value, uint pick)
    {
        open_picks[bettor] = pick;
        open_wagers[bettor] += value;
    }

    function openBetWithBool(address bettor, uint value, bool pick) {
        throw;
    }
}

contract StraightUpBet is OpenableUintBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveStraightUpBet(outcome, open_picks[bettor]);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract StreetBet is OpenableUintBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveStreetBet(outcome, open_picks[bettor]);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract SixLineBet is OpenableUintBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveSixLineBet(outcome, open_picks[bettor]);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract ColumnBet is OpenableUintBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveColumnBet(outcome, open_picks[bettor]);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract DozenBet is OpenableUintBet {

    function StraightUpBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveDozenBet(outcome, open_picks[bettor]);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract OpenableBoolBet is OpenableBet {
    mapping(address => bool) public open_picks;

    function openBetWithBool(address bettor, uint value, bool pick)
    {
        open_picks[bettor] = pick;
        open_wagers[bettor] += value;
    }

    function openBetWithUint(address bettor, uint value, uint pick) {
        throw;
    }

}

contract BlackBet is OpenableBoolBet {

    function BlackBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveBlackBet(outcome, true);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract OddBet is OpenableBoolBet {
    mapping(address => bool) public open_picks;

    function OddBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveOddBet(outcome, true);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract LowBet is OpenableBoolBet {
    mapping(address => bool) public open_picks;

    function LowBet() {
        owner = msg.sender;
    }

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool) {
        bool result = RouletteResolver(resolver).resolveLowBet(outcome, true);
        open_wagers[bettor] = 0;
        return result;
    }
}

contract OracledIssuableBet {

    function openBetWithBool(address bettor, uint value, bool pick);
    function openBetWithUint(address bettor, uint value, uint pick);

    function resolveOutcome(address bettor, uint outcome, address resolver) returns (bool);
    function getWager(address bettor) returns (uint);

}

contract RouletteTable is LiquidityBook {

    address public resolver;
    address public oracle;
    address public owner;

    address public straight_up_bet;
    address public black_bet;
    address public odd_bet;
    address public low_bet;
    address public street_bet;
    address public six_line_bet;
    address public column_bet;
    address public dozen_bet;

    mapping(address => bool) active_spins;

    event LogMessage(address from, string s);
    event LogValue(address from, uint v);
    event LogKindValue(address from, string kind, uint v);

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

    function RouletteTable(address _resolver, address _s_u_bet, address _b_bet, address _o_bet, address _l_bet, address _str_bet, address _sl_bet, address _col_bet, address _dz_bet) {
        resolver = _resolver;
        straight_up_bet = _s_u_bet;
        black_bet = _b_bet;
        odd_bet = _o_bet;
        low_bet = _l_bet;
        street_bet = _str_bet;
        six_line_bet = _sl_bet;
        column_bet = _col_bet;
        dozen_bet = _dz_bet;
        owner = msg.sender;
        oracle = msg.sender;
        odds[_s_u_bet] = 35000;
        odds[_str_bet] = 11000;
        odds[_sl_bet] = 5000;
        odds[_col_bet] = 2000;
        odds[_dz_bet] = 2000;
    }

    function takeBetWithBool (address target, bool pick)
        payable
    {
        OracledIssuableBet(target).openBetWithBool(msg.sender, msg.value, pick);
    }

    function takeBetWithUint (address target, uint pick)
        payable
    {
        OracledIssuableBet(target).openBetWithUint(msg.sender, msg.value, pick);
    }

    function betStraightUp(uint pick)
        payable
        from_pool(straight_up_bet)
    {
        takeBetWithUint(straight_up_bet, pick);
    }

    function betStreet(uint pick)
        payable
        from_pool(street_bet)
    {
        takeBetWithUint(street_bet, pick);
    }

    function betSixLine(uint pick)
        payable
        from_pool(six_line_bet)
    {
        takeBetWithUint(six_line_bet, pick);
    }

    function betColumn(uint pick)
        payable
        from_pool(column_bet)
    {
        takeBetWithUint(column_bet, pick);
    }

    function betDozen(uint pick)
        payable
        from_pool(dozen_bet)
    {
        takeBetWithUint(dozen_bet, pick);
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
        takeBetWithBool(low_bet, pick);
    }

    function handleOutcome(address bettor, uint outcome)
        only_oracle
    {
        resolveLow(bettor, outcome);
        resolveOdd(bettor, outcome);
        resolveBlack(bettor, outcome);
        resolveStraightUp(bettor, outcome);
        resolveStreet(bettor, outcome);
        resolveSixLine(bettor, outcome);
        resolveColumn(bettor, outcome);
        resolveDozen(bettor, outcome);
        active_spins[bettor] = false;
    }

    function resolveLow(address bettor, uint outcome) {
        resolveBet(low_bet, bettor, outcome);
    }

    function resolveOdd(address bettor, uint outcome) {
        resolveBet(odd_bet, bettor, outcome);
    }

    function resolveBlack(address bettor, uint outcome) {
        resolveBet(black_bet, bettor, outcome);
    }

    function resolveStraightUp(address bettor, uint outcome) {
        resolveBet(straight_up_bet, bettor, outcome);
    }

    function resolveStreet(address bettor, uint outcome) {
        resolveBet(street_bet, bettor, outcome);
    }

    function resolveSixLine(address bettor, uint outcome) {
        resolveBet(six_line_bet, bettor, outcome);
    }

    function resolveColumn(address bettor, uint outcome) {
        resolveBet(six_line_bet, bettor, outcome);
    }

    function resolveDozen(address bettor, uint outcome) {
        resolveBet(dozen_bet, bettor, outcome);
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

    function handleWinner (address target, address bettor, uint wager) private {
        if (amount_wagered[target] - wager > amount_wagered[target]) {
            amount_wagered[target] = 0;
        } else {
            amount_wagered[target] -= wager;
        }
        uint payout = wager * odds[target]/1000;
        available_values[target] -= payout;
        pays[bettor] += payout;
        LogKindValue(msg.sender, 'winner', odds[target]/1000);
    }

    function handleLoser (address target, address bettor, uint wager) private {
        if (amount_wagered[target] - wager > amount_wagered[target]) {
            amount_wagered[target] = 0;
        } else {
            amount_wagered[target] -= wager;
        }
        pays[owner] += wager;
        LogKindValue(msg.sender, 'loser', 0);
    }

    function spinWheel() {
        active_spins[msg.sender] = true;
        LogMessage(msg.sender, 'spun');
    }
}

"