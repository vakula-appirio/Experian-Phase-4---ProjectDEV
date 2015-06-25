/**=====================================================================
 * Appirio, Inc
 * Name: RecalculateBUrelationshipController_Test
 * Description: T-206013
				Provide test coverage to the class "RecalculateBUrelationshipController" 
 * Created Date: Nov 08th, 2013
 * Created By: Manish Soni (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 04th, 2014                   Arpita Bose(Appirio)         T-243282: Added constants in place of String
 * Apr 23rd, 2014               Nathalie Le Guay             Commented class
 =====================================================================*/

@isTest
private class RecalculateBUrelationshipController_Test {

		/*static BU_Relationship__c bu, bu2;
		
    static testMethod void testRecalculateBURelationship() {
    	createData();
    	                                            
    	Test.startTest();
	    	ApexPages.StandardController std = new ApexPages.StandardController(bu);
	    	RecalculateBUrelationshipController controller = new RecalculateBUrelationshipController(std);
	    	controller.recalculateBURelationship();
	    	bu = [ SELECT Id , Total_Open_Pipeline__c, Total_Won__c FROM BU_Relationship__c WHERE id =:bu.id ];
	    	system.assertEquals(bu.Total_Open_Pipeline__c, 10);
    	Test.stopTest();
    }
    
    //Method for create test data
    private static void createData() {
    	User user = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    	user.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    	user.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    	insert user;
    	
	  	Account account = Test_Utils.insertAccount();  	
	  	bu = Test_Utils.createBURelationship(account.Id);
	  	bu.Global_Line_of_Business_or_BU__c = Constants.BUSINESS_UNIT_MS_CIT;
	  	
	  	bu2 = Test_Utils.createBURelationship(account.Id);
	  	bu2.Global_Line_of_Business_or_BU__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
	  	
	  	List<BU_Relationship__c> listBURelationship = new List<BU_Relationship__c>();
	  	listBURelationship.add(bu);
	  	listBURelationship.add(bu2);
	  	
	  	insert listBURelationship;
	  	
	  	System.runAs(user){
		  	Opportunity opportunityBusinessUnit = Test_Utils.createOpportunity(account.Id);
		  	opportunityBusinessUnit.Amount = 10; 
	      opportunityBusinessUnit.Contract_End_Date__c = System.today().addDays(-20);
	      opportunityBusinessUnit.Business_Unit__c = bu.id;
		  	insert opportunityBusinessUnit;
	  	}
	  }*/
}