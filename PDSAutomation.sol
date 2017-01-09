pragma solidity ^0.4.0;

contract PDSAutomation{

      /*=======================================================================
        CONTRACT VARIABLES
        ========================================================================*/
      address center_admin; // address of the contract deployer
      uint public initial_balance; // gets initialized at the beginning of each month
      uint public final_balance;  //subsidy procured from state officials each month
      uint public subsidy_budget; // one-time initialization
      uint  public citizencount; // gets updated each time a new citizen is registered to the system
      Citizen public curcitizen;
      uint16 public rate;

      struct Citizen
      {
          uint bioInfo;
          bool bpl;
          uint16 subsidyBalance;
          uint16 requestedPurchase;
      }
      
      struct Dealer
      {
          uint subsidyCollected;
          uint remainingGoods;
          uint outstandingGoods;
          uint bioInfo;
          address stateOfficial;
          bool dealerPermission;
      }

      struct StateOfficial
      {
          uint subsidyCollected;
          uint bioInfo;
          bool statePermission;
      }

      mapping (uint => address) public citizenIndex;
      mapping (address => Citizen) public  citizendb;
      mapping (address => Dealer)  dealerdb;
      mapping (address => StateOfficial)  statedb;

      event printCustomer(address p1, bool p2, uint16 p3);
      /*=======================================================================
        FUNCTION: CONSTRUCTOR TO INITALIZE CONTRACT
        ========================================================================*/
      function PDSAutomation(uint _subsidy_budget) {

        center_admin = msg.sender;
        citizencount = 0;
        subsidy_budget = _subsidy_budget;
      }
      /*=======================================================================
        FUNCTION: PRINT CUSTOMER STATUS
        ========================================================================*/
      function printDebug() {

            for (uint i=0; i<citizencount; i++)
            {
                curcitizen = citizendb[citizenIndex[i]];
                printCustomer(citizenIndex[i], curcitizen.bpl, curcitizen.subsidyBalance);
            }
      }

    /*=======================================================================
        FUNCTION: Monthly Subsidy Allocator
        ========================================================================*/
      function monthlySubsidyAlloc() {

            initial_balance = subsidy_budget;
            for (uint i=0; i<citizencount; i++)
            {
               allocateSubsidy(citizenIndex[i]);
            }
      }
      /*=======================================================================
        FUNCTION: TO REGISTER A CITIZEN
        ========================================================================*/
      function registerCitizen(address _accountAddress, string _aadharID, uint _bioInfo, uint _income) payable returns (string){
            //Creating the citizendb entry

            citizendb[_accountAddress].bioInfo = _bioInfo;
            if (_income <= 10000000)
              citizendb[_accountAddress].bpl = true;
            else
              citizendb[_accountAddress].bpl = false;

            //Updating the citizen support structures
            
            citizenIndex[citizencount] = _accountAddress;
            citizencount++;
            return "registerCitizen";
      }
     /*=======================================================================
        FUNCTION: TO ALLOCATE SUBSIDY
        ========================================================================*/
      function allocateSubsidy(address _citizenID) returns (string) {

          if (msg.sender != center_admin)
            throw;
          if (citizendb[_citizenID].bpl)
          {
            citizendb[_citizenID].subsidyBalance = 50000;
            initial_balance -= 50000;
          }
          else
          {
            citizendb[_citizenID].subsidyBalance = 25000;
            initial_balance -= 25000;
          }
          return "allocateSubsidy";
      }
 
      /*=======================================================================
        FUNCTION: TO INITIATE A PURCHASE BY <CITIZEN>
        ========================================================================*/
      function initPurchase(uint16 _amount, address _dealeraddress, uint _bioInfo) returns (string){
            
            if (dealerdb[_dealeraddress].dealerPermission != true || citizendb[msg.sender].bioInfo != _bioInfo)
            {
                throw;
            }
            else if ((_amount*rate) < citizendb[msg.sender].subsidyBalance - citizendb[msg.sender].requestedPurchase)
            {
                throw;
            }
            else if (_amount < dealerdb[_dealeraddress].remainingGoods - dealerdb[_dealeraddress].outstandingGoods)
            {
                throw;
            }
            else
            {
                dealerdb[_dealeraddress].outstandingGoods +=_amount;
                citizendb[msg.sender].requestedPurchase += (_amount*rate);
            }
            return "initpurchase";
      }

      /*=======================================================================
        FUNCTION: TO PAY THE DEALER FROM <CITIZEN>s ACCOUNT
        ========================================================================*/
      function payDealer(uint16 _amount, address _citizenAddress, uint _bioInfo) returns (string){

            if (dealerdb[msg.sender].dealerPermission != true)
            {
              throw;
            }
            if (citizendb[_citizenAddress].bioInfo != _bioInfo)
            {
              throw;
            }
            dealerdb[msg.sender].subsidyCollected = dealerdb[msg.sender].subsidyCollected + (_amount * rate);
            citizendb[_citizenAddress].subsidyBalance = citizendb[_citizenAddress].subsidyBalance - (_amount * rate);
            dealerdb[msg.sender].outstandingGoods -= _amount;
            citizendb[_citizenAddress].requestedPurchase -=  (_amount*rate);
            return "payDealer";
      }

      /*=======================================================================
        FUNCTION: TO PAY THE STATE FROM THE <DEALER>s ACCOUNT
        ========================================================================*/
      function payState(uint _bioInfo) returns (string) {

            if (dealerdb[msg.sender].dealerPermission != true || dealerdb[msg.sender].bioInfo != _bioInfo)
            {
              throw;
            }

            statedb[dealerdb[msg.sender].stateOfficial].subsidyCollected = statedb[dealerdb[msg.sender].stateOfficial].subsidyCollected + dealerdb[msg.sender].subsidyCollected;
            dealerdb[msg.sender].subsidyCollected = 0;
            return "payState";
      }

      /*=======================================================================
        FUNCTION: TO PAY THE CENTER(central administrator) FROM <STATE>
        ========================================================================*/
      function payCenter(uint _bioInfo) returns (string) {

          if (statedb[msg.sender].statePermission != true || statedb[msg.sender].bioInfo != _bioInfo)
          {
            throw;
          }

          final_balance = final_balance + statedb[msg.sender].subsidyCollected;
          statedb[msg.sender].subsidyCollected = 0;
          return "payCenter";

      }
}
