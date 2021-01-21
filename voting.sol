pragma solidity 0.6.11;

contract Voting{
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    uint public countProposal = 0;
    uint public winningProposalId=0;
    bool public proposalStatus;
    bool public votingStatus;
    
    address public administrator;
    
    mapping(address => Voter) public voters;
    
    mapping(uint => Proposal) public proposals;
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    WorkflowStatus public state;
    
    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Seul l'administrateur peut effectuer cette action");
        _;
    }
    
    modifier inState(WorkflowStatus _state) {
        require(
            state == _state, "Ce statut n'existe pas"
        );
        _;
    }
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);
    
    constructor() public{
        administrator = msg.sender;
    }
    
    function startRegistration(bool _status) public onlyAdministrator {
        WorkflowStatus prevState = state;
        if(_status == true){
            state=WorkflowStatus.ProposalsRegistrationStarted;
            emit ProposalsRegistrationStarted();
            emit WorkflowStatusChange(prevState, state);
        }else{
            state = WorkflowStatus.ProposalsRegistrationEnded;
            emit ProposalsRegistrationEnded();
            emit WorkflowStatusChange(prevState, state);
        }
        proposalStatus = _status;
    }
    
    function startVoting(bool _status) public onlyAdministrator {
        WorkflowStatus prevState = state;
        if(_status == true){
            state = WorkflowStatus.VotingSessionStarted;
            emit VotingSessionStarted();
            emit WorkflowStatusChange(prevState, state);
        }else{
            state = WorkflowStatus.VotingSessionEnded;
            emit VotingSessionEnded();
            emit WorkflowStatusChange(prevState, state);
        }
        votingStatus = _status;
    }
    
    function whiteList (address _voter) public onlyAdministrator inState(WorkflowStatus.RegisteringVoters) {
        require(!voters[_voter].hasVoted,
        'Cette adresse à déjà voté');
        voters[_voter].isRegistered = true;
        emit VoterRegistered(_voter);
    }
    
    function submitProposal(string memory _description) public{
        require(voters[msg.sender].isRegistered, 
        "Seul les adresses autorisées peuvent faire une proposition.");
        require(
            proposalStatus == true,
        "Le délai pour ajouter de nouvelles proposition est dépassé"
        );
        countProposal+=1;
        proposals[countProposal].description= _description;
        proposals[countProposal].voteCount = 0;
        emit ProposalRegistered(countProposal);
    }
    
    function vote(uint _proposal) public {
        require(votingStatus == true,"Le délai pour voter est dépassé");
        Voter storage v = voters[msg.sender];
        require(!v.hasVoted, "Cette adresse a déjà voté");
        v.votedProposalId = _proposal;
        proposals[_proposal].voteCount+=1;
        v.hasVoted = true;
        emit Voted(msg.sender, _proposal);
    }
    
    function countingVote() public inState(WorkflowStatus.VotesTallied) {
        require(msg.sender==administrator,"Seul l'administrateur peut lancer le compte");
        uint winningProposal = 0;
        for(uint i=0; i < countProposal; i++){
            if(proposals[i].voteCount > winningProposal) {
                winningProposal = proposals[i].voteCount;
                winningProposalId = i;
            }
        emit VotesTallied();
        }
    }
}