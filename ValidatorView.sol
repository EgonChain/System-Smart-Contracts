// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;



interface InterfaceValidator {
    enum Status {
        // validator not exist, default status
        NotExist,
        // validator created
        Created,
        // anyone has staked for the validator
        Staked,
        // validator's staked coins < MinimalStakingCoin
        Unstaked,
        // validator is jailed by system(validator have to repropose)
        Jailed
    }
    struct Description {
        string moniker;
        string identity;
        string website;
        string email;
        string details;
    }
    function getTopValidators() external view returns(address[] memory);
    function getValidatorInfo(address val)external view returns(address payable, Status, uint256, uint256, uint256, uint256, address[] memory);
    function getValidatorDescription(address val) external view returns ( string memory,string memory,string memory,string memory,string memory);
    function totalStake() external view returns(uint256);
    function getStakingInfo(address staker, address validator) external view returns(uint256, uint256, uint256);
    function viewStakeReward(address _staker, address _validator) external view returns(uint256);
    function MinimalStakingCoin() external view returns(uint256);
    function isTopValidator(address who) external view returns (bool);
    function StakingLockPeriod() external view returns(uint64);
    function UnstakeLockPeriod() external view returns(uint64);
    function WithdrawProfitPeriod() external view returns(uint64);



}





contract ValidatorData {

    InterfaceValidator public valContract = InterfaceValidator(0x000000000000000000000000000000000000f000);
    
  

    function getAllValidatorInfo() external view returns (uint256 totalValidatorCount,uint256 totalStakedCoins,address[] memory,InterfaceValidator.Status[] memory,uint256[] memory,string[] memory,string[] memory)
    {
        address[] memory highestValidatorsSet = valContract.getTopValidators();
       
        uint256 totalValidators = highestValidatorsSet.length;
        InterfaceValidator.Status[] memory statusArray = new InterfaceValidator.Status[](totalValidators);
        uint256[] memory coinsArray = new uint256[](totalValidators);
        string[] memory identityArray = new string[](totalValidators);
        string[] memory websiteArray = new string[](totalValidators);
        
        for(uint8 i=0; i < totalValidators; i++){
            (, InterfaceValidator.Status status, uint256 coins, , , ,  ) = valContract.getValidatorInfo(highestValidatorsSet[i]);
            (, string memory identity, string memory website, ,) = valContract.getValidatorDescription(highestValidatorsSet[i]);
            
            statusArray[i] = status;
            coinsArray[i] = coins;
            identityArray[i] = identity;
            websiteArray[i] = website;
            
        }
        return(totalValidators, valContract.totalStake(), highestValidatorsSet, statusArray, coinsArray, identityArray, websiteArray);
    
    
    }





    function validatorSpecificInfo1(address validatorAddress, address user) external view returns(string memory identityName, string memory website, string memory otherDetails, uint256 withdrawableRewards, uint256 stakedCoins, uint256 waitingBlocksForUnstake ){
        
        (, string memory identity, string memory websiteLocal, ,string memory details) = valContract.getValidatorDescription(validatorAddress);
                
        
        uint256 unstakeBlock;
        uint256 withdrawableReward;

        (stakedCoins, unstakeBlock, ) = valContract.getStakingInfo(user,validatorAddress);

        if(unstakeBlock!=0){
            waitingBlocksForUnstake = stakedCoins;
            stakedCoins = 0;
        }
        else{
            withdrawableReward = valContract.viewStakeReward(user, validatorAddress);
        }
        

        

        return(identity, websiteLocal, details, withdrawableReward, stakedCoins, waitingBlocksForUnstake) ;
    }


    function validatorSpecificInfo2(address validatorAddress, address user) external view returns(uint256 totalStakedCoins, InterfaceValidator.Status status, uint256 selfStakedCoins, uint256 masterVoters, uint256 stakers, address){
        address[] memory stakersArray;
        (, status, totalStakedCoins, , , , stakersArray)  = valContract.getValidatorInfo(validatorAddress);

        (selfStakedCoins, , ) = valContract.getStakingInfo(validatorAddress,validatorAddress);

        return (totalStakedCoins, status, selfStakedCoins, 0, stakersArray.length, user);
    }


 

    
    function waitingWithdrawProfit(address user, address validatorAddress) external view returns(uint256){
        //only validator will have waiting 
        if(user== validatorAddress && valContract.isTopValidator(validatorAddress)){
            
            (, , , , , uint256 lastWithdrawProfitsBlock, )  = valContract.getValidatorInfo(validatorAddress);
            
            if(lastWithdrawProfitsBlock + valContract.WithdrawProfitPeriod() > block.number){
                return 3 * ((lastWithdrawProfitsBlock + valContract.WithdrawProfitPeriod()) - block.number);
            }
        }
        
       return 0;
    }

    function waitingUnstaking(address user, address validator) external view returns(uint256){
        
        //this function is kept as it is for the UI compatibility
        //no waiting for unstaking
        return 0;
    }

    function waitingWithdrawStaking(address user, address validatorAddress) public view returns(uint256){
        
        //validator and delegators will have waiting 
   
        (, uint256 unstakeBlock, ) = valContract.getStakingInfo(user,validatorAddress);

        if(unstakeBlock==0){
            return 0;
        }
        
        if(unstakeBlock + valContract.StakingLockPeriod() > block.number){
            return 3 * ((unstakeBlock + valContract.StakingLockPeriod()) - block.number);
        }
        
       return 0;
        
        
    }

    function minimumStakingAmount() external view returns(uint256){
        return valContract.MinimalStakingCoin();
    }

    function stakingValidations(address user, address validatorAddress) external view returns(uint256 minimumStakingAmt, uint256 stakingWaiting){
        return (valContract.MinimalStakingCoin(), waitingWithdrawStaking(user, validatorAddress));
    }
    
    function checkValidator(address user) external view returns(bool){
        //this function is for UI compatibility
        return true;
    }


}
