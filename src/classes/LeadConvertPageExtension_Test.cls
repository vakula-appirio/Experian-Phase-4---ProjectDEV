/**=====================================================================
 * Experian
 * Name: LeadConvertPageExtension_Test
 * Description: Tests for LeadConvertPageExtension
 *              Case #580226
 * Created Date: May 20th, 2015
 * Created By: Paul Kissick
 *
 * Date Modified      Modified By                  Description of the update
 * May 20th, 2015     Paul Kissick                 Created 
  =====================================================================*/
@isTest
private class LeadConvertPageExtension_Test {

  static testMethod void runNormalTest() {
    Lead testLead = [SELECT Id, Assigned_Campaign__c,IsConverted FROM Lead WHERE FirstName != 'BobLead' LIMIT 1];
    
    Integer totalCampsToCheck = [SELECT COUNT() FROM CampaignMember WHERE LeadId = :testLead.Id];
    
    ApexPages.StandardController con = new ApexPages.StandardController(testLead);
    LeadConvertPageExtension lcpe = new LeadConvertPageExtension(con);
    
    lcpe.prepareCampaigns();
    // On first load, we have 11 campaigns associated, so this must be equal to or less than the limit
    system.assert(lcpe.currentLimit >= lcpe.allCampaigns.size());
    
    do {
      lcpe.showMoreCampaigns();
      system.assert(lcpe.currentLimit >= lcpe.allCampaigns.size());
    } while(lcpe.currentLimit < totalCampsToCheck);
    
    
    system.assertEquals(totalCampsToCheck,lcpe.allCampaigns.size());
    
    // untick the do not create option...
    lcpe.doNotCreateOpp = false;
    lcpe.checkTicks();
    
    ApexPages.Message[] pageMessages = ApexPages.getMessages();
    system.assertEquals(0, pageMessages.size(),'There are page messages. There shouldn\'t be.');  // There shouldn't be any page messages yet.
    
    // now lets tick all the campaigns, and check again.
    for(LeadConvertPageExtension.campaignWrapper cw : lcpe.allCampaigns) {
      cw.selected = true;
    }
    lcpe.checkTicks();
    pageMessages = ApexPages.getMessages();
    system.assertNotEquals(0, pageMessages.size(),'There should be a page message.'); 
    
    // now lets count the ticks as 1 should be left
    Integer ticked = 0;
    for(LeadConvertPageExtension.campaignWrapper cw : lcpe.allCampaigns) {
      if (cw.selected) ticked+=1;
    }
    system.assertEquals(1,ticked,'Too many are now ticked.');
    
    // now lets tick all the campaigns, and try a save.
    for(LeadConvertPageExtension.campaignWrapper cw : lcpe.allCampaigns) {
      cw.selected = true;
    }
    lcpe.save();
    
    pageMessages = ApexPages.getMessages();
    system.assertNotEquals(0, pageMessages.size(),'There should be a page message.'); 
    
    // now lets count the ticks as 1 should be left
    ticked = 0;
    for(LeadConvertPageExtension.campaignWrapper cw : lcpe.allCampaigns) {
      if (cw.selected) ticked+=1;
    }
    system.assertEquals(1,ticked,'Too many are now ticked.');
    
    PageReference pr = lcpe.save();
    system.assert(pr != null);
    
  }
  
  static testMethod void runNoCampsTest() {
    Lead testLead = [SELECT Id, Assigned_Campaign__c,IsConverted FROM Lead WHERE FirstName = 'BobLead' LIMIT 1];
    
    ApexPages.StandardController con = new ApexPages.StandardController(testLead);
    LeadConvertPageExtension lcpe = new LeadConvertPageExtension(con);
    
    PageReference pr = lcpe.prepareCampaigns();
    system.assert(pr != null);
    
    
  }
  
  static testMethod void runCampsSkipTest() {
    Lead testLead = [SELECT Id, Assigned_Campaign__c,IsConverted FROM Lead WHERE FirstName != 'BobLead' LIMIT 1];
    Integer totalCampsToCheck = [SELECT COUNT() FROM CampaignMember WHERE LeadId = :testLead.Id];
    
    ApexPages.StandardController con = new ApexPages.StandardController(testLead);
    LeadConvertPageExtension lcpe = new LeadConvertPageExtension(con);
    
    lcpe.prepareCampaigns();
    system.assert(lcpe.allCampaigns.size() > 0);
    lcpe.doNotCreateOpp = true;
    lcpe.skipOpp();
    PageReference pr = lcpe.save();
    system.assert(pr != null);
    
    
  }
  
  static testMethod void runNormalNotTicked() {
    Lead testLead = [SELECT Id, Assigned_Campaign__c,IsConverted FROM Lead WHERE FirstName != 'BobLead' LIMIT 1];
    Integer totalCampsToCheck = [SELECT COUNT() FROM CampaignMember WHERE LeadId = :testLead.Id];
    
    ApexPages.StandardController con = new ApexPages.StandardController(testLead);
    LeadConvertPageExtension lcpe = new LeadConvertPageExtension(con);
    
    lcpe.prepareCampaigns();
    system.assert(lcpe.allCampaigns.size() > 0);
    lcpe.doNotCreateOpp = false;
    PageReference pr = lcpe.save();
    system.assert(pr == null); // should be an error about not ticking.
    
    system.assertNotEquals(0, ApexPages.getMessages().size(),'There should be a page message.'); 
    
  }
  
  static testMethod void testOppHelperResetCampaign() {
    // Pick a campaign
    Campaign cam = [SELECT Id FROM Campaign LIMIT 1];
    
    Account a = Test_Utils.createAccount();
    insert a;
    Opportunity o1 = Test_Utils.createOpportunity(a.Id);
    o1.Lead_Update_Campaign__c = true;
    o1.Lead_Assigned_Campaign__c = cam.Id;
    o1.Lead_Converted_with_No_Primary_Campaign__c = null;
    
    Opportunity o2 = Test_Utils.createOpportunity(a.Id);
    o2.Lead_Update_Campaign__c = true;
    o2.Lead_Assigned_Campaign__c = null;
    o2.Lead_Converted_with_No_Primary_Campaign__c = null;
    
    OpportunityTriggerHelper.resetCampaignForLeadConversions(new List<Opportunity>{o1,o2});
    system.assertEquals(o1.CampaignId,cam.Id,'Campaign isn\'t set correctly. ('+o1.CampaignId+','+cam.Id+')');
    system.assertEquals(o1.Lead_Converted_with_No_Primary_Campaign__c,false,'Incorrectly set Lead_Converted_with_No_Primary_Campaign__c when campaign set');
    system.assertEquals(o2.Lead_Converted_with_No_Primary_Campaign__c,true,'Incorrectly set Lead_Converted_with_No_Primary_Campaign__c when campaign not set');
    
  }
    
  @testSetup
  static void createTestData() {
    // Load up 11 campaigns.
    List<Campaign> loadCamps = new List<Campaign>();
    for(Integer i = 0;  i<11; i++) {
      Campaign cNew = new Campaign(
        Name = 'Test Campaign '+String.valueOf(i), 
        IsActive = true, 
        StartDate = Date.today().addDays(-10),
        EndDate = Date.today().addDays(10),
        Status = 'Active',
        Type = 'Other',
        Audience__c = 'Test',
        Campaign_Code__c = 'Smething'
      );
      loadCamps.add(cNew);
    }
    insert loadCamps;
    
    Lead testLead = Test_Utils.insertLead();
    Lead testLead2 = Test_Utils.insertLead();
    testLead2.FirstName = 'BobLead';
    update testLead2;
    
    List<CampaignMember> loadCms = new List<CampaignMember>();
    for(Campaign c : loadCamps) {
      loadCms.add(new CampaignMember(
        LeadId = testLead.Id,
        CampaignId = c.Id,
        Status = 'Sent'
      ));
    }
    insert loadCms;
    
  }
}