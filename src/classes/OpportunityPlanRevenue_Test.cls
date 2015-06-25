/**********************************************************
   Class        :    OpportunityPlanRevenue_Test
   Author       :    Tyaga Pati
   Date         :    04/17/2015
   Description  :    For Testing Opportunity Plan Revenue Consolidation at the Opportunity plan Level. 
                     This code was to consolidate Revenue from Opty line Schedule to Opty plan is part of the 
                     Account plan Trigger Handler Code. 
                     This Test Class created User, Account, Opty, Opty line then calls a function in Test Util class
                     to create 15 rev schedules spread across 3 years starting from current fiscal year. 
   
   Modified On              Modified By                   Description
 * Apr 17th, 2014           Tyaga Pati      
  ***********************************************************/ 
@isTest
public class OpportunityPlanRevenue_Test {
      static testMethod void createAccountPlanOppsTest() {
      
      //Create a New User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        //Create a New Account
        Global_Settings__c setting = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        Account account = Test_Utils.insertAccount();
        
        //Create the new Opportunity
            Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
            opportunity.Amount = 100;
            opportunity.CloseDate = date.today().addDays(5);
            Opportunity.Contract_Start_Date__c = date.today().addDays(5);
            Opportunity.Contract_End_Date__c = date.today().addDays(5);
            opportunity.Type = Constants.OPPTY_TYPE_RENEWAL;
            insert opportunity;     
        
        //Create the New Contact
            Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',AccountId = account.Id, Email = 'larrye@email.com');
            insert newcontact;
            OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, opportunity.Id, newcontact.Id, Constants.DECIDER, true);
        
        //Create Opportunity Line items
            Product2 product = Test_Utils.insertProduct();
            Product.CanUseRevenueSchedule = True;
            update product;
            PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
            OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(opportunity.Id, stdPricebookEntry.Id, opportunity.Type);
            opportunityLineItem.Start_Date__c = Date.today().addDays(5);
            opportunityLineItem.End_Date__c = Date.today().addDays(10);
            opportunityLineItem.CPQ_Quantity__c = 1000;
            insert opportunityLineItem;
        
        //Create Opportunity Revenue Schedule
            Test_Utils.createMultiOpportunityLineItemSche(opportunityLineItem.Id); 
        

        //Close the opty
            opportunity.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_TERMS;
            opportunity.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
            opportunity.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;

        //Start test Mode to Conserve Counts:
            Test.startTest();
        
        //Final Step Create Account plan
            Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
            accountPlan.Name = 'TestAccountPlan';
            insert accountPlan;
       //Stop Test     
            Test.stopTest();
                      
       //Final Data Retreival from Test Records and Assertion
            List<Account_Plan_Opportunity__c> optyplan = [SELECT Current_Year_Revenue__c,Year_1_Revenue__c, Year_2_Revenue__c FROM Account_Plan_Opportunity__c WHERE Account_Plan_Opportunity__c.Account_Plan__c =: accountPlan.ID AND Account_Plan_Opportunity__c.Type__c = 'Open Opps'];         
            
            System.assertEquals(optyplan[0].Current_Year_Revenue__c,500); //Assert That Current Year Rev is 500
            System.assertEquals(optyplan[0].Year_1_Revenue__c,500); //Assert That Year1 Rev is 500
            System.assertEquals(optyplan[0].Year_2_Revenue__c,500); //Assert That Year2 Rev is 500
            
      }
    } 
}