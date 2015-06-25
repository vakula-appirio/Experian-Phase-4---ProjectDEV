/**=====================================================================
 * Appirio, Inc
 * Name: Test_Utils 
 * Description: This class is use for all related Test clases for creating Pre required
                Data if needed in case of testing any scenario.
 * Created Date: Oct 30th, 2013 
 * Created By: Pankaj Mehra (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Jan 30th, 2014     Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * 02/12/2014         Naresh Ojha (Appirio)        Added method for creation of opportunity schedules
 * Feb 13th, 2014     Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Feb 18th, 2014     Jinesh Goyal(Appirio)        T-250105: Added Methods 'insertAddress'
 *                                                 and 'insertAddressMergeRequest'
 * Feb 20th, 2014     Nathalie Le Guay (Appirio)   Updated createOpportunity() to reference
 *                                                 Constants.OPPTY_STAGE_3 instead of 'na'
 * Feb 24th, 2014     Jinesh Goyal(Appirio)        T-250105: Added Methods 'insertAccountAddress'
 *                                                 and 'insertContactAddress'
 * Feb 26th, 2014     Nathalie Le Guay             Adding createTask() and createOpptyTasks() methods
 * Feb 27th, 2014     Arpita Bose(Appirio)         updated "insertTriggerSettings()" to get custom settings.
 * Mar 04th, 2014     Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 13th, 2014     Nathalie Le Guay             Adding createEvent()
 * Mar 27th, 2014     Nathalie Le Guay             T-266743: Remove references to Primary_Billing__c & Primary_Shipping__c (unused)
 *                                                 Comment 'newShare.ContactAccessLevel' bc ContactAccessLevel is now "Controlled by Parent"
 * Mar 28th, 2014     Arpita Bose(Appirio)         Updated createOpportunityLineItem() to set Quantity for the Validation Rule
 * Mar 31st, 2014     Nathalie Le Guay             Added createUser(Profile profile, String email, String lastName)
 * Apr 02nd, 2014     Arpita Bose                  T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 03rd, 2014     Arpita Bose                  T-268982: Updated the method name insertOrderLineItems() from inserOrder()
 * Apr 15th, 2014     Arpita Bose                  T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 18th, 2014     Rahul Jain                   Added insertCase, insertDeliveryProject, insertTimecard methods for Task T-270393 and T-270392
 * Apr 28th, 2014     Rahul Jain                   Added insertOpportunityPlan, insertOpportunityTeamMember, insertTimecard methods for Task T-273695
 * May 02nd, 2014     Rahul Jain                   Added insertAccountTeamMember,insertAccountPlan,insertAccountPlanTeam methods for T-275545
 * May 07th, 2014     Rahul Jain                   Added insertAccountPlanSwot,insertAccountPlanOpp, insertAccountPlanOppSwot methods for T-276704, T-276706
 * Jun 03rd, 2014     Jinesh Goyal                 Added method insertAccountPlanPenetration 
 * Jun 25th, 2014     Bharti                       
 * Jul 28th, 2014     Nathalie Le Guay             S-252919 - updated createTask(String whatId, String typeValue, String status) to use Outcomes__c instead of Type
 * Aug 01st, 2014     Arpita Bose                  Added method insertProject and insertDeliveryLine for T-268015
 * Aug 27th, 2014     Arpita Bose                  Added method insertCase for T-314309 (Experian Phase 2)
 * Sep 11th, 2014     Mohit Parnami                Added method insertRoyalty for T-318596
 * Oct 07th, 2014     Arpita Bose                  Added method insertOpportunityContactRole for T-322814
 * Oct 10th, 2014     Arpita Bose                  Added method insertAsset()
 * Oct 17th, 2014     Arpita Bose                  Added method createEDQUser()
 * Oct 21st, 2014     Pallavi Sharma               Added Math.random() for getting Unique External Ids - updated by NLG for I-135920
 * Nov 2nd,  2014     Nathalie Le Guay             Populating FirstName in the CreateUser methods, to prevent other test classes from failing
 * Jan 22nd, 2015     Arpita Bose                  Added methods insertAssignmentTeam(),insertAssignmentTeamMember()and insertAccAssignmentTeam() 
 * Mar 3rd,  2015     Gaurav Kumar Chadha          Added method insertContract() 
 * Mar 5th,  2015     Gaurav Kumar Chadha          Added method insertDeployment()
 * Mar 17th, 2015     Gaurav Kumar Chadha          Added method insertOpportunitySalesProcess()
 * Mar 26th, 2014     Tyaga Pati                   Added Function to Created multiple Revenue schedules for opty plan aggregation testing
 * Mar 27th, 2015     Arpita Bose                  Added method insertHierarchy() and insertAccountSegment() for T-373930
 * Apr 08th, 2015     Terri Kellough               Added insertBusinessProcessTemplateItem, insertBusinessProcessTemplate, 
 *                                                 insertBusinessProcess, insertBusinessProcessItem, and insertMembership
 * May 12th, 2015     Terri Kellough               Modified createOpportunityLineItem for I-162285
 * May 13th, 2015     Terri Kellough               Modified createOpportunity(Id accountId) for I-162285
 =====================================================================*/
//@isTest
public with sharing class Test_Utils {

    static {
      try {
        Global_Settings__c custSettings = Global_Settings__c.getValues('Global');
        if (custSettings == null) {
          custSettings = new Global_Settings__c(name='Global',Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER);
          insert custSettings;
        }
      } catch(Exception ex) {
        system.debug('#########Exception############'+ex);
        apexLogHandler.createLogAndSave('Test_Utils','static block', ex.getStackTraceString(), ex);
      }
    }
    
    public static Business_Unit_Group_Mapping__c edqSetting { 
      get {
        try {
          edqSetting = Business_Unit_Group_Mapping__c.getValues('EDQ');
          if (edqSetting == null) {
            edqSetting = new Business_Unit_Group_Mapping__c(Name='EDQ',User_Business_Unit__c = 'APAC:SE', Common_Group_Name__c = 'EDQ');
            insert edqSetting;
          }
        } catch(Exception ex) {
          system.debug('#########Exception############'+ex);
          apexLogHandler.createLogAndSave('Test_Utils','static block', ex.getStackTraceString(), ex);
        }
        return edqSetting;
      }
    }
  

    //=============================================================//
  //Creates Opportunity
  //============================================================//
  public static Opportunity createOpportunity(Id accountId){
    Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', CloseDate = date.today().addDays(2),    
                                                StageName = Constants.OPPTY_STAGE_3, AccountId = accountId,    
                                                CurrencyIsoCode = 'USD'); //, Below_Review_Thresholds__c = 'Yes');
    opportunity.Contract_Start_Date__c = date.today().addDays(3);
    opportunity.Contract_End_Date__c = date.today().addYears(1);
    opportunity.Type = 'test';
    opportunity.Reporting_Sales_Team__c = null;
    opportunity.Invoice_to_End_User__c = 'Yes';
    opportunity.FYR__c = null;
    opportunity.SYR__c = null;
    opportunity.Quote_Active__c = true;
    opportunity.Quote_Bill_Plan_Code__c = 'test';
    opportunity.Quote_Close_Date__c = datetime.now();
    opportunity.Quote_Created_Date__c = date.today();
    opportunity.Quote_Effective_As_Of__c = date.today();
    opportunity.Quote_Effective_Through__c = date.today().addYears(1);
    opportunity.Quote_Last_Modified_Date__c= datetime.now();
    opportunity.Quote_Number__c = 'test';
    opportunity.Quote_Primary__c = true;
    opportunity.Quote_Revision__c = 'test';
    opportunity.Quote_Type__c = 'test';
    opportunity.Requested_Bill_Plan__c = 'test';
    opportunity.Suggested_Bill_Plan__c = 'test';
    //opportunity.CSDA_Annual_Contract_Value__c = 1;
    opportunity.Quote_Created_Date__c = datetime.now(); 
    return opportunity;
  }

  //=============================================================//
  //Creates Opportunity
  //============================================================//
  public static Opportunity insertOpportunity(Id accountId){
    Opportunity opportunity = createOpportunity(accountId);
    //opportunity.Below_Review_Thresholds__c = 'Yes'; T-271695
    insert opportunity;
    return opportunity;
  }
  
  //=============================================================//
  //Creates Opportunity_Sales_Process__c
  //============================================================//
  public static Opportunity_Sales_Process__c insertOpportunitySalesProcess(Boolean isInsert , String name){
    Opportunity_Sales_Process__c oppSalesProcess = new Opportunity_Sales_Process__c();
    oppSalesProcess.Name = name;
    if (isInsert) {
      insert oppSalesProcess;
    }  
    return oppSalesProcess;
  }

  //=============================================================//
  //Insert Contact
  //============================================================//
  public static Contact insertContact(Id accountId){
    Contact contact = createContact(accountId);
    insert contact;
    return contact;
  }

  //=============================================================//
  //Creates Contact
  //============================================================//
  public static Contact createContact(Id accountId){
    Contact contact = new Contact(MailingCountry='USA',MailingState='TX',MailingCity='Dallas',
                                      FirstName='firstname',Salutation='Mr.',LastName='test',
                                      email='test@'+randomNumber()+'test.com' , AccountId = accountId);
    return contact;
  }

  //=============================================================//
  //Insert Contact
  //============================================================//
  public static Contact insertEDQContact(Id accountId, Boolean isInsert){
    Contact contact = createContact(accountId);
    contact.EDQ_On_Demand__c = true;
    contact.Title = 'NewTitle';
    contact.EDQ_Integration_Id__c = 'TESTID'+randomNumber();
    if (isInsert) {
      insert contact; 
    }
    return contact;
  }

  //=============================================================//
  //Creates Lead
  //============================================================//
  public static Lead createLead(){
    Lead lead = new Lead(LastName = 'Test Lead-'+randomNumber(),
                         FirstName = 'Test Lead-'+randomNumber(),
                         City = 'TestCity',State = 'TestCountry',
                         Street = 'TestStreet', Country = 'TestCountry',
                         PostalCode = '302120',Status = 'Open',
                         Email = 'test@test.com' , Company = 'TestComapny',
                         CurrencyIsoCode = Constants.CURRENCY_USD , Phone = '123442356',
                         LeadSource = 'Other' , Industry = 'Automotive',
                         Region__c = 'India');
    return lead;
  }

  //=============================================================//
  //Insert Lead
  //============================================================//
  public static Lead insertLead(){
    Lead lead = createLead();
    insert lead;
    return lead;
  }

   //=============================================================//
  //Creates MarketingActivity
  //============================================================//
  public static ELQA_Marketing_Activity__c createMarketingActivity(){
    ELQA_Marketing_Activity__c MarketingActivity = new ELQA_Marketing_Activity__c();
                                      //(Name = 'Test ELQA_Marketing_Activity__c-'+randomNumber());  Modified 19/11/13 Shane Khublall, this is now auto number
    return MarketingActivity;
  }

  //=============================================================//
  //insert MarketingActivity
  //============================================================//
  public static ELQA_Marketing_Activity__c insertMarketingActivity(){
    ELQA_Marketing_Activity__c MarketingActivity = createMarketingActivity();
    insert MarketingActivity;
    return MarketingActivity;
  }

  //=============================================================//
  //Creates Account
  //============================================================//
  public static Account createAccount(){

    Account defaultAccount = new Account();
    defaultAccount.Name = 'Test Account'+randomNumber();
    /*
    defaultAccount.BillingCountry = 'USA';
    defaultAccount.BillingState = 'New York';
    defaultAccount.BillingPostalCode = '12345';
    defaultAccount.BillingStreet = '1300 Ampitheatre';
    defaultAccount.BillingState = 'Arkansas';
    defaultAccount.BillingCity = 'Bentonville';
    */
    return defaultAccount;
  }
  
  //=============================================================//
  //Creates Accounts
  //============================================================//
  public static List<Account> createAccounts(Integer numberOfAccounts){

    List<Account> accounts = new List<Account>();
    for (Integer i=0; i < numberOfAccounts; i++) {
      accounts.add(new Account(Name = 'Test Account'+randomNumber()));
    }
    return accounts;
  }

  //=============================================================//
  //Creates Account
  //============================================================//
  public static Account insertEDQAccount(Boolean isInsert){

    Account defaultAccount = new Account();
    defaultAccount.Name = 'Test Account'+randomNumber();
    defaultAccount.EDQ_Integration_Id__c = 'TESTID'+randomNumber();
    if(isInsert) {
      insert defaultAccount;
    }
    return defaultAccount;
  }

  //=============================================================//
  //Creates Opportunity
  //============================================================//
  public static Account insertAccount(){
    Account account = createAccount();
    insert account;
    return account;
  }

  //=============================================================//
  //Creates Opportunity
  //============================================================//
  public static Competitor__c createCompetitor(Id opportuntiyId){
    Competitor__c competitor = new Competitor__c(Opportunity__c = opportuntiyId);
    return competitor;
  }

  //=============================================================//
  //Creates Opportunity
  //============================================================//
  public static Competitor__c insertCompetitor(Id opportuntiyId){
    Competitor__c competitor = createCompetitor(opportuntiyId);
    insert competitor;
    return competitor;
  }

   //=============================================================//
  //Create OpportunityLineItem
  //============================================================//
  public static OpportunityLineItem  createOpportunityLineItem(Id OpportunityId, Id PricebookEntryId , string oppType){
      OpportunityLineItem  oppLineItem = new OpportunityLineItem ();
      oppLineItem.TotalPrice = 200 + randomNumber();
      oppLineItem.UnitPrice = null;
      oppLineItem.Quantity = 1;
      oppLineItem.OpportunityId = OpportunityId;
      oppLineItem.PricebookEntryId = PricebookEntryId ;
      oppLineItem.Start_Date__c = Date.today().addDays(-5);
      oppLineItem.End_Date__c = Date.today().addDays(5);
      if (oppType == Constants.OPPTY_NEW_FROM_NEW ) { 
        oppLineItem.Order_Type__c = Constants.STATUS_NEW;
      }
      else if ( oppType == Constants.OPPTY_NEW_FROM_EXISTING ) {
        oppLineItem.Order_Type__c = Constants.CROSS_SELL;
      }
      else if ( oppType == Constants.OPPTY_TYPE_RENEWAL ) {
        oppLineItem.Order_Type__c = Constants.OPPTY_TYPE_RENEWAL;
      }
      else if ( oppType == Constants.OPPTY_TYPE_FREE_TRIAL ) {
        oppLineItem.Order_Type__c = Constants.OPPTY_TYPE_FREE_TRIAL;
      }

      oppLineItem.Type__c = 'test';
      oppLineItem.SaaS__c = false;
      oppLineItem.SaaS_Product_Code__c = 'test';
      oppLineItem.Product_Finance_BU__c = 'test';
      oppLineItem.Finance_BU_Name__c = 'test';
      oppLineItem.CPQ_Quantity__c = 1;
      oppLineItem.EDQ_Margin__c = 1;
      oppLineItem.Renewal_EDQ_Margin__c = 1;
      oppLineItem.Product_Upgrade__c = false;
      oppLineItem.Order_Type__c = 'test';
      oppLineItem.Renewal_List_Price__c = 1;
      oppLineItem.Opportunity_Country__c = 'test';
      oppLineItem.Application__c = 'test';
      oppLineItem.Compiler__c = 'test';
      oppLineItem.CD_Name__c = 'test';
      oppLineItem.Click_Expiry__c = false;
      oppLineItem.CRM_Product_Name__c = 'test';
      oppLineItem.Data_Installer_Password__c = 'test';
      oppLineItem.Data_Media__c = 'test';
      oppLineItem.Data_Required__c = false;
      oppLineItem.Delivery_Method__c = 'test';
      oppLineItem.Despatch_Status__c = 'test';
      oppLineItem.Delivery_Time__c = 'test';
      oppLineItem.CPQ_Discount__c = 1;
      oppLineItem.Discount_Amount__c = 1;
      oppLineItem.Distribution_Notes__c = 'test';
      oppLineItem.EDQ_On_Demand_Product__c = false;
      oppLineItem.eRenewal_Exception__c = false;
      oppLineItem.Extended_Amount__c = 1;
      oppLineItem.Hardware__c = 'test';
      oppLineItem.Implementation__c = 'test';
      oppLineItem.Description = 'test';
      oppLineItem.Item_Quantity__c = 1;
      oppLineItem.Item_Number__c = 'test';
      oppLineItem.List_Price__c = 1;
      oppLineItem.Manual_Registration__c = true;
      oppLineItem.Manuals_Required__c = false;
      oppLineItem.Media_Quantity__c = 1;
      oppLineItem.No_Delivery__c = true;
      oppLineItem.No_Update__c = true;
      oppLineItem.Operating_System__c = 'test';
      oppLineItem.Original_Asset_ID__c = 'test';
      oppLineItem.Parent_Item_Number__c = 'test';
      oppLineItem.Part_Number__c = 'test';
      oppLineItem.Partner_Amount__c = 0;
      oppLineItem.Partner__c = 0;
      oppLineItem.Precise_Day_License__c = false;
      oppLineItem.Price_Category__c = 'test';
      oppLineItem.Product_Code__c = 'test';
      oppLineItem.Product_Data__c = 'test';
      oppLineItem.Product_Family__c = 'test';
      oppLineItem.Product_Reference__c = 'test';
      oppLineItem.Product_Release_Name__c = 'test';
      oppLineItem.Renewal_Discount__c = 1;
      oppLineItem.Renewal_Discount_Amount__c = 1;
      oppLineItem.Renewal_Extended_Amount__c = 1;
      oppLineItem.Renewal_Partner_Amount__c = 1;
      oppLineItem.Renewal_Partner__c = 1;
      oppLineItem.Renewal_Registration__c = false;
      oppLineItem.Renewal_Sale_Price__c = 1;
      oppLineItem.Renewal_Total_Royalty__c = 1;
      oppLineItem.Renewals_Exclude__c = false;
      oppLineItem.Total_Royalty__c = 1;
      oppLineItem.Update_Frequency__c = 'test';
      oppLineItem.Users_From__c = 1;
      oppLineItem.Users_To__c = 1;

      oppLineItem.Adj_Amount__c = 1;
      oppLineItem.Adj_Percentage__c = 1;
      oppLineItem.AE_Discount__c = 1;
      oppLineItem.Annual_Sales_Price__c = 1;
      oppLineItem.Auto_Quote__c = false;
      oppLineItem.Bill_Plan_Product_Name__c = 'test';
      oppLineItem.Bundle_Discount_Category__c = 'test';
      oppLineItem.Bundle_Discount_Name__c = 'test';
      oppLineItem.CSDA_Estimated_Annual_Volume__c = 1;
      oppLineItem.CSDA_List_Price__c = 1;
      oppLineItem.CSDA_Product_Group__c = 'test';
      oppLineItem.CSDA_Product_Org__c = 'test';
      oppLineItem.CSDA_Product_Suite__c = 'test';
      oppLineItem.CSDA_Unit_Type__c = 'test';
      oppLineItem.Escalate__c = true;
      oppLineItem.Final_Price__c = 1;
      oppLineItem.Manager_Discount__c = 1;
      oppLineItem.Manual_Adj_Amount__c = 1;
      oppLineItem.Manual_Discount__c = 1;
      oppLineItem.Manual_Price_Override__c = 1;
      oppLineItem.Maximum_Price__c = 1;
      oppLineItem.Max_Volume__c = 1;
      oppLineItem.Minimum_Price__c = 1;
      oppLineItem.Min_Volume__c = 1;
      oppLineItem.Original_Price__c = 1;
      oppLineItem.Plan__c = 'test';
      oppLineItem.Quotable__c = 'test';
      oppLineItem.Quote_Sheet_Type__c = 'test';
      oppLineItem.Requested_Adjustment_Amount__c = 1;
      oppLineItem.Requested_Unit_Price__c = 1;
      oppLineItem.SA_Discount__c = 1;

      return oppLineItem;
  }

   //=============================================================//
  //Create OpportunityLineItem (overloaded)
  //============================================================//
  public static OpportunityLineItem  createOpportunityLineItem(Id OpportunityId, Id PricebookEntryId, Id BillingProductId , string oppType){
      OpportunityLineItem  oppLineItem = new OpportunityLineItem ();
      oppLineItem.TotalPrice = 200 + randomNumber();
      oppLineItem.UnitPrice = null;
      oppLineItem.Quantity = 1;
      oppLineItem.OpportunityId = OpportunityId;
      oppLineItem.PricebookEntryId = PricebookEntryId ;
      oppLineItem.Billing_Product__c = BillingProductId;
      if (oppType == Constants.OPPTY_NEW_FROM_NEW ) { 
        oppLineItem.Order_Type__c = Constants.STATUS_NEW;
      }
      else if ( oppType == Constants.OPPTY_NEW_FROM_EXISTING ) {
        oppLineItem.Order_Type__c = Constants.CROSS_SELL;
      }
      else if ( oppType == Constants.OPPTY_TYPE_RENEWAL ) {
        oppLineItem.Order_Type__c = Constants.OPPTY_TYPE_RENEWAL;
      }
      else if ( oppType == Constants.OPPTY_TYPE_FREE_TRIAL ) {
        oppLineItem.Order_Type__c = Constants.OPPTY_TYPE_FREE_TRIAL;
      }
      return oppLineItem;
  }

  //=============================================================//
  //Create OpportunityLineItem (overloaded)
  //============================================================//
  public static OpportunityLineItemSchedule  insertOpportunityLineItemSchedule(Id opportunityLineItemId){
      OpportunityLineItemSchedule lis = new OpportunityLineItemSchedule();
        lis.OpportunityLineItemId = opportunityLineItemId;
        lis.Type = 'Revenue';
        lis.Revenue = 100;
        lis.ScheduleDate = System.today().addDays(5);
        lis.Description = 'According to invoice '+randomNumber();
        insert lis;
      return lis;
  }


  //=============================================================//
  //Create OpportunityLineItem (overloaded)
  //============================================================//
  public static OpportunityLineItemSchedule  createOpportunityLineItemSchedule(Id opportunityLineItemId){
      OpportunityLineItemSchedule lis = new OpportunityLineItemSchedule();
        lis.OpportunityLineItemId = opportunityLineItemId;
        lis.Type = 'Revenue';
        lis.Revenue = 100;
        lis.ScheduleDate = System.today();
        lis.Description = 'According to invoice '+randomNumber();

      return lis;
  }

  //=============================================================//
  // Tyaga Pati : Create OpportunityLineItem schedule with multiple schedule lines (overloaded)
  //============================================================//
  public static void createMultiOpportunityLineItemSche(Id opportunityLineItemId) {
     List<OpportunityLineItemSchedule> OptyLineRevList= new List<OpportunityLineItemSchedule>();
     Integer count = 0;
     Integer count1 = 0;
     Integer count2 = 0;
     DateTime CurrentDt = DateTime.now();
     Integer Year1=CurrentDt.Year();
     Integer Year2 = Year1+1;
     Integer Year3 = Year1+2;
     Integer MonthSt = 3;
     Integer DateSt = 1;
     Decimal Rev = 100;
     List<OpportunityLineItemSchedule> RevListInsert= new List<OpportunityLineItemSchedule>();
     do {
        OpportunityLineItemSchedule lis = new OpportunityLineItemSchedule();
        lis.OpportunityLineItemId = opportunityLineItemId;
        lis.Type = 'Revenue';
        lis.Revenue = Rev;
        MonthSt +=1;
        Date RevDate = date.newinstance(Year1, MonthSt, DateSt);
        lis.ScheduleDate = RevDate;
        lis.Description = 'According to invoice '+ randomNumber();
        RevListInsert.add(lis);
        count++;
     } while (count < 5);
     MonthSt = 3;
     //While Loop1 for Revn For Next Year.
        
     do {
        OpportunityLineItemSchedule lis = new OpportunityLineItemSchedule();
        lis.OpportunityLineItemId = opportunityLineItemId;
        lis.Type = 'Revenue';
        lis.Revenue = Rev;
        MonthSt +=1 ;
        Date RevDate = date.newinstance(Year2, MonthSt, DateSt);
        lis.ScheduleDate = RevDate;
        lis.Description = 'According to invoice '+randomNumber();
        RevListInsert.add(lis);
        count1++;
     } while (count1 < 5);
     MonthSt = 3;
     //While Loop1 for Revn For Year+2.
     
     do {
        OpportunityLineItemSchedule lis = new OpportunityLineItemSchedule();
        lis.OpportunityLineItemId = opportunityLineItemId;
        lis.Type = 'Revenue';
        lis.Revenue = Rev;
        MonthSt +=1 ;
        Date RevDate = date.newinstance(Year3, MonthSt, DateSt);
        lis.ScheduleDate = RevDate;
        lis.Description = 'According to invoice '+randomNumber();
        RevListInsert.add(lis);
        count2++;
     } while (count2 < 5);
        
        system.debug('Revitem0:'+ RevListInsert.size());
        system.debug('Revitem1:'+RevListInsert[0]);
        system.debug('Revitem2:'+RevListInsert[1]);
        system.debug('Revitem3:'+RevListInsert[2]);
        system.debug('Revitem4:'+RevListInsert[3]);
        system.debug('Revitem5:'+RevListInsert[4]);
        system.debug('Revitem6:'+RevListInsert[5]);
        system.debug('Revitem7:'+RevListInsert[6]);
        system.debug('Revitem8:'+RevListInsert[7]);
        system.debug('Revitem9:'+RevListInsert[8]);
        system.debug('Revitem10:'+RevListInsert[9]);
        system.debug('Revitem11:'+RevListInsert[10]);
        system.debug('Revitem12:'+RevListInsert[11]);
        system.debug('Revitem13:'+RevListInsert[12]);
        system.debug('Revitem14:'+RevListInsert[13]);
        system.debug('Revitem15:'+RevListInsert[14]);
        system.debug('Tyaga This is the final schedule getting inserted :'+ RevListInsert + 'and size is:'+ RevListInsert.size() );
        Insert RevListInsert;   
  }

  //=============================================================//
  //Inserts OpportunityLineItem
  //============================================================//
  public static OpportunityLineItem  insertOpportunityLineItem(Id OpportunityId, Id PricebookEntryId ,string oppType){
      OpportunityLineItem  oppLineItem = createOpportunityLineItem(OpportunityId ,PricebookEntryId ,oppType );

      insert oppLineItem;
      return oppLineItem;
  }

  //=============================================================//
  //Inserts OpportunityLineItem (overloaded)
  //============================================================//
  public static OpportunityLineItem  insertOpportunityLineItem(Id OpportunityId, Id PricebookEntryId, Id BillingProductId ,string oppType ){
      OpportunityLineItem  oppLineItem = createOpportunityLineItem(OpportunityId ,PricebookEntryId, BillingProductId ,oppType );

      insert oppLineItem;
      return oppLineItem;
  }

  //=============================================================//
  //Query Pricebook2
  //============================================================//
    public static Pricebook2 getPriceBook2() {

    List<Pricebook2> lstPriceBook = [ SELECT Id FROM Pricebook2 WHERE IsActive = true];
    if(lstPriceBook.size() > 0){
        return lstPriceBook[0];
    }

    Pricebook2 priceBook = [ SELECT Id FROM Pricebook2 limit 1];
    priceBook.IsActive = true;
    return priceBook;
   }

   //=============================================================//
  //Query Pricebook2
  //============================================================//
    public static Pricebook2 getPriceBook2(String priceBookName) {

    Pricebook2 priceBook = [ SELECT Id FROM Pricebook2 where Name =: priceBookName limit 1];
    return priceBook;
   }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static Product2 createProduct(){
      double randomNumber = randomNumber();
      Product2 product = new Product2();
      product.Name = 'TestProduct'+ String.valueOf(randomNumber);
      product.IsActive = true;
      return product ;
   }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static Product2 insertProduct(){
        Product2 product = createProduct();
        insert product;
    return product;
   }

  //=============================================================//
  //Create PricebookEntry
  //============================================================//
  public static PricebookEntry createPricebookEntry(Id productId , Id priceBookId , String currencyType){
      PricebookEntry  pbe = new PricebookEntry();
      pbe.Pricebook2Id = priceBookId;
      pbe.Product2Id = productId ;
      pbe.IsActive = true;
      pbe.CurrencyIsoCode = currencyType;
      pbe.UnitPrice = 100.0;
      return pbe;
   }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static PricebookEntry insertPricebookEntry(Id productId , Id priceBookId , String currencyType){
        PricebookEntry pricebookEntry = createPricebookEntry(productId , priceBookId , currencyType);
        insert pricebookEntry;
    return pricebookEntry;
   }

  //=============================================================//
  //Creates User
  //============================================================//
  public static User createUser(String profileName){

    User testUser = new User();
    Profile p = [SELECT id from profile where name =: profileName ];
    //UserRole role = [SELECT ID from UserRole where Name = 'CEO'];

    testUser = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                 emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', Region__c = 'EMEA',
                 username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true,
                 CompanyName = 'test Company');

    return testUser;
  }

  //=============================================================//
  // Creates Users given Profile (already queried), email and LastName
  //============================================================//
  public static List<User> createUsers(Profile profile, String email, String alias, Integer numberOfUsers) {

    List<User> testUsers = new List<User>();
    for (Integer i=0; i < numberOfUsers; i++) {
    testUsers.add(new User(alias = alias+i, email=email+i,
                 emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', Region__c = 'EMEA',
                 username=email + Math.random(), IsActive=true,
                 CompanyName = 'test Company'));
    }
    return testUsers;
  }
  //=============================================================//
  // Creates User given Profile (already queried)
  //============================================================//
  public static User createUser(Profile profile, String email, String lastName) {

    User testUser = new User();
    testUser = new User(alias = lastName, email=email,
                 emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', Region__c = 'EMEA',
                 username=email + Math.random(), IsActive=true,
                 CompanyName = 'test Company');

    return testUser;
  }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static BU_Relationship__c createBURelationship(Id accountId){
      BU_Relationship__c bu = new BU_Relationship__c();
      bu.Account__c = accountId;
      return bu;
   }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static BU_Relationship__c insertBURelationship(Id accountId){
        BU_Relationship__c bu = createBURelationship(accountId);
        insert bu;
    return bu;
   }

  //=============================================================//
  //Create Product2
  //============================================================//
  public static User insertUser(String profileName){
        User user = createUser(profileName);
        insert user;
    return user;
   }

  //=============================================================//
  //Creates Custom setting Global_Settings__c
  //============================================================//
  public static Global_Settings__c insertGlobalSettings(){
    Global_Settings__c setting = new Global_Settings__c();
    setting.Name = Constants.GLOBAL_SETTING;
    setting.Account_Team_Member_Job_Last_Run__c = System.now();
    setting.Opp_Renewal_Probability__c = 30;
    setting.Opp_Closed_Lost_Stagename__c = Constants.OPPTY_CLOSED_LOST;
    setting.Opp_Renewal_Name_Format__c = 'Renewal - ####';
    setting.Opp_Renewal_StageName__c = Constants.OPPTY_STAGE_3;
    insert setting;
    return setting;
  }

  //=============================================================//
  //Creates Custom setting IsDataAdmin__c
  //============================================================//
  public static IsDataAdmin__c insertIsDataAdmin(boolean isActive){
    IsDataAdmin__c setting = new IsDataAdmin__c();
    setting.IsDataAdmin__c = isActive;
    insert setting;
    return setting;
  }

  //=============================================================//
  //Creates Custom setting TriggerSettings__c
  //============================================================//
  public static TriggerSettings__c insertTriggerSettings(String triggerName){
    TriggerSettings__c setting;
    Map<String, TriggerSettings__c> mcs = TriggerSettings__c.getAll();
    if(mcs.containsKey(triggerName)){
      setting = mcs.get(triggerName);
    }else{
      setting = new TriggerSettings__c(Name = triggerName);
      insert setting;
    }
    setting.IsActive__c = true;

    return setting;
  }

  //=============================================================//
  //Generate Random Number
  //============================================================//
  public static double randomNumber() {
    return Math.random();
  }
  
  //=============================================================//
  //Creates Billing Product
  //============================================================//
  public static Billing_Product__c insertBillingProduct(){
    return createBillingProduct(true);
  }

  //=============================================================//
  //Creates Billing Product
  //============================================================//
  public static Billing_Product__c createBillingProduct(Boolean isInsert){
    Billing_Product__c billingProd = new Billing_Product__c(BP_External_Id__c='extID'+Math.random());
    if(isInsert){
      insert billingProd;
    }
    return billingProd;
  }
  
  //============================================================//
  //Insert Order__c
  //============================================================//
  public static Order__c insertOrder (Boolean insertOrder, String accntId, String contactId,
                                      String oppId) {
    Order__c ordr = new Order__c (Name='test Order', Contract_Start_Date__c = Date.Today(),
                           Locked__c = false,  Type__c = 'New', Account__c = accntId,
                           Contact__c = contactId, Opportunity__c = oppId, Close_Date__c = Date.Today()+30,
                           Contract_Number__c = '1234test',Transactional_Sale__c = false);
    if (insertOrder) {
      insert ordr;
    }
    return ordr;
    }
  // T-268982: Updated the method name
  //============================================================//
  //Insert Order_Line_Item__c
  //============================================================//
  public static Order_Line_Item__c insertOrderLineItems (Boolean isInsert, String orderId, String billProdId) {
    Order_Line_Item__c oli = new Order_Line_Item__c (Start_Date__c = Date.Today(),
                                 End_Date__c = Date.Today()+30,
                                 Total__c = 1111, Type_of_Sale__c = 'Ad-Hoc', Quantity__c = 5,
                                 Order__c = orderId, Billing_Product__c = billProdId);
    if (isInsert) {
      insert oli;
    }
    return oli;
  }

  
  //=============================================================//
  //inserts Contract
  //============================================================//
  public static Contract__c insertContract(boolean isInsert, String accountId, String contractType, String status ){
    Contract__c contract = new Contract__c(Account__c = accountId , Contract_Name__c = 'Test Contract' ,
                               Contract_Type__c = contractType , Contract_Effective_Date__c = System.today() , 
                               Status__c = status );
    if (isInsert) {
      insert contract;
    }
    return contract;                             
  }
  
  
  //=============================================================//
  //Creates Address
  //============================================================//
  public static Address__c insertAddress(Boolean isInsert){
    Address__c address = new Address__c(Address_1__c = ''+Math.random()+Math.random(), Address_2__c = 'add2'+Datetime.now(),
                                        Address_3__c = 'add3'+Datetime.now(), Address_4__c = 'add4'+Datetime.now(),
                                        City__c = 'Sydney', Country__c = 'Australia',
                                        Validation_Status__c = 'true', EDQ_Integration_Id__c = String.valueOf(Math.random()));
    if(isInsert) {
      insert address;
    }
    return address;
  }



  //=============================================================//
  //Creates Address Merge Request
  //============================================================//
  public static Address_Merge_Request__c insertAddressMergeRequest(Boolean isInsert,
                                                                    String masterId, String slaveId){
    Address_Merge_Request__c addressMergeRequest = new Address_Merge_Request__c(
                                                       Master_Address_SFDC_Id__c = ''+Datetime.now(),
                                                       Master_Address__c = masterId,
                                                       Slave_Address__c = slaveId);
    if(isInsert) {
      insert addressMergeRequest;
    }
    return addressMergeRequest;
  }

  //=============================================================//
  //Create Account Address
  //============================================================//
  public static Account_Address__c insertAccountAddress (Boolean isInsert, String idParentAddress,
                                                         String idParentAccount) {
      Account_Address__c accAddress = new Account_Address__c();
        accAddress.Address__c = idParentAddress;
        accAddress.Account__c = idParentAccount;
        accAddress.Address_Type__c = Constants.ADDRESS_TYPE_REGISTERED;
        /*accAddress.Primary_Billing__c = true;
        accAddress.Primary_Shipping__c = true;NLG Mar27, field to be deleted*/
    if(isInsert) {
      insert accAddress;
    }
    return accAddress;
  }
  //=============================================================//
  //Create Contact Address
  //============================================================//
  public static Contact_Address__c insertContactAddress (Boolean isInsert, String idParentAddress,
                                                          String idParentContact) {
      Contact_Address__c conAddress = new Contact_Address__c();
        conAddress.Address__c = idParentAddress;
        conAddress.Contact__c = idParentContact;
        conAddress.Address_Type__c = Constants.ADDRESS_TYPE_REGISTERED;
        //conAddress.EDQ_Integration_Id__c = 'E' + Math.random(); I-135920 Remove field
        /*conAddress.Primary_Billing__c = true;
        conAddress.Primary_Shipping__c = true;NLG Mar27, field to be deleted*/
    if(isInsert) {
      insert conAddress;
    }
    return conAddress;
  }
  //============================================================//
  //Insert OpportunityContactRole as primay contact on opportunity
  //============================================================//
   public static OpportunityContactRole insertOpportunityCR (Boolean isInsert, String cntctId, String oppId) {
    OpportunityContactRole ocr = new OpportunityContactRole (ContactId = cntctId, IsPrimary = true,
                                                             OpportunityId = oppId);
    if (isInsert) {
      insert ocr;
    }
    return ocr;
  }

  public static Task createTask(String whatId, String typeValue, String status) {
    return new Task(WhatId = whatId, Outcomes__c = typeValue, Status = status);
  }

  public static List<Task> createOpptyTasks(String oppId, Boolean performInsert) {
    List<Task> tasks = new List<Task>();
    tasks.add(Test_Utils.createTask(oppId, Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED, Constants.STATUS_COMPLETED));
    tasks.add(Test_Utils.createTask(oppId, Constants.ACTIVITY_TYPE_SIGNED_CONTRACT, Constants.STATUS_COMPLETED));
    tasks.add(Test_Utils.createTask(oppId, Constants.ACTIVITY_TYPE_QUOTE_DELIVERED, Constants.STATUS_COMPLETED));
    if (performInsert) {
      insert tasks;
    }
    return tasks;
  }

  //================================================================//
  // Create an AccountTeamMember for given accountId
  //================================================================//
  public static AccountTeamMember createAccountTeamMembers (String accountId, String userId, Boolean isInsert) {
    AccountTeamMember atm = new AccountTeamMember(AccountId = accountId, UserId = userId);
    atm.TeamMemberRole = 'Sales Rep';
    if (isInsert) {
      insert atm;
    }
    return atm;
  }

  //================================================================//
  // Create an AccountTeamMember for given accountId
  //================================================================//
  public static AccountShare createAccountShare (String accountId, String userId, Boolean isInsert) {
    AccountShare newShare = new AccountShare(AccountId = accountId, UserOrGroupId = userId);
    newShare.AccountAccessLevel = 'Edit';
    newShare.CaseAccessLevel = 'Edit';
    //newShare.ContactAccessLevel = 'Edit'; NLG Mar 27 '14 commenting because ContactAccessLevel is now "Controlled by Parent"
    newShare.OpportunityAccessLevel = 'Edit';

    if (isInsert) {
      insert newShare;
    }
    return newShare;
  }

  //================================================================//
  // Create an Event given a WhoId and WhatId
  //================================================================//
  public static Event createEvent(String whoId, String whatId) {
    return new Event(StartDateTime=Datetime.now(), DurationInMinutes = 60, WhoId = whoId, WhatId = whatId);
  }

  //================================================================//
  // Create & insert an Event given a WhoId and WhatId
  //================================================================//
  public static Event insertEvent(String whoId, String whatId) {
    Event evt = createEvent(whoId, whatId);
    insert evt;
    return evt;
  }

  //================================================================//
  // Create a Task given a WhoId and WhatId
  //================================================================//
  public static Task createTask(String whoId, String whatId) {
    return new Task(ActivityDate=Date.today(), WhoId = whoId, WhatId = whatId);
  }

  //================================================================//
  // Create & insert a Task given a WhoId and WhatId
  //================================================================//
  public static Task insertTask(String whoId, String whatId) {
    Task task = createTask(whoId, whatId);
    insert task;
    return task;
  }

  //================================================================//
  // Create & return a Order object
  //================================================================//
  public static Order__c createOrder(){
    Order__c order = new Order__c();
    return order;
  }

   //================================================================//
  // Create & return a OpportunitySplit object
  //================================================================//
  public static OpportunitySplit createOppSplit(Opportunity opp){
    OpportunitySplit oppSplit = new OpportunitySplit();
    oppSplit.OpportunityId = opp.Id;
    return oppSplit;
  }

  //================================================================//
  // Experian Spain - Create & return a ESDEL_Delivery_Project__c object
  //================================================================//
  public static ESDEL_Delivery_Project__c insertDeliveryProject (Boolean isInsert, String projectName,
                                                          String idAccount, string idContact, string billingOrderId) {
    ESDEL_Delivery_Project__c deliveryProject = new ESDEL_Delivery_Project__c(
                                                    Name = projectName,
                                                                            ESDEL_Account__c = idAccount,
                                                                            ESDEL_Billing_Order_Id__c = billingOrderId,
                                                                            ESDEL_Primary_Contact__c = idContact
                                                  );
    if(isInsert) {
      insert deliveryProject;
    }
    return deliveryProject;
  }

  //================================================================//
  //Experian Spain - Create & return a Case object
  //================================================================//
  public static Case insertCase (Boolean isInsert, String deliveryProjectId,
                                    String idAccount, string billingOrderId) {
    Case newCase = new Case(
                            AccountId = idAccount,
                            ESDEL_Billing_Order_Line_Id__c = billingOrderId,
                            ESDEL_Project__c = deliveryProjectId
                          );
    if(isInsert) {
      insert newCase;
    }
    return newCase;
  }

  //================================================================//
  //Experian Spain - Create & return a ESDEL_Timecard__c object
  //================================================================//
  public static ESDEL_Timecard__c insertTimecard(Boolean isInsert, string idCase, integer minutesWorked){
    ESDEL_Timecard__c newTimecard = new ESDEL_Timecard__c(
                                     ESDEL_Case__c = idCase,
                                     ESDEL_Minutes_Worked__c = minutesWorked
                                     );
    if(isInsert) {
      insert newTimecard;
    }
    return newTimecard;
  }

  //================================================================//
  //Experian Spain - Create & return a ESDEL_Timecard__c object
  //================================================================//
  public static ESDEL_Timecard__c insertTimecard(Boolean isInsert, string idCase, integer minutesWorked, ID projectId, ID delveryLineId){
    ESDEL_Timecard__c newTimecard = new ESDEL_Timecard__c(
                                     ESDEL_Case__c = idCase,
                                     ESDEL_Minutes_Worked__c = minutesWorked
                                     );
    if(isInsert) {
      insert newTimecard;
    }
    return newTimecard;
  }

  //================================================================//
  //Experian Sales Academy - Create & return a Opportunity_Plan__c object
  //================================================================//
  public static Opportunity_Plan__c insertOpportunityPlan(Boolean isInsert, ID idOpportunity ){
    Opportunity_Plan__c oppPlan = new Opportunity_Plan__c(
                                    Opportunity_Name__c = idOpportunity,
                                    Opportunity_Expected_Close_Date__c = System.today().addDays(15),
                                    CurrencyIsoCode = 'USD'
                                  );
    if(isInsert){
        insert oppPlan;
    }
    return oppPlan;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a OpportunityTeamMember object
  //================================================================//
  public static OpportunityTeamMember insertOpportunityTeamMember(Boolean isInsert, string idOpportunity, string idUser, string role){
    OpportunityTeamMember oppTeamMember = new OpportunityTeamMember(
                                    UserId = idUser,
                                    OpportunityId = idOpportunity,
                                    TeamMemberRole = role
                                  );
    if(isInsert){
      insert oppTeamMember;
    }
    return oppTeamMember;
  }
  
    // Create Opportunity Plan contact record for specified  Opportunity_Plan__c record, also adds a new contact and set it as reports to contact.
  public static Opportunity_Plan_Contact__c createOpportunityPlanContact(Opportunity_Plan__c oppPlan){

    Contact con = new Contact();
    con.FirstName = 'Test';
    con.LastName='Contact';
    insert con;

    Contact con1 = new Contact();
    con1.FirstName = 'Testing';
    con1.LastName='Contact';
    insert con1;

    Opportunity_Plan_Contact__c opp = new Opportunity_Plan_Contact__c();
      opp.Business_Goal_1__c = 'Test';
      opp.Decision_Criteria_1__c = 'Test';
      opp.Personal_Goal_1__c = 'Test';
      opp.Opportunity_Plan__c = oppPlan.Id;
      opp.Role__c = 'Credit Risk Manager';
      opp.Contact__c = con.Id;
    insert opp;

    Opportunity_Plan_Contact__c opp1 = new Opportunity_Plan_Contact__c();
      opp1.Business_Goal_1__c = 'Test';
      opp1.Decision_Criteria_1__c = 'Test';
      opp1.Personal_Goal_1__c = 'Test';
      opp1.Opportunity_Plan__c = oppPlan.Id;
      opp1.Reports_to__c = opp.Id;
      opp1.Role__c = 'Purchasing Manager';
      opp1.Contact__c = con1.Id;
    insert opp1;

    return opp;
  }

  // Create Opportunity Plan contact record for specified  Opportunity_Plan__c record, also adds a new contact and set it as reports to contact.
  public static Opportunity_Plan_Contact__c createOpportunityPlanContact(Opportunity_Plan__c oppPlan,Contact con){
    Opportunity_Plan_Contact__c opp1 = new Opportunity_Plan_Contact__c();
      opp1.Business_Goal_1__c = 'Test';
      opp1.Decision_Criteria_1__c = 'Test';
      opp1.Personal_Goal_1__c = 'Test';
      opp1.Opportunity_Plan__c = oppPlan.Id;
      opp1.Role__c = 'Purchasing Manager';
      opp1.Contact__c = con.Id;
      return opp1;
  }

  // Create Plan Contact Relationship between specified Opportunity_Plan_Contact__c contacts and specified relation.
  public static Plan_Contact_Relationship__c createPlanContactRelationship(Boolean isInsert,Opportunity_Plan_Contact__c con1,Opportunity_Plan_Contact__c con2,String relation){

    Plan_Contact_Relationship__c opp = new Plan_Contact_Relationship__c();
    opp.Contact_1__c = con1.Id;
    opp.Contact_2__c = con2.Id;
    opp.Relationship__c = relation;
    
    if(isInsert){
      insert opp;
    }

    return opp;
  }


  // Create Plan Contact Relationship between specified Opportunity_Plan_Contact__c contacts and specified relation.
  public static Plan_Contact_Relationship__c createPlanContactRelationship(Opportunity_Plan_Contact__c con1,Opportunity_Plan_Contact__c con2,String relation){

    Plan_Contact_Relationship__c opp = new Plan_Contact_Relationship__c();
      opp.Contact_1__c = con1.Id;
      opp.Contact_2__c = con2.Id;
      opp.Relationship__c = relation;
    insert opp;

    return opp;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan__c object
  //================================================================//
  public static Account_Plan__c insertAccountPlan(Boolean isInsert, string idAccount){
    Account_Plan__c accountPlan = new Account_Plan__c(
                                    Account__c = idAccount
                                  );
    if(isInsert){
        insert accountPlan;
    }
    return accountPlan;
  }

  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan_Team__c object
  //================================================================//
  public static Account_Plan_Team__c insertAccountPlanTeam(boolean isInsert, string idAccountPlan, string idUser){
    Account_Plan_Team__c accountPlanTeam = new Account_Plan_Team__c(
                                                   Account_Plan__c = idAccountPlan,
                                                   User__c = idUser
                                               );
   if(isInsert){
    insert accountPlanTeam;
   }
   return accountPlanTeam;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan_Penetration__c object
  //================================================================//
  public static Account_Plan_Penetration__c insertAccountPlanPenetration(Boolean isInsert, string idAccountPlan){
    Account_Plan_Penetration__c accountPP = new Account_Plan_Penetration__c(Account_Plan__c = idAccountPlan,
                                       Account_Business_Unit__c = 'test BU', Capability__c='Application Processing',
                                       Penetration__c='H', Annual_Revenue__c=111);
    if(isInsert){
        insert accountPP;
    }
    return accountPP;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a AccountTeamMember object
  //================================================================//
  public static AccountTeamMember insertAccountTeamMember(Boolean isInsert, string idAccount, string idUser, string role){
    AccountTeamMember accTeamMember = createAccountTeamMembers(idAccount, idUser, false);
    accTeamMember.TeamMemberRole = role;

    if(isInsert){
      insert accTeamMember;
    }
    return accTeamMember;
  }

  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan_SWOT__c object
  //================================================================//
  public static Account_Plan_SWOT__c insertAccountPlanSwot(Boolean isInsert, string idAccountPlan){
    Account_Plan_SWOT__c accountPlanSwot = new Account_Plan_SWOT__c(
                                             Account_Plan__c = idAccountPlan
                                            );
    if(isInsert){
      insert accountPlanSwot;
    }
    return accountPlanSwot;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan_Opportunity__c object
  //================================================================//
  public static Account_Plan_Opportunity__c insertAccountPlanOpp(Boolean isInsert, string idAccountPlan, string idOpportunity){
    Account_Plan_Opportunity__c accountPlanOpp = new Account_Plan_Opportunity__c(
                                             Account_Plan__c = idAccountPlan,
                                             Opportunity__c = idOpportunity
                                            );
    if(isInsert){
      insert accountPlanOpp;
    }
    return accountPlanOpp;
  }
  //================================================================//
  //Experian Sales Academy - Create & return a Account_Plan_Opportunity_SWOT__c object
  //================================================================//
  public static Account_Plan_Opportunity_SWOT__c insertAccountPlanOppSwot(Boolean isInsert, string idAccountPlanOpp, string idAccountPlanSwot){
    Account_Plan_Opportunity_SWOT__c accountPlanOppSwot = new Account_Plan_Opportunity_SWOT__c(
                                             Account_Plan_Opportunity__c = idAccountPlanOpp,
                                             Account_Plan_SWOT__c = idAccountPlanSwot
                                            );
    if(isInsert){
      insert accountPlanOppSwot;
    }
    return accountPlanOppSwot;

  }
  
  //================================================================//
  //Experian Sales Academy - Create & return a Opp Plan Score Calc object
  //================================================================//
  
  public static Opp_Plan_Score_Calc__c insertOppPlanScoreCalc(String name, boolean isInsert){
        Opp_Plan_Score_Calc__c opsc = new Opp_Plan_Score_Calc__c(Name = name,
                                                                 Expected_Score__c = 25.00,
                                                                 CurrencyIsoCode = 'USD');
       if(isInsert){
        insert opsc;
        }
        return  opsc;
  
  }
  //================================================================//
  //Experian Sales Academy - Create & return a Opp Plan Scor Sub Calc object
  //================================================================//
  public static Opp_Plan_Score_Sub_Calc__c insertOppPlanScoreSubCalc(ID parentId, boolean isInsert){
        Opp_Plan_Score_Sub_Calc__c opssc = new Opp_Plan_Score_Sub_Calc__c(Name = 'testing',
                                                                 Opp_Plan_Score_Calc__c = parentId,
                                                                 Object_API_Name__c = 'Opportunity_Plan_Contact__c');
      if(isInsert){
          insert opssc;
      }                                                          
     return opssc;                                       
      
  
  }
  //================================================================//
  //Experian Sales Academy - Correcting Exception for Opp Plan Trigger
  //Corrects CANNOT_UPDATE_INSERT_ACTIVATE_ENTITY, For after Insert 
  //================================================================//
  public static void madeupAfterInsert(){
       List<Opp_Plan_Score_Calc__c> opsc = new List<Opp_Plan_Score_Calc__c>();
       List<String> namelist = new List<String>{'Information Scoring','Qualification Scoring',
                            'Buying Centre','Competition Scoring','Summary Position',
                            'Solution at a Glance','Joint Action Plan','Value Proposition','Action Plan'};
       For(String name : namelist) {
       Opp_Plan_Score_Calc__c op1 = Test_Utils.insertOppPlanScoreCalc(name,true);
       Opp_Plan_Score_Sub_Calc__c op2 = Test_Utils.insertOppPlanScoreSubCalc(op1.Id,true);
      
       }
  }
  
  
  //===================================================================//  
  //===================================================================//
  //                    Experian PHASE 2 
  //===================================================================//
  //===================================================================//  
  
  
  
  //================================================================//
  //Experian Phase 2 - Create & return Project__c
  //================================================================//
  public static Project__c insertProject(Boolean isInsert){
    Project__c project = new Project__c(Name = 'Test Project', Type__c = 'Internal Delivery', Business_Unit__c = 'TBD', 
                                        Status__c = 'Unassigned'     
                                            );
    if(isInsert){
      insert project;
    }
    return project;

  }
  
  //================================================================//
  // create and return Deployment__c
  //================================================================//
  public static Deployment__c insertDeployment(Boolean isInsert, Id AccountId, Boolean active ) {
    Deployment__c deployment = new Deployment__c( Name = 'Test Deployment', Account__c = AccountId,
                                                    Active__c  = active, Description__c = 'Test Descrption' );
    if (isInsert) {
      insert deployment;
    }
    return deployment;

  }
  
  //================================================================//
  //Experian Phase 2 - Create & return Delivery_Line__c
  //================================================================//
  public static Delivery_Line__c insertDeliveryLine(Boolean isInsert, Id projectId){
    Delivery_Line__c deliveryLine = new Delivery_Line__c(Name = 'Test Delivery Line', Project__c = projectId,
                                                         Status__c = 'Unassigned'     
                                            );
    if(isInsert){
      insert deliveryLine;
    }
    return deliveryLine;

  }
  
  //===================================================================//
  //Experian Phase 2 - Create & return Delivery_Template_Header
  //===================================================================//
  public static Delivery_Template_Header__c insertDeliveryTemplateHeader (Boolean isInsert) {
    Delivery_Template_Header__c dth = new Delivery_Template_Header__c(
                                      Name = 'TestDTH'+String.valueOf(Datetime.now()));
    
    if (isInsert) {
      insert dth;
    }
    
    return dth;
  }

  //===================================================================//
  //Experian PHASE 2 - Create & return Delivery_Template_Line
  //===================================================================//
  public static Delivery_Template_Line__c insertDeliveryTemplateLine (
                                                     Boolean isInsert, String dthID) {
    Delivery_Template_Line__c dtl = new Delivery_Template_Line__c(
                                      Name = 'TestDTL'+String.valueOf(Datetime.now()));
    dtl.Delivery_Template_Header__c = dthID;
    dtl.Sequence__c = 1;
    
    if (isInsert) {
      insert dtl;
    }
    
    return dtl;
  }
  //===================================================================//
  //Experian PHASE 2 - Create & return Case
  //===================================================================//
  public static Case insertCase (Boolean isInsert, String idAccount) {
    Case newCase = new Case(AccountId = idAccount);
    if(isInsert) {
      insert newCase;
    }
    return newCase;
  }
  
  //===================================================================//
  //Experian - Create Royalty and Return
  //===================================================================//
  public static Royalty__c insertRoyalty (Boolean isInsert, String oppLineRefNo){
    Royalty__c royalty = new Royalty__c();
    royalty.Line_Item_Reference_Number__c = oppLineRefNo;
    if(isInsert) {
      insert royalty;
    }
    return royalty;
  }


  //================================================================//
  //Experian - Create OpportunityContactRole and Return
  //================================================================//
  public static List<OpportunityContactRole> insertEDQOpportunityContactRoles(String oppId, String contactId) {
    List<OpportunityContactRole> oppRoles = new List<OpportunityContactRole>();
    OpportunityContactRole oppContactRole1 = insertOpportunityContactRole(false, oppId, contactId, Constants.DECIDER, true);
    OpportunityContactRole oppContactRole2 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, false);                                     
    OpportunityContactRole oppContactRole3 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_RENEWAL, false);
    OpportunityContactRole oppContactRole4 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_UPDATE, false);
    OpportunityContactRole oppContactRole5 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);
    OpportunityContactRole oppContactRole6 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_SHIPTO, false);
    OpportunityContactRole oppContactRole7 = insertOpportunityContactRole(false, oppId, contactId, Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL, false);

    oppRoles.add(oppContactRole1);
    oppRoles.add(oppContactRole2);
    oppRoles.add(oppContactRole3);
    oppRoles.add(oppContactRole4);
    oppRoles.add(oppContactRole5);
    oppRoles.add(oppContactRole6);
    oppRoles.add(oppContactRole7);

    insert oppRoles;

    return oppRoles;
  }

  public static OpportunityContactRole insertOpportunityContactRole(Boolean isInsert, string idOpportunity, string IdContact, string role, Boolean isPrimary){
    OpportunityContactRole oppConRole = new OpportunityContactRole(
                                    ContactId = IdContact,
                                    OpportunityId = idOpportunity,
                                    Role = role,
                                    IsPrimary = isPrimary
                                  );
    if(isInsert){
      insert oppConRole;
    }
    return oppConRole;
  }

  //================================================================//
  //Experian Phase 2- Create Asset and Return
  //================================================================//
  public static Asset insertAsset(Boolean isInsert, string idAccount){
    Asset asset = new Asset(
                              Name = 'Test Asset',
                              AccountId = idAccount,
                              Release_Version__c = 'Test Version1',
                              Operating_System__c = 'PC+',
                              Renewal_Discount__c = 5,
                              Data_Usage__c = 'N/A',
                              Price = 1.00,
                              Users_To__c = 2);
    if(isInsert){
      insert asset;
    }
    return asset;
  }
  
  //================================================================//
  //Experian Phase 2- Create Group and Return
  //================================================================//
  public static Group createGroup(Boolean isInsert){
    Group grp = new Group();
    grp.Name = 'Test Group'+ Math.random();
    grp.Type = 'Queue';
    if(isInsert){
      insert grp;
    }
    return grp;
  }

  //================================================================//
  //Experian Phase 2- Create User Share
  //================================================================//  
  public static UserShare createUserShare(Boolean isInsert, Id userId, Id userOrGroupId){
    UserShare userShare = new UserShare();
    userShare.UserId = userId;
    userShare.UserOrGroupId = userOrGroupId;
    userShare.UserAccessLevel = 'Edit';
    if(isInsert){
        insert userShare;
    }
    return userShare;
  }

  //=============================================================//
  // Creates EDQ User given Profile (already queried)
  //============================================================//
  public static User createEDQUser(Profile profile, String email, String lastName) {

    User testUser = new User();
    String bu = edqSetting.User_Business_Unit__c;
    testUser = new User(alias = lastName, email=email,
                 emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles',
                 username=email + Math.random(), IsActive=true,
                 CompanyName = 'test Company', Global_Business_Line__c = 'Credit Services',
                 Business_Line__c = 'APAC Credit Services', Business_Unit__c = bu,
                 Office_Location__c = 'Amsterdam',Department__c = 5, Region__c = 'EMEA',
                 Payroll__c = 100);

    return testUser;
  }

  //=============================================================//
  // Creates EDQ User given Profile (already queried)
  //============================================================//
  public static User createCPQUser(Profile profile, String email, String lastName) {

    User testUser = new User();
    String bu = edqSetting.User_Business_Unit__c;
    testUser = new User(alias = lastName, email=email,
                 emailencodingkey='UTF-8', firstName = 'Test User', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles',
                 username=email + Math.random(), IsActive=true,
                 CompanyName = 'test Company', Global_Business_Line__c = 'Credit Services',
                 Business_Line__c = 'APAC Credit Services', Business_Unit__c = bu,
                 Office_Location__c = 'Amsterdam',Department__c = 5, Region__c = 'EMEA',
                 Payroll__c = 100, CPQ_User__c = true, CPQ_User_Type__c = 'CFO', Country__c = 'United States of America');

    return testUser;
  }
  
  //=============================================================//
  // Creates Product Master
  //============================================================//
  public static Product_Master__c createProductMaster(Boolean isInsert){
    Product_Master__c productMaster = new Product_Master__c();
    productMaster.Name = 'Test Product Master';
    if(isInsert){
        insert productMaster;
    }
    return productMaster;
  }
  
  //=============================================================//
  // Creates Product Country
  //============================================================//
  public static Product_Country__c createProductCountry(Boolean isInsert, Id countryId){
      Product_Country__c productCountry = new Product_Country__c(Country__c = countryId);
      if(isInsert){
        insert productCountry;
      }
      return productCountry;
  }
  
  //=============================================================//
  // Creates Product Region
  //============================================================//
  public static Product_Region__c createProductRegion(Boolean isInsert, Id regionId){
    Product_Region__c productRegion = new Product_Region__c(Region__c = regionId);
    if(isInsert){
      insert productRegion;
    }
    return productRegion;
  }
  
  //=============================================================//
  // Creates Country
  //============================================================//
  public static Country__c createCountry(Boolean isInsert){
    Country__c country = new Country__c(Name = 'United States');
    if(isInsert){
      insert country;
    }
    return country;
  }
  
  //=============================================================//
  // Creates Region
  //============================================================//
  public static Region__c createRegion(Boolean isInsert){
    Region__c region = new Region__c(Name = 'North America');
    if(isInsert){
      insert region;
    }
    return region;
  }
  
  //============================================================//
  // Create Assignment_Team__c
  //===========================================================//
  public static Assignment_Team__c insertAssignmentTeam(Boolean isInsert, Id userId){
    Assignment_Team__c assgnTeam = new Assignment_Team__c();
    assgnTeam.Account_Executive__c = userId;
    assgnTeam.Primary_Team__c = true;
    if(isInsert){
      insert assgnTeam;
    }
    return assgnTeam;  
  }
  
  //============================================================//
  // Create Assignment_Team_Member_c
  //===========================================================//
  public static Assignment_Team_Member__c insertAssignmentTeamMember(Boolean isInsert, Id assgnTeamId, Id userId, String memRole){
    Assignment_Team_Member__c assgnTeamMem = new Assignment_Team_Member__c();
    assgnTeamMem.Assignment_Team__c = assgnTeamId;
    assgnTeamMem.Assignment_Team_Role__c = memRole;
    assgnTeamMem.IsActive__c = true;
    assgnTeamMem.User__c = userId;
    if(isInsert){
      insert assgnTeamMem;
    }
    return assgnTeamMem;  
  }
  

  //============================================================//
  // Create Account_Assignment_Team__c
  //===========================================================//
  public static Account_Assignment_Team__c insertAccAssignmentTeam(Boolean isInsert, Id assgnTeamId, Id accId){
    Account_Assignment_Team__c accAssgnTeam = new Account_Assignment_Team__c();
    accAssgnTeam.Account__c = accId;
    accAssgnTeam.Assignment_Team__c =  assgnTeamId;
    if(isInsert){
      insert accAssgnTeam;
    }
    return accAssgnTeam;  
  }
  //==========================================================//
  // Create Hierarchy__c records
  //=========================================================//
  public static Hierarchy__c insertHierarchy(Boolean isInsert, Id parentId, String value, String hierarchyType){
    Hierarchy__c hierarchy = new Hierarchy__c();
    hierarchy.Parent__c = parentId;
    hierarchy.Value__c = value;
    hierarchy.Type__c = hierarchyType;
    if (isInsert){
    	insert hierarchy;
    }
    return hierarchy;
  }
  //=========================================================//
  // Create Account_Segment__c
  //========================================================//
  public static Account_Segment__c insertAccountSegment(Boolean isInsert, Id accountId, Id hierarchyId, Id parAccSegId){
  	Account_Segment__c accSegment = new Account_Segment__c();
  	accSegment.CurrencyIsoCode = Constants.CURRENCY_USD;
  	accSegment.Account__c = accountId;
  	accSegment.Segment__c = hierarchyId;
  	//accSegment.Name = 'Test-Account Segment';
  	accSegment.Parent_Account_Segment__c = parAccSegId;
  	if (isInsert){
  		insert accSegment;
  	}
  	return accSegment;
  }

  //=========================================================//
  // Create Business_Process_Template__c
  //========================================================//
  public static Business_Process_Template__c insertBusinessProcessTemplate(Boolean isInsert, 
    String relatedTo, String businessUnit, String subBusinessUnit) {
   
    Business_Process_Template__c busProcTemplate = new Business_Process_Template__c();
    busProcTemplate.Related_To__c = relatedTo;
    busProcTemplate.Business_Unit__c = businessUnit;
    busProcTemplate.Sub_Business_Unit__c = subBusinessUnit;
    busProcTemplate.Name = 'Test';
    busProcTemplate.Description__c = 'Test';

    if (isInsert) {
      insert busProcTemplate;
    }
    return busProcTemplate;
  }

  //=========================================================//
  // Create Business_Process_Template_Item__c
  //========================================================//
  public static Business_Process_Template_Item__c insertBusinessProcessTemplateItem(Boolean isInsert, 
    Id businessProcessTemplateId, Decimal sequence) {
    
    Business_Process_Template_Item__c busProcTemplateItem = new Business_Process_Template_Item__c();
    busProcTemplateItem.Business_Process_Template__c = businessProcessTemplateId;
    busProcTemplateItem.Name = 'Test';
    busProcTemplateItem.Description__c = 'Test Description';
    busProcTemplateItem.Sequence__c = sequence;


    if (isInsert) {
      insert busProcTemplateItem;
    }
    return busProcTemplateItem;
  }


  //=========================================================//
  // Create Business_Process___c
  //========================================================//
  public static Business_Process__c insertBusinessProcess(Boolean isInsert, Id businessProcessTemplateId,
    Id caseId, Id membershipId, Id accountId, Id opportunityId) {

    Business_Process__c bp = new Business_Process__c();
    bp.Business_Process_Template__c = businessProcessTemplateId;
    if (caseId != null) {
      bp.Case__c = caseId;
    } else if (membershipId != null) {
      bp.Membership__c = membershipId;
    } else if (accountId != null) {
      bp.Account__c = accountId;
    } else if (opportunityId != null) {
      bp.Opportunity__c = opportunityId;
    } 

    if (isInsert) {
      insert bp;
    }

    return bp;
  }

  //=========================================================//
  // Create Business_Process_Item__c
  //========================================================//
  public static Business_Process_Item__c insertBusinessProcessItem(Boolean isInsert, Id businessProcessTemplateItemId) {

    Business_Process_Item__c bpi = new Business_Process_Item__c();
    bpi.Business_Process_Template_Item__c = businessProcessTemplateItemId;

    if (isInsert) {
      insert bpi;
    }

    return bpi;
  }


  //=========================================================//
  // Create Membership__c
  //========================================================//
  public static Membership__c insertMembership(Boolean isInsert, Id accountId) {

    Membership__c mem = new Membership__c();
    mem.Account__c = accountId;

    if (isInsert) {
      insert mem;
    }

    return mem;
  }
}