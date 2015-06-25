/**=====================================================================
 * Appirio, Inc
 * Name: EDQSaaS_ClosedWonOpp_EmailController
 * Description: Controller class for EDQSaaS_ClosedWonOpp_EmailComponent (for T-365146)
 * Created Date: March 02st, 2015
 * Created By: Naresh Kr Ojha(Appirio)
 *
 * Date Modified      Modified By                Description of the update
 =====================================================================*/
public with sharing class EDQSaaS_ClosedWonOpp_EmailController{
    public ID opportunityId {get;set;}
    public String externalURL {get;set;}

  //==========================================================================
  // Property of Opportunity
  //==========================================================================
  public OpportunityWrapper getSaaSOpportunity () {
    externalURL = URL.getSalesforceBaseUrl().toExternalForm();
    OpportunityWrapper wonOppty = null;
    Opportunity thisOpportunity = null;
    List<Contact> contactList = new List<Contact>();
    System.debug('==opportunityId=='+opportunityId);
    //Fetching Opportunity information and SaaS Assets.
    for (Opportunity oppty : [SELECT ID, Name, AccountID, Account.Name, OwnerID, Owner.Name,
                                   (SELECT Id, Name, UsageEndDate, Quantity, SaaS__c, Deployment__c,
                                           SaaS_Product_Code__c, Deployment_Status__c
                                    FROM Opportunity_Assets__r
                                    WHERE SaaS__c = true)
                              FROM Opportunity WHERE ID =: opportunityId]) {
      thisOpportunity = oppty;
    }

    //Fetching SaaS Contacts
    for (Contact cont : [SELECT SaaS__c, Name, LastName, Id, FirstName, Email
                         FROM Contact
                         WHERE AccountID =: thisOpportunity.AccountID AND SaaS__c = true]) {
        contactList.add(cont);
    }

    //Creating Wrapper object to get accessed from component
    if (thisOpportunity != null) {
        wonOppty = new OpportunityWrapper(thisOpportunity, contactList);
    }

    return wonOppty;
}

  //==========================================================================
  // Wrapper class to hold Contact list along with Opportunity details
  //==========================================================================
  public class OpportunityWrapper {
    public List<Contact> opptyAccountSaaSContacts {get;set;}
    public Opportunity oppty {get;set;}

    public OpportunityWrapper(Opportunity param_oppty, List<Contact> param_opptyAccContacts) {
        oppty = param_oppty;
        opptyAccountSaaSContacts = param_opptyAccContacts;
    }
  }
}