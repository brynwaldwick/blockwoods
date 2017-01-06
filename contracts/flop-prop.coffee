# FlopPropResolver is CardDeckResolver
module.exports = "
pragma solidity ^0.4.0;

contract CardDeck {

    mapping(string => uint) suit_slugs;
    mapping(string => uint) rank_slugs;

    struct Card {
        string slug;
        uint suit;
        uint rank;
        bool black;
        bool face;
    }

    mapping(uint => Card) cards;

    function CardDeck() {
        suit_slugs['s'] = 0;
        suit_slugs['h'] = 1;
        suit_slugs['d'] = 2;
        suit_slugs['c'] = 3;

        cards[0] = Card('As', 0, 12, true, false);
        cards[1] = Card('Ah', 1, 12, false, false);
        cards[2] = Card('Ad', 2, 12, false, false);
        cards[3] = Card('Ac', 3, 12, true, false);
        cards[4] = Card('Ks', 0, 11, true, true);
        cards[5] = Card('Kh', 1, 11, false, true);
        cards[6] = Card('Kd', 2, 11, false, true);
        cards[7] = Card('Kc', 3, 11, true, true);
        cards[8] = Card('Qs', 0, 10, true, true);
        cards[9] = Card('Qh', 1, 10, false, true);
        cards[10] = Card('Qd', 2, 10, false, true);
        cards[11] = Card('Qc', 3, 10, true, true);
        cards[12] = Card('Js', 0, 10, true, true);
        cards[13] = Card('Jh', 1, 10, false, true);
        cards[14] = Card('Jd', 2, 10, false, true);
        cards[15] = Card('Jc', 3, 10, true, true);
        cards[28] = Card('7s', 0, 7, true, false);
        cards[29] = Card('7h', 1, 7, false, false);
        cards[30] = Card('7d', 2, 7, false, false);
        cards[31] = Card('7c', 3, 7, true, false);
    }

    function getSuit(uint i) returns (uint) {
        return cards[i].suit;
    }

    function getRank(uint i) returns (uint) {
        return cards[i].rank;
    }

    function getFace(uint i) returns (bool) {
        return cards[i].face;
    }
}

contract FlopPropResolver {
    uint middle_bonus = 2;
    uint seven_bonus = 4;
    uint ace_bonus = 2;
    address public deck_layout;

    struct Card {
        string slug;
        uint suit;
        uint rank;
        bool black;
        bool face;
    }

    function FlopPropResolver(address d) {
        deck_layout = d;
    }

    function resolveFlop(uint suit, uint c_1, uint c_2, uint c_3) returns (uint) {
        uint result = 0;

        uint _s_1 = getSuit(c_1);
        uint _s_2 = getSuit(c_2);
        uint _s_3 = getSuit(c_3);

        if (_s_1 == suit) {
            result += getPoints(c_1);
        }
        if (_s_2 == suit) {
            result += (getPoints(c_2) * middle_bonus);
        }
        if (_s_3 == suit) {
            result += getPoints(c_3);
        }

        return result;
    }

    function getSuit(uint card_index) returns (uint) {
        uint suit = CardDeck(deck_layout).getSuit(card_index);
        return suit;
    }

    function getPoints(uint card_index) returns (uint) {
        uint rank = CardDeck(deck_layout).getRank(card_index);
        uint mult;
        if (rank == 7) {
            mult = seven_bonus;
        } else if (rank == 12) {
            mult = ace_bonus;
        } else {
            mult = 1;
        }
        return mult;
    }
}

contract FlopProp {
    address oracle;
    address resolver;

    uint public rate = 50000000000000000;

    mapping(address => uint) suits;
    mapping(uint => bool) taken_suits;
    mapping(address => uint) points;

    event LogMessage(address from, string s);
    event LogValue(address from, uint v);

    function FlopProp(address _r) {
        resolver = _r;
        oracle = msg.sender;
    }

    function claimProp(uint c_1, uint c_2, uint c_3) {
        uint suit = suits[msg.sender];
        uint result = FlopPropResolver(resolver).resolveFlop(suit, c_1, c_2, c_3);
        if (result > 0) {
            points[msg.sender] += result;
            LogValue(msg.sender, points[msg.sender]);
        }
    }

    function pickSuit(uint s) {
        if (taken_suits[s]) throw;
        suits[msg.sender] = s;
        taken_suits[s] = true;
    }
}
"