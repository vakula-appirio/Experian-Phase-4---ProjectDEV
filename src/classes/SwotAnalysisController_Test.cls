/**=====================================================================
 * Appirio, Inc
 * Name: SwotAnalysisController.cls/(For use with SwotAnalysis.page)
 * Description: This class works with the above VF page to display a SWOT analysis page to the end user,
 *              a 2 x 2 grid with Account Plan SWOT records displayed in the appropriate section.
 *              This page will also allow the creation of new Account Plan SWOT records, and can have a
 *              maximum of 8 records per "Type," for each "Who" selected.
 * Created Date: 05/07/14
 * Created By: Shane Khublall (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 13 May 2014                  Shane Khublall               Creation of class for S-210209 specification (T-278175)
 =====================================================================*/


@isTest
private class SwotAnalysisController_Test
{
    static testMethod void test_method_one()
    {
        Account testAcc = Test_Utils.createAccount();
        insert testAcc; // Insert the account record
        system.debug('aaaaa Account:' + testAcc);
        Account_Plan__c testAccPlan = Test_Utils.insertAccountPlan(false,testAcc.id);
        insert testAccPlan; // insert the account plan record, associate it with the above account
        system.debug('bbbbbb Account Plan' + testAccPlan);

        // Empty List of Account Plan SWOT records to insert
        List<Account_Plan_SWOT__c> allTestAccPlanSWOTRecs = new List<Account_Plan_SWOT__c>();

        // Create 40 records for insertion, add them to the list
        for(integer i=0; i<20; i++)
        {
            // Creating 5 records per section
            Account_Plan_SWOT__c testAccPlanSWOT = Test_Utils.insertAccountPlanSwot(false,testAccPlan.id);
            testAccPlanSWOT.Who__c = 'Experian';
            if(i<5)
            {
                testAccPlanSWOT.Type__c = 'Strength';
            }
            else if(i<10)
            {
                testAccPlanSWOT.Type__c = 'Weakness';
            }
            else if(i<15)
            {
                testAccPlanSWOT.Type__c = 'Opportunity';
            }
            else
            {
                testAccPlanSWOT.Type__c = 'Threat';
            }
            allTestAccPlanSWOTRecs.add(testAccPlanSWOT);
        }

        insert allTestAccPlanSWOTRecs; // insert the list of account plan SWOT records
        PageReference pageRef = Page.SwotAnalysis;
        Test.setCurrentPage(pageRef); // Set the page to 'SwotAnalysis'
        system.debug('TEST PAGE REFERENCE: ' + pageRef); // works

        //putting in the Account Plan as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('id',testAccPlan.id);

        // Problem picking up the parent account name
        SwotAnalysisController testController =  new SwotAnalysisController(new ApexPages.StandardController(testAccPlan));

        // We have the account plan set up, also have its related acc plan SWOT records set too.
        assertCreatedRecords('Experian', testController);

        testController.selectClientSWOTRecords();
        assertCreatedRecords('Client', testController);
        testController.selectExperianSWOTRecords();
        assertCreatedRecords('Experian', testController);

        // set currentRecId to a record value, then call the following methods:
        List<Account_Plan_SWOT__c> insertedRecords = [SELECT name, id, Type__c, Who__c FROM Account_Plan_SWOT__c WHERE Account_Plan__c =: testAccPlan.id];

        system.debug('ZZZZZZ' + insertedRecords.size());
        Account_Plan_SWOT__c singleRecord = insertedRecords[3]; // take a record at random
        testController.currentRecId = singleRecord.Id;


        testController.showCurrentAccPlanSWOTRecordPopup();
        testController.closeCurrentAccPlanSWOTRecordPopup();


        testController.currentRec = insertedRecords[6];
        testController.currentRec.Type__c = 'Client';
    testController.currentRec.Description__c = 'anything';
    testController.currentRec.Impact__c = 'anyImpact';
    testController.currentRec.Importance__c = '5';
    testController.updateCurrentAccPlanSWOTRecord();

        system.debug('ZZZZZZ' + insertedRecords.size()); // need to reselect the records before doing this to confirm 39.

        testController.closeCurrentAccPlanSWOTRecordPopup();
        testController.showCurrentAccPlanSWOTRecordPopup();
        testController.updateCurrentAccPlanSWOTRecord();
        testController.closeNewItemPopup();
        testController.showNewItemPopup();

        testController.newAccPlanSWOT.Type__c = 'Strength';
    testController.newAccPlanSWOT.Description__c = 'anything';
    testController.newAccPlanSWOT.Impact__c = 'anyImpact';
    testController.newAccPlanSWOT.Importance__c = '7';
    testController.saveNewAccPlanSWOTRecord();

        testController.newAccPlanSWOT.Type__c = 'Weakness';
    testController.newAccPlanSWOT.Description__c = 'anything';
    testController.newAccPlanSWOT.Impact__c = 'anyImpact';
    testController.newAccPlanSWOT.Importance__c = null;
        testController.saveNewAccPlanSWOTRecord();

        testController.newAccPlanSWOT.Type__c = 'Opportunity';
    testController.newAccPlanSWOT.Description__c = 'anything';
    testController.newAccPlanSWOT.Impact__c = 'anyImpact';
    testController.newAccPlanSWOT.Importance__c = '1';
        testController.saveNewAccPlanSWOTRecord();

        testController.newAccPlanSWOT.Type__c = 'Threat';
    testController.newAccPlanSWOT.Description__c = 'anything';
    testController.newAccPlanSWOT.Impact__c = 'anyImpact';
    testController.newAccPlanSWOT.Importance__c = '1';
        testController.saveNewAccPlanSWOTRecord();
        testController.saveNewAccPlanSWOTRecord();
        testController.selectExperianSWOTRecords();
        testController.deleteAccPlanSWOTRecord();
    }

    private static void assertCreatedRecords(String who, SwotAnalysisController testController)
    {
        // We have the account plan set up, also have its related acc plan SWOT records set too.
        for( Account_Plan_SWOT__c singleAccPlanSWOT : testController.strengthAccPlanSWOTs )
        {
            system.assert(singleAccPlanSWOT.Who__c== who);
            system.assert(singleAccPlanSWOT.Type__c=='Strength');
        }

        for( Account_Plan_SWOT__c singleAccPlanSWOT : testController.weaknessAccPlanSWOTs )
        {
            system.assert(singleAccPlanSWOT.Who__c== who);
            system.assert(singleAccPlanSWOT.Type__c=='Weakness');
        }

        for( Account_Plan_SWOT__c singleAccPlanSWOT : testController.opportunityAccPlanSWOTs )
        {
            system.assert(singleAccPlanSWOT.Who__c== who);
            system.assert(singleAccPlanSWOT.Type__c=='Opportunity');
        }

        for( Account_Plan_SWOT__c singleAccPlanSWOT : testController.threatAccPlanSWOTs )
        {
            system.assert(singleAccPlanSWOT.Who__c== who);
            system.assert(singleAccPlanSWOT.Type__c=='Threat');
        }
    }
}