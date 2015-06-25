/**=====================================================================
 * Appirio, Inc
 * Name: EmailMessageTriggerHandler
 * Description: T-311459: Trigger to update Case Sub Origin with email address
 * Created Date: Aug 11th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Sep 3rd, 2014                Arpita Bose(Appirio)         T-316539: Updated code to populate Sub_Origin__c with ToAddress     
 * Sep 16th, 2014               Mohit Parnami                T-318433: Updated code to resolve the error of Duplicate Ids.                                       
 * Oct 20, 2014                 Nathalie Le Guay (Appirio)   Add Database.DMLOptions to resend the Auto-Response rules
 * Nov 20, 2014                 Noopur                       Added fields in the case query, so that they can be updated.
 * Apr 16th, 2015               Nathalie Le Guay             I-154983: Populate the Requestor_Email__c regardless of RT
 * Apr 17th, 2015               Noopur                       Added code to remove semi-colon if there is only one email address in sub origin.
 * May 20th, 2015               Noopur                       Added a check to remove semi colon only if there is a single email Address in sub-origin
  =====================================================================*/
public class EmailMessageTriggerHandler {

  //=========================================================================
  // After Insert Call
  //=========================================================================    
  public static void afterInsert(LIST<EmailMessage> newEmailMsg) {
    populateSubOriginOnCase(newEmailMsg);         
  }

  // Method to populate Sub Origin on Case
  public static void populateSubOriginOnCase(LIST<EmailMessage> newEmailMsg) {
    List<Case> lstCaseToUpdate = new List<Case>();
    Set<String> setCaseToUpdate = new Set<String>();
    Map<String, String> mapParentIdTotoAddress = new Map<String, String>();
    Map<String, List<Case>> mapRequestorEmailToCaseIds = new Map<String, List<Case>>();   
    // get keyprefix for case
    String keyPrefix = Case.sObjectType.getDescribe().getKeyPrefix();
    // Id EDQGPDId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('EDQ GPD Case').getRecordTypeId();
    
    try {
      /*for (EmailMessage msg : [SELECT Id, ToAddress, ccAddress, Subject, Status, ParentId
                               FROM EmailMessage
                               WHERE Id IN:newEmailMsg AND Incoming = true]) {*/

      // Noopur - Fetch the values from custom settings
      EMSSupportEmailAddresses__c emailAddresses = EMSSupportEmailAddresses__c.getValues('Default');


      for (EmailMessage msg: newEmailMsg) {
        if (msg.Incoming == false) {
          continue;
        }

        // comparing parentId with keypreix, it should be a case ID. If not, continue.
        if (!String.valueOf(msg.ParentId).startsWith(keyPrefix)) { 
         continue;
        }
        else {
          mapParentIdTotoAddress.put(msg.ParentId, msg.ToAddress+ ';');
          if (String.isNotBlank(msg.CcAddress)) {
            String address = mapParentIdTotoAddress.get(msg.ParentId);
            address = address + msg.ccAddress;
            mapParentIdTotoAddress.put(msg.ParentId, address);
          }
        }
      }
      
      Map<String,BusinessHours> businessHoursMap = new Map<String,BusinessHours>();
      for ( BusinessHours hour : [SELECT Id,Name 
                                  FROM BusinessHours]) {
        businessHoursMap.put(hour.Name,hour);
      }
      Map<String, Case> caseMap = new Map<String, Case>([SELECT Id, SuppliedEmail,RecordTypeId,User_Requestor__c, BusinessHoursId,
                                                                Requestor__c,Requestor_Email__c,Requestor_Work_Phone__c, Business_Hours_Afternoon__c
                                                         FROM Case 
                                                         WHERE Id IN: mapParentIdTotoAddress.keySet()]);

      for (Case newCase : caseMap.values()) {
          if (!mapRequestorEmailToCaseIds.containsKey(newCase.SuppliedEmail)) {
            mapRequestorEmailToCaseIds.put(newCase.SuppliedEmail, new List<Case>());
          }
          mapRequestorEmailToCaseIds.get(newCase.SuppliedEmail).add(newcase);
      }

      for (Case newCase: caseMap.values()) {
        //newCase.Sub_Origin__c = mapParentIdTotoAddress.get(newCase.Id);
        
        // Noopur - added this to remove semi colon if there is only one email address,
        String subOrigin = mapParentIdTotoAddress.get(newCase.Id);
        if ( subOrigin.countMatches(';') == 1 && (subOrigin.substringAfter(';') == null || 
            subOrigin.substringAfter(';') == '' )) {
          subOrigin = subOrigin.replace(';','');
        }
        newCase.Sub_Origin__c = subOrigin;
        if( emailAddresses != null && emailAddresses.France_Emails__c != null &&  emailAddresses.France_Emails__c.contains(subOrigin)) {
          newCase.BusinessHoursId = businessHoursMap.containsKey('France Morning Hours') ? businessHoursMap.get('France Morning Hours').Id: null;
          newCase.Business_Hours_Afternoon__c = businessHoursMap.containsKey('France Afternoon Hours') ? businessHoursMap.get('France Afternoon Hours').Id: null;
        }
        if( emailAddresses != null && emailAddresses.Germany_Emails__c != null &&  emailAddresses.Germany_Emails__c.contains(subOrigin)) {
          newCase.BusinessHoursId = businessHoursMap.containsKey('Germany') ? businessHoursMap.get('Germany').Id: null;
        }
        if( emailAddresses != null && emailAddresses.Spain_Emails__c != null &&  emailAddresses.Spain_Emails__c.contains(subOrigin)) {
          newCase.BusinessHoursId = businessHoursMap.containsKey('Spain') ? businessHoursMap.get('Spain').Id: null;
        }
        if (!setCaseToUpdate.contains(newCase.Id)) {
          setCaseToUpdate.add(newCase.Id);
          lstCaseToUpdate.add(newCase);
          system.debug('\nSETTING THE SUB ORIGIN : ' + newCase.Sub_Origin__c);
        }
      }

      for (User user : [Select Id, Email, Phone From User Where Email IN : mapRequestorEmailToCaseIds.keySet()]) {
        if (mapRequestorEmailToCaseIds.containsKey(user.Email)){
          for (Case newCase : mapRequestorEmailToCaseIds.get(user.Email)) {
            system.debug('newCase--'+newCase);
            /* NLG - Apr 16th: this behavior to be extended to all record types
            if (newCase.RecordTypeId != EDQGPDId) {
              continue;
            }*/
            newCase.User_Requestor__c = newCase.SuppliedEmail;
            newCase.Requestor__c = user.Id;
            newCase.Requestor_Email__c = user.Email;
            newCase.Requestor_Work_Phone__c = user.Phone;  
            if (!setCaseToUpdate.contains(newCase.Id)) {
              setCaseToUpdate.add(newCase.Id);
              lstCaseToUpdate.add(newCase);
            }
          }
        }
      }
      Database.DMLOptions dlo = new Database.DMLOptions();
      dlo.EmailHeader.triggerAutoResponseEmail = true;
      database.update(lstCaseToUpdate, dlo);
      //update lstCaseToUpdate; 
    } catch (DMLException e) {
          ApexLogHandler.createLogAndSave('EmailMessageTriggerHandler','populateSubOriginOnCase', e.getStackTraceString(), e);
          for (Integer i=0; i < e.getNumDml(); i++) {
            newEmailMsg.get(0).addError(e.getDMLMessage(i)); 
          }
    }   
  }
  
}