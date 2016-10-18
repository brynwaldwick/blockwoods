# Potentially make jackpot more likely by putting some sort of flip logic to weight symbols
# i.e. 22 has a 1/100 chance of occuring, 11 1/20, 7 1/7.

# Resolver computes payout as a multiple of the amount wagered

# pairs + trips + straights
# (1 * 16 * 3 * 9) + (14 * 16) + 7 * (2 + 3 + 4 + 5 + 6 + 7 + 8 + 9) = 964  ( / 1000 spins)

module.exports = "
pragma solidity ^0.4.0;

contract SlotMachineLayout {

    string public standard='kerning-slot-machine-layout-0.0.1';

    struct Number {
        uint n;
        uint weight;
    }

    mapping(uint => Number) numbers;

    function SlotMachineLayout () {
        numbers[0] = Number(0, 1);
        numbers[1] = Number(1, 1);
        numbers[2] = Number(2, 1);
        numbers[3] = Number(3, 1);
        numbers[4] = Number(4, 1);
        numbers[5] = Number(5, 1);
        numbers[6] = Number(6, 2);
        numbers[7] = Number(7, 5);
        numbers[8] = Number(8, 1);
        numbers[9] = Number(9, 2);
    }

    function getWeight (uint n) returns (uint) {
        return numbers[n].weight;
    }
}


contract SlotMachineResolver {

    string public standard='kerning-slot-machine-resolver-0.0.1';

    address public machine_layout;

    function SlotMachineResolver(address _layout) {
        machine_layout = _layout;
    }

    function resolvePull(uint s_1, uint s_2, uint s_3) returns (uint) {
        if (s_1 == s_2) {
            if (s_2 == s_3) {
                return trips(s_1);
            } else {
                return pair(s_2);
            }
        } else if (s_2 == s_3) {
            return pair(s_2);
        } else if (s_1 == s_3) {
            return pair(s_1);
        } else {
            if ((s_2 == s_1 + 1) && (s_3 == s_2 + 1)) {
                return straight(s_3);
            } else {
                return 0;
            }
        }
    }

    function pair (uint n) returns (uint) {
        uint weight = SlotMachineLayout(machine_layout).getWeight(n);
        return weight;
    }

    function trips (uint n) returns (uint) {
        uint weight = SlotMachineLayout(machine_layout).getWeight(n);
        return weight * 14;
    }

    function straight (uint hi) returns (uint) {
        return hi * 7;
    }

    function numberWeight(uint n) returns (uint) {
        SlotMachineLayout(machine_layout).getWeight(n);
    }
}

contract OracleSlotMachine{

    address public owner;
    address public resolver;
    address public oracle;

    uint public max_bet;

    mapping(address => uint) public wagered;
    mapping(address => bool) public active;
    mapping(address => uint) public pays;

    event LogMessage(address from, string s);
    event LogValue(address from, uint v);

    modifier not_active() {
        if (active[msg.sender]) throw;
        _;
    }

    modifier only(address _a) {
        if (msg.sender != _a) throw;
        _;
    }

    modifier bet_range() {
        if (msg.value > max_bet) throw;
        _;
    }

    function OracleSlotMachine (address r) {
        resolver = r;
        owner = msg.sender;
        max_bet = 100000000000000000;
    }

    function pullLever()
        payable
        bet_range
        not_active
    {
        wagered[msg.sender] += msg.value;
        active[msg.sender] = true;
        LogMessage(msg.sender, 'pulled');
    }

    function betProfits(uint amount)
        bet_range
        not_active
    {
        if (amount > pays[msg.sender]) throw;
        pays[msg.sender] -= amount;
        wagered[msg.sender] += amount;
        active[msg.sender] = true;
        LogMessage(msg.sender, 'pulled');
    }

    function handleOutcome(address bettor, uint s_1, uint s_2, uint s_3)
        only(oracle)
    {
        uint result = SlotMachineResolver(resolver).resolvePull(s_1, s_2, s_3);

        LogValue(msg.sender, result);

        if (result > 0) {
            pays[bettor] += result * wagered[bettor];
            wagered[bettor] = 0;
            active[bettor] = false;
        } else {
            pays[owner] += wagered[bettor];
            wagered[bettor] = 0;
            active[bettor] = false;
        }
    }

    function disburse() {
        uint amount = pays[msg.sender];
        if (amount > 0) {
            if (!msg.sender.send(amount)) throw;
            pays[msg.sender] = 0;
        } else throw;
    }

    function injectCapital() only(owner) payable {}

    function getBalance() public returns (uint) {
        return this.balance;
    }

    function setOracle(address _o) only(owner) {
        oracle = _o;
    }

    function setMaxBet(uint n) only(owner) {
        max_bet = n;
    }
}

"
