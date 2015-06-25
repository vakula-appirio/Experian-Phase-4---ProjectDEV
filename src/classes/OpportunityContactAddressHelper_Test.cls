/**======================================================================================================
 * Appirio, Inc
 * Name             : OpportunityContactAddressHelper_Test
 * Description      : Unit test coverage of OpportunityContactAddressHelper
 * Created Date     : Oct 14th, 2014
 * Created By       : Pallavi Sharma(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Nov 5th, 2014                 Arpita Bose(Appirio)         I-137466: Updated method test_populateAddress()
 * Feb 23rd, 2015                Paul Kissick                 Case #551906 - Adding for testing replacing address and removing contact from opp
 =======================================================================================================*/
@isTest  
private class OpportunityContactAddressHelper_Test {
  
  //===================================================================//
  //Test Method for unit test coverage of Method populateAddress
  //===================================================================//
  static testMethod void test_populateAddress(){
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    System.runAs(testUser) {
        Account acc = Test_Utils.insertAccount();
        
        Contact con = Test_Utils.insertContact(acc.ID);
        Address__c address = Test_Utils.insertAddress(true);
        
        Contact con2 = Test_Utils.insertContact(acc.ID);
        Address__c address2 = Test_Utils.insertAddress(true);
        
        Contact con3 = Test_Utils.insertContact(acc.ID);
        Address__c address3 = Test_Utils.insertAddress(true);
        Contact_Address__c ca3 = Test_Utils.insertContactAddress(true, address3.Id, con3.Id);
        // Will be used to change on a contact
        Address__c address4 = Test_Utils.insertAddress(true);
      
        Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
        
        // create a Contact Address with Address_Type__c not as 'Registered'
        Contact_Address__c ca1 = Test_Utils.insertContactAddress(false, address.Id, con.Id);
        ca1.Address_Type__c = Constants.ADDRESS_TYPE_SECONDARY;
        insert ca1;
        
        Test.startTest();
                
        String result;
        
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result1>>>' +result);
        //Asserting when no Contact Role found
        system.assert(result == system.label.OPPTY_CONT_ADD_NO_OPPORTUNITY_CONTACT_ROLE);
        
        OpportunityContactRole oppConRole = Test_Utils.insertOpportunityContactRole(true, opp.Id, con.Id, 'Assessor', true); 
                                       
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result2>>>' +result);
        //Asserting when no Registered Address found
        system.assertEquals(true, result.startsWith(system.label.OPPTY_CONT_ADD_NO_REGISTERED_CONTACT_ADDRESS));
        
        Contact_Address__c ca = Test_Utils.insertContactAddress(true, address.Id, con.Id);
        
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result3>>>' +result);

        //Assert when successfull 
        system.assertEquals(System.Label.OPPTY_CONT_ADD_SAVED_SUCCESSFULLY, result);
        //Assert newly created Opportunity Contact Address
        List<Opportunity_Contact_Address__c> lstOppContactAddress = [ SELECT ID , Contact__c, Address__c
                                                                      FROM Opportunity_Contact_Address__c 
                                                                      WHERE Opportunity__c =: opp.Id];
        system.assertEquals(1, lstOppContactAddress.size());
        system.assertEquals(con.Id, lstOppContactAddress.get(0).Contact__c);
        system.assertEquals(address.Id, lstOppContactAddress.get(0).Address__c);
       
        OpportunityContactRole oppConRole2 = Test_Utils.insertOpportunityContactRole(true, opp.Id, con2.Id, 'Decider', false);
        
        Contact_Address__c ca2 = Test_Utils.insertContactAddress(true, address2.Id, con2.Id);
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        
        OpportunityContactRole oppConRole3 = Test_Utils.insertOpportunityContactRole(true, opp.Id, con3.Id, 'Assessor', false);
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result4>>>'+result); // should be fine...
        // now change the address...
        ca3.Address__c = address4.Id;
        update ca3;
        
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result5>>>'+result); // should be fine...
        system.assertEquals(3, [SELECT COUNT() FROM Opportunity_Contact_Address__c WHERE Opportunity__c =: opp.Id]);
        
        // now remove the contact we just added...
        delete oppConRole3;
        result = OpportunityContactAddressHelper.populateAddresses(opp.Id);
        system.debug('result6>>>'+result); // should be fine...
        
        system.assertEquals(2, [SELECT COUNT() FROM Opportunity_Contact_Address__c WHERE Opportunity__c =: opp.Id]);
        
        Test.stopTest();
        
        system.assertEquals(System.Label.OPPTY_CONT_ADD_SAVED_SUCCESSFULLY, result);
        
      
    }
  }
}