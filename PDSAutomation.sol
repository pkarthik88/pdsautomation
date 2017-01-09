pragma solidity ^0.4.0;

contract PDSAutomation{

      /*=======================================================================
        CONTRACT VARIABLES
        ========================================================================*/
      address center_admin; // address of the contract deployer
      uint16 public initial_balance; // gets initialized at the beginning of each month
      uint16 public final_balance;  //subsidy procured from state officials each month
      uint16 public subsidy_budget; // one-time initialization
      uint16  public citizencount; // gets updated each time a new citizen is registered to the system
      uint16 public stateofficialcount;
      uint16 public dealercount;
      Citizen public curcitizen;
      uint16 public rate;

      struct Citizen
      {
          uint16 bioInfo;
          bool bpl;
          uint16 subsidyBalance;
      }

      struct Dealer
      {
          uint16 subsidyCollected;
          uint16 remainingGoods;
          uint16 outstandingGoods;
          uint16 bioInfo;
          address stateOfficial;
          bool dealerPermission;
      }

      struct StateOfficial
      {
          uint16 subsidyCollected;
          uint16 bioInfo;
          bool statePermission;
      }

      mapping (uint16 => address) public citizenIndex;
      mapping (address => Citizen) public  citizendb;
      mapping (address => Dealer)  public dealerdb;
      mapping (address => StateOfficial)  public statedb;

      event printCustomer(address p1, bool p2, uint16 p3);
      /*=======================================================================
        FUNCTION: CONSTRUCTOR TO INITALIZE CONTRACT
        ========================================================================*/
      function PDSAutomation(uint16 _subsidy_budget) {

        center_admin = msg.sender;
        citizencount = 0;
        stateofficialcount = 0;
        dealercount = 0;
        subsidy_budget = _subsidy_budget;
      }
      /*=======================================================================
        FUNCTION: PRINT CUSTOMER STATUS
        ========================================================================*/
      function printDebug() {

            for (uint16 i=0; i<citizencount; i++)
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
            for (uint16 i=0; i<citizencount; i++)
            {
               allocateSubsidy(citizenIndex[i]);
            }
      }
      /*=======================================================================
        FUNCTION: TO REGISTER A CITIZEN
        ========================================================================*/
      function registerCitizen(address _accountAddress, string _aadharID, uint16 _bioInfo, uint16 _income) payable returns (string){
            //Creating the citizendb entry
            if (msg.sender != center_admin)
            {
              throw;
            }
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
        FUNCTION: TO REGISTER A STATE OFFICIAL
        ========================================================================*/
      function registerStateOfficial(address _accountAddress, string _aadharID, uint16 _bioInfo) payable returns (string){
            //Creating the statedb entry
            if (msg.sender != center_admin)
            {
              throw;
            }
            statedb[_accountAddress].bioInfo = _bioInfo;
            statedb[_accountAddress].statePermission = true;
            stateofficialcount++;
            return "registerStateOfficial";
      }
      /*=======================================================================
        FUNCTION: TO REGISTER A DEALER
        ========================================================================*/
      function registerDealer(address _accountAddress, string _aadharID, uint16 _bioInfo) payable returns (string){
            //Creating the dealerdb entry
            if (statedb[msg.sender].statePermission != true)
            {
              throw;
            }
            dealerdb[_accountAddress].bioInfo = _bioInfo;
            dealerdb[_accountAddress].dealerPermission = true;
            dealerdb[_accountAddress].stateOfficial = msg.sender;
            dealercount++;
            return "registerDealer";
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
        FUNCTION: TO PAY THE DEALER FROM <CITIZEN>s ACCOUNT
        ========================================================================*/
      function payDealer(uint16 _amount, address _citizenAddress, uint16 _bioInfo) returns (string){

            if (dealerdb[msg.sender].dealerPermission != true || citizendb[_citizenAddress].bioInfo != _bioInfo)
            {
              throw;
            }
            dealerdb[msg.sender].subsidyCollected = dealerdb[msg.sender].subsidyCollected + _amount * rate;
            citizendb[_citizenAddress].subsidyBalance = citizendb[_citizenAddress].subsidyBalance - _amount * rate;
            return "payDealer";
      }
      /*=======================================================================
        FUNCTION: TO PAY THE STATE FROM <DEALER>s ACCOUNT
        ========================================================================*/
      function payState(uint16 _amount, address _dealerAddress, uint16 _bioInfo) returns (string){

            if (dealerdb[msg.sender].dealerPermission != true || dealerdb[_dealerAddress].bioInfo != _bioInfo)
            {
              throw;
            }
            statedb[dealerdb[msg.sender].stateOfficial].subsidyCollected = statedb[dealerdb[msg.sender].stateOfficial].subsidyCollected + _amount * rate;
            dealerdb[msg.sender].subsidyCollected = dealerdb[msg.sender].subsidyCollected - _amount * rate;
            return "payState";
      }
      /*=======================================================================
        FUNCTION: TO PAY THE STATE FROM <DEALER>s ACCOUNT
        ========================================================================*/
      function payCenter(uint16 _amount, address _stateAddress, uint16 _bioInfo) returns (string){

            if (statedb[msg.sender].statePermission != true || statedb[_stateAddress].bioInfo != _bioInfo)
            {
              throw;
            }
            statedb[_stateAddress].subsidyCollected = statedb[_stateAddress].subsidyCollected - _amount;
            final_balance = final_balance + _amount;
            return "payState";
      }
}
