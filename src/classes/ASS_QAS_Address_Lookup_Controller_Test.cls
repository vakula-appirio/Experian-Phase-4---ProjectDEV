/**=====================================================================
 * Appirio, Inc
 * Name: ASS_QAS_Address_Lookup_Controller_Test
 * Description: Test class for ASS_QAS_Address_Lookup_Controller
                
 * Created Date: Apr 22nd, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 
 =====================================================================*/
 @isTest
 public class ASS_QAS_Address_Lookup_Controller_Test {
 	
 	@isTest
 	public static void testASS_QAS_Address_Lookup_Controller() {
 		Account testAcc = Test_Utils.insertAccount();
 		List<Address__c> addrsLst = new List<Address__c>();
     Address__c addrs1 = new Address__c(Address_1__c = 'Test Addr1 001', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    Authenticated_Address__c = true);
     Address__c addrs2 = new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    zip__c = 'test zip', Country__c = 'test country',
                                    Authenticated_Address__c = false);
     Address__c addrs3 = new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    zip__c = 'test zip', Country__c = 'test country',
                                    Authenticated_Address__c = false);
     addrsLst.add(addrs1);  
     addrsLst.add(addrs2);
     addrsLst.add(addrs3);                               
     insert addrsLst; 
     
    List<Account_Address__c> accList = new List<Account_Address__c>();
       
    for (Address__c rec : addrsLst) {
            accList.add(new Account_Address__c(Account__c = testAcc.ID, Address__c = rec.ID));
    }
    insert accList;
    
    Test.startTest();
    
    ASS_QAS_Address_Lookup_Controller controller = new ASS_QAS_Address_Lookup_Controller();
    
    QAS_NA__QAS_CA_Account__c account =  new QAS_NA__QAS_CA_Account__c();
    account.QAS_NA__ValidationSessionToken__c = 'test_Token';
    account.QAS_NA__InteractiveIntervalFromLastUpdate__c = 18000;
    account.QAS_NA__InteractiveInvokeIntervalFromLastUpdate__c = 8 ;
    account.QAS_NA__LicenseKey__c = 'test123';
    account.QAS_NA__TriggerRecordsLimit__c =2;
    account.QAS_NA__ValidCountryValues__c = 'CA';
    insert account;
    
    controller.accId = testAcc.Id ;
    controller.accId = null;
    
    Test.stopTest();
    
 	}

}