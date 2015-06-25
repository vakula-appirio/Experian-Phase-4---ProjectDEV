/**=====================================================================
 * Appirio, Inc
 * Name        : AddressMergeController_Test
 * Description : Test various functionality of AddressMergeController.cls
 * Created Date: Mar 05, 2013
 * Created By  : Naresh Kr Ojha (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * March 06, 2014     Nathalie Le Guay             Change Label names
 * Mar 14th, 2014     Arpita Bose (Appirio)        T-253906: Fixed error
 * Oct 25th, 2014     Nathalie Le Guay (Appirio)   Removing functionality
 =======================================================================*/
 @isTest
public with sharing class AddressMergeController_Test {
    
/*    static testMethod void  testManualAccountMerge () {
	    List<Address__c> addressList = new List<Address__c>();
	        
	    for (Integer i = 0; i < 20; i++) {
	      Address__c newAddress_t = Test_Utils.insertAddress(false);
	      addressList.add(newAddress_t);    
	    }
	    
	    insert addressList;
	
	    PageReference pageRef = Page.AddressMerge;
	    Test.setCurrentPage(pageRef);
	    Address__c newAddress = Test_Utils.insertAddress(true);
	    Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(newAddress);
	    
	    AddressMergeController scExt = new AddressMergeController(controller);
	    scExt.processMerge();
        
        //Assert to test listing of records
        System.assert(scExt.addressMap.size() > 0);
        scExt.getItems();
        
        //Selecting two records
        ApexPages.CurrentPage().getParameters().put('addressId', addressList.get(0).ID);
        ApexPages.CurrentPage().getParameters().put('event', 'Add');
        scExt.addressMap.get(addressList.get(0).ID).isSelected = true;
        scExt.addSelectedToSet();
        
        //To show error message, select two or more.
        scExt.mergeAddresses();
        //Assert to test when selected single record and trying to go to merge process, it should raise error
        System.assert(String.valueOf(ApexPages.getMessages().get(0)).contains(Label.Address_Merge_SELECT_TWO_OR_MORE) == true);
        
        
        ApexPages.CurrentPage().getParameters().put('addressId', addressList.get(1).ID);
        ApexPages.CurrentPage().getParameters().put('event', 'Add');
        scExt.addressMap.get(addressList.get(1).ID).isSelected = true;
        scExt.addSelectedToSet();
        
        //Assert to test two records get selected
        System.assert(scExt.selectedAddressResultMap.size() == 2);
        System.assert(scExt.getTotalSelectedAddresses() == 2);
        
        //Removing record from selected
        ApexPages.CurrentPage().getParameters().put('addressId', addressList.get(1).ID);
        ApexPages.CurrentPage().getParameters().put('event', 'Remove');
        scExt.addressMap.get(addressList.get(1).ID).isSelected = true;
        scExt.addSelectedToSet();       
        
        
        //Assert to test one record removed
        System.assert(scExt.selectedAddressResultMap.size() == 1);

        //Removing record from selected
        ApexPages.CurrentPage().getParameters().put('addressId', addressList.get(1).ID);
        ApexPages.CurrentPage().getParameters().put('event', 'Add');
        scExt.addressMap.get(addressList.get(1).ID).isSelected = true;
        scExt.addSelectedToSet();       
        
        scExt.mergeAddresses();
        scExt.cancelProcess();
        scExt.first();
        scExt.last();
        scExt.previous();
        scExt.next();
        //Two records are on second page to merge
        System.assert(scExt.addressMergeMap.size() == 2);
        
        scExt.processMerge();
        //Assert to test when no master selected and trying to process merge, it should raise error
        System.assert(String.valueOf(ApexPages.getMessages().get(1)).contains(Label.Address_Merge_SELECT_ONE_RECORD) == true);
                
        //First record will be master in address merge request
        scExt.selectedMaster = addressList.get(0).ID;
        scExt.processMerge();
        List<Address_Merge_Request__c> addressMergeRequests = [SELECT Slave_Address__c, Slave_Address_SFDC_Id__c, Perform_Auto_Merge__c, Merge_Type__c, Master_Address__c, Master_Address_SFDC_Id__c, Id From Address_Merge_Request__c];        
        //One address merge got created for above two records
        System.assert(addressMergeRequests.size() == 1);
        System.assert(addressMergeRequests.get(0).Merge_Type__c == Constants.MERGE_TYPE_MANUAL);
        System.assert(addressMergeRequests.get(0).Perform_Auto_Merge__c == false);
        System.assert(addressMergeRequests.get(0).Master_Address_SFDC_Id__c == addressList.get(0).ID);
        System.assert(addressMergeRequests.get(0).Slave_Address_SFDC_Id__c == addressList.get(1).ID);
        
    }
    
    //General pagination functionality test
    /*static testMethod void  testManualAccountMerge2 () {
      PageReference pageRef = Page.AddressMerge;
      Test.setCurrentPage(pageRef);

        List<Address__c> addressList = new List<Address__c>();
        Address__c newAddress;
        
        for (Integer i=0; i<20; i++) {
            newAddress = Test_Utils.insertAddress(false);
            addressList.add(newAddress);    
        }
        insert addressList;
        
   // ApexPages.StandardSetController sc = new ApexPages.StandardSetController();    
    //AddressMergeController scExt = new AddressMergeController();        
        //scExt.processMerge();
        
        //Assert to test listing of records
        System.assert(scExt.addressMap.size() > 0);
        scExt.cancelProcess();
        scExt.next();
        //Moved to next page.
        //System.assertEquals(scExt.pageNumber, '2');
        
        scExt.first();
        scExt.last();
        scExt.previous();
    }*/
}