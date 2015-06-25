/**=====================================================================
 * Appirio, Inc
 * Name: BatchBUCreationManualStartController
 * Description: Visualforce page Controller, allowing Admin to start Batch Manually.
 * Created Date: Dec 08th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                   Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 =====================================================================*/

public class BatchBUCreationManualStartController
{
	/*
/////////////////###############Class Varible declaration start####################\\\\\\\\\\\\\\\\\\\\
public string confirmationMessage {get;set;}
public boolean hasBatchQueued {get;set;}
public boolean hasFoundBUs {get;set;}
/////////////////###############Class Varible declaration End####################\\\\\\\\\\\\\\\\\\\\

    //Constructor.
    public BatchBUCreationManualStartController(){
      try {
        hasFoundBUs=false;
        BU_Relationship__c BU = [select id from BU_Relationship__c limit 1];
        hasFoundBUs = true;
      } catch(Exception ex) {
        hasFoundBUs = false;
        ApexLogHandler.createLogAndSave('BatchBUCreationManualStartController','BatchBUCreationManualStartController', ex.getStackTraceString(), ex);
      }
    }

    public void startBatch(){
            try
            {
                //Start Job.
                BatchReCreateBURelationship cls = new BatchReCreateBURelationship();
                Id JobId = database.executebatch(cls);
                system.debug('##########JobId############'+JobId);
                system.debug('#######################cls#############'+cls); 
    
                confirmationMessage = 'Job is successfully Queued, You will be notified via email on completion.'+
                            'To track progress, check status from Apex Job Monitor. JobId :'+JobId;
        
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,confirmationMessage));
        
                hasBatchQueued =true;            

            } catch(Exception ex) {
              ApexLogHandler.createLogAndSave('BatchBUCreationManualStartController','startBatch', ex.getStackTraceString(), ex);
              confirmationMessage =ex.getMessage();
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,confirmationMessage));
            }
    }//END method startBatch
*/
}