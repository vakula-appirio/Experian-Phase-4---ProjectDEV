/**=====================================================================
 * Appirio, Inc
 * Name: TestOverrideAddressDetailExtension
 * Description: The following class is for testing the OverrideAddressDetailExtension class.
                Story:        S-150052
                Task:         T-203132
 * Created Date: 
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014							  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 05th, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Oct 29th,2014                Pallavi Sharma(Appirio)      Fix Failure
 =====================================================================*/
@isTest
private class TestOverrideAddressDetailExtension
{    
    
    static testMethod void testAddressWithFieldSet() {
        
        //define an address record here, pull all fields from it, insert it into SF
        Address__c testAddress = new Address__c(Address_1__c='addr1', Address_2__c='addr2',
        Address_3__c='addr3',Address_4__c='addr4',CEDEX__c='cedextest',City__c='testCity',codiga_Postal__c='testCodig',
        Country__c='Cyprus',County__c='sample',Floor__c='testfloor',Partofterritory__c='testTerr',POBox__c='testBox',
        Postcode__c='testCode',Prefecture__c='Iwate', Province__c='testprovince',SortingCode__c='testCode',Suite__c='testSuite');

        insert testAddress;
        
        // generate a vf page taking in the address id
        PageReference pageRef = Page.OverrideAddressDetail;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAddress.id);
        
        OverrideAddressDetailExtension testController =  new OverrideAddressDetailExtension(new ApexPages.StandardController(new Address__c()));
        
        //testing address 1 below
        String countryOfController = testController.getAddressName().country__c;
        system.debug('WWWWWW' + countryOfController);
        system.assert(countryOfController=='Cyprus');

        system.assert(testController.getAddressName().name!=null);
        testController.getAddress();
        /*
        system.assert(testController.getAddressName().Address_1__c =='addr1' );
        system.assert(testController.getAddressName().Address_2__c =='addr2' );
        system.assert(testController.getAddressName().PostCode__c =='testCode' );
        system.assert(testController.getAddressName().City__c =='testCity' );
        system.assert(testController.getAddressName().Country__c =='Cyprus' );*/
    }
    
    static testMethod void testAddressWithoutFieldSet() {
        
        Address__c testAddress2 = new Address__c(Address_1__c='addr12', Address_2__c='addr22',
        Address_3__c='addr32',Address_4__c='addr42',CEDEX__c='cedextest2',City__c='testCity2',codiga_Postal__c='testCodig2',
        Country__c='Unknown country',County__c='sample2',Floor__c='testfloor2',Partofterritory__c='testTerr2',POBox__c='testBox2',
        Postcode__c='testCode2',Prefecture__c='Iwate2', Province__c='testprovince2',SortingCode__c='testCode2',Suite__c='testSuite2');
        
        insert testAddress2;
        
        PageReference pageRef = Page.OverrideAddressDetail;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAddress2.id);
        
        OverrideAddressDetailExtension testController =  new OverrideAddressDetailExtension(new ApexPages.StandardController(new Address__c()));
        
        String countryOfController = testController.getAddressName().country__c;
        system.debug('WWWWWW' + countryOfController);
        system.assert(countryOfController=='Unknown country');

        system.assert(testController.getAddressName().name!=null);
        testController.getAddress();
        /*
        system.assert(testController.getAddressName().Address_1__c =='addr12' );
        system.assert(testController.getAddressName().Address_2__c =='addr22' );
        system.assert(testController.getAddressName().PostCode__c =='testCode2' );
        system.assert(testController.getAddressName().City__c =='testCity2' );
        system.assert(testController.getAddressName().Country__c =='Unknown country' );
        system.assert(testController.getAddressName().Suite__c =='testSuite2' );*/
        
    }
    
    static testMethod void testAddressWithAddressFieldSetMappings() {
        
        Address_Field_Set_Mappings__c testMapping = new Address_Field_Set_Mappings__c();
        testMapping.Name = 'United States';
        testMapping.Fieldset_to_use__c='USA';
        insert testMapping; 
        
        Address__c testAddress2 = new Address__c(Address_1__c='addr12', Address_2__c='addr22',
        Address_3__c='addr32',Address_4__c='addr42',CEDEX__c='cedextest2',City__c='testCity2',codiga_Postal__c='testCodig2',
        Country__c='United States',County__c='sample2',Floor__c='testfloor2',Partofterritory__c='testTerr2',POBox__c='testBox2',
        Postcode__c='testCode2',Prefecture__c='Iwate2', Province__c='testprovince2',SortingCode__c='testCode2',Suite__c='testSuite2',
        State__c ='testState');
        
        insert testAddress2;
        
        PageReference pageRef = Page.OverrideAddressDetail;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAddress2.id);
        
        OverrideAddressDetailExtension testController =  new OverrideAddressDetailExtension(new ApexPages.StandardController(new Address__c()));
        
        String countryOfController = testController.getAddressName().country__c;
        system.debug('WWWWWW' + countryOfController);
        system.assert(countryOfController=='United States');

        system.assert(testController.getAddressName().name!=null);
        testController.getAddress();
        /*
        system.assert(testController.getAddressName().Address_1__c =='addr12' );
        system.assert(testController.getAddressName().Address_2__c =='addr22' );
        system.assert(testController.getAddressName().Address_3__c =='addr32' );
        system.assert(testController.getAddressName().City__c =='testCity2' );
        system.assert(testController.getAddressName().County__c =='sample2' );
        system.assert(testController.getAddressName().Country__c =='United States' );
        system.assert(testController.getAddressName().State__c =='testState' );*/
        
    }
    
    static testMethod void testAddressWithNullFieldSet() {
        
        Address__c testAddress2 = new Address__c(Address_1__c='addr12', Address_2__c='addr22',
        Address_3__c='addr32',Address_4__c='addr42',CEDEX__c='cedextest2',City__c='testCity2',codiga_Postal__c='testCodig2',
        Country__c='unknown',County__c='sample2',Floor__c='testfloor2',Partofterritory__c='testTerr2',POBox__c='testBox2',
        Postcode__c='testCode2',Prefecture__c='Iwate2', Province__c='testprovince2',SortingCode__c='testCode2',Suite__c='testSuite2',
        State__c ='testState', Authenticated_Address__c=true);
        
        insert testAddress2;
        
        PageReference pageRef = Page.OverrideAddressDetail;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAddress2.id);
        
        OverrideAddressDetailExtension testController =  new OverrideAddressDetailExtension(new ApexPages.StandardController(new Address__c()));
        
        String countryOfController = testController.getAddressName().country__c;
        system.debug('WWWWWW' + countryOfController);
        system.assert(countryOfController=='unknown');

        system.assert(testController.getAddressName().name!=null);
        testController.getAddress();
        /*
        system.assert(testController.getAddressName().Address_1__c =='addr12' );
        system.assert(testController.getAddressName().Address_2__c =='addr22' );
        system.assert(testController.getAddressName().Address_3__c =='addr32' );
        system.assert(testController.getAddressName().City__c =='testCity2' );
        system.assert(testController.getAddressName().County__c =='sample2' );
        system.assert(testController.getAddressName().Country__c =='unknown' );
        system.assert(testController.getAddressName().State__c =='testState' );*/
        
    }
    
    static testMethod void testCustomSettings() {
        Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN];
        User testUser1 = new User(lastName ='test1',Email = 'test1@gmail.com', profileId = p.Id, Business_Unit__c = null, Global_Business_Line__c = null,alias = 'test1', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test1@testorg.com');
        
        Global_Settings__c lastRun = new Global_Settings__c();
        lastRun.Profile_IDs_allowed_to_edit_Addresses__c =  String.valueOf(p.Id).left(15);
        lastRun.Name = (Constants.GLOBAL_SETTING);
        insert lastRun;
        
        Address__c testAddress2 = new Address__c(Address_1__c='addr12', Address_2__c='addr22',
        Address_3__c='addr32',Address_4__c='addr42',CEDEX__c='cedextest2',City__c='testCity2',codiga_Postal__c='testCodig2',
        Country__c='unknown',County__c='sample2',Floor__c='testfloor2',Partofterritory__c='testTerr2',POBox__c='testBox2',
        Postcode__c='testCode2',Prefecture__c='Iwate2', Province__c='testprovince2',SortingCode__c='testCode2',Suite__c='testSuite2',
        State__c ='testState', Authenticated_Address__c=true);
        
        insert testAddress2;
        
        PageReference pageRef = Page.OverrideAddressDetail;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAddress2.id);
        
        OverrideAddressDetailExtension testController =  new OverrideAddressDetailExtension(new ApexPages.StandardController(new Address__c()));
        
        String countryOfController = testController.getAddressName().country__c;
        system.debug('WWWWWW' + countryOfController);
        system.debug('1111111122: ' + UserInfo.getProfileId());
        
        system.assert(countryOfController=='unknown');

        system.assert(testController.getAddressName().name!=null);
        
        // test the getProfileEditPermission() method here
        system.assert(testController.getProfileEditPermission());
        
        testController.getAddress();
        /*
        system.assert(testController.getAddressName().Address_1__c =='addr12' );
        system.assert(testController.getAddressName().Address_2__c =='addr22' );
        system.assert(testController.getAddressName().Address_3__c =='addr32' );
        system.assert(testController.getAddressName().City__c =='testCity2' );
        system.assert(testController.getAddressName().County__c =='sample2' );
        system.assert(testController.getAddressName().Country__c =='unknown' );
        system.assert(testController.getAddressName().State__c =='testState' );*/
        
    }     
    
}