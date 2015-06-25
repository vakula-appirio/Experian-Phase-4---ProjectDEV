/**=====================================================================
 * Appirio, Inc
 * Name: CaseTriggerHandler
 * Description: T-208210.
 * Created Date: Nov 08th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282:Added Constants in place of String
 * Apr 3rd, 2014                Nathalie Le Guay             S-183567: Adding addUsersToCaseTeams() - Mass Transfer topCoder challenge
 * Apr 08th, 2014               Arpita Bose (Appirio)        T-269372: Added addError()in try-catch block
 * Apr 21st, 2014               Arpita Bose                  Updated comment header to match coding conventions
 * Apr 22nd, 2014               Rahul Jain                   Added beforeUpdate, beforeInsert and supporting methods (updateCaseAndParentCaseForBilling) for T-270394
 * Jun 20th, 2014               Richard Joseph               Made is before Insert and Update . 
                                                              To populate the Requestor__c field from Requestor email.Case#1939
 * Aug 07th, 2014               Arpita Bose                  T-311131: Replaced Case.Account__c references with the standard Case.Account                                                             
 * Aug 28th, 2014               Arpita Bose                  T-309768: Added code from CaseTriggerHandler of the installed package
 * Sep 04th, 2014               Arpita Bose                  T-310733: Added afterInsert() method and caseResolutionTimeTrackingProcess()
 * Sep 08th, 2014               Arpita Bose                  T-310733: Added reference to helper class CaseTrigger_ResolutionTime in afterInsert and afterUpdate
 * Sep 16th, 2014               Arpita Bose                  T-318031: Added method addUserToCaseTeamforEDQ_GPD_RecType()
 * Sep 17th, 2014               Naresh Kr Ojha               T-319846: Creating CaseTeamMember from Requestor. Added createCaseTeamMembersForCases() &
                                                             createNewCaseTeamMember();
 * Oct 1st, 2014                Nathalie Le Guay             fixed toPopulateRequestor() to use format used across the code, and to leave Requestor__c blank for some RT
 * Oct 28th, 2014               Naresh kr Ojha               Updated method createCaseTeamMembersForCases( ) to fix null pointer exception
 * Nov 10th, 2014               Nathalie Le Guay             I-138305: update to createCaseTeamMembersForCases() to prevent creation of duplicate CaseTeamMember
 *                                                           for CreatedById, which is created as part of onOwnerChangeAddUserToCaseTeam()
 * 17th Dec, 2014               James Weatherall             Case #28782: Add IsActive check to toPopulateRequestor() method
 * Apr 27th, 2015               Noopur                       created method populateBusinessHours() to populate business hours on EMS cases.
 * Apr 28th, 2015               Noopur                       S-304907 :- created method updateChildCasesOnCaseResolved () to update the child records when parent is updated
 * May 15th, 2015               Arpita Bose                  I-163081 : Added method toPopulateCaseOwnerManagerEmail()  
  =====================================================================*/

public class CaseTriggerHandler{
  //added for Task T-309768
  private boolean m_isExecuting = false;
  private Integer batchSize = 0;
  public static boolean firstRun = true;
    
  public CaseTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    batchSize = size;
  }

  //=========================================================================
  //Before Insert Call
  //=========================================================================    
  public static void beforeInsert(LIST<Case> newCases){
    updateCaseAndParentCaseForBilling(false, newCases, new Map<Id, Case>());  
     //[RJ]
    toPopulateRequestor(newCases, null);
    populateBusinessHours(newCases);
    //I-163081
    toPopulateCaseOwnerManagerEmail (newCases, null);
  }

  //=========================================================================
  // After Update Call
  //=========================================================================
  public static void afterUpdate(List<Case> lstOld, LIST<Case> lstNew, Map<Id, Case> newMap, MAP<Id,Case> oldMap) {
    onOwnerChangeAddUserToCaseTeam(lstNew, oldMap);
    processAccessRequest(lstNew);
    //T-310733
    CaseTrigger_ResolutionTime.caseResolutionTimeTrackingProcess(lstOld, lstNew, newMap, oldMap);
    createCaseTeamMembersForCases(lstNew, oldMap);
    updateChildCasesOnCaseResolved (lstNew, oldMap) ;
  }

  //=========================================================================
  //Before Update Call
  //=========================================================================
  public static void beforeUpdate(LIST<Case> newCases, MAP<Id,Case> oldCases){
    updateCaseAndParentCaseForBilling(true, newCases, oldCases);
    //[RJ] - starts
    toPopulateRequestor(newCases, oldCases);
    //[RJ] - ends
    //I-163081
    toPopulateCaseOwnerManagerEmail (newCases, oldCases);
  }

  //=========================================================================
  // T-310733 : After Insert Call
  //=========================================================================    
  public static void afterInsert(LIST<Case> newCases){
    CaseTrigger_ResolutionTime.createCaseHistoryRec(newCases);
    //T-318031 : code is commented as Task is blocked
    //addUserToCaseTeamforEDQ_GPD_RecType(newCases);
    createCaseTeamMembersForCases(newCases, null);
  }

  //Owner changed, old older was DQ
  public static void onOwnerChangeAddUserToCaseTeam(LIST<Case> lstNew, MAP<Id,Case> oldMap) {
    List<CaseTeamMember> lstCaseTeamMembers = new List<CaseTeamMember>();
    
    //Retrive CaseTeamRole name from Custom Setting.
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
    
    //Retrive CaseTeamRole recordId by name
    CaseTeamRole ctrRec = [SELECT Id,Name,AccessLevel FROM CaseTeamRole where Name=:custSettings.Case_Access_Request_TeamRole__c];
    
    //MIrfan. 19Dec13. Always share with Creater
    //Group grpQueueRec = [Select Id From Group where Type='Queue' and Name =:custSettings.Case_DQ_Team_Queue__c limit 1];
    
    for (Case caseRec: lstNew) {
        /* ######################### MIrfan. 19Dec13. Comment START #####################
        Id oldOwnerId = oldMap.get(caseRec.Id).OwnerId;
        
        
        String objName = (oldOwnerId==null)?null:oldOwnerId.getSObjectType().getDescribe().getName();
        //If Owner has Changed and new is DQ Team Queue
        if(oldOwnerId!=null && oldOwnerId != caseRec.OwnerId) && caseRec.OwnerId == grpQueueRec.id && objName!=null && objName.equalsIgnoreCase('User') )
        ######################### MIrfan. 19Dec13. Comment END ##################### */
        
        //If Owner is not Creator then add to Case Team.
        if (oldMap!=null && oldMap.size()>0 && caseRec.OwnerId != oldMap.get(caseRec.Id).OwnerId) {
             //Create CaseTeamMember record and populate fields.
             lstCaseTeamMembers.add(new CaseTeamMember(ParentId = caseRec.id,
                                    MemberId = caseRec.CreatedById, TeamRoleId=  ctrRec.id));
        }
    }
    
    system.debug('#################lstCaseTeamMembers############'+lstCaseTeamMembers);
    //Create record.
    if (lstCaseTeamMembers.size() > 0) {
        //insert lstCaseTeamMembers;
      try {
        //MIrfan. 19Dec13. This to handle any exception, trying to add same user, on update.
        Database.SaveResult[] dsr = Database.Insert(lstCaseTeamMembers, false);
        system.debug('#################dsr############'+dsr);
      }  catch (DMLException ex) {
        System.debug('[CaseTriggerHandler:createCaseTeamMembersForCases]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('CaseTriggerHandler','createCaseTeamMembersForCases', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          lstNew.get(0).addError(ex.getDmlMessage(i));
        }
      }
    }    
  }

  //Trigger Codd to add the Accessrequest User to the Account Team and OptyTeam/CaseTeam etc
  public static void processAccessRequest(LIST<Case> accessReq) {
    string caseRecType = Constants.CASE_REC_TYPE_ACCESS_REQUEST; //Access Request
    if (caseRecType == null) {
         caseRecType ='Access Request';
    }     
    RecordType rt = [select Id from RecordType where Name = :caseRecType  and SobjectType = 'Case' limit 1];
    string rectypeId = rt.Id;
    string accntRole ;
    //system.debug('Gen case type :' + rectypeId);

    List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
    List<AccountShare> accountShares = new List< AccountShare>();
    
    for(Case caseRec: accessReq) {
      system.debug('case type :' + caseRec.RecordTypeId);
      if (caseRec.RecordTypeId == rectypeId && caseRec.Status ==Constants.CASE_STATUS_APPROVED ) //'Approved')
      {
        system.debug('case type Access Request found that has been approved, trying to add to account team');   
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = caseRec.AccountId ; // acct.id;
        atm.UserId =caseRec.Requestor__c; // '005c0000000l5YX';
        accntRole = caseRec.Team_Role__c; //"Account Manager";
        atm.TeamMemberRole = accntRole ; // 'Account Manager';
        accountTeamMembers.add(atm);
                
        AccountShare accShare = new AccountShare();
        accShare.UserOrGroupId = caseRec.Requestor__c;                //atm.UserId;
        accShare.AccountId = caseRec.AccountId ;                      // acct.Id;
        accShare.AccountAccessLevel =Constants.ACCT_TEAM_ACCESS ;     //'Edit';
        accShare.OpportunityAccessLevel =Constants.OPTY_TEAM_ACCESS ; //'Edit';
        //accShare.ContactAccessLevel = Constants.CONTACT_TEAM_ACCESS;  //'Edit';
        accountShares.add(accShare);
           
       }
     } //end of for loop
        
     try {
       if (accountTeamMembers.Size() > 0 ) {
         insert accountTeamMembers;     
       }
       if (accountShares.Size() > 0 ) {
         insert accountShares;     
       }        
     }catch (Exception e){
        system.debug('Error during Insert of AccoutTeamMember/AccountShare:' + e.getMessage());
     }
        
  }

  /*=========================================================================
  // ESDEL - SPAIN DELIVERY IMPLEMENTATION BELOW
  //=========================================================================*/

  //=========================================================================
  // Generic method to update case and parenet case for billing information
  //=========================================================================
  public static void updateCaseAndParentCaseForBilling(boolean isUpdate, LIST<Case> newCases, MAP<Id,Case> oldIdsToCaseMap){
    Map<Id, Case> caseIdToParentCaseMap = new Map<Id, Case>();
    Map<Id, Case> toBeUpdatedParentCasesMap = new Map<Id, Case>();      
    Set<Id> parentCaseIds = new Set<Id>(); 
    Set<String> closedStatuses = new Set<String>();
    for(CaseStatus cStatus : getClosedCaseStatuses()){
      closedStatuses.add(cStatus.MasterLabel);                          
    }    
    //iterate on Trigger.new list to populate a list of ids of parent cases for later use in the logic 
    for(Case caseRecord : newCases){
      if(caseRecord.ParentId <> null && closedStatuses.contains(caseRecord.status) && caseRecord.Type == Constants.CASE_TYPE_SPAIN_DELIVERY_TASK){
        parentCaseIds.add(caseRecord.ParentId);
      }
    }
    // check if parentCaseIds exists on insert or updated cases.        
    if(!parentCaseIds.isEmpty()){
      caseIdToParentCaseMap = getCaseIdsToCaseMap(parentCaseIds);
    }
    // iterate Trigger.new to implement the business logic                                            
    for(Case caseRecord : newCases){
      // check for insert operation and update operation when status is changed
      if((!isUpdate && closedStatuses.contains(caseRecord.status) && caseRecord.Type == Constants.CASE_TYPE_SPAIN_DELIVERY_TASK) || 
         (isUpdate && closedStatuses.contains(caseRecord.status) && caseRecord.Type == Constants.CASE_TYPE_SPAIN_DELIVERY_TASK && caseRecord.status <> oldIdsToCaseMap.get(caseRecord.id).status)){
        // set current case send to billing date to today and calculated billing units to billing units          
        if(caseRecord.ESDEL_Billing_Order_Line_Id__c <> NULL  && caseRecord.ESDEL_Send_to_Billing_Date__c == NULL){
          setBillingFieldsOnCase(caseRecord, System.today(), caseRecord.ESDEL_Billing_Units__c);    
        }  
        // set current case send to billing date to today and calculated billing units to billing units              
        if(caseRecord.ESDEL_Billing_Order_Line_Id__c == NULL && caseRecord.ParentId <> NULL){
          // set new case send to billing date to today and calculated billing units to billing units
          setBillingFieldsOnCase(caseRecord, System.today(), caseRecord.ESDEL_Billing_Units__c);     
          // PARENT CASE UPDATE OPERATION         
          Case parentCase = caseIdToParentCaseMap.get(caseRecord.ParentId);
          // set billing fields on parent case on when its billing date is set to prior month          
          if(parentCase.ESDEL_Send_to_Billing_Date__c == NULL || parentCase.ESDEL_Send_to_Billing_Date__c.month() < System.today().month()){
            setBillingFieldsOnCase(parentCase, System.today(), caseRecord.ESDEL_Billing_Units__c);
            // update the map for next iteration
            caseIdToParentCaseMap.put(parentCase.id, parentCase);
            // add updated parentCase to the tobeupdated map 
            toBeUpdatedParentCasesMap.put(parentCase.id, parentCase);
          }else if(caseRecord.ESDEL_Send_to_Billing_Date__c.month() == System.today().month()){
            // update parent case calucated billing units + new case billing units
            parentCase.ESDEL_Calculated_Billing_Units__c = (parentCase.ESDEL_Calculated_Billing_Units__c == null ? 0 : parentCase.ESDEL_Calculated_Billing_Units__c) + 
                                                               (caseRecord.ESDEL_Billing_Units__c == null ? 0 : caseRecord.ESDEL_Billing_Units__c);                
            // update the map for next iteration
            caseIdToParentCaseMap.put(parentCase.id, parentCase);    
            // add updated parentCase to the tobeupdated map 
            toBeUpdatedParentCasesMap.put(parentCase.id, parentCase);           
          }
        }          
      }
    }
    // check if tobe udpated map is not empty before doing dml operation
    if(!toBeUpdatedParentCasesMap.isEmpty()){
      try{
        update toBeUpdatedParentCasesMap.values();
      }catch(DmlException ex){
        apexLogHandler.createLogAndSave('CaseTriggerHandler','updateCaseAndParentCaseForBilling', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newCases.get(0).addError(ex.getDMLMessage(indx));
        }
      }  
    }
  } 

  //=========================================================================
  //Generic method to set billings field on case
  //========================================================================= 
  public static void setBillingFieldsOnCase(Case caseRecord, Date sendToBillingDate, decimal billingUnits){
    // set provided case's send to billing date and calculated billing units       
    caseRecord.ESDEL_Send_to_Billing_Date__c = sendToBillingDate;   
    caseRecord.ESDEL_Calculated_Billing_Units__c = billingUnits;
  }

  //=========================================================================
  //Generic method to get Case Closed statuses
  //=========================================================================
  public static List<CaseStatus> getClosedCaseStatuses(){
    // retrieve list of closed case statuses
    return [Select Id, 
            MasterLabel 
            From CaseStatus 
            WHERE IsClosed = true];
  }

  //=========================================================================
  //Generic method to get list of cases associated to caseIds
  //=========================================================================
  public static Map<Id, Case> getCaseIdsToCaseMap(Set<Id> caseIds){
    
    return new Map<Id, Case>([SELECT Id, ESDEL_Calculated_Billing_Units__c, 
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c, 
                              ESDEL_Billing_Order_Line_Id__c 
                              FROM Case 
                              WHERE Id IN : caseIds]);    
  }


/*
  //============================================================================
  //  @Description : add the requestor user to the case teams
  //                ADDED FROM A TOP CODER CHALLENGE - Mass Transfer
  //  @param caseIds set of case ids 
  //  @return void 
  //============================================================================
  @future 
  public static void addUsersToCaseTeams(Set<Id> caseIds){
    CaseTeamRole caseTeamRole = null;
    CaseTeamTemplate caseTeamTemplate = null;
    Set<Id> UserIds = new Set<Id>();
    Mass_Transfer_Template_Settings__c templateSettings = Mass_Transfer_Template_Settings__c.getOrgDefaults();
    List<CaseTeamTemplateMember> caseTeamMemberToInsert = new List<CaseTeamTemplateMember>();

    List<Case> rsCases = [SELECT Id, Requestor__c FROM Case WHERE Id IN: caseIds LIMIT 25000];

    // Get the caseteamrole and caseteamtemplate
    try{
      if (templateSettings != null){
        if (!String.isBlank(templateSettings.Case_Team_Role__c) && !String.isBlank(templateSettings.Case_Team_Template__c)){
          caseTeamRole = Database.query('SELECT Id FROM CaseTeamRole WHERE Name = \''+String.escapeSingleQuotes(templateSettings.Case_Team_Role__c)+'\' LIMIT 1');
          caseTeamTemplate = Database.query('SELECT Id FROM CaseTeamTemplate WHERE Name = \''+String.escapeSingleQuotes(templateSettings.Case_Team_Template__c)+'\' LIMIT 1');
          List<CaseTeamTemplateMember> rsMembers = [SELECT Id, MemberId FROM CaseTeamTemplateMember LIMIT 2000];

          //Get all the member Ids 
          for (CaseTeamTemplateMember member : rsMembers){
            UserIds.add(member.MemberId);
          }
        }
      }
    }catch(Exception ex){
       for (Integer i=0; i< ex.getNumDml(); i++) {
         rsCases.get(0).addError(ex.getDMLMessage(i));
       }
    }
    // Insert case team members
    if (caseTeamRole != null && caseTeamTemplate != null){
      for (Case caseRecord : rsCases){
        if (caseRecord.Requestor__c != null){
          if (!UserIds.contains(caseRecord.Requestor__c)) caseTeamMemberToInsert.add(
            new CaseTeamTemplateMember(MemberId=caseRecord.Requestor__c, TeamTemplateId=caseTeamTemplate.Id, TeamRoleId=caseTeamRole.Id));
            
        }
      }
    }

    // Insert case team member
    if (!caseTeamMemberToInsert.isEmpty()) {
      insert caseTeamMemberToInsert;
    }
  } 
  */
  //[RJ] To populate the Requestor__c field from Requestor email.Case#1939
  public static void toPopulateRequestor (LIST<Case> newCases, Map<Id, Case> oldCases) { 
    try {
      Set <string> reqsEmailSet = new Set <string>();
       // NLG Update 2014-10-01 - checks on RT that do not apply
      DescribeUtility du = new DescribeUtility('Case');
      Set<String> doesNotApplyRT = new Set<String>();
      doesNotApplyRT.add(du.recordTypeId_Map.get(Constants.RECORDTYPE_CASE_EDQ));
      doesNotApplyRT.add(du.recordTypeId_Map.get(Constants.CASE_REC_TYPE_CCM_NA_CASE));
      doesNotApplyRT.add(du.recordTypeId_Map.get(Constants.RECORDTYPE_CASE_SPANISH));

      for (Case caseRec : newCases) {
        if (!doesNotApplyRT.contains(caseRec.RecordTypeId) &&
              ((oldCases == null && caseRec.Requestor_Email__c != null) || oldCases.get(caseRec.Id).Requestor_Email__c != caseRec.Requestor_Email__c) ) {
          reqsEmailSet.add( (String) caseRec.Requestor_Email__c);
        }
      }
      Map <String,Id> reqsUserMap = new Map <string,Id>();

      // 17th Dec, 2014 - JW Case #28782: Add IsActive check
      for (User reqsUserRec :[SELECT Id, Email, Name FROM User WHERE Email in :reqsEmailSet and IsActive = true]) {
        reqsUserMap.put(reqsUserRec.email, reqsUserRec.Id);
      }
    
      for (Case caseRec :newCases) {   
        if (caseRec.Requestor_Email__c != null && reqsUserMap.containsKey(caseRec.Requestor_Email__c)) {
          caseRec.Requestor__c = reqsUserMap.get(caseRec.Requestor_Email__c); 
        } else if (oldCases == null){
          caseRec.Requestor__c = caseRec.CreatedById;
        }
      }
    }
    catch (Exception e) {
      system.debug('CaseTriggerHandler in method CaseTriggerHandler Error:' + e.getMessage());
      ApexLogHandler.createLogAndSave('CaseTriggerHandler','toPopulateRequestor', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newCases.get(0).addError(e.getDmlMessage(i)); 
      }
    }
  }//[RJ] Ends
   
   //===============================================================
   // added for Task T-309768: Round Robin on Case
   //===============================================================
   //code start
   public void onBeforeUpdate(Case[] oldCases, Case[] updatedCases, 
                                Map<ID, Case> caseMap, Map<ID, Case> caseMapOld){

     // lead assignment rules execute after 1st pass of triggers
     // they will fire before/after update one more time
     assignCasesRoundRobin(oldCases, updatedCases, CaseMapOld);                              
     return;
    
    }

    public void onAfterUpdate(Case[] oldCases, Case[] updatedCases,  
                                Map<ID, Case> caseMap, Map<ID, Case> caseMapOld){
        
      if (firstRun) {
        firstRun = false;
      }
      else {
        System.debug('Already ran!');               
        return;
      }       
        
    }

    @future public static void onAfterUpdateAsync(Set<ID> updatedCaseIDs){
      List<Case> updatedCases = [SELECT Id FROM Case WHERE Id IN :updatedCaseIDs];
    }

    public boolean isTriggerContext{
      get{ 
        return m_isExecuting;
      }
    }
    
    public boolean isVisualforcePageContext{
      get{ 
        return !IsTriggerContext;
      }
    }
    
    public boolean isWebServiceContext{
      get{ 
        return !IsTriggerContext;
      }
    }
    
    public boolean isExecuteAnonymousContext{
      get{ 
        return !IsTriggerContext;
      }
    }

    /**
     * assignCasesRoundRobin
     *
     * Use Assignment_Group_Queues__c to round-robin assign Cases
     * Design assumes that out-of-box Case Assignment rules will be used
     * to assign Cases to a Queue. If the Queue is defined in Assignment_Group_Queues__c
     * object, then the next user in the Assignment_Group_Queues__c related list will be assigned instead.  
     */
     private static void assignCasesRoundRobin(Case[] oldCases, 
                                                 Case[] updatedCases, Map<ID, Case> caseMapOld) {
            
       Map<Integer, Id> queueIds = new Map<Integer, Id>();   //Trigger index --> Queue ID
       Integer idx = 0;
            
       for (Case cse : updatedCases) {
         if (Trigger.isUpdate) {                     
            // detect change in OwnerId
            if (cse.OwnerId <> CaseMapOld.get(cse.id).OwnerId) {  
              queueIds.put(idx, cse.OwnerId);
            }           
         }else {
            queueIds.put(idx, cse.OwnerId);
         }      
         idx++;  
       }
            
       // If no queueid's found, return          
       if (queueIds.isEmpty()) {
         return;
       }
            
       // Find active Assignment Group for Queue
       Map<Integer, Id> asgnGroupNameIds = new Map<Integer, Id>();   //Trigger index --> Assignment_Group_Name ID
       Map<Id, Assignment_Group_Queues__c> asgnGroupQueues = new Map<Id, Assignment_Group_Queues__c>(); //Queue ID --> Assignment Group Queues
            
       for (Assignment_Group_Queues__c[] agq : [SELECT Assignment_Group_Name__c, QueueId__c
                                                FROM Assignment_Group_Queues__c 
                                                WHERE QueueId__c in :queueIds.values()
                                                AND Active__c = 'True'
                                                AND Assignment_Group_Name__r.Type__c = 'Case']) {
            for (Integer i = 0; i < agq.size() ; i++) {
              asgnGroupQueues.put(agq[i].QueueId__c, agq[i]);
            }                                           
       }
            
       // if no maching Assignment Groups found for the queues, return        
       if (asgnGroupQueues.isEmpty()) {
         return;
       }  
        
       for (Integer i : queueIds.keySet()) {
         Assignment_Group_Queues__c agq = asgnGroupQueues.get(queueIds.get(i));
         if (agq <> null) {
            asgnGroupNameIds.put(i, agq.Assignment_Group_Name__c);
         }
         //else no active assignment group queue error
       }
            
       if (asgnGroupNameIds.isEmpty()) {
         return;
       }    
       // Determine next valid user in Queue/Assignment Group for round robin
       // User with earliest last assignment date wins.
       Map<Id, Assignment_Groups__c[]> asgnGroups = new Map<Id, Assignment_Groups__c[]>(); // Assignment Group Name ID --> Assignment_Groups__c (User ID)
       for(Assignment_Group_Name__c agn : [SELECT  a.Name, a.Id, 
                                            (SELECT Id, Name, Group_Name__c, Active__c, 
                                             Last_Assignment__c, Millisecond__c, Status__c, 
                                             User_Active__c, User__c 
                                             FROM Assignment_Groups__r
                                             WHERE Active__c = 'True'AND User_Active__c = 'True'
                                             ORDER BY Last_Assignment__c, Millisecond__c) 
                                           FROM Assignment_Group_Name__c a    
                                           WHERE a.Id in :asgnGroupNameIds.values() 
                                           AND a.Type__c = 'Case'
                                           FOR UPDATE ]) {                                               
          asgnGroups.put(agn.ID, agn.Assignment_Groups__r);                                           
         }
               
         if (asgnGroups.isEmpty()) {
          return;
         } 
                                                   
         Map<Id, Assignment_Groups__c> updateAssignmentGroups = new Map<Id, Assignment_Groups__c>();
         Map<Id, datetime> latestAGDateTime = new Map<Id, datetime>();
         idx = 0;    
         Map<ID, ID> mapCaseIdOwnerId = new Map<ID, ID>();
            
         for (Integer i : queueIds.keySet()) {
           Assignment_Groups__c[] ags = asgnGroups.get(asgnGroupNameIds.get(i));
           if (ags.size() > 0) {   
              // Choose next user in line if user ID has already been used 
              // but not committed in this trigger batch 
              Assignment_Groups__c ag = ags[math.mod(idx, ags.size())];
                        
              // Assign User to Case as the new owner
              System.debug('>>>>>Owner changed for Case ' + updatedCases[i].Id + ' from '+updatedCases[i].OwnerId+' to '+ ag.User__c);
                    
              updatedCases[i].OwnerId = ag.User__c;
                            
              // Set last assignment datetime
              datetime now = datetime.now();
              ag.Last_Assignment__c = now;
              ag.Millisecond__c = now.millisecondGMT();
                    
              // update only latest Assignment Groups per ID
              if (latestAGDateTime.containsKey(ag.id)) {
                 if (latestAGDateTime.get(ag.id) < now) {
                    updateAssignmentGroups.put(ag.id, ag);
                    latestAGDateTime.put(ag.id, now);
                 }
              } else {
                  updateAssignmentGroups.put(ag.id, ag);
                  latestAGDateTime.put(ag.id, now);
              }
                    
              idx++;
           }
         }
                
         // Map --> List/Array for DML update
         List<Assignment_Groups__c> updateAG = new List<Assignment_Groups__c>();
         for (Id agId : updateAssignmentGroups.keySet()) {
            updateAG.add(updateAssignmentGroups.get(agId));
         }
        
         // Update last assignment for Assignment Group in batch
         if (updateAG.size()>0) {
            try {
              update updateAG;
            } catch (Exception e){
                addExceptionError(updatedCases, queueIds, e.getMessage());
                System.debug('\n[CaseTriggerHandler: assignCasesRoundRobin]: ['+e.getMessage()+']]');
                apexLogHandler.createLogAndSave('CaseTriggerHandler','assignCasesRoundRobin', e.getStackTraceString(), e); 
            }
         }           
   }
     
   public static void addExceptionError(Case[] updatedCases, Map<Integer,Id> queueIds, String errMsg){
     for (Integer i : queueIds.keySet()) {
        updatedCases[i].addError('ERROR: Could not update Assignment Group records ' + ' DETAIL: '+ errMsg);  
     }
   }// code ends
   

// T-318031: Code is commented as Task is blocked
/*
  // T-318031: code to add User to CaseTeam for 'EDQ GPD' Record Type
  public static void addUserToCaseTeamforEDQ_GPD_RecType(List<Case> lstCase){
    String caseRecType = Constants.CASE_REC_TYPE_EDQ_GPD_CASE; 
    if (caseRecType == null) {
        caseRecType ='EDQ GPD Case';
    }
     
    RecordType rt = [SELECT Id FROM RecordType WHERE Name = :caseRecType AND SobjectType = 'Case' limit 1];
    String rectypeId = rt.Id;

    List<CaseTeamMember> lstCTMs = new List<CaseTeamMember>();
     
    //Retrive CaseTeamRole name from Custom Setting.
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
             
    //Retrive CaseTeamRole recordId by name
    CaseTeamRole ctrRec = [SELECT Id, Name, AccessLevel FROM CaseTeamRole 
                           WHERE Name = :custSettings.Case_Access_Request_TeamRole__c];

    for (Case caseRec : lstCase) {

        if (caseRec.CreatedById != null && caseRec.RecordTypeId == rectypeId ) {
          // create case team member record
          lstCTMs.add( new CaseTeamMember(ParentId = caseRec.id,
                        MemberId = caseRec.Requestor__c, TeamRoleId = ctrRec.id));                  
          }
    }
    if (lstCTMs.size() > 0) {
       try {
         insert lstCTMs;
       } catch (DMLException ex) {
           ApexLogHandler.createLogAndSave('CaseTriggerHandler','addUserToCaseTeamforEDQ_GPD_RecType', ex.getStackTraceString(), ex);
           for (Integer i = 0; i < ex.getNumDml(); i++) {
              lstCase.get(0).addError(ex.getDmlMessage(i)); 
           }
       }   
     }


  } */
  
  //T-319846: Creating case team members for allowed RTs
  private static void createCaseTeamMembersForCases(List<Case> newList, Map<ID, Case> oldMap) {
    DescribeUtility du = new DescribeUtility('Case');
    List<CaseTeamMember> teamMemberList = new List<CaseTeamMember>();

    Set<String> allowedRecordTypes = new Set<String>();
    allowedRecordTypes.add(du.recordTypeId_Map.get(Constants.RECORDTYPE_CASE_EDQ_GPD));
    allowedRecordTypes.add(du.recordTypeId_Map.get(Constants.RECORDTYPE_CASE_EDQ_COMMERCIAL));
    allowedRecordTypes.add(du.recordTypeId_Map.get(Constants.RECORDTYPE_CASE_ONBOARDING));
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
    CaseTeamRole ctrObj;
    for (CaseTeamRole ctr : [SELECT ID, Name, AccessLevel FROM CaseTeamRole WHERE Name =: custSettings.Case_Access_Request_TeamRole__c]) {
      ctrObj = ctr;
      break;
    }
    
    if (ctrObj == null || ctrObj.ID == null) {
      return;
    }
    
    for (Case newCase : newList) {
      if (newCase.Requestor__c != null && allowedRecordTypes.contains(newCase.RecordTypeId) && newCase.Requestor__c != newCase.CreatedById &&
          (oldMap == null || newCase.Requestor__c != oldMap.get(newCase.ID).Requestor__c)) {
        teamMemberList.add(createNewCaseTeamMember(newCase, ctrObj));
      }
    }
    
    //Inserting case team members
    if (teamMemberList.size() > 0) {
      try {
        insert teamMemberList;
      } catch (DMLException ex) {
        System.debug('[CaseTriggerHandler:createCaseTeamMembersForCases]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('CaseTriggerHandler','createCaseTeamMembersForCases', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
      }
    }
  }
  
  //Creating new team member
  private static CaseTeamMember createNewCaseTeamMember (Case newCase, CaseTeamRole csTeamRole) {
    CaseTeamMember newTeamMember = new CaseTeamMember();
    newTeamMember.ParentId = newCase.ID;
    newTeamMember.MemberId = newCase.Requestor__c;
    newTeamMember.TeamRoleId = csTeamRole.ID;
    return newTeamMember;
  }

  //================================================================================
  //================================= EMS / Gleam ==================================
  //================================================================================
  // Method to update the child records when Parent case is closed resolved
  private static void updateChildCasesOnCaseResolved (list<Case> newCases, map<Id,Case> oldCases) {
    try {
        List<Case> childCases = new List<Case>();
        set<Id> parentCases = new set<Id>();
        String emsRecordType = '';
        emsRecordType = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.RECORDTYPE_CASE_EMS);
        for ( Case cs : newCases) {
            if ( cs.RecordTypeId == emsRecordType && cs.Status != oldCases.get(cs.Id).Status 
            && cs.Status == Constants.CASE_STATUS_CLOSED_RESOLVED && ( cs.Type == Constants.CASE_TYPE_INCIDENT)) {
                parentCases.add(cs.Id);
            }
        }
        for ( Case cs : [SELECT Id, Status 
                         FROM Case
                         WHERE parentId IN :parentCases
                         AND RecordTypeId = :emsRecordType
                         AND IsClosed = :false]) {
            cs.Status = Constants.CASE_STATUS_CLOSED_RESOLVED;
            childCases.add(cs);
        }
        update childCases;
    }
    catch ( Exception ex ) {
        System.debug('[CaseTriggerHandler:updateChildCasesOnCaseResolved]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('CaseTriggerHandler','updateChildCasesOnCaseResolved', ex.getStackTraceString(), ex);
    }
  }
  
  // method to associate business hours with the cases
  private static void populateBusinessHours (list<Case> newCases) {
    set<String> frenchUserRoles = new set<String>();
    frenchUserRoles.add(Constants.USER_ROLE_FRANCE_EVOLUTION);
    frenchUserRoles.add(Constants.USER_ROLE_FRANCE_L1_CLIENT_SERVICE_AGENT);
    frenchUserRoles.add(Constants.USER_ROLE_FRANCE_L2_CLIENT_SERVICE_AGENT);
    frenchUserRoles.add(Constants.USER_ROLE_FRANCE_ONBOARDING);
    set<String> germanUserRoles = new set<String>();
    germanUserRoles.add(Constants.USER_ROLE_GERMANY_EVOLUTION);
    germanUserRoles.add(Constants.USER_ROLE_GERMANY_L1_CLIENT_SERVICE_AGENT);
    germanUserRoles.add(Constants.USER_ROLE_GERMANY_L2_CLIENT_SERVICE_AGENT);
    germanUserRoles.add(Constants.USER_ROLE_GERMANY_ONBOARDING);
    set<String> spanishUserRoles = new set<String>();
    spanishUserRoles.add(Constants.USER_ROLE_SPAIN_EVOLUTION);
    spanishUserRoles.add(Constants.USER_ROLE_SPAIN_L1_CLIENT_SERVICE_AGENT);
    spanishUserRoles.add(Constants.USER_ROLE_SPAIN_L2_CLIENT_SERVICE_AGENT);
    spanishUserRoles.add(Constants.USER_ROLE_SPAIN_ONBOARDING);
    Map<String,BusinessHours> businessHoursMap = new Map<String,BusinessHours>();
      for ( BusinessHours hour : [SELECT Id,Name 
                                  FROM BusinessHours]) {
        businessHoursMap.put(hour.Name,hour);
      }
      
      set<Id> owners = new set<Id>();
      for (Case cs : newCases ) {
        owners.add(cs.OwnerId);
      }
      map<Id,String> userRoleMap = new map<Id,String>();
      for ( User usr : [SELECT userRoleId,userRole.Name ,Id 
                        FROM User
                        WHERE Id IN :owners]) {
        if (usr.UserRoleId != null) {
            userRoleMap.put(usr.Id, usr.userRole.Name);
        }
      }
      String emsRecordType = '';
      emsRecordType = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.RECORDTYPE_CASE_EMS); 
      for( Case cs : newCases ) {
        if( !userRoleMap.containsKey(cs.OwnerId) ) {
            continue;
        }
        if ( cs.RecordTypeId == emsRecordType) {
            if ( frenchUserRoles.contains(userRoleMap.get(cs.OwnerId)) ) {
                cs.BusinessHoursId = businessHoursMap.containsKey(Constants.CASE_BUSINESSHOURS_FRANCE_MORNING) ? businessHoursMap.get(Constants.CASE_BUSINESSHOURS_FRANCE_MORNING).Id: null;
                cs.Business_Hours_Afternoon__c = businessHoursMap.containsKey(Constants.CASE_BUSINESSHOURS_FRANCE_AFTERNOON) ? businessHoursMap.get(Constants.CASE_BUSINESSHOURS_FRANCE_AFTERNOON).Id: null;
            }
            else if ( germanUserRoles.contains(userRoleMap.get(cs.OwnerId)) ) {
            cs.BusinessHoursId = businessHoursMap.containsKey(Constants.CASE_BUSINESSHOURS_GERMANY) ? businessHoursMap.get(Constants.CASE_BUSINESSHOURS_GERMANY).Id: null;
          }
          if ( spanishUserRoles.contains(userRoleMap.get(cs.OwnerId)) ) {
            cs.BusinessHoursId = businessHoursMap.containsKey(Constants.CASE_BUSINESSHOURS_SPAIN) ? businessHoursMap.get(Constants.CASE_BUSINESSHOURS_SPAIN).Id: null;      
          }
        }
      }
  }
    // I-163081:  method to populate CaseOwner's Manager email
  public static void toPopulateCaseOwnerManagerEmail (LIST<Case> newCases, Map<Id, Case> oldCases) { 
    try {
      Map<String, String> mapUserIdToCaseId = new Map<String, String>();
      
      String emsRecordType = '';
      emsRecordType = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.RECORDTYPE_CASE_EMS); 

      for (Case caseRec : newCases) {
        if ((caseRec.RecordTypeId == emsRecordType ) &&
              ((oldCases == null && caseRec.CaseOwner_Manager_Email__c == null) ||
                 oldCases.get(caseRec.Id).OwnerId != caseRec.OwnerId) ) {
           mapUserIdToCaseId.put(caseRec.OwnerId, caseRec.Id);
        }
      }
      Map <Id,User> mapUserIdToMangerEmail = new Map <Id,User>();

      for (User userRec :[SELECT Id, Email, Managers_Email__c, Name, Managers_Name__c 
                            FROM User WHERE Id IN :mapUserIdToCaseId.keyset()]) {
        mapUserIdToMangerEmail.put(userRec.Id, userRec);
      }
      
      for (Case caseRec :newCases) {   
        if (mapUserIdToMangerEmail.containsKey(caseRec.OwnerId)) {
          caseRec.CaseOwner_Manager_Email__c = mapUserIdToMangerEmail.get(caseRec.OwnerId).Managers_Email__c; 
          caseRec.Owner_s_Manager_s_Name__c = mapUserIdToMangerEmail.get(caseRec.OwnerId).Managers_Name__c;
        }
      }
    }
    catch (Exception e) {
      system.debug('CaseTriggerHandler in method toPopulateCaseOwnerManagerEmail() Error:' + e.getMessage());
      ApexLogHandler.createLogAndSave('CaseTriggerHandler','toPopulateCaseOwnerManagerEmail', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newCases.get(0).addError(e.getDmlMessage(i)); 
      }
    }
  }
}