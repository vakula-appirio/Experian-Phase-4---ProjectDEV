@isTest
public class TestErrorReportingTrigger
{
    public static testMethod void TestSessionToken()
    {     
        QAS_NA__QAS_CA_Account__c acct = new QAS_NA__QAS_CA_Account__c (QAS_NA__ValidationSessionToken__c = '481E10B2-0541-49E2-847E-29B882E4E01D',  QAS_NA__InteractiveIntervalFromLastUpdate__c = 2, QAS_NA__InteractiveInvokeIntervalFromLastUpdate__c = 8, QAS_NA__LicenseKey__c = 'HGxh6Y2tqTuE0r6pu3PPUuGmun+/JFQYcnIjYWx1Y78fWv/BJOjHLO8Et8ENfAn0uGLJ6XgCXLYCs8JZ9hOVeA==', QAS_NA__TriggerRecordsLimit__c = 2, QAS_NA__ValidCountryValues__c = 'CA, USA' );
        insert acct;
        
        acct.QAS_NA__ValidationSessionToken__c = 'Test';
        update acct;
        
        System.assertEquals(acct.QAS_NA__ValidationSessionToken__c,'Test');
    }
}