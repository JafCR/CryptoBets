pragma solidity ^ 0.4.24;

import "./SafeMath.sol";
import "./Team.sol";

contract Match is Restricted {

    using SafeMath for uint256;

    // No matchStatus = 0
    // Team A = 1
    // Team B = 2
    mapping(address => mapping(uint8 => uint256)) public balances; //per player
    mapping(uint8 => address[]) public teamBets;
    mapping(address => uint8) teamLocalId;
    // commision :)
    uint256 commision;

    address[3] public teamAddress;
    uint256[3] public teamPools;
    uint8 public matchStatus;
   
    uint256 public MAX_DECIMALS;
    
    event BetSet(address indexed _player, address _team, address _match);

    // Initial state of the contract
    constructor(address _team1, address _team2, uint256 _commision) public {
        assert(_commision < 10000 && _commision >= 10);
        // Validate client input commision * 100 | range(0.1% - 100%) | range(10 - 10000)
        
        owner = msg.sender;
        teamLocalId[_team1] = 1;
        teamLocalId[_team2] = 2;
        teamAddress[1] = _team1;
        teamAddress[2] = _team2;
        matchStatus = 0;
        commision = _commision;
        MAX_DECIMALS = 10000000;
    
    }

    function getMatch() public view returns(address _team1, address _team2, uint _poolTeam1, uint _poolTeam2, uint _winner, uint _commision) {
        _team1 = teamAddress[1];
        _team2 = teamAddress[2];
        _poolTeam1 = teamPools[1];
        _poolTeam2 = teamPools[2];
        _winner = matchStatus;
        _commision = commision;
    }
    
    // Set the team id for betting
    // Team A = 1
    // Team B = 2
    function setBet(address _team, address _sender) public payable {
        //require(teamLocalId[_team] != 0);

        uint8 _id = teamLocalId[_team];

        if (balances[_sender][_id] == 0) {
            teamBets[_id].push(_sender);
        }
        
        balances[_sender][_id] = balances[_sender][_id].add(msg.value);
        teamPools[_id] = teamPools[_id].add(msg.value);
        
        emit BetSet(_sender, _team, address(this));
    }

    function getWinner() public view returns(address) {
        return teamAddress[matchStatus];
    }
    
    function getTeamAddress(uint8 _id) public view returns(address) {
        return teamAddress[_id];
    }
   
    // Type 3: Draw
    // Type 4: Cancel
    function finishMatch(uint8 _type) public onlyOwner {
        require(_type == 3 || _type == 4);
        
        for (uint8 i = 1; i < 3; i++){
            for(uint j = 0; j < teamBets[i].length; j++) {
                address person = teamBets[i][j];
                person.transfer(balances[person][i]);
            }
        }
        
        if(_type == 3){
            matchStatus = 3;// draw
        }
        else{
            matchStatus = 4;// cancel
        }
    }
    
    // Winner 1: TeamA
    // Winner 2: TeamB
    function setWinner(uint8 _winner) public onlyOwner {
        require(_winner == 1 || _winner == 2);
        assert(teamPools[1] > 0 && teamPools[2] > 0);
        
        matchStatus = _winner;
        
        uint256 recalcLoserPool = teamPools[teamAddress.length.sub(_winner)].mul(uint(10000).sub(commision)).div(10000);
        
        // CAUTION: Funds will be frozen if the winner team's pool time 10000 causes overflow (when is bigger than 256uint)

        // MAX DIFERENCE BETWEEN BETS 10000000 - 1
        for (uint i = 0; i < teamBets[_winner].length; i++) {
            address luckyPerson = teamBets[_winner][i];
            uint percentage = balances[luckyPerson][_winner].mul(MAX_DECIMALS).div(teamPools[_winner]);
            luckyPerson.transfer(balances[luckyPerson][_winner].add(percentage.mul(recalcLoserPool).div(MAX_DECIMALS)));
        }

        owner.transfer(address(this).balance);
    }

    function () public payable {
        //require(false);
    }
}