/**=====================================================================
 * Appirio, Inc
 * Name: LeadTriggerHandler_Test
 * Description: Test class for lead Trigger
 								T-194935 , T-213204
 * Created Date: Nov 19th, 2012
 * Created By: Pankaj Mehra (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014								Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Feb 27th, 2014								Arpita Bose(Appirio)				 Fixed failure.
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282:Added constants in place of String
 * Mar 14th, 2014               Arpita Bose(Appirio)         T-253906: Fixed error
 * Apr 22nd, 2014               Arpita Bose                  Updated method testLeadConversion()to increase the code coverage
 =====================================================================*/
@isTest(seealldata=true)
public class LeadTriggerHandler_Test { 
    
    @isTest
    public static void testLeadConversion() {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.LEAD_TRIGGER);
        //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        IsDataAdmin__c isDateAdmin = [SELECT Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];
        isDateAdmin.IsDataAdmin__c = false;
        update isDateAdmin;
        
        Lead lead = Test_Utils.createLead();
        lead.LastName = 'Test_Lead_Convert';
        lead.Capability__c = 'Application Processing';
        lead.Budget__c = 'Less than 1,000';
        insert lead;
        system.debug('#########lead#########'+lead);
                
        ELQA_Marketing_Activity__c marketActivity = Test_Utils.createMarketingActivity(); 
        marketActivity.Lead__c = lead.Id;
        insert marketActivity;
        system.debug('#########marketActivity#########'+marketActivity);
        User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        insert testUser;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.id);      
        lc.setOwnerId(testUser.Id);
        //Test.startTest();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.convertedStatus =convertStatus.MasterLabel;
        lc.setDoNotCreateOpportunity(true);
        system.debug('#########lc#########'+lc);
        
        Test.startTest();

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        system.debug('#########lcr#########'+lcr);

        System.assert(lcr.isSuccess());
        
        Lead existingLead = [Select id, isConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId, 
                               createdbyid FROM Lead where id = :lead.id];
        
        System.assert(existingLead.isConverted);
        System.assert(existingLead.ConvertedAccountId != null);
        System.assert(existingLead.ConvertedOpportunityId == null);
        
        List<ELQA_Marketing_Activity__c> mActivityLst1 = [SELECT Id, Contact__c from ELQA_Marketing_Activity__c
                                                         WHERE Contact__c =: lcr.getContactId()];
        
        system.debug('#######mActivityLst1.size()########' +mActivityLst1.size());                                                 
        System.assert(mActivityLst1.size() > 0);
        
        List<ELQA_Marketing_Activity__c> mActivityLst2 = [SELECT Id, Contact__c from ELQA_Marketing_Activity__c
                                                         WHERE Account__c =: lcr.getAccountId()];
        
        system.debug('#######mActivityLst2.size()########' +mActivityLst2.size());                                                 
        System.assert(mActivityLst2.size() > 0);                                                  
        Test.stopTest();
    }
}