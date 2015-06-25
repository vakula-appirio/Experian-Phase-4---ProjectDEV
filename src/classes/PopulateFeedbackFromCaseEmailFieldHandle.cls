//
// (c) 2014 Appirio, Inc.
//
// To update the email ids of Case Owner and the Manager to the owner on Survey object for WF
// Handler for PopulateFeedbackFromCaseEmailFieldTrigger
//
// 8 May 2015   Sidhant Agarwal    Original (Ref. T-375157)
//
public with sharing class PopulateFeedbackFromCaseEmailFieldHandle {
    private static String errMsg = '';
    private static String GRP_KEY_PREFIX = '00G';
    private static String emsRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_EMS );
    private static map<String, String> mapFeedbackIdToCaseId;
    // @description: called after the insert of the feedback item
    // @param: Map<String, Feedback__c> newMap 
    // @return: void
    public static void afterInsert(Map<ID, Feedback__c> newMap) {
        Set<String> newCaseIdSet = new Set<String>();
        mapFeedbackIdToCaseId = new map<String, String>();
        for(Feedback__c feedback : newMap.values()) {
            if(feedback.Case__c != null) {
                newCaseIdSet.add(feedback.Case__c);
                mapFeedbackIdToCaseId.put(feedback.ID, feedback.Case__c);
            }
        }
        if(mapFeedbackIdToCaseId.size()>0) {
            populateEmail(mapFeedbackIdToCaseId.keyset(), mapFeedbackIdToCaseId.values());
        }
    }
    
    // @description: called after the update of the feedback record; 
    //               includes check to prevent update in loop
    // @param: Map<String, Feedback__c> newMap 
    // @return: void
    public static void afterUpdate(Map<ID, Feedback__c> newMap, Map<ID, Feedback__c> oldMap) {
        Set<String> newCaseIdSet = new Set<String>();
        Set<String> oldCaseIdSet = new Set<String>();
        mapFeedbackIdToCaseId = new map<String, String>();
        for(String oldVersionId : oldMap.keySet()){
            //check if case assigned to the survey has changed, add CaseId to set; then add to map
            if( oldMap.get(oldVersionId).Case__c != newMap.get(oldVersionId).Case__c ){
                //checks if Survey's case is not empty
                if(newMap.get(oldVersionId).Case__c != null ) {
                    newCaseIdSet.add(newMap.get(oldVersionId).Case__c);
                    mapFeedbackIdToCaseId.put(newMap.get(oldVersionId).Id, newMap.get(oldVersionId).Case__c);
                }
            }
            //to check if the email fields of old Case have been updated
            else{
                //checks if Survey's case is not empty
                if(oldMap.get(oldVersionId).Case__c != null) {
                    oldCaseIdSet.add(oldMap.get(oldVersionId).Case__c);
                    mapFeedbackIdToCaseId.put(oldMap.get(oldVersionId).Id, oldMap.get(oldVersionId).Case__c);
                }
            }
        }
        if(mapFeedbackIdToCaseId.size()>0) {
        	populateEmail(mapFeedbackIdToCaseId.keyset(), mapFeedbackIdToCaseId.values());
        }
    }
    
    // @description: Method to populate Owner email & Owner's Manager email
    // @param: Set<String> 
    // @return: void
    private static void populateEmail(Set<String> feedbackIdSet, list<String> caseIdSet) {
        //if case is not replaced; 
        if(caseIdSet.size()>0) {
        	map<String, Feedback__c> mapcaseIDtoFeedback = new map<String, Feedback__c>();
        	list<Feedback__c> tempLstFeedback = new list<Feedback__c>();
            map<String, String> mapCaseIdToEmail = new map<String, String>();
            map<String, String> mapUserIdToCaseId = new map<String, String>();
            //traversing through all the cases in caseIdSet; RecordType as EMS
            for(Case caseVar : [SELECT Id, OwnerId, RecordTypeId
                                FROM Case
                                WHERE ID 
                                IN: caseIdSet ]) {
                if(caseVar.RecordTypeId == emsRecordTypeId) {
                    mapUserIdToCaseId.put(caseVar.OwnerId, caseVar.Id);
                }
            }
            
            for(User tempUser : [SELECT Managers_Email__c, Email 
                                 FROM User 
                                 WHERE ID IN: mapUserIdToCaseId.keyset()]) {
                //building a map; Id vs a String of two emails separated by ';'
                mapCaseIdToEmail.put(mapUserIdToCaseId.get(tempUser.Id), tempUser.Email + ';' + tempUser.Managers_Email__c);                         
            }
            for(Feedback__c feedback : [SELECT ID, CaseOwnerEmail__c, CaseOwnerManagerEmail__c, Case__c 
                                    FROM Feedback__c 
                                    WHERE ID 
                                    IN: feedbackIdSet]) {
                mapcaseIDtoFeedback.put(feedback.Case__c, feedback);
            }
            //if the case owner is Queue; then populate the Email fields with blank value
            for(String grpIdCheck : mapUserIdToCaseId.keySet()) {
            	Boolean toUpdate = false;
                if(grpIdCheck.mid(0, 3).equalsIgnoreCase(GRP_KEY_PREFIX)) {
                    Feedback__c tempFeedback = mapcaseIDtoFeedback.get(mapUserIdToCaseId.get(grpIdCheck));
                    if(!String.isBlank(tempFeedback.CaseOwnerEmail__c)) {
                    	tempFeedback.CaseOwnerEmail__c = '';
                    	toUpdate = true;
                    }
                    if(!String.isBlank(tempFeedback.CaseOwnerManagerEmail__c)) {
                    	tempFeedback.CaseOwnerManagerEmail__c = '';
                    	toUpdate = true;
                    }
                    if(toUpdate) {
                    	tempLstFeedback.add(tempFeedback);
                    }
                }
            }
            
            
            for(String str : mapCaseIdToEmail.keySet()) {
            	system.debug('--str--'+str);
                Feedback__c tempFeedback = mapcaseIDtoFeedback.get(str);
                List<String> lstMail = mapCaseIdToEmail.get(str).split(';');
                //check if the list generated after splitting of string contains values
                if(lstMail.size()>0) {
                    //flag; set as true if any of the emails have been changed; initially false
                    Boolean toUpsert = false;
                    if(tempFeedback.CaseOwnerEmail__c != lstMail[0]) {
                        if(lstMail[0] != 'null') {
                            tempFeedback.CaseOwnerEmail__c = lstMail[0];
                            toUpsert = true;
                        }else if(String.isBlank(lstMail[0])) {
                        	tempFeedback.CaseOwnerEmail__c = '';
                        	toUpsert = true;
                        }
                    }
                    if(tempFeedback.CaseOwnerManagerEmail__c != lstMail[1]) {
                        if(lstMail[1] != 'null') {
                            tempFeedback.CaseOwnerManagerEmail__c = lstMail[1];
                            toUpsert = true;
                        }else if(String.isBlank(lstMail[1])){
                        	tempFeedback.CaseOwnerManagerEmail__c = '';
                        	toUpsert = true;
                        }
                    }
                    if(toUpsert) {
                        //add feedback record to the list for upsert
                        tempLstFeedback.add(tempFeedback);
                    }
                }
            }
            try{
                if(tempLstFeedback.size()>0) {
                    update tempLstFeedback;
                }
            }catch(Exception e) {
                errMsg = e.getMessage();
                system.debug('Error Message'+errMsg);
            }
        }
    }
}