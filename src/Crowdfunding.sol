
pragma solidity ^0.8.30;
// SPDX-License-Identifier: MIT
contract Crowdfunding {
    string public name;
    string public description;
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    bool public paused;
   

    enum CampaignState {Active, Successful, Failed}
    CampaignState public state;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
        
    }

    struct Backer {
        uint256 totalContribution;
        mapping (uint256 => bool) fundedTiers;
    }

    Tier [] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner() {
        require(msg.sender == owner, "kamu bukan owner");
        _;
    }

    modifier campaignOpen (){
        require(state == CampaignState.Active, "campaign belum terbuka");
        _;
    }

    modifier notPaused(){
        require(!paused, "campaign sedang di pause");
        _;
    }

    constructor (address _owner, string memory _name, string memory _description,  uint256 _goal, uint256 _duration) {
        name = _name;
        description = _description;
        owner = _owner;
        goal = _goal;
        deadline = block.timestamp + (_duration * 1 days);
        state = CampaignState.Active;
    }

    function checkCampaignState() internal {
        if (state == CampaignState.Active){
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;            
            } else {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
            }
        }
    }
    
    function fund(uint _tierIndex) public payable campaignOpen notPaused {
        require(_tierIndex < tiers.length, "Tier tidak ada");
        require(msg.value == tiers[_tierIndex].amount, "uang tidak sesuai");

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierIndex] = true;

        checkCampaignState();
    }

    function addTier(string memory _name, uint256 _amount) public onlyOwner{
        require(_amount > 0, "harus diisi lebih dari 0");
         tiers.push(Tier(_name,_amount,0));
    }

    function removeTier(uint256 _index) public onlyOwner{
        require(_index < tiers.length, "tier tidak ada.");
        tiers [_index] = tiers[tiers.length -1];
        tiers.pop();
    }

    function withdraw() public onlyOwner {
        checkCampaignState();
        require(state == CampaignState.Successful, "campaign belum berhasil");

        uint256 balance = address(this).balance;
        require(balance > 0, "tidak ada dana untuk diambil.");

        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    
    function refund() public {
        checkCampaignState();
        require(state == CampaignState.Failed, "Refund belum bisa dilakukan.");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "tidak ada yang di refund");

        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) {
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function getTiers() public view returns (Tier[] memory){
        return tiers;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += _daysToAdd * 1 days;
    }
}