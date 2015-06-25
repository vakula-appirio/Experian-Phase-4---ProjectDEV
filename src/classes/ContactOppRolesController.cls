/**=====================================================================
 * Appirio, Inc
 * Name: ContactOppRolesController
 * Description: Component controller for Contact's Opp role component. 
 * 
 * @author Antenna (reused from Appirio's Asset "Contact Role Summarizer Related List"
 * Created Date: Feb 24th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * June 13, 2014		James Weatherall			 Added checkAccountAccess method to check user is on the Account Team
 =====================================================================*/
public with sharing class ContactOppRolesController {

    // Contact ID from component attribute 
    public Id contactId {get;set;}
    public Id accountId {get;set;}
    public Contact contact {get;set;}
    public String nameSubstring {get;set;}
    public Boolean hasAccess {get;set;}

    public ContactOppRolesController() {
    	contactId = apexpages.currentpage().getparameters().get('id');
    	checkAccountAccess();    	
    }

    /**
        Returns all OpportunityContactRoles for the attribute contactId. 
    */
    public OpportunityContactRole[] getOpportunityRoles() {
      if (contact == null) {
        contact = [SELECT Id, AccountId, Account.Name
                 FROM Contact
                 WHERE Id =: contactId];
      }
      return [SELECT Role,
                       IsPrimary,
                       ContactId,
                       Contact.AccountId,
                       Opportunity.Name,
                       OpportunityId,
                       Opportunity.RecordType.Name,
                       Opportunity.CloseDate,
                       Opportunity.CreatedDate,
                       Opportunity.Owner.Name,
                       Opportunity.StageName,
                       Opportunity.Amount,
                       Opportunity.Type
                FROM OpportunityContactRole
                WHERE ContactId = :contactId];
    }
    
    public Boolean checkAccountAccess() {        
        String currentUserId = UserInfo.getUserId();
        hasAccess = false;
        
        for(Contact c : [SELECT AccountId FROM Contact WHERE Id =: contactId])
        {
        	accountId = c.AccountId;
        }
                
        Map<Id, Profile> allowedProfiles = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name= :Constants.PROFILE_SYS_ADMIN 
        															OR Name= :Constants.PROFILE_EXP_SALES_ADMIN]);

        //Check if user has Admin profile
        if (allowedProfiles.keySet().contains(UserInfo.getProfileId()))
    	{
        	hasAccess = true;
    	}
        
        //Populating hasAccess map to check further access.
        for (UserRecordAccess userAccess  : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :currentUserId AND RecordId = :accountId]) {
            if(userAccess.HasEditAccess == true)
            {
            	hasAccess = true; 
            }
        }        		
		return hasAccess;
    }   
}