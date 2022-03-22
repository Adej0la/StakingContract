// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol"; //import the console logging function


contract SubaruERC20 is ERC20, Ownable {
 using SafeMath for uint256;

    address private msgSender = _msgSender();
    uint _totalSupply = 1000;
    uint256 public tokensPerEth = 10;
    event Bought(address _buyer, uint _amountOfETH, uint _amountOfToken);


    // Initializes a total capped supply of 1,000 tokens on deployment
    constructor() ERC20("Subaru", "SBU") {
        _mint(msgSender, _totalSupply * 10 ** uint256(decimals()));       

    }

    // Replenishes the total supply of tokens to the initial capped supply
    function modifyTokenBuyPrice(uint _newTokenPrice) 
        private 
        onlyOwner 
        returns(uint256){
            tokensPerEth = _newTokenPrice;
            return tokensPerEth;
        }

   // This allows users to buy tokens
  function buy() 
        payable
        public
        {
     // Ensures that the eth value sent to the contract is greater than 0
        require(msg.value > 0, "You need to send some Ether");         
        
    // The eth amount of the total tokens to be bought
        uint256 buyAmount = msg.value * tokensPerEth;        

    // Requires that token owner has enough tokens to sell to user
        require(balanceOf(msgSender) >= buyAmount);

    // Transfer tokens to the caller of this function
       _transfer(msgSender, msg.sender, buyAmount);        

    //    require(sent, "Failed to transfer token to user");
        
        emit Bought(msg.sender, msg.value, buyAmount);        // Emit the event

        (bool sent,) = payable(msgSender).call{value: msg.value}("");
        require(sent, "failed to receive ETH from the user");

    }
    // A dynamic array of stakeholders
    address[] internal stakeholdersArray; 

    // This function verifies that an address is a stakeholder
    function isStakeholder(address _address) 
        public 
        view 
        returns(bool, uint256){
        for(uint256 i = 0; i < stakeholdersArray.length; i++){
            if(_address == stakeholdersArray[i]) return (true, i);
        }
        return (false, 0);
    }

    // This function adds a stakeholder
    function addStakeholder (address _stakeholder)
        public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholdersArray.push(_stakeholder);
    }

    // This function removes a stakeholder
    function removeStakeholder (address _stakeholder) 
        public
         {
        (bool _isStakeholder, uint256 i) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholdersArray[i] = stakeholdersArray[stakeholdersArray.length - 1];
            stakeholdersArray.pop();
             }

    }

    // the stakes map maps a stakeholder to their stake size
    mapping(address => uint256) internal stakes;

    //  This retrieves the stake for a stakeholder.
    function stakeOf(address _stakeholder)
        public
        view
        returns (uint256){
        return stakes[_stakeholder];
    }

    // This  retrieves the total stakes from all the stakeholders
    function totalStakes()
        public 
        view 
        returns (uint256){
        uint256 _totalStakes;
        for(uint i = 0; i < stakeholdersArray.length; i++){
           _totalStakes += stakes[stakeholdersArray[i]];
        }
           return _totalStakes;
    }

    mapping (address => uint256) stakingPeriod;

    // This creates Stake for the caller of the function
    function createStake(uint256 _stake)
        public
    {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
        stakingPeriod[msg.sender] = block.timestamp + 259200;
    }

    // This removes stake for the caller of the function
    function removeStake(uint256 _stake)
        public
    {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
    }

    // The accumulated rewards for each stakeholder
    mapping(address => uint256) internal rewards;

    // This allows the stakeholder to check his rewards
    function rewardOf (address _stakeholder) 
        view 
        public 
        returns (uint256) {
        return rewards[_stakeholder];
    }

    // This retrieves the aggregated rewards from all the stakeholders
        function totalRewards()
        public 
        view 
        returns(uint256){
       uint256 _totalRewards = 0;
       for (uint256 i = 0; i < stakeholdersArray.length; i++){
           _totalRewards = _totalRewards.add(rewards[stakeholdersArray[i]]);
       }
       return _totalRewards;
   }

    // This calculates the rewards (which is 1%) for each stakeholder
    function calculateRewards(address _stakeholder) 
        public 
        view 
        returns(uint256){
        return stakes[_stakeholder] / 100;
    }


    // This allows the stakeholder to claim his rewards.
    function claimReward()
       public
   {
       uint256 reward;
       (bool _isStakeholder,) = isStakeholder(msg.sender);
       require(_isStakeholder);
      if(stakingPeriod[msg.sender] < block.timestamp && block.timestamp < stakingPeriod[msg.sender] + 172800){
	 reward = calculateRewards(msg.sender);
           rewards[msg.sender] = rewards[msg.sender] + reward;
	}
	reward = 0;
	rewards[msg.sender] = rewards[msg.sender] + reward;
   }

//    This allows the stakeholder to withdraw his rewards
     function withdrawReward()
       public
   {
       uint256 reward = rewards[msg.sender];
       rewards[msg.sender] = 0;
       _mint(msg.sender, reward);
   }
    
}

