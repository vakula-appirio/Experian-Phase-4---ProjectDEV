@isTest (SeeAllData=False)
public class SMXNominationProcessorBatchTest{

    static testMethod void testOpportunityNomination(){   
        Global_Settings__c gs = new Global_Settings__c();
        gs.Name = 'Global';
        gs.Batch_Failures_Email__c = '';
        insert gs;

         Database.BatchableContext BC;
         List<Feedback__c> lstFeedback = new List<Feedback__c>();
         Test.startTest();         
         SMXNominationProcessorBatch b = new SMXNominationProcessorBatch();
         Database.executeBatch(b);
         /*Iterable<Feedback__c> itrFeedback = b.start(BC);
         Iterator<Feedback__c> iterator = itrFeedback.iterator();
         while(iterator.hasNext()){
             lstFeedback.add(iterator.next());         
         }
         b.execute(BC,lstFeedback);
         //b.finish(BC);*/         
         Test.stopTest();    
    }
}