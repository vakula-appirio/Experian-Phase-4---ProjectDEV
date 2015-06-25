/**=====================================================================
 * Appirio, Inc
 * Name: EDQSaaS_ClosedLostOpp_EmailController
 * Description: Controller class for EDQSaaS_ClosedLostOpp_EmailControllerComponent (for T-366269)
 * Created Date: March 03st, 2015
 * Created By: Naresh Kr Ojha(Appirio)
 *
 * Date Modified      Modified By                Description of the update
 * Apr 4th, 2015      Terri Kellough             T-373132 modify to pull asset list from
 *                                               Opportunity's account instead of the opportunity
 *                                               Note:  Close Lost Opportunities should not
 *                                               have associated assets.
 * Apr 15th, 2015     Terri Kellough             Added opportunity line items
 =====================================================================*/
public with sharing class EDQSaaS_ClosedLostOpp_EmailController {
  public ID opportunityId {get;set;}
  public String externalURL {get;set;}

  //==========================================================================
  // Property of Opportunity
  //==========================================================================
  public OpportunityWrapper getSaaSOpportunity () {
    externalURL = URL.getSalesforceBaseUrl().toExternalForm();
    OpportunityWrapper lostOppty = null;
    Opportunity thisOpportunity = null;
    List<Contact> contactList = new List<Contact>();
    List<Asset> assetList = new List<Asset>();
    List<OpportunityLineItem> oppLinesList = new List<OpportunityLineItem>();
    System.debug('==opportunityId=='+opportunityId);
    //Fetching Opportunity information and SaaS Assets.
//    for (Opportunity oppty : [SELECT ID, Name, AccountID, Account.Name, OwnerID, Owner.Name,
//                                       (SELECT Id, Name, UsageEndDate, Quantity, SaaS__c, Deployment__c,
//                                               SaaS_Product_Code__c, Deployment_Status__c
//                                        FROM Opportunity_Assets__r
//                                        WHERE SaaS__c = true)
//                                  FROM Opportunity WHERE ID =: opportunityId]) {
    for (Opportunity oppty : [SELECT ID, Name, AccountID, Account.Name, OwnerID, Owner.Name
                                  FROM Opportunity WHERE ID =: opportunityId]) { 
      thisOpportunity = oppty;
    }

        // Fetching SaaS Contacts
    for (Contact cont : [SELECT SaaS__c, Name, LastName, Id, FirstName, Email
                         FROM Contact
                         WHERE AccountID =: thisOpportunity.AccountID AND SaaS__c = true]) {
      contactList.add(cont);
    }

    //Fetching SaaS Assets associated with the Opportunity's account
    for(Asset ast: [SELECT Id, Name, UsageEndDate, Quantity, SaaS__c, Deployment__c,
                                               SaaS_Product_Code__c, Deployment_Status__c
                                        FROM Asset
                                        WHERE SaaS__c = true 
                                        AND AccountID =:thisOpportunity.AccountID]) {
      assetList.add(ast);
    }

     //Fetching SaaS lines associated with the Opportunity
    for(OpportunityLineItem opl: [SELECT Id, Name, CPQ_Quantity__c, End_Date__c, 
                                      SaaS_Product_Code__c, SaaS__c
                                        FROM OpportunityLineItem
                                        WHERE SaaS__c = true 
                                        AND OpportunityId =:opportunityId]) {
      oppLinesList.add(opl);
    }   

    // Creating Wrapper object to get accessed from component
    if (thisOpportunity != null) {
      lostOppty = new OpportunityWrapper(thisOpportunity, contactList, assetList,
        oppLinesList);
    }

    return lostOppty;
  }

  //==========================================================================
  // Property of Opportunity
  //==========================================================================
  public class OpportunityWrapper {
    public List<Contact> opptyAccountSaaSContacts {get;set;}
    public Opportunity oppty {get;set;}
    public List<Asset> opptyAccSaaSAssets {get;set;}
    public List<OpportunityLineItem> oppSaaSLines {get;set;}
    public OpportunityWrapper(Opportunity param_oppty, 
      List<Contact> param_opptyAccContacts, List<Asset> param_opptyAccAssets,
      List<OpportunityLineItem> param_opptyLines) {
      oppty = param_oppty;
      opptyAccountSaaSContacts = param_opptyAccContacts;
      opptyAccSaaSAssets = param_opptyAccAssets;
      oppSaaSLines = param_opptyLines;
    }
  }
}