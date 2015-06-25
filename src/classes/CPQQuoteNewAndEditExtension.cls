/**=====================================================================
 * Appirio, Inc
 * Name: CPQQuoteNewAndEditExtension
 * Description: T-313527: Controller Extension for the VF Pages CPQQuoteNew and CPQQuoteEdit 
 * Created Date: Aug 19th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                Description of the update
 * Sept 24th, 2014              Naresh Kr Ojha             As per T-321383, added OpportunityContactRole checks  
 * Sept 29th, 2014              Naresh Kr Ojha             As per T-321383, consolidated message for EDQ Quote required.
 * Oct 18, 2014                 Nathalie Le Guay (Appirio) Add check for CPQ User
 * Nov 25th, 2014               Naresh Kr Ojha             As per T-336011, enhanced access criteria.
 * Jan 27th, 2015               Nathalie Le Guay           I-146811: adding validation around opp.Invoice_to_End_User__c (Label.CPQ_Quote_Missing_fields_on_Opp)
 * Apr 15th, 2015               Nathalie Le Guay           I-155540: Invoice to End user check is for EDQ users only
 * Apr 22nd, 2015               Arpita Bose                I-156139: Allowed CPQ_USERTYPE_CSDA_AE_MANAGER and CPQ_USERTYPE_CSDA_STRATEGIC_PRICING
 * Apr 22nd, 2015               Naresh kr Ojha             I-155541:Need Validation rule for Opportunity Term Start/End Dates.
  =====================================================================*/
public with sharing class CPQQuoteNewAndEditExtension {
  public Quote__c quote;
  public Boolean isError{get;set;}
   
  //constructor
  public CPQQuoteNewAndEditExtension(ApexPages.StandardController controller){
    isError = false;
    Boolean haveAccess = false;
    Boolean contractDateError = false;
    ID opptyID = null;

    Set<String> errorMessages = new Set<String>();
    Boolean isOCR_ShipTo_Available, isOCR_PurLed_Available, isOCR_Commercial_Available;
    isOCR_ShipTo_Available = isOCR_PurLed_Available = isOCR_Commercial_Available = false;
    String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
    Set<String> allowedCPQUserTypes = new Set<String>{Constants.EDQ_USER_TYPE_SALES_MANAGER, Constants.EDQ_USER_TYPE_CUSTOMER_OPERATIONS, 
                                                        Constants.EDQ_USER_TYPE_COMM_TECH_LEGAL, Constants.EDQ_USER_TYPE_FINANCE_MANAGER, 
                                                        Constants.EDQ_USER_TYPE_PROFESSIONAL_SERVICES,
                                                        Constants.CPQ_USERTYPE_CSDA_AE_MANAGER, Constants.CPQ_USERTYPE_CSDA_STRATEGIC_PRICING};//I-156139      
    User currentUser = [SELECT Id, Name, CPQ_User__c, CPQ_User_Type__c FROM User WHERE Id =: UserInfo.getUserId()];
    if (!currentUser.CPQ_User__c) {
      isError = true;
      errorMessages.add(Label.CPQ_Quote_Create_Edit_Message_To_User);
    } 
    
    //As per task T-336011
    if (currentUser.CPQ_User__c && allowedCPQUserTypes.contains(currentUser.CPQ_User_Type__c)) {
        haveAccess = true;
    }
     
    System.debug((!isError)+'~~~~debugaccess~~~~'+haveAccess);
    if (!isError) {
      quote = (Quote__c)controller.getRecord(); 

      if (quote.Opportunity__c != null) {
        opptyID = quote.Opportunity__c;
      }

      if (opptyId != null) {  
        for (Opportunity opp : [SELECT ID, Invoice_to_End_User__c, Contract_Start_Date__c, Contract_End_Date__c,
                                      (Select Id, UserId From OpportunityTeamMembers WHERE UserId =: UserInfo.getUserId()), 
                                      (Select ContactId, Role From OpportunityContactRoles 
                                       WHERE Role =: Constants.OPPTY_CONTACT_ROLE_SHIPTO OR 
                                                 Role =: Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER OR 
                                                 Role =: Constants.OPPTY_CONTACT_ROLE_COMMERCIAL) 
                                FROM Opportunity 
                                WHERE ID =: opptyId]) {
          //Check weather current user is on Opportunity team or not
          if (!haveAccess && opp.OpportunityTeamMembers.size() > 0) {
            haveAccess = true;
          }
          
          if (haveAccess && (opp.Contract_Start_Date__c == null || opp.Contract_End_Date__c == null)) {
            errorMessages.add(Label.CPQ_Quote_Create_Edit_Require_Term_Dates);
          }
          
          if (groupName == 'EDQ') {
            // NLG - April 15th, 2015 - check is for EDQ users only
            if (String.isBlank(opp.Invoice_to_End_User__c)) {
              errorMessages.add(Label.CPQ_Quote_Missing_fields_on_Opp);
            }
            //Check if ShipTo / Bill-To (old Purchase Ledger) / Commercial Contact role is on Opportunity
            for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
              if (ocr.Role == Constants.OPPTY_CONTACT_ROLE_SHIPTO) {
                isOCR_ShipTo_Available = true;
              } 
              if (ocr.Role == Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER) {
                isOCR_PurLed_Available = true;
              } 
              if (ocr.Role == Constants.OPPTY_CONTACT_ROLE_COMMERCIAL) {
                isOCR_Commercial_Available = true;
              }
            }
          }
        }
        //Adding errors
        if (!haveAccess) {
          errorMessages.add(Label.CPQ_Quote_Create_Edit_Message_To_User);
        }

        String rolesMissing = '';
        //Error creation to show on page.
        if (groupName == 'EDQ') {
          if (!isOCR_ShipTo_Available) {
            rolesMissing += Label.CPQ_Quote_Missing_Contact_Role_Ship;
          }
          if (!isOCR_PurLed_Available) {
            rolesMissing += (String.isBlank(rolesMissing)) ? Label.CPQ_Quote_Missing_Contact_Role_Purchase_Ledger : ', ' + Label.CPQ_Quote_Missing_Contact_Role_Purchase_Ledger;
          }
          if (!isOCR_Commercial_Available) {
            rolesMissing += (String.isBlank(rolesMissing)) ? Label.CPQ_Quote_Missing_Contact_Role_Commercial : ', ' + Label.CPQ_Quote_Missing_Contact_Role_Commercial;
          }
          if (!String.isBlank(rolesMissing)) {
            errorMessages.add(Label.CPQ_Quote_Missing_Contact_Roles + ' ' + rolesMissing);
          }
        }

        //Mapking isError true to be available at page
        if (errorMessages.size() > 0) {
          isError = true;
        }
      }
    }

    //Adding all error on page
    if (isError) {
      for (String err : errorMessages) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));
      }
    }
  }

}