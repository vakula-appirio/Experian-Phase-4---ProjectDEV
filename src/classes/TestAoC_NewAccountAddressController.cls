/**=====================================================================
 * Appirio Inc
 * Name: TestAoC_NewAccountAddressController.cls
 * Description: 
 * Created Date: Nov 11, 2013
 * Created By: Mohammed Irfan (Appirio)
 *
 * Date Modified         Modified By          Description of the update
 * January 28th, 2014    Nathalie Le Guay     Adding duplicate check tests
 * Mar 04th, 2014        Arpita Bose(Appirio) T-243282: Added Constants in place of String
 * Aprl 22nd, 2014       Aditi Bhardwaj  - Modify myUnitTest method to increase coverage  
 * Sep 11th, 2014        Naresh kr Ojha       Test class fix for issue: I-130073 
 =====================================================================*/
@isTest
private class TestAoC_NewAccountAddressController {
  
  
  static testMethod void myUnitTest() {
    Global_Settings__c custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING, Smart_Search_Query_Limit__c=250);
        insert custSettings;
        ApexPages.StandardController sc;
        Account acc = new Account(Name = '00TestAccount0',BillingCountry = 'Sweden');
       insert acc;    
       
       Address__c addr = new Address__c(Address_1__c='Test Addr1', Address_2__c='Test Addr2',Address_3__c='Test Addr3',
                                        State__c='test state',City__c='test city',zip__c='test zip',Country__c='test country');
       insert addr;
       
       Account_Address__c accAddrRel = new Account_Address__c(Account__c=acc.id,Address__c=addr.id);
       insert accAddrRel;
       
       ApexPages.currentPage().getParameters().put('accName', 'Test Acc');
       AddOrCreateNewAccountAddressController cntInit = new AddOrCreateNewAccountAddressController();
       
       ApexPages.currentPage().getParameters().put('accId',acc.id);
       ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_AddAddress);
       ApexPages.currentPage().getParameters().put('addrId',accAddrRel.Id+';'+addr.Id); 
        
        AddOrCreateNewAccountAddressController cnt = new AddOrCreateNewAccountAddressController();
        system.debug('###########'+cnt.QASTypedownSessionToken);
        cnt.address.Validation_Status__c='test';
        cnt.performSave();
        
        ApexPages.currentPage().getParameters().put('addrId',accAddrRel.id+';'+addr.id); 
        ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_AddAddress);
        cnt.performSave();
        
        ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_NewAccountAddress);
        cnt.performSave();
        cnt.cancel();
        cnt.blankCall();
        
  }


  static testMethod void testNewAccountAddressAndNewAccountExisting() {
    ApexPages.StandardController sc;
    createData();
    
    ApexPages.currentPage().getParameters().put('accId',acc.id);
    ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_AddAddress);

    AddOrCreateNewAccountAddressController cnt = new AddOrCreateNewAccountAddressController();
    system.debug('###########'+cnt.QASTypedownSessionToken);

    // Assign the address selected as being unique
    cnt.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cnt.address.Validation_Status__c='test';
    
    // This should create an Account, an Address record and an Account_Address__c junction record
    cnt.performSave();
    
    
    
    // Unique Address which we want to verify will not be created as a duplicate
    Address__c addressVerif = [SELECT Id, Address_Id__c FROM Address__c WHERE Id =: cnt.address.Id];
    
    Account_Address__c accountAddressFirst = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                              FROM Account_Address__c
                                              WHERE Account__c =: cnt.account.Id AND Address__c =: cnt.address.Id];

    // Address_Id__c is the generated key
    System.assertNotEquals(null, addressVerif.Address_Id__c);
    
    // Checks on the junction object
    System.assertEquals(addressVerif.Id, accountAddressFirst.Address__c);
    /* As createAccountAddress method is commented in AccountTriggerHandler.cls so this code snippet 
      is not more valid to be checked. nojha@appirio.com. 
    cnt = new AddOrCreateNewAccountAddressController();
    
    // Specifying that a new address needs to be created
    cnt.action = Label.ASS_Operation_NewAccountAddress;
    ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_NewAccountAddress);
    
    // Create new Account
    Account acc1 = new Account(Name = '00TestDuplicateAccount0',BillingCountry = 'United States');
    insert acc1;
    cnt.account = acc1;
     

    // Assign the same address as for the first Account
    Address__c newAddress = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    insert newAddress;
    cnt.address = newAddress;
    cnt.address.Validation_Status__c='test';

    Test.StartTest();
    // This should use the existing address record
    cnt.performSave();
    Test.StopTest();
    
    system.debug('===cnt.account.Id===' + cnt.account.Id);
    system.debug('===cnt.address.Id===' + cnt.address.Id);
    // Getting the created Account_Address__c junction record. We want to verify it links to the existing Address__c record
    Account_Address__c accountAddressSecond;
    for(Account_Address__c accAddressSec : [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                               FROM Account_Address__c
                                               WHERE Account__c =: cnt.account.Id AND Address__c =: cnt.address.Id]){
      accountAddressSecond = accAddressSec;
    }
    System.assertEquals(addressVerif.Id, accountAddressSecond.Address__c);
    */
  }



  private static Account acc;
  private static Address__c address;

  static testMethod void testNewAccountAddressAndNewContactExisting() {
    ApexPages.StandardController sc;
    createData();
    ApexPages.currentPage().getParameters().put('accId',acc.id);
    ApexPages.currentPage().getParameters().put('action',Label.ASS_Operation_AddAddress);

    AddOrCreateNewAccountAddressController cnt = new AddOrCreateNewAccountAddressController();
    system.debug('###########'+cnt.QASTypedownSessionToken);

    // Assign the address selected as being unique
    cnt.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cnt.address.Validation_Status__c='test';

    // This should create an Account, an Address record and an Account_Address__c junction record
    cnt.performSave();
    
    // Unique Address which we want to verify will not be created as a duplicate
    Address__c addressVerif = [SELECT Id, Address_Id__c FROM Address__c WHERE Id =: cnt.address.Id];
    Account_Address__c accountAddressFirst = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                              FROM Account_Address__c
                                              WHERE Account__c =: cnt.account.Id AND Address__c =: cnt.address.Id];

    // Address_Id__c is the generated key
    System.assertNotEquals(null, addressVerif.Address_Id__c);
    
    // Checks on the junction object
    System.assertEquals(addressVerif.Id, accountAddressFirst.Address__c);
    
    AddOrCreateNewContactAddressController cntContact = new AddOrCreateNewContactAddressController();
    
    // Specifying that a new address needs to be created
    cntContact.action = Label.CSS_Operation_NewContactAddress;
    ApexPages.currentPage().getParameters().put('action', Label.CSS_Operation_NewContactAddress);
    
    // Create new Contact
    cntContact.contact = new Contact(FirstName= '00TestContact0',LastName = 'Sweden');

    // Assign the same address as for the Account
    cntContact.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cntContact.address.Validation_Status__c='test';

    Test.StartTest();
    // This should use the existing address record
    cntContact.performSave();
    Test.StopTest();

    // Getting the created Contact_Address__c junction record. We want to verify it links to the existing Address__c record
    Contact_Address__c contactAddressSecond = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                               FROM Contact_Address__c
                                               WHERE Contact__c =: cntContact.contact.Id AND Address__c =: cntContact.address.Id];
    System.assertEquals(addressVerif.Id, contactAddressSecond.Address__c);
  }

  static void CreateData() {
    Global_Settings__c custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING,Smart_Search_Query_Limit__c=250);
    insert custSettings;
    acc = new Account(Name = '00TestAccount0',BillingCountry = 'Sweden');
    insert acc;
    address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    insert address;
  }
}