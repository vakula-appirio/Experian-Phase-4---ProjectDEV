//
// (c) 2014 Appirio, Inc.
//
// To update the email ids of Case Owner and the Manager to the owner on Survey object for WF
// Trigger for PopulateFeedbackFromCaseEmailFieldHandle
//
// 8 May 2015   Sidhant Agarwal    Original (Ref. T-375157)
//
trigger PopulateFeedbackFromCaseEmailFieldTrigger on Feedback__c (after insert,  after update) {
    if (Trigger.isInsert && Trigger.isAfter) {
        PopulateFeedbackFromCaseEmailFieldHandle.afterInsert(trigger.newMap);
    }else if (Trigger.isupdate && Trigger.isafter) {
        PopulateFeedbackFromCaseEmailFieldHandle.afterUpdate(trigger.newMap , trigger.oldMap);
    } 
}