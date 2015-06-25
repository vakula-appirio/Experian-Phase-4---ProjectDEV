/**=====================================================================
 * Appirio Inc
 * Name: TestAoC_NewContactAddressController.cls
 * Description: 
 * Created Date: Nov 20, 2013
 * Created By: Mohammed Irfan (Appirio)
 *
 * Date Modified         Modified By          Description of the update
 * January 28th, 2014    Nathalie Le Guay     Adding duplicate check tests
 * Mar 04th, 2014        Arpita Bose(Appirio) T-243282: Added Constants in place of String
 * Mar 20th, 2014        Arpita Bose(Appirio) T-253906: Fixed test class
 * Aprl 22nd, 2014       Aditi Bhardwaj       Modified myUnitTest method to increase coverage 
 * May 1st, 2014         Arpita Bose          Updated myUnitTest method to increase coverage 
 * Sep 11th, 2014        Naresh kr Ojha       Test class fix for issue: I-130073
 =====================================================================*/
@isTest
private class TestAoC_NewContactAddressController {

    static testMethod void myUnitTest() {
       createData();
       ApexPages.StandardController sc;
       Contact con = new Contact(FirstName= '00TestContact0',LastName = 'Sweden');
       insert con;    
       
       Address__c addr = new Address__c(Address_1__c='Test Addr1', Address_2__c='Test Addr2',Address_3__c='Test Addr3',
                                        State__c='test state',City__c='test city',zip__c='test zip',Country__c='test country');
       insert addr;
       
       Contact_Address__c conAddrRel = new Contact_Address__c(Contact__c=con.id,Address__c=addr.id);
       insert conAddrRel;
       
       // call constructor without passing conId
       ApexPages.currentPage().getParameters().put('conFName', 'Test FName');
       ApexPages.currentPage().getParameters().put('conLName', 'Test LName');
       ApexPages.currentPage().getParameters().put('conEmail', 'test@test.com');
       ApexPages.currentPage().getParameters().put('accId', acc.Id);

       AddOrCreateNewContactAddressController cntAdd = new AddOrCreateNewContactAddressController(); 
       
       
       
       ApexPages.currentPage().getParameters().put('conId',con.id);
       ApexPages.currentPage().getParameters().put('action',Label.CSS_Operation_AddAddress);
       ApexPages.currentPage().getParameters().put('addrId',conAddrRel.Id+';'+addr.Id);  
        
        AddOrCreateNewContactAddressController cnt = new AddOrCreateNewContactAddressController();
        system.debug('###########'+cnt.QASTypedownSessionToken);
        cnt.address.Validation_Status__c='test';
        cnt.performSave();
        
        ApexPages.currentPage().getParameters().put('addrId',conAddrRel.id+';'+addr.id); 
        ApexPages.currentPage().getParameters().put('action',Label.CSS_Operation_AddAddress);
        cnt.performSave();
        
        ApexPages.currentPage().getParameters().put('action',Label.CSS_Operation_NewContactAddress);
        cnt.performSave();
        cnt.cancel();
        cnt.blankCall();
        cnt.accountUpdateId();
        cnt.updateAddress(); // NLG - SPRINT 2 DEPLOYMENT - uncomment past March 25th
        cnt.address.Id = null;
        cnt.address.Validation_Status__c = null;
        cnt.performSave();
        
    }

  static testMethod void testNewContactAddressAndNewContactExisting() {
    ApexPages.StandardController sc;
    createData();
    ApexPages.currentPage().getParameters().put('conId',contact.id);
       ApexPages.currentPage().getParameters().put('action',Label.CSS_Operation_AddAddress);

    AddOrCreateNewContactAddressController cnt = new AddOrCreateNewContactAddressController();
    system.debug('###########'+cnt.QASTypedownSessionToken);

    // Assign the address selected as being unique
    cnt.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cnt.address.Validation_Status__c='test';

    // This should create a Contact, an Address record and an Account_Address__c junction record
    cnt.performSave();
    
    // Unique Address which we want to verify will not be created as a duplicate
    Address__c addressVerif = [SELECT Id, Address_Id__c FROM Address__c WHERE Id =: cnt.address.Id];
    Contact_Address__c contactAddressFirst = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                              FROM Contact_Address__c
                                              WHERE Contact__c =: cnt.contact.Id AND Address__c =: cnt.address.Id];

    // Address_Id__c is the generated key
    System.assertNotEquals(null, addressVerif.Address_Id__c);
    
    // Checks on the junction object
    System.assertEquals(addressVerif.Id, contactAddressFirst.Address__c);
    
    cnt = new AddOrCreateNewContactAddressController();
    
    // Specifying that a new address needs to be created
    cnt.action = Label.CSS_Operation_NewContactAddress;
    ApexPages.currentPage().getParameters().put('action', Label.CSS_Operation_NewContactAddress);
    
    // Create new Contact
    cnt.contact = new Contact(FirstName= '00TestDuplicateContact0',LastName = 'Sweden');

    // Assign the same address as for the first Contact
    cnt.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cnt.address.Validation_Status__c='test';

    Test.StartTest();
    // This should use the existing address record
    cnt.performSave();
    Test.StopTest();

    // Getting the created Contact_Address__c junction record. We want to verify it links to the existing Address__c record
    Contact_Address__c contactAddressSecond = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                               FROM Contact_Address__c
                                               WHERE Contact__c =: cnt.contact.Id AND Address__c =: cnt.address.Id];
    System.assertEquals(addressVerif.Id, contactAddressSecond.Address__c);
  }


  static testMethod void testNewContactAddressAndNewAccountExisting() {
    ApexPages.StandardController sc;
    createData();
    ApexPages.currentPage().getParameters().put('conId',contact.id);
       ApexPages.currentPage().getParameters().put('action',Label.CSS_Operation_AddAddress);

    AddOrCreateNewContactAddressController cnt = new AddOrCreateNewContactAddressController();
    system.debug('###########'+cnt.QASTypedownSessionToken);

    // Assign the address selected as being unique
    cnt.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cnt.address.Validation_Status__c='test';

    // This should create a Contact, an Address record and an Account_Address__c junction record
    cnt.performSave();
    
    // Unique Address which we want to verify will not be created as a duplicate
    Address__c addressVerif = [SELECT Id, Address_Id__c FROM Address__c WHERE Id =: cnt.address.Id];
    Contact_Address__c contactAddressFirst = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                              FROM Contact_Address__c
                                              WHERE Contact__c =: cnt.contact.Id AND Address__c =: cnt.address.Id];

    // Address_Id__c is the generated key
    System.assertNotEquals(null, addressVerif.Address_Id__c);
    
    // Checks on the junction object
    System.assertEquals(addressVerif.Id, contactAddressFirst.Address__c);


   /*
    //As createAccountAddress method is commented in AccountTriggerHandler.cls so this code snippet 
      is not more valid to be checked. nojha@appirio.com. 

    AddOrCreateNewAccountAddressController cntAccount = new AddOrCreateNewAccountAddressController();

    // Specifying that a new address needs to be created
    cntAccount.action = Label.ASS_Operation_NewAccountAddress;
    ApexPages.currentPage().getParameters().put('action', Label.ASS_Operation_NewAccountAddress);
    
    // Create new Contact
    Account acc = new Account(Name = '00TestDuplicateAccount0',BillingCountry = 'United States');
    //insert acc;
    cntAccount.account = acc;

    // Assign the same address as for the first Account
    cntAccount.address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    cntAccount.address.Validation_Status__c='test';

    Test.StartTest();
    // This should use the existing address record
    cntAccount.performSave();
    Test.StopTest();

    // Getting the created Account_Address__c junction record. We want to verify it links to the existing Address__c record
    Account_Address__c accountAddressSecond = [SELECT Id, Address__r.Id, Address__r.Address_Id__c
                                               FROM Account_Address__c
                                               WHERE Account__c =: cntAccount.account.Id AND Address__c =: cntAccount.address.Id];
    System.assertEquals(addressVerif.Id, accountAddressSecond.Address__c);*/
  }

  private static Contact contact;
  private static Address__c address;
  private static Account acc;
  
  static void CreateData() {
    Global_Settings__c custSettings = new Global_Settings__c(name=Constants.GLOBAL_SETTING,Smart_Search_Query_Limit__c=250);
    insert custSettings;
    
    acc = new Account(Name = '00TestAccount0',BillingCountry = 'Sweden');
    insert acc;
    contact = new Contact(FirstName= '00TestContact0',LastName = 'Sweden');
    insert contact;
    address = new Address__c(Address_1__c='818 40th Avenue', Address_2__c='',Address_3__c='',
                          State__c='CA',City__c='San Francisco',zip__c='94121',Country__c='USA');
    insert address;
    
    Profile p = [SELECT id from profile where name =: Constants.PROFILE_SYS_ADMIN ];
    User testUser = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                       emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                       localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', 
                       username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true,
                       CompanyName = 'test Company');
    testUser.Country__c = 'United States';                
    insert testUser;
  }
}