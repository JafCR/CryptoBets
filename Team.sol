pragma solidity ^0.4.24;

import "./Match.sol";

contract Restricted {
    address public owner;

    event OwnerChanged(address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public onlyOwner{
        owner = _owner;
        emit OwnerChanged(owner);
    }
}

contract Team is Restricted {
    address public currentMatch;

    constructor() public {
        owner = msg.sender;
    }

    function () public payable {
        require(currentMatch != 0);
        Match(currentMatch).setBet.value(msg.value)(address(this), msg.sender);
    }

    function setMatch(address _match) public onlyOwner{
        currentMatch = _match;
    }
    
    function endMatch() public onlyOwner {
        currentMatch = address(0);
    }
}
