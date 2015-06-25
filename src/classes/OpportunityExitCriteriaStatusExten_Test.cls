/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityExitCriteriaStatusExtension_Test
 * Description: This test class is for testing the 'OpportunityExitCriteriaStatusExtension.cls' class
 * Created Date: Dec 17th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Apr 15th, 2014               Arpita Bose(Appirio)         T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014               Arpita Bose                  T-271695: Renamed field Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Oct 20th, 2014               Arpita Bose                  Updated method createTestData() to remove IsDataAdmin__c
 * Feb 2nd, 2015                Gaurav Kumar Chadha          Updated method createTestData() to insert new opportunity from existing
                                                             one and testOpptyExitCriteria() to update the opp to stage 7   
 =====================================================================*/

@isTest (seeAllData=true)
private class OpportunityExitCriteriaStatusExten_Test{
    private static Opportunity oppty;
    private static Opportunity oppty1;
    private static Opportunity opptyNew;
    static testmethod void testOpptyExitCriteria(){
        
        createTestData();
        
        OpportunityExitCriteriaStatusExtension cls = new OpportunityExitCriteriaStatusExtension(new ApexPages.StandardController(oppty));
        
        cls.hasSignedContract = true;
        cls.hasSelectionConfirmed = true;
        cls.hasQuoteDelivered = true;
        
        Test.startTest(); 
        
        system.debug('--------->'+oppty.StageName);
       
        oppty.StageName = Constants.OPPTY_STAGE_7;
        oppty.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
        oppty.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        oppty.Amount = 100;
        oppty.Has_Senior_Approval__c = true;
        oppty.CloseDate = date.today();
        oppty.Contract_Start_Date__c = date.today().addDays(1);
        oppty.Contract_End_Date__c = date.today().addYears(1);
        oppty.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        oppty.Is_There_Financial_Risk__c = 'Yes';
        oppty.Has_There_Been_Significant_Change__c  = 'Yes';
        oppty.Has_Stage_3_Approval__c = true;
        oppty.Budget__c= '1,001 - 10,000';
        oppty.Is_There_Commercial_Risk__c = 'Yes';
        oppty.Is_There_Delivery_Risk__c = 'Yes';
        oppty.Is_There_Legal_Risk__c = 'Yes';
        update oppty; 
        
        
        Test.stopTest();
    }
    
   /* static testmethod void  runTest()
    {
        ApexPages.StandardController sc = new ApexPages.StandardController([select Id from Opportunity limit 1]);
        OpportunityExitCriteriaStatusExtension cls = new OpportunityExitCriteriaStatusExtension(sc);
    }*/
    
    static void createTestData(){
        // Create an account    
        Account testAccount = Test_Utils.insertAccount();
        Address__c addrs1 = Test_Utils.insertAddress(true);
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);
        // Create Contact
        Contact testContact = Test_Utils.insertContact(testAccount.id);
        // insert contact address
        Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).id,testContact.Id);
        // Create an opportunity
        oppty = Test_Utils.createOpportunity(testAccount.Id);
        oppty.Type = Constants.OPPTY_NEW_FROM_NEW;
        oppty.Has_Senior_Approval__c = true;
        oppty.StageName = Constants.OPPTY_STAGE_3;
        //oppty.Below_Review_Thresholds__c = 'Yes';
        oppty.Amount = 500;
        oppty.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
        oppty.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        insert oppty;
        
        //Create OpportunityLineItem
        Product2 product = Test_Utils.insertProduct();
        product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;     
        product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;   
        product.NumberOfRevenueInstallments = 2;        
        product.CanUseRevenueSchedule = true;
        update product;
            
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 pricebook = new Pricebook2();
        pricebook.name = Constants.STANDARD_PRICE_BOOK;
        insert pricebook;
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);
        //insert OLI
        OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(oppty.Id, stdPricebookEntry.Id, oppty.Type);
        opportunityLineItem2.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem2.End_Date__c = System.today().addDays(10);
        opportunityLineItem2.Type__c = Constants.OPPTY_TYPE_RENEWAL ;
        opportunityLineItem2.CPQ_Quantity__c = 1000;
        insert opportunityLineItem2;
        
        system.debug('****opportunityLineItem2***'+opportunityLineItem2+'******oppty****'+oppty);
        // insert Coompleted Tasks
        list<Task> tasks =  Test_Utils.createOpptyTasks(oppty.id , true);
        // insert competitor
        Competitor__c competitor  = Test_Utils.insertCompetitor(oppty.id);
        // insert opportunity contact role
        OpportunityContactRole oppConRole  = Test_Utils.insertOpportunityContactRole(true , String.valueof(oppty.id),String.valueOf(testContact.id) , Constants.DECIDER , true );
        
        
    }
}