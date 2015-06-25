/**=====================================================================
 * Experian
 * Name: LeadConvertPageExtension
 * Description: Override of the Lead Convert screen to allow Primary Campaign Attribution
 *              Case #580226
 * Created Date: May 20th, 2015
 * Created By: Paul Kissick
 *
 * Date Modified      Modified By                  Description of the update
 * May 20th, 2015     Paul Kissick                 Created 
  =====================================================================*/

public with sharing class LeadConvertPageExtension {
  
  ApexPages.StandardController stdCon;
  
  Lead currentLead;
  
  @TestVisible Integer limitSteps = 5; // change this to increase the steps per 'more' call
  
  @TestVisible Integer currentLimit = 5;
  
  public Boolean doNotCreateOpp {get{if(doNotCreateOpp == null) doNotCreateOpp = false; return doNotCreateOpp;}set;}
  public Boolean doNotAssignCamp {get{if(doNotAssignCamp == null) doNotAssignCamp = false; return doNotAssignCamp;}set;}
  
  @TestVisible String getUrlNoOpty() {
    return '/lead/leadconvert.jsp?retURL='+currentLead.Id+'&id='+currentLead.Id+'&nooppti=1';
  }
  @TestVisible String getUrlYesOpty() {
    return '/lead/leadconvert.jsp?retURL='+currentLead.Id+'&id='+currentLead.Id+'&nooppti=0';
  }
  
  public class campaignWrapper {
    public Boolean selected {get;set;}
    public Campaign camp {get;set;}
    public campaignWrapper(Campaign c, Boolean sel) {
      camp = c;
      selected = sel;
    }
  }

  public List<campaignWrapper> allCampaigns {get{
    if (allCampaigns == null) {
      allCampaigns = new list<campaignWrapper>();
    }
    return allCampaigns;
  }set;}
  
  public LeadConvertPageExtension(ApexPages.StandardController c) {
    stdCon = c;
    if (!Test.isRunningTest()) {
      stdCon.addFields(new List<String>{'Assigned_Campaign__c','IsConverted'});
    }
    currentLead = (Lead)stdCon.getRecord();
  }
  
  //*********************************************
  // Load the list of the most recent campaigns
  //*********************************************
  public PageReference prepareCampaigns() {
    allCampaigns.clear();
    // Also check the lead isn't already converted...
    if (currentLead.IsConverted) {
      return new PageReference('/'+currentLead.Id);
    }
    currentLimit = (currentLimit > 2000) ? 2000 : currentLimit;
    for(CampaignMember cm : [
      SELECT Campaign.Id, Campaign.Name, Campaign.StartDate, Campaign.EndDate, Campaign.Type, Campaign.Status 
      FROM CampaignMember 
      WHERE LeadId = :currentLead.Id
      ORDER BY CreatedDate DESC
      LIMIT :currentLimit
      ]) {
      allCampaigns.add(new campaignWrapper(cm.Campaign, (cm.Campaign.Id == currentLead.Assigned_Campaign__c) ? true : false));
    }
    if (allCampaigns.isEmpty()) {
      // redirect to normal lead convert page as there are no campaigns associated
      return new PageReference(getUrlNoOpty());
    }
    return null;
    
  }
  
  //*********************************************
  // Dummy method to force refresh
  //*********************************************
  public PageReference skipOpp() {
    return null;
  }
  
  //*********************************************
  // Clicking the show more button should increase the number of available campaigns to show.
  //*********************************************
  public PageReference showMoreCampaigns() {
    currentLimit += limitSteps;
    return prepareCampaigns();
  }
  
  //*********************************************
  // Validate the checkboxes on every selection
  //*********************************************
  public PageReference checkTicks() {
    // only 1 should be ticked, so keep the first one ticked...
    Boolean foundTick = false;
    for(campaignWrapper c : allCampaigns) {
      if (foundTick && c.selected) {
        c.selected = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,System.Label.LeadConvert_Only_One));
      }
      if (c.selected) foundTick = true;
    }
    return null;
  }
  
  public PageReference save() {
    // check the ticks...
    if (doNotCreateOpp) {
      // redirect to normal page 
      return new PageReference(getUrlNoOpty());
    }
    else {
      // check the ticks...
      Boolean foundTick = false;
      Boolean errorFound = false;
      Id campId = null;
	    for(campaignWrapper c : allCampaigns) {
	      if (foundTick && c.selected) {
	        c.selected = false;
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,System.Label.LeadConvert_Only_One));
	        errorFound = true;
	      }
	      if (c.selected) {
	        foundTick = true;
	        campId = c.camp.Id;
	      }
	    }
	    if (campId == null && !doNotAssignCamp) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,System.Label.LeadConvert_PleaseSelectOne));
	      errorFound = true;
	    }
	    if (!errorFound) {
	      // proceed to set the source on the lead and to the next page...
	      currentLead.Assigned_Campaign__c = (doNotAssignCamp) ? null : campId;
	      currentLead.Update_Campaign__c = true;
	      stdCon.save();
	      return new PageReference(getUrlYesOpty());
	    }
    }
    return null;
  }
  
  public PageReference cancel() {
    return stdCon.view();
  }
  
}