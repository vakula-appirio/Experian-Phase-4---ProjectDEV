/**=====================================================================
 * Appirio, Inc
 * Name: URLRedirectController
 * Description: This class contains logic to build url depending on where the user is
 *              coming from and where s/he plans on going - T-249349
 * Created Date: March 2014
 * Created By: Nathalie LE GUAY (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 14, 2014                 Nathalie Le Guay             Adding EncodingUtil.urlEncode(paramName, 'UTF-8'); in buildOpp/OrderUrl()
 * Apr 25, 2014                 Nathalie Le Guay             Adding 'retURL' to urls
 * Jul 28, 2014                 James Weatherall             Case #2323 Added ability to create Follow-on Opportunity
 * Aug 04, 2014                 James Weatherall             Case #2323 Added query for Primary Contact Id and pass Opp Id and Name 
 *                                                           for Previous Opp relationship
 * Aug 27, 2014                 Tyaga Pati                   Case #6948 Added code to copy Lead Source from Contact to new Opportunity(paramLeadSourceName)
 * Sep 04, 2014                 Naresh Kr Ojha (Appirio)     T-317502: Remove CF from line 108 as per task.
 * Oct 20, 2014                 James Weatherall            Case #8566 Added code to default the Reporting Sales Team on a new Opportunity
 * Jan 16th, 2015               James Weatherall            Case #21168 Added code to prevent CPQ Users from creating Transactional 
 * Feb 26th, 2015               James Weatherall            Case #562501 Added Lead Source check in getParameterValues() for Cross Business Unit Leads
 *                                                          Case #540588 Added COPS user check in BuildOrderUrl to allow Transactional Orders to be created
 * Apr 07th, 2015               Nur Azlini                  Case #12481 Added new Method to check is user part of the Account Team.
 =====================================================================*/
public without sharing class URLRedirectController {
  private String recordId;
  private String recordName = ''; // Case #2323
  private String objectName;
  private String action;
  private String userSalesTeam; // Case #21168 - Added by JW 01/16/2015 
  private SObject sourceRecord;
  private Contact contact;
  private Task task;
  private Event event; 
  private Opportunity opportunity; // Case #2323 - Added by JW 07/28/2014
  private ELQA_Marketing_Activity__c mktgActivity;
  private User user; // Case #21168 - Added by JW 01/16/2015 
  private String paramCampaignSourceId = '';
  private String paramCampaignSourceName = '';
  private String paramOppOrderName;
  private String paramOppId;
  private String paramOppName;
  private String paramAccountId;
  private String paramAccountName;
  private String paramContactId = '';
  private String paramTaskId = '';
  private String paramContactName;
  private String paramReportingSalesTeam = ''; // Case #8566 - Added by JW 10/20/2014
  private String paramLeadSourceName = '';  //[TP] Changes Added Case #6948 09/02/2014
  public String errorMessage {get;set;}
  private Custom_Fields_Ids__c fieldIds;
  private Record_Type_Ids__c recordTypeIds;
  public Id recAccountId; //07042015 Case #12481 - Added by [AZ]
  private Set<String> oppOrderAllowedFromObjectsSet = new Set<String>{
                               Constants.SOBJECT_EVENT,
                               Constants.SOBJECT_TASK,
                               Constants.SOBJECT_MKTG_ACTIVITY,
                               Constants.SOBJECT_CONTACT,
                               Constants.SOBJECT_OPPORTUNITY}; // Case #2323 - Added by JW 07/28/2014


  public URLRedirectController() {
  }

  //========================================================================================
  // This method checks which action to perform, loads the custom settings and will either 
  // return the error message if any, or the built url otherwise
  //========================================================================================
  public PageReference getURL() {
    recordId = ApexPages.currentPage().getParameters().get('Id');
    recordName = ApexPages.currentPage().getParameters().get('Name');
    action = ApexPages.currentPage().getParameters().get('action');
    if (String.isEmpty(recordId) || String.isEmpty(action)) {
      return new PageReference('/'+recordId);
    }
    objectName = DescribeUtility.getSObjectName(recordId);
    System.debug('\n[URLRedirectController: constructor] : objectName is ' + objectName);

    // Start : Case #21168 - Added by JW 01/16/2015   
    // Get User to check CPQ User and to set the Sales Team
    user = getCurrentUser(UserInfo.getUserId());   
    // End 
      
    Boolean fetchSuccess = fetchFieldIdsCustomSettings();
    if (!fetchSuccess) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, errorMessage));
      return null;
    }

    if (action.equalsIgnoreCase(Constants.REDIRECT_CREATE_OPPORTUNITY)) {

      String url = buildOpportunityURL();
      if (url == null) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, errorMessage));
        return null;
      }
      return new PageReference(url);
    } else if (action.equalsIgnoreCase(Constants.REDIRECT_CREATE_ORDER)) {
      String url = buildOrderURL();
      if (url == null) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, errorMessage));
        return null;
      }
      return new PageReference(url);
    } else if (action.equalsIgnoreCase(Constants.REDIRECT_PRE_SALES_SUPPORT)) {
      String url = buildPreSalesSupportURL();
      if (url == null) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, errorMessage));
        return null;
      }
      return new PageReference(url);   
    }
    return new PageReference('/'+recordId);
  }

  //========================================================================================
  // Will build the url to create an Opp by populating the Name, Account, Stage, Campaign
  // Source (if applicable) as well as the Originating_Contact_Id__c field
  //========================================================================================
  private String buildOpportunityURL() {
    if (!oppOrderAllowedFromObjectsSet.contains(objectName)) {
      errorMessage = Label.URL_Redirect_Opp_From_Object_Not_Supported;
      return null;
    }
    if (!validateSourceData()) {
      System.debug('\n[URLRedirect: buildOpportunityURL]: Validate was unsuccessful.');
      return null;
    }
    // [AZ] Start Case #12481
    if(!userhaveAccountAccess() && objectName.equalsIgnoreCase(Constants.SOBJECT_TASK)){
      System.debug('User have no access to create Opportunity');
      errorMessage = Label.OPP_DONTHAVEACCESS_MSG;
      return null;
    }// [AZ] End Case #12481
    System.debug('\n[URLRedirect: buildOpportunityURL]: Validate was successful.');

    String url = '/' + DescribeUtility.getPrefix(Constants.SOBJECT_OPPORTUNITY) + '/e?'
               + 'opp11='+ Constants.OPPTY_STAGE_3;
    getParameterValues();

    //[TP] Changes Start Case #6948 
    if (paramLeadSourceName == null) {
     paramLeadSourceName= '';
    }
    //[TP] Changes End Case #6948 

    url += '&opp17_lkid=' + paramCampaignSourceId
        + '&opp17=' + EncodingUtil.urlEncode(paramCampaignSourceName, 'UTF-8')
        + '&opp3=' + EncodingUtil.urlEncode(paramOppOrderName + ' - ', 'UTF-8')
        + '&opp6=' + EncodingUtil.urlEncode(paramLeadSourceName, 'UTF-8') // [TP] Changes for Case #6948 09/02/2014
        + '&opp4_lkid='+ paramAccountId
        + '&opp4=' + EncodingUtil.urlEncode(paramAccountName, 'UTF-8')
        + '&conid=' + paramContactId 
        + '&'+fieldIds.Opportunity_Originating_Contact_Id__c + '=' + paramContactId
        + '&'+fieldIds.Opportunity_Originating_Task_Id__c + '=' + paramTaskId
        // Start: Case #8566 - Added by JW 10/20/2014
        + '&'+fieldIds.Opportunity_Reporting_Sales_Team__c + '=' + EncodingUtil.urlEncode(paramReportingSalesTeam, 'UTF-8');
        // :End
    // Start: Case #2323 Added to prevent incorrect Id being passed into Previous Opp field
    if(objectName.equalsIgnoreCase(Constants.SOBJECT_OPPORTUNITY))
    {
      url += '&CF'+fieldIds.Opportunity_Previous_Opportunity__c + '_lkid=' + recordId
          + '&CF'+fieldIds.Opportunity_Previous_Opportunity__c + '=' + EncodingUtil.urlEncode(recordName, 'UTF-8');
    }
    // :End
      url += '&retURL=/' + recordId;
    System.debug('\n[URLRedirectController: buildOpportunityURL]: URL is ' + url);
    return url;
  }

  //========================================================================================
  // Will build the url to create an Order by populating the Name, Account, Contact, Campaign
  // Source (if applicable)
  //========================================================================================
  private String buildOrderURL() {
    Set<String> copsRoles = new Set<String>{ Constants.ROLE_NA_COPS, Constants.ROLE_UKI_COPS, Constants.ROLE_GLOBAL_ADMIN }; // JW - 26/02/2015 - Case #540588
      
    if (!oppOrderAllowedFromObjectsSet.contains(objectName)) {
      errorMessage = Label.URL_Redirect_Order_From_Object_Not_Supported;
      return null;
    }
    // Start : Case #21168 - Modified by JW 01/16/2015
    if(user.CPQ_User__c == true && !copsRoles.contains(user.UserRole.Name) && IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
      errorMessage = Label.URL_Redirect_cannot_create_Transactional_Orders;
      return null;
    } // End
    if (!validateSourceData()) {
      System.debug('\n[URLRedirect: buildOrderURL]: Validate was unsuccessful.');
      return null;
    }
    //[AZ] Start Case #12481
    if(!userhaveAccountAccess() && objectName.equalsIgnoreCase(Constants.SOBJECT_TASK)){
      System.debug('User have no access to create order');
      errorMessage = Label.ORDER_DONTHAVEACCESS_MSG;
      return null;
    }//[AZ] End Case #12481
    
    System.debug('\n[URLRedirect: buildOrderURL]: Validate was successful.');

    String url = '/' + DescribeUtility.getPrefix(Constants.SOBJECT_ORDER) + '/e?';
    getParameterValues();


    url += 'Name=' + paramOppOrderName + ' - '
        + '&' + fieldIds.Order_Transactional_Sale__c + '=1'
        + '&CF' + fieldIds.Order_Account__c + '_lkid='+ paramAccountId
        + '&CF' + fieldIds.Order_Account__c + '=' + EncodingUtil.urlEncode(paramAccountName, 'UTF-8')
        + '&CF' + fieldIds.Order_Contact__c + '_lkid=' + paramContactId
        + '&CF' + fieldIds.Order_Contact__c + '=' + EncodingUtil.urlEncode(paramContactName, 'UTF-8')
        // Start: Case #8566 - Added by JW 10/20/2014
        + '&'+fieldIds.Order_Reporting_Sales_Team__c + '=' + EncodingUtil.urlEncode(paramReportingSalesTeam, 'UTF-8')
        + '&retURL=/' + recordId;
    if (String.isNotBlank(paramCampaignSourceId) && String.isNotBlank(paramCampaignSourceName)) {
      url += '&CF' + fieldIds.Order_Campaign__c + '_lkid=' + paramCampaignSourceId
          + '&CF' + fieldIds.Order_Campaign__c + '=' + EncodingUtil.urlEncode(paramCampaignSourceName, 'UTF-8');
    }
    System.debug('\n[URLRedirectController: buildOrderURL]: URL is ' + url);
    return url;
  }
    
  //========================================================================================
  // Will build the url to create a Pre Sales Support record by populating the 
  // Opportunity Name, Contact
  //========================================================================================
  private String buildPreSalesSupportURL() {
    if (!validateSourceData()) {
      System.debug('\n[URLRedirect: buildPreSalesSupportURL]: Validate was unsuccessful.');
      return null;
    }
    System.debug('\n[URLRedirect: buildPreSalesSupportURL]: Validate was successful.');

    String url = '/' + DescribeUtility.getPrefix(Constants.SOBJECT_SALES_SUPPORT_REQUEST) + '/e?';
    getParameterValues();

    url += fieldIds.SalesSupportRequest_Opportunity__c + '_lkid=' + paramOppId
        + '&' + fieldIds.SalesSupportRequest_Opportunity__c + '=' + paramOppName        
        + '&RecordType=' + recordTypeIds.Sales_Support_Request_Pre_Sales_Request__c
        + '&retURL=/' + recordId;
    System.debug('\n[URLRedirectController: buildPreSalesSupportURL]: URL is ' + url);
    return url;
  }
    
  //========================================================================================
  // Checks if the data is correct:
  // - Activities need to be attached to a Contact
  // - Marketing Activities need to have both an Account & a Contact
  //========================================================================================
  private Boolean validateSourceData() {
    //record = getObject();
    String whoObject;
    if (objectName.equalsIgnoreCase(Constants.SOBJECT_EVENT)) {
      event = [SELECT Id, WhoId, WhatId
               FROM Event
               WHERE Id =: recordId];
      whoObject = DescribeUtility.getSObjectName(event.WhoId);
      if (!whoObject.equalsIgnoreCase(Constants.SOBJECT_CONTACT)) {
        errorMessage = Label.URL_Redirect_Missing_Contact;
        return false;
      }
    }

    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_TASK)) {
      task = [SELECT Id, WhoId, WhatId, Type, AccountId // JW - 26/02/2015 - Case #562501: Added Type field || 07042015- [AZ] Case #12481 - Added AccountId field
               FROM Task
               WHERE Id =: recordId];

      recAccountId = task.AccountId;//07042015- [AZ] Case #12481
      whoObject = DescribeUtility.getSObjectName(task.WhoId);
      if (!whoObject.equalsIgnoreCase(Constants.SOBJECT_CONTACT)) {
        errorMessage = Label.URL_Redirect_Missing_Contact;
        return false;
      }
    }
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_MKTG_ACTIVITY)) {
      mktgActivity = [SELECT Account__c, Contact__c, Contact__r.Name, Account__r.Name, Campaign__c, Campaign__r.Name
                      FROM ELQA_Marketing_Activity__c
                      WHERE Id =: recordId];
      if (mktgActivity.Account__c == null || mktgActivity.Contact__c == null) {
        errorMessage = Label.URL_Redirect_Missing_Contact_or_Account;
        return false;
      }
    }

    //[TP] Changes Start Case #6948 09/02/2014
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_CONTACT)) {
      contact = [SELECT Id, AccountId, Account.Name, Name, LeadSource 
                 FROM Contact
                 WHERE Id =: recordId];
    } //[TP] End

    // Start: Case #2323 - Added by JW 07/28/2014
    else if(objectName.equalsIgnoreCase(Constants.SOBJECT_OPPORTUNITY)) {
        opportunity = [SELECT Id, Name, AccountId, Account.Name, (SELECT Id, ContactId, Contact.Name From OpportunityContactRoles WHERE IsPrimary = true limit 1) 
                       FROM Opportunity 
                       WHERE Id =: recordId];
    }
    // End: Case #2323 
    return true;
  }

  //========================================================================================
  // Will populate the variable to build the url
  //========================================================================================
  private void getParameterValues() {
    userSalesTeam = user.Sales_Team__c != null ? user.Sales_Team__c : ''; // Added by JW 01/16/2015
    if (objectName.equalsIgnoreCase(Constants.SOBJECT_EVENT)) {
      String whatObject = DescribeUtility.getSObjectName(event.WhatId);
      if (whatObject.equalsIgnoreCase(Constants.SOBJECT_CAMPAIGN)) {
        paramCampaignSourceId = event.WhatId;
        Campaign campaign = [SELECT Id, Name FROM Campaign WHERE Id =: event.WhatId LIMIT 1];
        if (campaign != null) {
          paramCampaignSourceName = campaign.Name;
        }
      }
      Contact cont = getContact(event.WhoId);
      paramAccountId = cont.AccountId;
      paramContactId = event.WhoId;
      paramContactName = cont.Name;
      paramReportingSalesTeam = userSalesTeam; // Case #8566 - Added by James Weatherall 10/20/2014
      paramOppOrderName = cont.Account.Name;
    }
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_TASK)) {
      String whatObject = DescribeUtility.getSObjectName(task.WhatId);
      if (whatObject.equalsIgnoreCase(Constants.SOBJECT_CAMPAIGN)) {
        paramCampaignSourceId = task.WhatId;
        Campaign campaign = [SELECT Id, Name FROM Campaign WHERE Id =: task.WhatId LIMIT 1];
        if (campaign != null) {
          paramCampaignSourceName = campaign.Name;
        }
      }
      Contact cont = getContact(task.WhoId);
      paramAccountId = cont.AccountId;
      paramContactId = task.WhoId;
      paramContactName = cont.Name;
      paramReportingSalesTeam = userSalesTeam; // JW - 10/20/2014 Case #8566 
      paramOppOrderName = cont.Account.Name;
      if(task.Type == Constants.ACTIVITY_TYPE_CROSS_BUSINESS_UNIT) { 
        paramLeadSourceName = task.Type; // JW - 26/02/2015 - Case #562501
      }
      paramTaskId = task.ID;
    }
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_MKTG_ACTIVITY)) {
      paramCampaignSourceId = mktgActivity.Campaign__c;
      if (String.isNotEmpty(paramCampaignSourceId)) {
        paramCampaignSourceName = mktgActivity.Campaign__r.Name;
      }
      paramAccountId = mktgActivity.Account__c;
      paramContactId = mktgActivity.Contact__c;
      paramContactName = mktgActivity.Contact__r.Name;
      paramReportingSalesTeam = userSalesTeam; // Case #8566 - Added by James Weatherall 10/20/2014
      paramOppOrderName = mktgActivity.Account__r.Name;
    }
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_CONTACT)) {
      paramAccountId = contact.AccountId;
      paramContactId = contact.Id;
      paramContactName = contact.Name;
      paramReportingSalesTeam = userSalesTeam; // Case #8566 - Added by James Weatherall 10/20/2014
      paramOppOrderName = contact.Account.Name;
      paramLeadSourceName = contact.LeadSource; // [TP]  Case #6948 09/02/2014
    }
    // Start: Case #2323 - Added by JW 07/28/2014
    else if (objectName.equalsIgnoreCase(Constants.SOBJECT_OPPORTUNITY)) { 
      OpportunityContactRole oppContactRole;
      paramAccountId = opportunity.AccountId;
      // Extract Primary Contact
      if(opportunity.OpportunityContactRoles.size() > 0)
      {
        oppContactRole = opportunity.OpportunityContactRoles;
        paramContactId = oppContactRole.ContactId;
      }
      system.debug('paramContactId = ' + paramContactId);
      if(paramContactId != '')
      {
        paramContactName = oppContactRole.Contact.Name;
      } else {
        paramContactName = '';  
      }
      paramReportingSalesTeam = userSalesTeam; // Case #8566 - Added by James Weatherall 10/20/2014
      paramOppOrderName = opportunity.Account.Name;
      // 12052014 Case 9748 - JW
      paramOppId = opportunity.Id; 
      paramOppName = opportunity.Name;   
    }
    // :End
      
    paramAccountName = paramOppOrderName;
    if (paramOppOrderName.length() > 15) {
      paramOppOrderName = paramOppOrderName.substring(0, 15);
    }
  }

  //========================================================================================
  // Retrieves the Contact from the database
  //========================================================================================
  private Contact getContact(String contactId) {
    return [SELECT Id, AccountId, Account.Name, Name
            FROM Contact
            WHERE Id =: contactId];
  }
  
  // Case #8566 - Added by JW 10/20/2014
  // Modified by JW 01/16/2015
  // Start : Get the current user reporting sales team as the default value for the Opp  
  private User getCurrentUser(String userId) {
    return [SELECT Id, Sales_Team__c, CPQ_User__c, UserRole.Name 
            FROM User 
            WHERE Id =: userId];
  }  
  // End

  //========================================================================================
  // Retrieves the custom settings that stores the field Ids (to dynamically build the url,
  // in order not to be org-dependent)
  //========================================================================================
  private Boolean fetchFieldIdsCustomSettings() {
    fieldIds = Custom_Fields_Ids__c.getOrgDefaults();
    recordTypeIds = Record_Type_Ids__c.getOrgDefaults(); // 12052014 Case 9748 - JW
    if (fieldIds == null || String.isEmpty(fieldIds.Order_Account__c)
                         || String.isEmpty(fieldIds.Order_Campaign__c)
                         || String.isEmpty(fieldIds.Order_Contact__c)) {
      errorMessage = Label.URL_Redirect_Custom_Setting_Missing;
      return false;
    }
    return true;
  }

  //========================================================================================
  // Link behind the "Go Back" button in case of error message
  //========================================================================================
  public PageReference goBack() {
    return new PageReference('/' + recordId);
  }
  
  //========================================================================================
  // Method to validate is user have access to create Opportunity on the Account or not.
  // Case #12481 - Added by AZ 07042015
  //========================================================================================
  public boolean userhaveAccountAccess(){
    List <UserRecordAccess> userAccess = [Select RecordId from UserRecordAccess WHERE
                                          UserId =: user.id AND 
                                          HasEditAccess = TRUE AND
                                          RecordId =: recAccountId];
    If(userAccess.size()>0){
      return true;
    }
      return false;
  }
}