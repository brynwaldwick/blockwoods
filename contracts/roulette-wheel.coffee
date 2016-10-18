
# Capturing the outcomes of a roulette game's bets

# 0 is even
# 1 is odd

# 0 is red
# 1 is black

# 0 is high
# 1 is low

# Roulette Wheel maps random number from 0 to 37 to betting outcomes
# Roulette Wheel resolver interprets the results of different bets

# They are decoupled so you could e.g. deploy a new resolver and change
# the rules of the game without having to remake another wheel.

# TODO: maybe move bet validation to resolver

module.exports = "
pragma solidity ^0.4.0;

contract RouletteWheel {
    string public standard='kerning-roulette-wheel-0.0.1';

    struct Number {
        uint n;
        bool odd;
        bool black;
        bool low;
    }

    mapping(uint => Number) numbers;

    function RouletteWheel () {
        numbers[0] = Number(0, false, false, false);
        numbers[1] = Number(1, true, false, true);
        numbers[2] = Number(2, false, true, true);
        numbers[3] = Number(3, true, false, true);
        numbers[4] = Number(4, false, true, true);
        numbers[5] = Number(5, true, false, true);
        numbers[6] = Number(6, false, true, true);
        numbers[7] = Number(7, true, false, true);
        numbers[8] = Number(8, false, true, true);
        numbers[9] = Number(9, true, false, true);
        numbers[10] = Number(10, false, true, true);
        numbers[11] = Number(11, true, true, true);
        numbers[12] = Number(12, false, false, true);
        numbers[13] = Number(13, true, true, true);
        numbers[14] = Number(14, false, false, true);
        numbers[15] = Number(15, true, true, true);
        numbers[16] = Number(16, false, false, true);
        numbers[17] = Number(17, true, true, true);
        numbers[18] = Number(18, false, false, true);
        numbers[19] = Number(19, true, true, false);
        numbers[20] = Number(20, false, true, false);
        numbers[21] = Number(21, true, false, false);
        numbers[22] = Number(22, false, true, false);
        numbers[23] = Number(23, true, false, false);
        numbers[24] = Number(24, false, true, false);
        numbers[25] = Number(25, true, false, false);
        numbers[26] = Number(26, false, true, false);
        numbers[27] = Number(27, true, false, false);
        numbers[28] = Number(28, false, true, false);
        numbers[29] = Number(29, true, true, false);
        numbers[30] = Number(30, false, false, false);
        numbers[31] = Number(31, true, true, false);
        numbers[32] = Number(32, false, false, false);
        numbers[33] = Number(33, true, true, false);
        numbers[34] = Number(34, false, false, false);
        numbers[35] = Number(35, true, true, false);
        numbers[36] = Number(36, false, false, false);
        numbers[37] = Number(00, false, false, false);
    }

    function getBlack(uint n) public returns (bool) {
        return numbers[n].black;
    }

    function getOdd(uint n) public returns (bool) {
        return numbers[n].odd;
    }

    function getLow(uint n) public returns (bool) {
        return numbers[n].low;
    }
}

contract RouletteWheelResolver {
    address public wheel;

    function RouletteWheelResolver(address _wheel) {
        wheel = _wheel;
    }

    function resolveStraightUpBet(uint _outcome, uint _pick) returns (bool) {
        return (_outcome == _pick);
    }

    function resolveStreetBet(uint _outcome, uint _pick) returns (bool) {
        return ((_outcome - (_outcome - 1)%3) == _pick);
    }

    function resolveSixLineBet(uint _outcome, uint _pick) returns (bool) {
        return ((_outcome - (_outcome - 1)%6) == _pick);
    }

    function resolveColumnBet(uint _outcome, uint _pick) returns (bool) {
        return (_outcome%3 == _pick);
    }

    function resolveDozenBet(uint _outcome, uint _pick) returns (bool) {
        return ((_outcome - (_outcome - 1)%12) == _pick);
    }

    function resolveBlackBet(uint _outcome, bool _pick) returns (bool) {
        bool _r = RouletteWheel(wheel).getBlack(_outcome);
        return (_r == _pick);
    }

    function resolveOddBet(uint _outcome, bool _pick) returns (bool) {
        bool _r = RouletteWheel(wheel).getOdd(_outcome);
        return (_r == _pick);
    }

    function resolveLowBet(uint _outcome, bool _pick) returns (bool) {
        bool _r = RouletteWheel(wheel).getLow(_outcome);
        return (_r == _pick);
    }
}

"
