/**=====================================================================
 * Appirio, Inc
 * Name: BatchReCreateBURelationship
 * Description: 
 * Created Date: Dec 08th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014                                     Jinesh Goyal(Appirio)              T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 * Apr 07th, 2014               Arpita Bose(Appirio)          T-269372: Added addError()in try-catch block
 * Apr 23rd, 2014               Nathalie Le Guay              Commenting class
 =====================================================================*/

global class BatchReCreateBURelationship /*implements Database.Batchable<SObject>, Database.Stateful*/

{ 
    /*global string EmailToOnFinish{get;set;}
    global List<map<Id,String>> lstUpdateFailedOpps{get;set;}
    
    //Start method, which will excute the query and retrive records based on filters set in CustomLabels.
    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator(Label.BU_Creation_Batch_Query+(Test.isRunningTest()?' limit 10':''));
    }//END, start method.

    public BatchReCreateBURelationship(){
    //If Batch is started Manually from UI then send email confirmation on complete to user, who started.
            EmailToOnFinish = [Select Email From User where Username = : UserInfo.getUserName() limit 1].Email;
            lstUpdateFailedOpps = new List<map<Id,String>>();
    }
    
    //Execute method. process the resultset and update Account fields values respectively.
    global void execute(Database.BatchableContext BC, List<Opportunity> lstOpps){
    
        
        try
        {
            OpportunityTrigger_BUHelper.populateBUsOnCreate(lstOpps);
            //update lstOpps;

            Database.SaveResult[] srList = Database.update(lstOpps, false);
            Integer idxCounter = 0;
            Map<Id,String> mapUpdateFailed = new Map<Id,String>();
            Map<Id,Opportunity> mapOpps =  new Map<Id,Opportunity>();
    
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('#############Exception######.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('#############Opportunity fields that affected this error: ' + err.getFields());
                        mapUpdateFailed.put(lstOpps[idxCounter].id,err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
                
              mapOpps.put(lstOpps[idxCounter].id,lstOpps[idxCounter]);  
             //Increment counter   
             idxCounter++;
          }//END: FOR sr 
          
          System.debug('#############mapUpdateFailed######.'+mapUpdateFailed);   
           
          //Add exceptions, so to send those as email attachment.  
          if(mapUpdateFailed.size()>0)
              lstUpdateFailedOpps.add(mapUpdateFailed);  
          
          //This call to align Parent Child BUs.
          OpportunityTrigger_BUHelper.populateParentBUs(mapOpps, null);
        }catch(Exception ex){
              ApexLogHandler.createLogAndSave('BatchReCreateBURelationship','execute', ex.getStackTraceString(), ex);
            system.debug('########Exception##########'+ex);
            for (Integer i=0; i < ex.getNumDml(); i++) {
              lstOpps.get(0).addError(ex.getDMLMessage(i));
            }   
        }
    
    }//END. execute method.
    
    
    //On finish send email, if started manually.
    global void finish(Database.BatchableContext BC){ 
    
        //send confirmation email who triggered.
        if(EmailToOnFinish!=null)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
            mail.setToAddresses(new String[] {EmailToOnFinish});
            mail.setReplyTo('noreply@experian.com');
            mail.setSenderDisplayName('Batch Processing');
            mail.setSubject('Experian:BU Creation Batch Process Completed');
            //string strBodyText='';

            //If there are any processing error/exception.

            if(lstUpdateFailedOpps.size()>0 || Test.isRunningTest()){
                system.debug('############lstUpdateFailedOpps###############'+lstUpdateFailedOpps);
                string header = 'Record Id, Exception\n';
                string finalstr = header ;
                
                //Iterate through all records to create CSV..
                for(Map<Id,String> recs:lstUpdateFailedOpps)
                {
                    for(Id oppId:recs.keySet())
                    {
                           finalstr  = finalstr + oppId+','+ recs.get(oppId) +'\n';
                    }
                }
                
                //Create Email CSV attachment of created.
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('BU_Creation_Failures_'+System.today()+'.csv');
                efa.setBody( Blob.valueOf(finalstr));
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            }

            
            //system.debug('############in finish before TextBody strBodyText##############'+strBodyText);
            mail.setPlainTextBody('BU Creation Batch Process has completed');
            try
            {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }catch(Exception ex){System.debug('##########LIMIT Exception##########'+ex);
              ApexLogHandler.createLogAndSave('BatchReCreateBURelationship','finish', ex.getStackTraceString(), ex);
            }
            
            //Schedule another batch to Populate Amount and Type on BUs.
            try
            {
                BURelationshipCalculator_Batch batch = new BURelationshipCalculator_Batch(); 
                if(!Test.isRunningTest())
                    Database.executeBatch(batch);
            }catch(Exception ex){
                  ApexLogHandler.createLogAndSave('BatchReCreateBURelationship','finish', ex.getStackTraceString(), ex);
                  createMailMessage(EmailToOnFinish ,ex.getMessage());
            }
            
        }
        
    }//END. method Finish
    
     public void createMailMessage(String toAddress, String exMsg){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {toAddress});
        mail.setReplyTo('noreply@experian.com');
        mail.setSenderDisplayName('Batch Processing-Failed');
        mail.setSubject('Experian:BURelationshipCalculator_Batch Failed');
        mail.setPlainTextBody(exMsg+'\n\n\nKindly start BURelationshipCalculator_Batch manully from developer console to update Amount and Type on BU records.');
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }catch(Exception excep){System.debug('##########LIMIT Exception excep##########'+excep);
          ApexLogHandler.createLogAndSave('BatchReCreateBURelationship','Finish', excep.getStackTraceString(), excep);               
        }
    }*/

}