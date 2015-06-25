@isTest
private class BuyingCenterAnalysisController_Test {

	// Test Method which creates test data and calls all methods used to display Opportunity Plan Contacts on page.
    static testMethod void testLoadOpportunityContacts() {

        //test data start
        Account account = Test_Utils.insertAccount();

        Opportunity opp = Test_Utils.insertOpportunity(account.id);        

    	// creates Opportunity_Plan__c records
    	Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(true, opp.id);
    	
    	List<Contact> contacts = new List<Contact>();
    	for(integer i = 0 ; i < 6 ; i++){
    		contacts.add(Test_Utils.createContact(account.id));
    	}
    	insert contacts;
    	
        
    	// creates Opportunity_Plan_Contact__c records
    	List<Opportunity_Plan_Contact__c> oppPlanContacts = new List<Opportunity_Plan_Contact__c>();
    	for(Contact contct : contacts){
    		oppPlanContacts.add(Test_Utils.createOpportunityPlanContact(oPlan,contct));
    	}
    	insert oppPlanContacts;
    	
    	//preparing hierarchy
    	Integer cntr = 1;
    	while(cntr < 6){
    		oppPlanContacts.get(cntr).reports_to__c = oppPlanContacts.get(cntr - 1).Id;
    		cntr++;
    	}    	
    	update oppPlanContacts;
    	
    	//preparing relationships
    	List<Plan_Contact_Relationship__c> relationships = new List<Plan_Contact_Relationship__c>();
    	cntr = 1;
        while(cntr < 6){
            relationships.add(Test_Utils.createPlanContactRelationship(false,oppPlanContacts.get(cntr) , oppPlanContacts.get(cntr - 1),'Positive'));
            cntr++;
        }
        
        cntr = 0;
        while(cntr < 5){
            relationships.add(Test_Utils.createPlanContactRelationship(false,oppPlanContacts.get(cntr) , oppPlanContacts.get(cntr + 1),'Negative'));
            cntr++;
        }
        insert relationships;
        //test data end
        
    	// Start Test
    	Test.startTest();
        ApexPages.currentPage().getParameters().put('id', oPlan.Id);
    	BuyingCenterAnalysisController bcac = new BuyingCenterAnalysisController();
    	// Stop Test
    	Test.stopTest();

    }

}