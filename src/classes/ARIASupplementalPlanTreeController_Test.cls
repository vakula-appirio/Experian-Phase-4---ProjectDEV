/**=====================================================================
 * Appirio, Inc
 * Name: ARIASupplementalPlanTreeController_Test
 * Description: Test class to verify the behavior of ARIASupplementalPlanTreeController.cls
                and ARIASupplementalPlanTreeHelper.cls
 * Created Date: 20 May' 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest (seeAllData=false)
private class ARIASupplementalPlanTreeController_Test {
//data members
private static ARIA_Plan__c ariaPlanMaster1, ariaPlanMaster2, ariaPlanChild11, ariaPlanChild12,
                            ariaPlanChild21, ariaPlanChild211, ariaPlanMaster3;
private static ARIA_Plan_Relationship__c ariaPRM1C11, ariaPRM1C12, ariaPRM2C21, ariaPRC21C211, ariaPRM3C11;
private static Account account;
private static ARIA_Billing_Account__c ariaBA1, ariaBA2;
private static Profile p;
private static User u1, u2;
    static testMethod void myUnitTest() {
    	  //create user
        p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        u1 = new User(Alias = 'stdtstu1', Email='standarduser@testorg.com', 
                  EmailEncodingKey='UTF-8', LastName='TestingUsr', LanguageLocaleKey='en_US', 
                  LocaleSidKey='en_US', ProfileId = p.Id, Country__c = 'United States',
                  TimeZoneSidKey='America/Los_Angeles', UserName='testUsr1@random.com');
        insert new List<User> {u1};
        
        //new governor limits
        Test.startTest();
	        System.runAs(u1) {
	        	createTestData();
	        	//set current page	        	
		        PageReference pageRef = Page.ARIASupplementalPlanTree;
		        Test.setCurrentPage(pageRef);		        
		        System.currentPageReference().getParameters().put('id', ariaBA1.id);
	        	ApexPages.StandardController sc1 = new ApexPages.StandardController(ariaBA1);
	          ARIASupplementalPlanTreeController control1 = new ARIASupplementalPlanTreeController (sc1);
	          //no plans associated
            System.assertEquals(true, ARIASupplementalPlanTreeController.getSupplementalPlans (ariaBA1.Id).isEmpty());
	          String tempTree = control1.getPlanTreeHierarchy();
	          //Prepaid indicator = 32 and only plans with Country of that of user are available
	          System.assert(tempTree.containsIgnoreCase(ariaPlanMaster1.Id));
	          System.assert(!tempTree.containsIgnoreCase(ariaPlanMaster2.Id));
	          System.assert(!tempTree.containsIgnoreCase(ariaPlanMaster3.Id));
	          //save
	          System.currentPageReference().getParameters().put('masterPlanId', '-'+ariaPlanMaster1.Id);
	          System.currentPageReference().getParameters().put('selectedPlans', '-'+ariaPlanChild11.Id);
	          control1.savePlansRelated();
	          //verify ARIA Billing Account Supplemental Plan created
	          List<ARIA_Billing_Account_Supplimental_Plans__c> tempABASP = [SELECT Id, ARIA_Plan_Relationship__c
	                                                                        FROM ARIA_Billing_Account_Supplimental_Plans__c
	                                                                        WHERE ARIA_Billing_Account__c = :ariaBA1.Id];
	          System.assertEquals(1, tempABASP.size());
	          System.assertEquals(ariaPRM1C11.Id, tempABASP.get(0).ARIA_Plan_Relationship__c);
	          System.assertEquals(ariaPlanMaster1.Id, [SELECT Master_Plan__c 
										                                 FROM ARIA_Billing_Account__c
										                                 WHERE Id = :ariaBA1.Id].get(0).Master_Plan__c);
	          control1.getSelectedPlans();
	          //call to goBack method        
		        String pg = control1.goBack().getUrl();
		        System.assertEquals('/'+ariaBA1.Id, pg);	
		        //with associated plans
            System.assertEquals(false, ARIASupplementalPlanTreeController.getSupplementalPlans (ariaBA1.Id).isEmpty());
	          //unselecting master plan and then saving to verify deletion of child ARIA Billing Account Supplemental Plans
	          System.currentPageReference().getParameters().put('masterPlanId', '');
            System.currentPageReference().getParameters().put('selectedPlans', '');
            control1.savePlansRelated();
	          System.assertEquals(null, [SELECT Master_Plan__c 
                                                     FROM ARIA_Billing_Account__c
                                                     WHERE Id = :ariaBA1.Id].get(0).Master_Plan__c);
	          tempABASP = [SELECT Id, ARIA_Plan_Relationship__c
		                      FROM ARIA_Billing_Account_Supplimental_Plans__c
		                      WHERE ARIA_Billing_Account__c = :ariaBA2.Id];
            System.assertEquals(0, tempABASP.size());
	        }
        Test.stopTest();
    }
    
    //method to create test data
    private static void createTestData () {
        account = Test_Utils.insertAccount();
        ariaBA1 = new ARIA_Billing_Account__c (Account__c = account.Id, Billing_System_Ref__c = 'test reference 1',
                                               Pre_Paid_Ind__c = true, ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE);
        ariaBA2 = new ARIA_Billing_Account__c (Account__c = account.Id, Billing_System_Ref__c = 'test reference 2',
                                               Pre_Paid_Ind__c = false, ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE);
        insert new List<ARIA_Billing_Account__c> {ariaBA1, ariaBA2};  
        ariaPlanMaster1 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanMaster1', Supplimental_Plan_Ind__c = false,
                                            Country__c = 'United States', Status__c = Constants.STATUS_ACTIVE,
                                            Pre_Paid_Indicator__c = '32');
        ariaPlanMaster2 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanMaster2', Supplimental_Plan_Ind__c = false,
                                            Country__c = 'Netherlands', Status__c = Constants.STATUS_ACTIVE);
        ariaPlanMaster3 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanMaster3', Supplimental_Plan_Ind__c = false,
                                            Country__c = 'Netherlands', Status__c = Constants.STATUS_ACTIVE,
                                            Pre_Paid_Indicator__c = '32');
        ariaPlanChild11 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanChild11', Supplimental_Plan_Ind__c = true,
                                            Country__c = 'United States', Status__c = Constants.STATUS_ACTIVE);
        ariaPlanChild12 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanChild12', Supplimental_Plan_Ind__c = true,
                                            Country__c = 'United States', Status__c = Constants.STATUS_ACTIVE);
        ariaPlanChild21 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanChild21', Supplimental_Plan_Ind__c = true, 
                                            Country__c = 'Netherlands', Status__c = Constants.STATUS_ACTIVE);
        ariaPlanChild211 = new ARIA_Plan__c (Plan_Name__c = 'test ariaPlanChild211', Supplimental_Plan_Ind__c = true,
                                             Country__c = 'Netherlands', Status__c = Constants.STATUS_ACTIVE);
        insert (new List<ARIA_Plan__c> {ariaPlanMaster1, ariaPlanMaster2, ariaPlanMaster3, ariaPlanChild11,
        	                          ariaPlanChild12, ariaPlanChild21, ariaPlanChild211});
        ariaPRM1C11 = new ARIA_Plan_Relationship__c (Parent_Plan__c=ariaPlanMaster1.Id , Child_Plan__c=ariaPlanChild11.Id);
        ariaPRM1C12 = new ARIA_Plan_Relationship__c (Parent_Plan__c=ariaPlanMaster1.Id , Child_Plan__c=ariaPlanChild12.Id);
        ariaPRM2C21 = new ARIA_Plan_Relationship__c (Parent_Plan__c=ariaPlanMaster2.Id , Child_Plan__c=ariaPlanChild21.Id);
        ariaPRC21C211 = new ARIA_Plan_Relationship__c (Parent_Plan__c=ariaPlanChild21.Id , Child_Plan__c=ariaPlanChild211.Id);
        ariaPRM3C11 = new ARIA_Plan_Relationship__c (Parent_Plan__c=ariaPlanMaster3.Id , Child_Plan__c=ariaPlanChild11.Id);
        insert (new List<ARIA_Plan_Relationship__c> {ariaPRM1C11, ariaPRM1C12, ariaPRM2C21, ariaPRC21C211, ariaPRM3C11});
        System.debug ('+++++++++ plan relationship '+ariaPRM1C11);        
    }
}