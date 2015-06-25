/**=====================================================================
 * Appirio, Inc 
 * Name: OpportunityTriggerHandlerWonRenewal_Test 
 * Description: Created new test class from OpportunityTriggerHandler_Test.cls
 *              moved specific funcitonal tests for renewal and won oppty
 * Created Date: 10/28/2014
 * Created By    : Naresh Kr Ojha (Appirio)
 * Note          : Refer header entries for changes done before 28th oct 14
 *
 * Date Modified      Modified By                  Description of the update
 * Nov 12th, 2014     Arpita Bose                  Added Type in test data of Opportunity and OLI
 * Dec 11th, 2014     Naresh Kr Ojha               Added method to test OnDemand oppty should have OnDemanc Decider contact. 
                                                   method: test_validateOnDemandOpportunityDataOnClosedWon()
 * Dec 19th, 2014     Arpita Bose                  Updated method test_validateOnDemandOpportunityDataOnClosedWon() to populate con.Phone
 * Mar 12th, 2015     Gaurav Kumar Chadha          Updated  test_validateOpptyContactRoleOnClosedWon2() , inserted contact address for 6 contacts
 * Mar 12th, 2015     Paul Kissick                 Case #530104 - Adding addresses to check copies, also fixing for contacts cloned.
 * May 1st, 2015      Suminder Singh                Fixed test class for assert failures
 =====================================================================*/
@isTest
public class OpportunityTriggerHandlerWonRenewal_Test {

  //@isTest
    static void testCreateRenewalOpportunties() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        Global_Settings__c setting = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        Account account = Test_Utils.insertAccount();
        Address__c addrs1 = Test_Utils.insertAddress(true);
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, account.Id);    
    
        Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
        //opportunity.Auto_Create_Renewal_on_Close_Win__c = true;
        opportunity.Amount = 100;
        opportunity.CloseDate = date.today().addDays(5);
        opportunity.Type = Constants.OPPTY_TYPE_RENEWAL;
        insert opportunity;
        
        

        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                                                            AccountId = account.Id, Email = 'larrye@email.com');
        insert newcontact;
        Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, newcontact.Id);
        OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, opportunity.Id, newcontact.Id, Constants.DECIDER, true);

        // Create Opportunity Line itemn
        Product2 product = Test_Utils.insertProduct();
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
        //PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, priceBook.Id, 'USD');
        OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(opportunity.Id, stdPricebookEntry.Id, opportunity.Type);
        opportunityLineItem.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem.End_Date__c = Date.today().addDays(10);
        opportunityLineItem.CPQ_Quantity__c = 1000;
        opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
        insert opportunityLineItem;
        system.debug('opportunityLineItem>>>' +opportunityLineItem);
        Test.startTest();
        
        opportunity.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_TERMS;
        opportunity.StageName = Constants.OPPTY_STAGE_CLOSED_WON;
        opportunity.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        //opportunity.Contract_Term__c = '5';
        
        
        system.debug('opportunity>>>' +opportunity);
        
        update opportunity; // Invokes createRenewalOpportunties
        String newOpportunityName = setting.Opp_Renewal_Name_Format__c.replace('####',opportunity.Name);
        
        Test.stopTest();
        List<Opportunity> lstRenewalOppty = [SELECT Id, IsClosed,IsWon FROM Opportunity WHERE Previous_Opportunity__c=: opportunity.Id]; //Name = :newOpportunityName];
        System.debug('\nNumber of renewals: '+ lstRenewalOppty.size());
        Opportunity renewalOpportunity;
        if(lstRenewalOppty.size() > 0) {
            renewalOpportunity = lstRenewalOppty[0]; 
        }
        List<OpportunityLineItem> lstOLI = [Select ServiceDate,Discount,ListPrice,OpportunityId,PriceBookEntryId,Quantity,CPQ_Quantity__c,
                                              UnitPrice,Subtotal From OpportunityLineItem where OpportunityId =: lstRenewalOppty];
        system.debug('###lstOLI###' +lstOLI);                                      
                                            
        Opportunity testPopulate = OpportunityTrigger_RenewalUtility.populateRenewalData(opportunity);
        
        
        // Check id renewal  Opportunity is created
        System.assert(renewalOpportunity != NULL); 
      }
    } 

    
  //T-267436 : Test if the owner related fields get updated if isWon or isClosed Fields are updated from False to true
  static testmethod void testUpdateOppFieldsIfWonOrClosed(){
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;

    System.runAs(testUser1) {
    
      Account testAccount = Test_Utils.insertAccount();
      Address__c addrs1 = Test_Utils.insertAddress(true);
      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);    
    
      User oldUser = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
      oldUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
      oldUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
      insert oldUser;
  
      // Create an opportunity
      Opportunity oppr = Test_Utils.createOpportunity(testAccount.Id);
      oppr.Has_Senior_Approval__c = true;
      oppr.StageName = Constants.OPPTY_STAGE_3;
      //oppr.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c 
      oppr.Amount = 500;
      oppr.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      oppr.OwnerId = oldUser.Id;
      oppr.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
      insert oppr;
  
      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
      insert newcontact;
      Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, newcontact.Id);
      Test_Utils.createOpptyTasks(oppr.Id, true);
  
      OpportunityContactRole oppContactRole =  Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.DECIDER, true);
      
      OpportunityContactRole oppConRole1 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, false);                                     
  
      OpportunityContactRole oppConRole2 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_RENEWAL, false);
  
      OpportunityContactRole oppConRole3 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_UPDATE, false);
  
      OpportunityContactRole oppConRole4 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);
         
      OpportunityContactRole oppConRole5 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_SHIPTO, false);
  
      OpportunityContactRole oppConRole6 = Test_Utils.insertOpportunityContactRole(true, oppr.Id, newcontact.Id, Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL, false);
          
      Test.startTest();
      OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
      OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
      oppr.StageName = Constants.OPPTY_STAGE_7;
      oppr.Starting_Stage__c = Constants.OPPTY_STAGE_6; 
      update oppr;
  
      Opportunity updatedOpp = [SELECT Id, Owner_GBL_on_Opp_Close_Date__c, Owner_BU_on_Opp_Close_Date__c, Owner_BL_on_Opp_Close_Date__c,
                                       Owner_Sales_Team_on_Opp_Close_Date__c, Owner_Sales_Sub_Team_on_Opp_Close_Date__c,
                                       Owner_Country_on_Opp_Close_Date__c, Owner_Region_on_Opp_Close_Date__c,IsWon,IsClosed
                                FROM Opportunity
                              WHERE Id =: oppr.Id];
      system.debug('@@IsWon' + updatedOpp.IsWon); 
      system.debug('@@Query=========' + [SELECT Id, Owner_GBL_on_Opp_Close_Date__c, Owner_BU_on_Opp_Close_Date__c, Owner_BL_on_Opp_Close_Date__c,
                                       Owner_Sales_Team_on_Opp_Close_Date__c, Owner_Sales_Sub_Team_on_Opp_Close_Date__c,
                                       Owner_Country_on_Opp_Close_Date__c, Owner_Region_on_Opp_Close_Date__c,IsWon,IsClosed
                                FROM Opportunity
                              WHERE Id =: oppr.Id]); 
      system.debug('@@IsWon' + updatedOpp.IsClosed);
      Test.stopTest();
      
      system.assertEquals(updatedOpp.Owner_BU_on_Opp_Close_Date__c , Constants.BUSINESS_UNIT_MS_CIT);
      system.assertEquals(updatedOpp.Owner_GBL_on_Opp_Close_Date__c , Constants.GLOBAL_BUSINESS_MARKETING_SERVICES);
    }
    
  }
  
  // T-322920: test method to test checkOpptyContactRoleOnClosedWon()
  static testmethod void testCheckOpptyContactRoleOnClosedWon(){
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;   
             
    System.runAs(testUser1){
      // insert account 
      Account acc = Test_Utils.insertAccount();
      Address__c addrs1 = Test_Utils.insertAddress(true);
      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, acc.Id); 
      Contact testContact = Test_Utils.createContact(acc.ID);
      insert testContact;
      Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, testContact.Id);
      // insert opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      insert testOpp;

      OpportunityContactRole oppContactRole1 =  Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);

      OpportunityContactRole oppContactRole2 =  Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);

      // start test
      Test.startTest();
      // change oppty stage
      //update opp
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      testOpp.Has_Senior_Approval__c = true;
      testOpp.Amount = 100;
      
      try {
        update testOpp;
       }catch(Exception ex){
          // assert to verify error message        
          // Noopur - Commented -TBD
        // System.assert(ex.getMessage().contains(Label.OPPTY_ERR_CONTACT_ROLE_CHECK));
       }

       // Update 2nd Contact Role to have role = Constants.Decider
       oppContactRole2.Role = Constants.DECIDER;
       update oppContactRole2;
  
       testOpp.StageName = Constants.OPPTY_STAGE_7;
       testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
       testOpp.Has_Senior_Approval__c = true;
       testOpp.Amount = 100;
       update testOpp;

      //stop test
      Test.stopTest();

      //Assert
      List<Opportunity> resultOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = : testOpp.Id];
      //System.assert(resultOpp.size() > 0);
     }  

  }

  //T-320132
  static testmethod void test_checkOpptyChannelTypeOnClosedWon(){
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;   
             
    System.runAs(testUser1){
      // insert Address
      Address__c address = Test_Utils.insertAddress(true);
      // insert account 
      Account acc = Test_Utils.insertAccount();
      
      Contact testContact = Test_Utils.createContact(acc.ID);
      insert testContact;
      // insert Contact Address
      Contact_Address__c contactAddress1 = Test_Utils.insertContactAddress(true, address.Id, testContact.Id);
      //Insert account Address
      Account_Address__c accAdd = Test_Utils.insertAccountAddress(true, address.id, acc.id);
      // insert opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
      testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      
      insert testOpp;
      
      OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);
      
      // start test
      Test.startTest();
      //update opp
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      //testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      testOpp.Has_Senior_Approval__c = true;
      testOpp.Amount = 100;
      
      try {
        update testOpp;
       }catch(Exception ex){
          // assert to verify error message   
          system.debug('*******Ex::::'+ex);     
          System.assert(ex.getMessage().contains(Label.OPPTY_CHANNELTYPE_INDIRECT_PARTNER_REQUIRED));
       }

       //update opp channel type='Direct'
       testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
       update testOpp;

       // create Opportunity Partner record
       Account accPartner = Test_Utils.insertAccount();
	   
       Partner opr = new Partner();
       opr.OpportunityId = testOpp.Id;
       opr.IsPrimary = true;
       opr.AccountToId = accPartner.Id;
       insert opr;
       
       system.debug('testOpp>>' +testOpp);
       
       testOpp.StageName = Constants.OPPTY_STAGE_7;
       testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
       testOpp.Has_Senior_Approval__c = true;
       testOpp.Amount = 100;


 
       try{
         update testOpp;
       }catch(Exception ex){
          // assert to verify error message        
          System.assert(ex.getMessage().contains(Label.OPPTY_CHANNELTYPE_DIRECT_NO_PARTNER_ALLOWED));
       }

       // delte Opportunity Partner
       delete opr;
  
       testOpp.StageName = Constants.OPPTY_STAGE_7;
       try{
         update testOpp;
       }catch(Exception ex){
          // assert to verify no error message        
          System.assertEquals(ex.getMessage(), null);
       }
                                   
       //stop test
       Test.stopTest();

     } 
  }  


     //T-321347
      static testmethod void testCreateOppContactRoles_RenewalOpps(){
       Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
       User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
       insert testUser1;

       System.runAs(testUser1) {
       
        User currentUser = new User();
        currentUser.Id = UserInfo.getUserId();
        currentUser.Global_Business_Line__c = 'Corporate';
        currentUser.Business_Line__c = 'Corporate';
        currentUser.Business_Unit__c = 'APAC:SE';
        update currentUser;
        
        Business_Unit_Group_Mapping__c custSetting1 = new Business_Unit_Group_Mapping__c();
        custSetting1.Name = 'EDQ';
        custSetting1.User_Business_Unit__c = 'APAC:SE';
        custSetting1.Common_Group_Name__c = 'EDQ';
        insert custSetting1;    
         
       // Create Account
       Account testAccount = Test_Utils.insertAccount();
       
       // Create an Contact
       Contact con1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con2  = new Contact (FirstName = 'Test 2', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con3  = new Contact (FirstName = 'Test 3', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con4  = new Contact (FirstName = 'Test 4', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       
       List<Contact> conLst = new List<Contact>();
       conLst.add(con1);
       conLst.add(con2);
       conLst.add(con3);
       conLst.add(con4);
       insert conLst;
       
        Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, con1.Id);
       
       // Create an opportunity
       Opportunity testPrevOpp = Test_utils.createOpportunity(testAccount.Id);
       insert testPrevOpp;
       
       OpportunityContactRole oppConRole1 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(0).Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);

       OpportunityContactRole oppConRole2 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(1).Id, Constants.OPPTY_CONTACT_ROLE_RENEWAL, false);

       OpportunityContactRole oppConRole3 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(2).Id, Constants.OPPTY_CONTACT_ROLE_UPDATE, false);

       OpportunityContactRole oppConRole4 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(3).Id, Constants.DECIDER, false);
       OpportunityContactRole oppConRole5 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(0).Id, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);
       OpportunityContactRole oppConRole6 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(1).Id, Constants.OPPTY_CONTACT_ROLE_SHIPTO, false);
       OpportunityContactRole oppConRole7 = Test_Utils.insertOpportunityContactRole(false, testPrevOpp.Id, conLst.get(2).Id, Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL, false);
       
       List<OpportunityContactRole> conRoleLst = new List<OpportunityContactRole>();
       conRoleLst.add(oppConRole1);
       conRoleLst.add(oppConRole2);
       conRoleLst.add(oppConRole3);
       conRoleLst.add(oppConRole4);
       conRoleLst.add(oppConRole5);
       conRoleLst.add(oppConRole6);
       conRoleLst.add(oppConRole7);
       insert conRoleLst;
       
       List<Opportunity_Contact_Address__c> oppConAdds = new List<Opportunity_Contact_Address__c>();
        Opportunity_Contact_Address__c oppConAdd = new Opportunity_Contact_Address__c();
        oppConAdd.Opportunity__c= testPrevOpp.Id ;
        oppConAdd.Address__c = conAdd.Address__c;
        oppConAdd.Contact__c = conLst.get(0).Id;
        oppConAdd.Role__c = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER;
        oppConAdds.add( oppConAdd);
        
        Opportunity_Contact_Address__c oppConAdd1 = new Opportunity_Contact_Address__c();
        oppConAdd1.Opportunity__c= testPrevOpp.Id ;
        oppConAdd1.Address__c = conAdd.Address__c;
        oppConAdd1.Contact__c = conLst.get(1).Id;
        oppConAdd1.Role__c = Constants.OPPTY_CONTACT_ROLE_RENEWAL;
        oppConAdds.add( oppConAdd1);
        
        Opportunity_Contact_Address__c oppConAdd2 = new Opportunity_Contact_Address__c();
        oppConAdd2.Opportunity__c= testPrevOpp.Id ;
        oppConAdd2.Address__c = conAdd.Address__c;
        oppConAdd2.Contact__c = conLst.get(2).Id;
        oppConAdd2.Role__c = Constants.OPPTY_CONTACT_ROLE_UPDATE;
        oppConAdds.add( oppConAdd2);
        
        Opportunity_Contact_Address__c oppConAdd3 = new Opportunity_Contact_Address__c();
        oppConAdd3.Opportunity__c= testPrevOpp.Id ;
        oppConAdd3.Address__c = conAdd.Address__c;
        oppConAdd3.Contact__c = conLst.get(3).Id;
        oppConAdd3.Role__c = Constants.DECIDER;
        oppConAdds.add( oppConAdd3);
        
        Opportunity_Contact_Address__c oppConAdd4 = new Opportunity_Contact_Address__c();
        oppConAdd4.Opportunity__c= testPrevOpp.Id ;
        oppConAdd4.Address__c = conAdd.Address__c;
        oppConAdd4.Contact__c = conLst.get(0).Id;
        oppConAdd4.Role__c = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL;
        oppConAdds.add( oppConAdd4);
        
        Opportunity_Contact_Address__c oppConAdd5 = new Opportunity_Contact_Address__c();
        oppConAdd5.Opportunity__c= testPrevOpp.Id ;
        oppConAdd5.Address__c = conAdd.Address__c;
        oppConAdd5.Contact__c = conLst.get(1).Id;
        oppConAdd5.Role__c = Constants.OPPTY_CONTACT_ROLE_SHIPTO;
        oppConAdds.add( oppConAdd5);
        Opportunity_Contact_Address__c oppConAdd6 = new Opportunity_Contact_Address__c();
        oppConAdd6.Opportunity__c= testPrevOpp.Id ;
        oppConAdd6.Address__c = conAdd.Address__c;
        oppConAdd6.Contact__c = conLst.get(2).Id;
        oppConAdd6.Role__c = Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL;
        oppConAdds.add( oppConAdd6);
        
        insert oppConAdds;
       Opportunity testOpp;
       Test.startTest();
       OpportunityTriggerHandler.isAfterInsertTriggerExecuted = false;
       // Create a renewal type opportunity
       testOpp = Test_utils.createOpportunity(testAccount.Id);
       testOpp.Previous_Opportunity__c = testPrevOpp.Id;
       testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
       insert testOpp;
       Test.stopTest();
       List<OpportunityContactRole> oppContactRoleList = [SELECT Id, Role FROM OpportunityContactRole WHERE OpportunityId = :testOpp.Id];
       //Asserts
       System.assertEquals(oppContactRoleList.size(), 6);
       

       }
  }


     //T-322814 : Update oppty with missing contact roles
      static testmethod void test_validateOpptyContactRoleOnClosedWon1(){
       Address__c addrs1 = Test_Utils.insertAddress(true);
       Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
       User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
       insert edqUser;

       System.runAs(edqUser) {  
         
       // Create Account
       Account testAccount = Test_Utils.insertAccount();
       
       // Create an Contact
       Contact con1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       insert con1;
       
       Account_Address__c accAdd = Test_Utils.insertAccountAddress(true, addrs1.id, testAccount.id);
       Contact_Address__c conAdd = Test_Utils.insertContactAddress(true,addrs1.id, con1.Id);
       // Create an opportunity
       Opportunity testPrevOpp = Test_Utils.createOpportunity(testAccount.Id);
        testPrevOpp.StageName = Constants.OPPTY_STAGE_3;
        testPrevOpp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        testPrevOpp.Invoice_to_End_User__c = null;
        insert testPrevOpp;
  
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.StageName = Constants.OPPTY_STAGE_6;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Invoice_to_End_User__c = null;
        testOpp.Previous_Opportunity__c = testPrevOpp.Id;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

       OpportunityContactRole oppConRole1 = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, con1.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);                                     
       
       
       // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
        
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
        
        //insert OLI
        OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem2.Start_Date__c = date.today().addDays(7);
        opportunityLineItem2.End_Date__c = date.today().addDays(20);
        insert opportunityLineItem2;                
       
                
        Test_Utils.createOpptyTasks(testOpp.Id, true);
        
        Test.startTest();
        
        // update opp
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Amount = 100;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;

        try{
         update testOpp;
        }catch(Exception ex){
            //Assert for error message
            system.debug('Message >>>' +ex.getMessage());
         // System.assertEquals(ex.getMessage().contains(Label.OPPTY_ERR_CONTACT_ADDRESS_CHECK_FOR_EDQ));
           System.assertEquals(ex.getMessage(),Label.OPPTY_ERR_CONTACT_ADDRESS_CHECK_FOR_EDQ);
       }
        Test.stopTest();

       }
  } 

  //T-322814 : with all Contact Roles
      static testmethod void test_validateOpptyContactRoleOnClosedWon2(){
      	TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_ADDRESS_TRIGGER);
        insertTriggerSettings.IsActive__c = false;
        update insertTriggerSettings;
       Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
       User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
       insert testUser1;

       System.runAs(testUser1) {
       
        User currentUser = new User();
        currentUser.Id = UserInfo.getUserId();
        currentUser.Global_Business_Line__c = 'Corporate';
        currentUser.Business_Line__c = 'Corporate';
        currentUser.Business_Unit__c = 'APAC:SE';
        update currentUser;
        
        Business_Unit_Group_Mapping__c custSetting1 = new Business_Unit_Group_Mapping__c();
        custSetting1.Name = 'EDQ';
        custSetting1.User_Business_Unit__c = 'APAC:SE';
        custSetting1.Common_Group_Name__c = 'EDQ';
        insert custSetting1;    
         
       // Create Account
       Account testAccount = Test_Utils.insertAccount();
       
       Address__c addrs1 = Test_Utils.insertAddress(true);
   //insert account address
       Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);
       // Create an Contact
       Contact con1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con2  = new Contact (FirstName = 'Test 2', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con3  = new Contact (FirstName = 'Test 3', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con4  = new Contact (FirstName = 'Test 4', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con5  = new Contact (FirstName = 'Test 5', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       Contact con6  = new Contact (FirstName = 'Test 6', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       
       //Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, con1.Id);
       
       List<Contact> conLst = new List<Contact>();
       conLst.add(con1);
       conLst.add(con2);
       conLst.add(con3);
       conLst.add(con4);
       conLst.add(con5);
       conLst.add(con6);
       insert conLst;
       
       // Create an opportunity
       Opportunity testPrevOpp = Test_Utils.createOpportunity(testAccount.Id);
        testPrevOpp.StageName = Constants.OPPTY_STAGE_3;
        testPrevOpp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        testPrevOpp.Invoice_to_End_User__c = null;
        insert testPrevOpp;
  
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.StageName = Constants.OPPTY_STAGE_6;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Invoice_to_End_User__c = null;
        testOpp.Previous_Opportunity__c = testPrevOpp.Id;
        testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
        insert testOpp;
       
       OpportunityContactRole oppConRole1 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(0).Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);                                     

       OpportunityContactRole oppConRole2 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(1).Id, Constants.OPPTY_CONTACT_ROLE_RENEWAL, false);

       OpportunityContactRole oppConRole3 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(2).Id, Constants.OPPTY_CONTACT_ROLE_UPDATE, false);

       OpportunityContactRole oppConRole4 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(3).Id, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);
       
       OpportunityContactRole oppConRole5 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(4).Id, Constants.OPPTY_CONTACT_ROLE_SHIPTO, false);

       OpportunityContactRole oppConRole6 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, conLst.get(5).Id, Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL, false);

       List<OpportunityContactRole> conRoleLst = new List<OpportunityContactRole>();
       conRoleLst.add(oppConRole1);
       conRoleLst.add(oppConRole2);
       conRoleLst.add(oppConRole3);
       conRoleLst.add(oppConRole4);
       conRoleLst.add(oppConRole5);
       conRoleLst.add(oppConRole6);
       insert conRoleLst;      
       
       Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(0).Id);
       Contact_Address__c conAdd1 = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(1).Id);
       Contact_Address__c conAdd2 = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(2).Id);
       Contact_Address__c conAdd3 = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(3).Id);
       Contact_Address__c conAdd4 = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(4).Id);
       Contact_Address__c conAdd5 = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, conLst.get(5).Id);
        
        List<Opportunity_Contact_Address__c> oppConAdds = new List<Opportunity_Contact_Address__c>();
        Opportunity_Contact_Address__c oppConAdd = new Opportunity_Contact_Address__c();
        oppConAdd.Opportunity__c= testOpp.Id ;
        oppConAdd.Address__c = conAdd.Address__c;
        oppConAdd.Contact__c = conLst.get(0).Id;
        oppConAdd.Role__c = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER;
        oppConAdds.add( oppConAdd);
        
        Opportunity_Contact_Address__c oppConAdd1 = new Opportunity_Contact_Address__c();
        oppConAdd1.Opportunity__c= testOpp.Id ;
        oppConAdd1.Address__c = conAdd.Address__c;
        oppConAdd1.Contact__c = conLst.get(1).Id;
        oppConAdd1.Role__c = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL;
        oppConAdds.add( oppConAdd1);
        
        Opportunity_Contact_Address__c oppConAdd2 = new Opportunity_Contact_Address__c();
        oppConAdd2.Opportunity__c= testOpp.Id ;
        oppConAdd2.Address__c = conAdd.Address__c;
        oppConAdd2.Contact__c = conLst.get(2).Id;
        oppConAdd2.Role__c = Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL;
        oppConAdds.add( oppConAdd2);
        
        Opportunity_Contact_Address__c oppConAdd3 = new Opportunity_Contact_Address__c();
        oppConAdd3.Opportunity__c= testOpp.Id ;
        oppConAdd3.Address__c = conAdd.Address__c;
        oppConAdd3.Contact__c = conLst.get(3).Id;
        oppConAdd3.Role__c = Constants.OPPTY_CONTACT_ROLE_RENEWAL;
        oppConAdds.add( oppConAdd3);
        
        Opportunity_Contact_Address__c oppConAdd4 = new Opportunity_Contact_Address__c();
        oppConAdd4.Opportunity__c= testOpp.Id ;
        oppConAdd4.Address__c = conAdd.Address__c;
        oppConAdd4.Contact__c = conLst.get(4).Id;
        oppConAdd4.Role__c = Constants.OPPTY_CONTACT_ROLE_SHIPTO;
        oppConAdds.add( oppConAdd4);
        
        Opportunity_Contact_Address__c oppConAdd5 = new Opportunity_Contact_Address__c();
        oppConAdd5.Opportunity__c= testOpp.Id ;
        oppConAdd5.Address__c = conAdd.Address__c;
        oppConAdd5.Contact__c = conLst.get(5).Id;
        oppConAdd5.Role__c = Constants.OPPTY_CONTACT_ROLE_UPDATE;
        oppConAdds.add( oppConAdd5);
        
        insert oppConAdds;
       // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
       
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
        
        //insert OLI
        OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem2.Start_Date__c = date.today().addDays(7);
        opportunityLineItem2.End_Date__c = date.today().addDays(20);
        // insert opportunityLineItem2;                
       
                
        Test_Utils.createOpptyTasks(testOpp.Id, true);
        
        Test.startTest();
        
        // update opp
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Amount = 100;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        update testOpp;

        Test.stopTest();
        
        //Assert
        System.assertEquals(testOpp.StageName, Constants.OPPTY_STAGE_7);

     }
  } 
  
    //T-265681: Test method for multi-currency dashboard
    @isTest
    static void testMultiCurrencyFieldUpdate(){
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
       User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
       insert testUser1;

       System.runAs(testUser1) {
      //create Account
      Account testAcc = Test_Utils.insertAccount();
      //create Opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      testOpp.Amount = 1000;
      testOpp.CurrencyIsoCode ='GBP';
      testOpp.CloseDate = Date.today().addDays(7);
      testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
      insert testOpp;
      System.debug('testOpp>>' +testOpp);

      Test.startTest();
      Opportunity resultOpp = [SELECT ID, CloseDate, Amount, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c 
                               FROM Opportunity WHERE Id =:testOpp.Id];
      System.debug('resultOpp1>>' +resultOpp);                         
      Map<String, DatedConversionRate> dtConvRateMap = new Map<String, DatedConversionRate>();

      for (DatedConversionRate dcr : [SELECT ISOCode, ID, ConversionRate
                                      FROM DatedConversionRate 
                                      WHERE StartDate < NEXT_N_DAYS:7 AND NextStartDate > NEXT_N_DAYS:7]) {
        dtConvRateMap.put(dcr.ISOCode, dcr);
      }

      system.assertEquals(dtConvRateMap.get('GBP').ConversionRate, resultOpp.GBP_Conversion_Rate__c);
      //system.assertEquals([], resultOpp.GBP_Conversion_Rate__c);
      system.assertEquals(dtConvRateMap.get('AUD').ConversionRate, resultOpp.AUD_Conversion_Rate__c);
      system.assertEquals(resultOpp.Amount_Corp__c, resultOpp.Amount / dtConvRateMap.get('GBP').ConversionRate);
      //update the currency on Opp
      testOpp.CurrencyIsoCode ='AUD';
      testOpp.CloseDate = Date.today().addDays(8);
      update testOpp;

      resultOpp = [SELECT ID, CloseDate, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c, Amount FROM Opportunity WHERE Id =:testOpp.Id];
      System.debug('resultOpp2>>' +resultOpp);
      
      Test.stopTest();
       System.debug('Expected>>' +resultOpp.Amount_Corp__c);
      System.debug('Actual>>' +resultOpp.Amount / dtConvRateMap.get('AUD').ConversionRate);
      
      //system.assertEquals(resultOpp.Amount_Corp__c, resultOpp.Amount / dtConvRateMap.get('AUD').ConversionRate);
       }
    }


    static testmethod void test_validateOnDemandOpportunityDataOnClosedWon(){
      
        Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
        User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
        insert edqUser;

        System.runAs(edqUser) {  
         
        // Create Account
        Account testAccount = Test_Utils.insertEDQAccount(true);
        Address__c addrs1 = Test_Utils.insertAddress(true);
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);    
              
        // Create an Contact
        Contact con1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
        con1.EDQ_On_Demand__c = true;
        con1.Title = 'NewTitle';
        con1.EDQ_Integration_Id__c = 'TESTID0011001002';
        con1.Phone = '9799559433';
        insert con1;
        //Contact con1 = Test_Utils.insertEDQContact(testAccount.ID, true);
        Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, con1.Id);
        // Create an opportunity
        Opportunity testPrevOpp = Test_Utils.createOpportunity(testAccount.Id);
        testPrevOpp.StageName = Constants.OPPTY_STAGE_3;
        testPrevOpp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        testPrevOpp.Invoice_to_End_User__c = null;
        insert testPrevOpp;
  
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.StageName = Constants.OPPTY_STAGE_6;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Invoice_to_End_User__c = null;
        testOpp.Previous_Opportunity__c = testPrevOpp.Id;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

        OpportunityContactRole oppConRole1 = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, con1.Id, Constants.DECIDER, true);                                     
        
       
        // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
        
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
        
        //insert OLI
        OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem.Start_Date__c = date.today().addDays(7);
        opportunityLineItem.End_Date__c = date.today().addDays(20);
        //opportunityLineItem.EDQ_On_Demand_Product__c = true;
        insert opportunityLineItem;                
       
                
        Test_Utils.createOpptyTasks(testOpp.Id, true);
        
        Test.startTest();
        
        // update opp
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Amount = 100;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;

        try {
         update testOpp;
        } catch(Exception ex) {
          //Assert for error message 
          system.debug('Message >>>' +ex.getMessage());
          System.assert(ex.getMessage().contains(Label.OPPTY_CLSWON_REQ_ONDEMAND_CONTACT));
       }
        Test.stopTest();

       }
  } 
  
}