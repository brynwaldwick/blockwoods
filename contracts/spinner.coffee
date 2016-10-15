
module.exports = "
pragma solidity ^0.4.0;

contract Spinner {
    address public wheel;

    event LogMessage(address from, string spun);

    function Spinner(address _wheel) {
        wheel = _wheel;
    }

    function spinWheel() {
        LogMessage(msg.sender, 'spun');
    }
}"