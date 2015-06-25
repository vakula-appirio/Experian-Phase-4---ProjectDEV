@isTest(seealldata=true)

private class AriaOrderClone_Test {

    static testMethod void cloneUnitTest() {
        
        Test.startTest();
        // insert Test data
        // Insert ARIA Order Standard RT Id into Global Settings
        //Global_Settings__c custSetting = new Global_Settings__c(Name = Constants.GLOBAL_SETTING, ARIA_Order_Standard_RecordTypeId__c ='012f0000000CxVHAA0');
        // '012i0000001AJKP');
        //insert custSetting;        
        
        string AriaOrderRecTypeId;
        AriaOrderRecTypeId = [SELECT Id FROM RecordType WHERE SobjectType ='Aria_Order__c' and Name = 'Standard'].Id;
        
        // Create an Account
        Account a = Test_Utils.insertAccount();
        // Add a Billing Account
        ARIA_Billing_Account__c ba = new ARIA_Billing_Account__c(Account__c = a.Id);
	      ba.Billing_Account_Country__c  = 'USA';
	      ba.Business_ID_Number__c = '1232313213';
	      ba.Push_To_Aria__c = 'Yes';
	      ba.Billing_System_Ref__c = 'TESTING0001';         
        insert ba; 
        // Add an Order
        ARIA_Order__c ao = new ARIA_Order__c(ARIA_Order_Ref_Number__c = '12345', Billing_Account__c = ba.Id, Invoice_Template_Name__c = 'Dutch Tax Exempt Manual Invoice Template', Order_Country__c = 'NL', RecordTypeId = AriaOrderRecTypeId  );
        insert ao;
        // Add a Product
        ARIA_Product__c ap = new ARIA_Product__c(Name = 'ARIA Test Product', ARIA_Item_ID__c = '12345', Item_Currency_Code__c = 'GBP');
        insert ap;
        // Add an Order Item
        Aria_Order_Items_Detail__c aoid = new Aria_Order_Items_Detail__c(ARIA_Order__c = ao.Id, ARIA_Product__c = ap.Id, Quantity__c = 1, Price_Per_Unit__c = 10, Comments__c = 'Test Aria Order Item');
        insert aoid;
        
        System.debug('UserInfo.getProfileId() = ' + UserInfo.getProfileId());
        
        // Instantiate the Standard Controller for an ARIA Order
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(ao); 
        // AriaOrderClone aoc = new AriaOrderClone(sc);
        AriaOrder_CloneController aoc = new AriaOrder_CloneController(sc);
        
        PageReference pageRef =Page.AriaOrderClone; // Page.CloneAriaOrder;
        pageRef.getParameters().put('Id', String.valueOf(ao.Id));
        Test.setCurrentPage(pageRef);
        
        // Test the Clone with Global Setting
        System.assertNotEquals(aoc.cloneOrder(), null);
        aoc.runClone();        
        
        // Test the Clone without Global Setting to cover catch statement
       // delete custSetting;
        aoc.runClone();
        
        Test.stopTest();        
    }
}