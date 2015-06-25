/*
 Batch class to process Nominated survey records 
*/
global class SMXNominationProcessorBatch implements Database.Batchable<Feedback__c>, Database.AllowsCallouts
{
    // query the nominated survey records
    Feedback__c [] fbkArrParticipants = [select Feedback__c.Contact__c,Feedback__c.Name,Feedback__c.DataCollectionId__c 
                                         from Feedback__c where Feedback__c.Status__c ='Nominated'];
    
    global Iterable<Feedback__c> start(database.batchablecontext BC)
    {          
        if(Test.isRunningTest()){
           return prepareTestData();
        }
        return (fbkArrParticipants);
    }
    
    global void execute(Database.BatchableContext BC, List<Feedback__c> scope)
    {
        for(Feedback__c fbk : scope){
            // T-375155 for EMS Cases
            if (fbk.DataCollectionId__c == 'EXPERIAN_107228') {
            	SMX_EMS_NominationProcessor.processNomination(fbk.Name);
            }
            else {
            	// pass thru nomination processor to push into Xperience
            SMXNominationProcessor.processNomination(fbk.Name);
            }
        }
    }
    
    //global void finish loop
    global void finish(Database.BatchableContext info)    
    {
       
    }
 
    static List<Feedback__c> prepareTestData()
    {
        Account a = Test_Utils.createAccount();
        a.Name='SMX Test Account';
        a.Industry='Test Industry';
        a.BillingPostalCode='211212'; 
        a.BillingStreet='TestStreet';
        a.BillingCity='TestCity';
        a.BillingCountry='TestCountry';
        insert a;
        
        Contact c = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com', Phone='9999999');
        insert c;    
            
        List <Feedback__c> feedbackList = new List<Feedback__c>();
        Feedback__c feedback = new Feedback__c();
        feedback.Name = 'TEST_CRM_12345';
        feedback.Contact__c = c.Id; //ContactName
        feedback.DataCollectionId__c = 'NYSEEURONEXT_20049';
        feedback.DataCollectionName__c = 'NYSE Listing Survey';
        feedback.Status__c = 'Test_Nominated';                       
        feedback.PrimaryScore__c = 9;
        feedback.PrimaryComment__c = 'Test comment';
        feedback.Status__c = 'Test Status';
        feedback.StatusDescription__c = 'Test Description';
        feedback.SurveyDetailsURL__c = '';
        insert feedback;
        
        feedbackList.add(feedback); 
        
        return feedbackList;
    }  
    
}