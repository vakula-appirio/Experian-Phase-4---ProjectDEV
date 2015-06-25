/*======================================================================================
 * Experian Plc.
 * Name: BatchQuoteStatusUpdate
 * Description: Batch Job to query all Opty closed today and update status for all quotes realted to it.
 * Created Date: Oct 15th 2014
 * Created By: Richard Joseph
 * 
 * Date Modified                Modified By                  Description of the update
 * 
 =======================================================================================*/

global class BatchQuoteStatusUpdate implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
  global String query;
  global Map<id,Opportunity> updateOpportunityMap;
  
  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
       
    If (query == null)
    {
        query = 'Select id,Quote_Id__c,Primary__c,Opportunity__c,Opportunity__r.StageName,Name,Status_Change_Error_Message__c  from Quote__c where Opportunity__r.SyncCPQ__c = true ';
        
          updateOpportunityMap = new Map<id,Opportunity>([Select id,SyncCPQ__c from Opportunity where SyncCPQ__c = true AND isclosed = true ])  ;
          
          System.debug('\n[BatchQuoteStatusUpdate - Opportunity Toupdated total]:'+ updateOpportunityMap.size() ); 
        }
    return Database.getQueryLocator(query);
  }
  
  //==============================================================
  // execute method
  //==============================================================
  global void execute(Database.BatchableContext BC, List<Quote__c> quoteProcessList) {
    System.debug('\n[BatchQuoteStatusUpdate : execute] : Scope size: '+quoteProcessList.size());
  
  String serviceResponseMessage=null;
  For (Quote__c quoteRec:quoteProcessList) {
   try {
         serviceResponseMessage=SFDCToCPQChangeStatusServiceClass.callCPQUserAdminSerivce(quoteRec);
         If(serviceResponseMessage != null)
         {
             quoteRec.Status_Change_Error_Message__c = serviceResponseMessage ; 
               //update quoteRecord;
              if (updateOpportunityMap!= null && updateOpportunityMap.containsKey(quoteRec.Opportunity__c))
                  updateOpportunityMap.remove(quoteRec.Opportunity__c);    
         }
             
    } catch (Exception e) {
        
         if (updateOpportunityMap!= null && updateOpportunityMap.containsKey(quoteRec.Opportunity__c))
                  updateOpportunityMap.remove(quoteRec.Opportunity__c);    
         
      ApexLogHandler.createLogAndSave('BatchQuoteStatusUpdate','execute', e.getStackTraceString(), e);
     
    }
    }
    Update quoteProcessList;
  }

  //==============================================================
  // finish method
  //==============================================================
  global void finish(Database.BatchableContext BC) {
    
    //Update the Sync Flag in Opportunity
    if (updateOpportunityMap != null){
    For(Opportunity optyRec: updateOpportunityMap.Values())
    {
        optyRec.SyncCPQ__c =false;
    }
    
    try{
    
        Update updateOpportunityMap.Values();
      }
      catch (exception ex)
      {
          System.debug('BatchQuoteStatusUpdate  Exception :'+ ex.getLineNumber() + ' Stack:' +ex.getStackTraceString() );
      }
       System.debug('\n[BatchQuoteStatusUpdate - Opportunity Updated total]:'+ updateOpportunityMap.size() );  
        }
    //Batch completion and verification process
   
    
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];
      
    System.debug('\n[BatchQuoteStatusUpdate : finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');
    
    

    if (a.NumberOfErrors > 0 || Test.isRunningTest()) {
      String emailBody = 'The Batch job on Quote status update is completed successful processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' and generated ' + a.NumberOfErrors ;
           if (updateOpportunityMap != null && updateOpportunityMap.size() > 0)    
               emailBody  = emailBody +   + '\\n Opportunities which are updated are :' + updateOpportunityMap.keySet();     
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
      mail.setSaveAsActivity(false);
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSubject('Force.com BatchQuoteStatusUpdate  status mail');
      mail.setBccSender(false);
      mail.setUseSignature(false);
      mail.setPlainTextBody(emailBody);
      if (!Test.isRunningTest()) {  
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }  
  /* Execution 
      BatchQuoteStatusUpdate objTest = new BatchQuoteStatusUpdate ();
      database.executeBatch(objTest ,1); 
  
  */
}