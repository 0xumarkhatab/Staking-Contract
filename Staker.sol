// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Staker{
    mapping(address=>uint) public balances;
    mapping(address=>uint) public depositTimestamps;


    uint public rewardRatePerSecond =0.01 ether;
    uint public withdrawlDeadline=0;
    uint public claimedDeadline=0;
    bool public stakingStarted=false;
    bool public stakeCompleted=false;


    // owner
    address payable private owner;



constructor()payable{
    owner=payable(msg.sender);

}

modifier isStakingStarted{
require(stakingStarted,"staking is not started");
_;

}

modifier onlyOwner{
    require(msg.sender==owner,"only owner is allowed to call this function");
    _;

}

function startStaking()public onlyOwner{
withdrawlDeadline=block.timestamp+120; // 2 minutes for depositing
claimedDeadline=block.timestamp+240; // 2 minutes for withdraw stakes
stakingStarted=true;


}
 function withdrawlTimeLeft() public view isStakingStarted returns (uint256 withdrawlTimeLeft) {


    if( block.timestamp >= withdrawlDeadline) {
      return (0);
    } else {
      return (withdrawlDeadline - block.timestamp);
    }

  }

  function claimPeriodLeft() public view isStakingStarted returns (uint256 claimPeriodLeft) {
    if( block.timestamp >= claimedDeadline) {
      return (0);
    } else {
      return (claimedDeadline - block.timestamp);
    }
  
  }

modifier stakeIsNotCompleted{
    // logic to be implemented
    require(stakeCompleted,"Stake is completed");
    _;
  
  }
  


modifier withdrawlDeadlineCompletionStatus(bool statusRequirement){
    uint withdrawlTimeRemaining=withdrawlTimeLeft();

    // if we want to see that deadline is reached 
    if(statusRequirement ){
     require(withdrawlTimeRemaining == 0, "withdrawl period is not reached");
    }
    else
    require(withdrawlTimeRemaining >0, "withdrawl period is reached");
_;
}


modifier claimedDeadlineCompletionStatus(bool statusRequirement){
    uint claimedTimeRemaining=claimPeriodLeft(); 

    // if we want to see that deadline is reached 
    if(statusRequirement ){
     require(claimedTimeRemaining == 0, "claimed period is not reached");
    }
    else
    require(claimedTimeRemaining >0, "claimed period is reached");
_;
}

function Stake()public payable isStakingStarted withdrawlDeadlineCompletionStatus(false) claimedDeadlineCompletionStatus(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    // emit Stake(msg.sender, msg.value);


}


 function withdraw() public payable withdrawlDeadlineCompletionStatus(true) claimedDeadlineCompletionStatus(false) stakeIsNotCompleted{
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    uint256 indBalanceRewards = individualBalance + ((block.timestamp-depositTimestamps[msg.sender])*rewardRatePerSecond );
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawl failed :( ");
  }


function completeStake()public onlyOwner{
  stakeCompleted=true;
}

function withdrawContractFunds()public payable onlyOwner isStakingStarted claimedDeadlineCompletionStatus(true){
  require(owner.send(address(this).balance),"Unable to transfer funds");

} 




}
