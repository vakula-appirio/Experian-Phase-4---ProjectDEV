/**=====================================================================
 * Appirio, Inc
 * Test Class Name: ARIASupplementalPlanHierarchyCont_Test
 * Class Name: ARIASupplementalPlanHierarchyController
 * Description: T-283161
 * Created Date: May 28th, 2014
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class ARIASupplementalPlanHierarchyCont_Test {
	private static ARIA_Plan__c ariaPlanMaster1, ariaPlanMaster2, ariaPlanChild11, ariaPlanChild12,
	                            ariaPlanChild21, ariaPlanChild211, ariaPlanMaster3;
	private static ARIA_Plan_Relationship__c ariaPRM1C11, ariaPRM1C12, ariaPRM2C21, ariaPRC21C211, ariaPRM3C11;
	private static Account account;
	private static ARIA_Billing_Account__c ariaBA1, ariaBA2;
	private static Profile p;
	private static User u1, u2;
  
  //Test method
  static testMethod void myUnitTest() {
    List<ARIASupplementalPlanHierarchyController.ObjectStructureMap> obsList = new List<ARIASupplementalPlanHierarchyController.ObjectStructureMap>();
    
    createTestData();
    
    Pagereference pg = Page.ARIASupplementalPlanHierarchy;
    pg.getParameters().put('id', ariaBA1.ID);
    Test.setCurrentPage(pg);
    
    ARIASupplementalPlanHierarchyController controller = new ARIASupplementalPlanHierarchyController();
    obsList = controller.getObjectStructure();
    //Assert to check map populated by related data
    System.assert(obsList.size() > 0);
    
    controller.setcurrentId(ariaBA1.ID);
    ARIASupplementalPlanHierarchyController.ObjectStructureMap objStruc;
    objStruc = obsList.get(0);
    System.assertNotEquals(objStruc.getnodeType(), null);
    System.assertNotEquals(objStruc.getaccount(), null);
    System.assertNotEquals(objStruc.getcloseFlag(), null);
    System.assertNotEquals(objStruc.getcurrentNode(), null);
    System.assertNotEquals(objStruc.getlevelFlag(), null);
    System.assertNotEquals(objStruc.getnodeId(), null);
    controller.GetTopElement(ariaPRM1C11.ID);
    controller.GetTopElement1(ariaPlanMaster1.ID);
  }
  
	//method to create test data
	private static void createTestData () {
	    account = Test_Utils.insertAccount();
	    ariaBA1 = new ARIA_Billing_Account__c (Account__c = account.Id, Billing_System_Ref__c = 'test reference 1',
	                                           Pre_Paid_Ind__c = true, ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE,
	                                           Billing_Account_Country__c  = 'USA', Business_ID_Number__c = '1232313213',
	                                           Business_ID_Type__c = 'ABN');
	    
	    ariaBA2 = new ARIA_Billing_Account__c (Account__c = account.Id, Billing_System_Ref__c = 'test reference 2',
	                                           Pre_Paid_Ind__c = false, ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE,
	                                           Billing_Account_Country__c  = 'USA', Business_ID_Number__c = '1232313210',
	                                           Business_ID_Type__c = 'ABN');
	                                           
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
	    
	    ARIA_Billing_Account_Supplimental_Plans__c ariaBillAccSuppPlan = new ARIA_Billing_Account_Supplimental_Plans__c();
	    ariaBillAccSuppPlan.ARIA_Billing_Account__c = ariaBA1.ID;
	    ariaBillAccSuppPlan.ARIA_Plan_Relationship__c =  ariaPRM1C11.ID;
	    insert ariaBillAccSuppPlan; 
	}
}