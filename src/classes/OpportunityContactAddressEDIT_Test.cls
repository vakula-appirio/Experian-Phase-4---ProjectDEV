/******************************************************************************
 * Appirio, Inc
 * Name: OpportunityContactAddressEDIT_Test.cls
 * Description: Test functionality of the OpportunityContactAddressEDIT_Extension.cls
 * Created Date: Oct 15th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * 
 ******************************************************************************/
 @isTest
 private class OpportunityContactAddressEDIT_Test {

   public static testmethod void  testOppConAddrsEDIT(){
     // create test data
     Account testAcc = Test_Utils.insertAccount();
     Contact testCon = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAcc.Id, Email = 'test1@email.com');
     insert testCon;
     Opportunity testOpp = Test_Utils.insertOpportunity(testAcc.Id);
     
     Address__c addrs1 = Test_Utils.insertAddress(true);

     List<Address__c> addrsLst = new List<Address__c>();
     for (Integer i = 0; i < 30; i++){
       Address__c addrs = Test_Utils.insertAddress(false);
       addrsLst.add(addrs);	
     }
     insert addrsLst;

     List<Contact_Address__c> conAddressList = new List<Contact_Address__c>();
     for (Integer i = 0; i < 30; i++){
       Contact_Address__c conAddrs = new Contact_Address__c(Contact__c = testCon.Id, Address__c = addrsLst.get(i).Id);
       conAddressList.add(conAddrs);
     }
     insert conAddressList;

     Opportunity_Contact_Address__c opConAdrs = new Opportunity_Contact_Address__c();
     opConAdrs.Contact__c = testCon.Id;
     opConAdrs.Opportunity__c = testOpp.Id;
     opConAdrs.Address__c = addrs1.Id;
     insert opConAdrs;
     
     PageReference pageRef = Page.OpportunityContactAddressEDIT;
     Test.setCurrentPage(pageRef);
     // start test
     Test.startTest();
	   ApexPages.StandardController sc = new ApexPages.standardController(opConAdrs);
	   OpportunityContactAddressEDIT_Extension ocaEdit = new OpportunityContactAddressEDIT_Extension(sc);
	   
	   ocaEdit.currentOpptyContactAddress = opConAdrs;
	   ocaEdit.selectedRec = conAddressList.get(1).Id;
	   ocaEdit.getContactAddressList();

	   ocaEdit.saveOpptyContact();
	   //Asserts
	   Contact_Address__c selectedContAddress = [SELECT Address__c, ID FROM Contact_Address__c WHERE ID =: ocaEdit.selectedRec];
	   System.assertEquals(opConAdrs.Address__c, selectedContAddress.Address__c);
	   
	   ocaEdit.refresh();
	   
	   ocaEdit.hasNext = true;
	   ocaEdit.hasPrevious = false;
	   ocaEdit.pageNumber = 1;
	   
	   ocaEdit.first();
	   ocaEdit.last();
	   ocaEdit.previous();
	   ocaEdit.next();
	   // stop test
     Test.stopTest();
   }

}