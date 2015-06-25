/**=====================================================================
 * Appirio, Inc
 * Name: ARIABillingAccount_ChooseParent_Test
 * Description: Test class to verify the behavior of ARIABillingAccount_ChooseParent.cls
 * Created Date: 20 May' 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest (seeAllData=false)
private class ARIABillingAccount_ChooseParent_Test {
//data members
private static Account account;
private static ARIA_Billing_Account__c ariaBAParent, ariaBAChild, ariaBAGrandChild, ariaBANotActive;
    static testMethod void myUnitTest() {
    	  createTestData();
    	  //set current page
    	  PageReference pageRef = Page.ARIABillingAccount_ChooseParent;
        Test.setCurrentPage(pageRef);
    	  System.currentPageReference().getParameters().put('Id', ariaBAChild.id);
    	  System.currentPageReference().getParameters().put('acctId', account.id);
    	  ARIABillingAccount_ChooseParentCont ariaControl = new ARIABillingAccount_ChooseParentCont();
    	  ariaControl.responsibilityLevel = 'Parent Usage & Pay';
    	  ariaControl.parentARIABillingAccountSelectedId = ariaBAParent.Id;
        //new governor limits
        Test.startTest();
        //save
        ariaControl.save();
        ARIA_Billing_Account__c tempARIABA = [SELECT Responsibility_Level__c, Parent_Billing_Account_Name__c
                                              FROM ARIA_Billing_Account__c 
                                              WHERE Id = :ariaBAChild.Id];
        //Responsibility_Level__c and Parent_Billing_Account_Name__c populated
        System.assertEquals('Parent Usage & Pay', tempARIABA.Responsibility_Level__c);
        System.assertEquals(ariaBAParent.Id, tempARIABA.Parent_Billing_Account_Name__c);
        //number of eligible parent ARIA
        System.assertEquals(1, ariaControl.mapIdToEligibleParents.size());
        //clear
        ariaControl.responsibilityLevel = '';
        ariaControl.parentARIABillingAccountSelectedId = null;
        //save
        ariaControl.save();
        tempARIABA = [SELECT Responsibility_Level__c, Parent_Billing_Account_Name__c
                                              FROM ARIA_Billing_Account__c 
                                              WHERE Id = :ariaBAChild.Id];
        //Responsibility_Level__c and Parent_Billing_Account_Name__c removed
        System.assertEquals(null, tempARIABA.Responsibility_Level__c);
        System.assertEquals(null, tempARIABA.Parent_Billing_Account_Name__c);
        //call to goBack method        
        String pg = ariaControl.goBack().getUrl();
        System.assertEquals('/'+ariaBAChild.Id, pg);
        Test.stopTest();
    }
    
    //method to create test data
    private static void createTestData () {
        account = Test_Utils.insertAccount();
        ariaBAParent = new ARIA_Billing_Account__c (Account__c = account.Id, Billing_System_Ref__c = 'test reference',
                                                    ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE);
        ariaBAParent.Billing_Account_Country__c  = 'USA';
        ariaBAParent.Business_ID_Number__c = '1232313213';
        ariaBAParent.Business_ID_Type__c = 'ABN';
      
        ariaBAChild = new ARIA_Billing_Account__c (Account__c = account.Id, ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE);
        ariaBAChild.Billing_Account_Country__c  = 'USA';
        ariaBAChild.Business_ID_Number__c = '1232313214';
        ariaBAChild.Business_ID_Type__c = 'ABN';
        
        ariaBANotActive = new ARIA_Billing_Account__c (Account__c = account.Id, ARIA_Billing_Account_Status__c = Constants.STATUS_INACTIVE);
        ariaBANotActive.Billing_Account_Country__c  = 'USA';
        ariaBANotActive.Business_ID_Number__c = '1232313215';        
        ariaBANotActive.Business_ID_Type__c = 'ABN';
        
        insert new List<ARIA_Billing_Account__c> {ariaBAParent, ariaBAChild};
        ariaBAGrandChild = new ARIA_Billing_Account__c (Account__c = account.Id, Parent_Billing_Account_Name__c = ariaBAChild.Id,
                                                        ARIA_Billing_Account_Status__c = Constants.STATUS_ACTIVE, 
                                                        Billing_System_Ref__c = 'test reference 2', Responsibility_Level__c='Standard Self Pay');
        insert ariaBAGrandChild;                                                        
    }
}