pragma solidity ^ 0.4 .24;

import "./Match.sol";

contract GameManager is Restricted {
    
    event MatchCreated(address indexed _contract, uint indexed _id);
    event TeamCreated(address indexed _address, string _name);
    event MatchFinished(address indexed _match);
    event BalanceWithDrawn(uint balance);
    
    address[] teamsAddresses;
    mapping(address => string) public teamsNames;
    
    function getTeamAddresses() public view returns(address[]) {
        return teamsAddresses;
    }
    
    // Use SafeMath
    using SafeMath for uint256;

    // Active Matches address mapping index
    mapping(address => uint256) activeMatchsIndex;

    // Arrays
    address[] internal allMatchs;
    address[] internal activeMatchs;

    // Initial state of Contract
    constructor() public {
        owner = msg.sender;
        activeMatchs.push(0);
    }

    function getAllMatches() public view returns(address[]) {
        return allMatchs;
    }

    function getActiveMatches() public view returns(address[]) {
        return activeMatchs;
    }

    function createTeam(string _nameTeam) public onlyOwner {
        Team newTeam = new Team();
        teamsAddresses.push(address(newTeam));
        teamsNames[address(newTeam)] = _nameTeam;
        
        emit TeamCreated(newTeam, _nameTeam);
    }
    
    function createMatch(address _teamA, address _teamB, uint256 _fee) onlyOwner public {
        Match newMatch = new Match(_teamA, _teamB, _fee);
        activeMatchs.push(newMatch);
        activeMatchsIndex[newMatch] = activeMatchs.length.sub(1);
        allMatchs.push(newMatch);
        
        // Set Team's Owner
        (Team(_teamA)).setMatch(address(newMatch));
        (Team(_teamB)).setMatch(address(newMatch));
        
        emit MatchCreated(newMatch, allMatchs.length);
    }
    
    function finishMatch(address _match, uint8 _id) onlyOwner public {
        // Modify state of Child Match
        // Type 3: Draw
        // Type 4: Cancel
        address teamA = (Match(_match)).getTeamAddress(1);
        address teamB = (Match(_match)).getTeamAddress(2);
        
        (Match(_match)).finishMatch(_id);
        
        Team(teamA).endMatch();
        Team(teamB).endMatch();
        emit MatchFinished(this);
    }

    // No Winner = 0
    // Team A = 1
    // Team B = 2
    function burnMatch(address _match, uint8 _id) onlyOwner public {
        require(activeMatchsIndex[_match] != 0);

        // Reorg all Matchs array
        uint256 matchIndex = activeMatchsIndex[_match];
        uint256 lastMatchIndex = activeMatchs.length.sub(1);
        address lastMatch = activeMatchs[lastMatchIndex];

        activeMatchs[matchIndex] = lastMatch;
        activeMatchs[lastMatchIndex] = 0;

        activeMatchs.length--;
        activeMatchsIndex[_match] = 0;
        activeMatchsIndex[lastMatch] = matchIndex;

        // Modify state of Child Match
        (Match(_match)).setWinner(_id);
        
        // Get Match Teams Addresses
        address teamA = (Match(_match)).getTeamAddress(1);
        address teamB = (Match(_match)).getTeamAddress(2);
        
        Team(teamA).endMatch();
        Team(teamB).endMatch();
        
        emit MatchFinished(this);
    }
    
    function getMatchAddresses(address _match, uint8 _id) public view returns(address){
        return (Match(_match).getTeamAddress(_id));
    }
    
    function withdrawBalance() public onlyOwner {
        owner.transfer(address(this).balance);
        emit BalanceWithDrawn(address(this).balance);
    }

    function () internal payable {
        // TODO: VALIDATE ETH PAYMENTS
    }
}