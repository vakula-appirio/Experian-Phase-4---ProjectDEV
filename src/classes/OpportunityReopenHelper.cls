/******************************************************************************
 * Appirio, Inc
 * Name: OpportunityReopenHelper
 * Description: T-323320: Change Opportunity Process: Custom Opp Button.
 * Created Date: Oct 09th, 2014
 * Created By:  Noopur (Appirio)
 * Date Modified        Modified By                  Description of the update
 * Oct 18th, 2014       Nathalie Le Guay (Appirio)   reopenCurrentOpportunity() and reopenPreInvoiceOpp() run for edq users only
 * Nov 03rd, 2014       Nathalie Le Guay             Check is no longer on EDQ business unit, but rather on the COPS roles
 * Nov 11th, 2014       Nathalie Le Guay             I-138510: blank the Primary_Reason_W_L__c and Other_Closed_Reason__c fields
 * Feb 06th, 2015       James Weatherall             Case #542401 - Update Record Type to Standard in reopenPreInvoiceOpp
 * May 19th, 2015       Nur Azlini                   Case #630336 - get the list of COPS role from public group(EDQ COPS Team) instead of role name from constant class.
                                                     Changed UserRole.Name to UserRole.DeveloperName
 ******************************************************************************/
global class OpportunityReopenHelper {
    
    static Opportunity oppToReopen;
    //Start Case #630336
    static List<Group> copsList = [SELECT Id, DeveloperName FROM Group
                                   WHERE Id in (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name =: Constants.GROUP_EDQ_COPS)];
    static Set<String> copsRoles = new Set<String>{'Global_Admin'};
    
    //End Case #630336
    static User currentUser {
      get {
        if (currentUser == null) {
          currentUser = [SELECT Id, UserRole.DeveloperName FROM User WHERE Id =: UserInfo.getUserId()];
        }
        return currentUser;
      }
      set;
    }
    
    // webservice to fetch the Opportunity record by using the Id sent by the button
    webservice static String reopenCurrentOpportunity ( String opptyId) {
    //Start Case #630336
    for(Group cR : copsList)
    {
        System.debug('copsList' + cR);
        String copRole = cR.DeveloperName;  // assignation
        system.debug( 'sObject to String  conversion : '  + copRole ) ;
        copsRoles.add(copRole);
        system.debug( 'FinalList: '  + copsRoles ) ;
        
    }
    //End Case #630336

      if (String.isBlank(currentUser.UserRoleId) || !copsRoles.contains(currentUser.UserRole.DeveloperName)) {
        return Label.Opportunity_Reopen_Not_a_COPS_User;
      }

      for ( Opportunity opp : [SELECT Id,StageName, Forecast_Category__c,Type,
                                     (SELECT Id,Exported_for_Invoicing__c From Orders__r)
                              FROM Opportunity
                              WHERE Id = :opptyId] ){
        oppToReopen = opp;
        if ( !oppToReopen.Orders__r.isEmpty() ) {

          // check the Export to invoicing field and redirect to the methods accordingly
          Boolean isExportedToInvoicing = oppToReopen.Orders__r[0].Exported_for_Invoicing__c;
          if (isExportedToInvoicing) {
            return reopenPostInvoiceOpp();
          }
          else {
            return reopenPreInvoiceOpp() ;
          }
        }
      }
      return ''; //oppToReopen.Id;
    }


    // Method to re-open Opportunity when the Export to Invoicing is false.
    static String reopenPreInvoiceOpp() {

      if (String.isBlank(currentUser.UserRoleId) || !copsRoles.contains(currentUser.UserRole.DeveloperName)) {
        return Label.Opportunity_Reopen_Not_a_COPS_User;
      }

      try {
        // Start: Case #542401 - 6/2/2015 - JW
        String recTypeId = Record_Type_Ids__c.getOrgDefaults().Opportunity_Standard__c;
        oppToReopen.RecordTypeId = recTypeId;
        // End
        oppToReopen.StageName = Constants.OPPTY_STAGE_4;
        oppToReopen.Forecast_Category__c = 'Pipeline';
        oppToReopen.Primary_Reason_W_L__c = '';
        oppToReopen.Other_Closed_Reason__c = '';
        update oppToReopen;
      } catch (DMLException ex) {
        system.debug('[OpportunityReopenHelper: reopenPreInvoiceOpp] Exception: ' + ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityReopenHelper','reopenPreInvoiceOpp', ex.getStackTraceString(), ex);
        String error = '';
        for (Integer i=0; i < ex.getNumDml(); i++) {
          error += ex.getDMLMessage(i);
        }
        return error;
      }
      return ''; //oppToReopen.Id;
    }

    // Method to re-open Opportunity when the Export to Invoicing is true.
    static String reopenPostInvoiceOpp() {
        Savepoint sp;
        try {
         
         sp = Database.setSavepoint();
            oppToReopen.StageName = Constants.OPPTY_CLOSED_LOST;
            oppToReopen.Type = Constants.OPPTY_TYPE_CREDITED;
            oppToReopen.Primary_Reason_W_L__c = '';
            oppToReopen.Other_Closed_Reason__c = '';
            update oppToReopen;
           // reopenPostInvoiceOpp_PostProcess(oppToReopen);
        }
        catch (DMLException ex) {
          system.debug('[OpportunityReopenHelper: reopenPostInvoiceOpp] Exception: ' + ex.getMessage());
          ApexLogHandler.createLogAndSave('OpportunityReopenHelper','reopenPostInvoiceOpp', ex.getStackTraceString(), ex);

          //Removed by Nur Azlini as have caused JavaScript error. Replace with below getNumDML
          /*String error = '';
          error = ex.getMessage();
          Integer startPoint;    
              If(error.indexOf('caused by') == -1)
              {
                startPoint = error.indexOf('first error:');
              }
              else
              {
                startPoint = error.indexOf('caused by');      
              }
              
              Integer endPoint = error.indexOf(': [');
              error = error.substring(startPoint, endPoint);
              startPoint = error.indexOf('error:')+'error: '.length();
              endPoint = error.length();
              
              
            return error.substring(startPoint, endPoint);*/
        Database.rollback(sp);    
        String error = '';
          for (Integer i=0; i < ex.getNumDml(); i++) {
          error += ex.getDMLMessage(i);
        }
        return error;
      }
        return ''; //oppToReopen.Id;
    }

}