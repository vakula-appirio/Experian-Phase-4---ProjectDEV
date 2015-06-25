/**=====================================================================
 * Appirio, Inc
 * Name: JointActionPlanExt_Test
 * Description: Apex test class for JointActionPlanExt controller
 *              Page is triggered by clicking button on the Opportunity Plan Record.
 *              Main features include
 *                  - Saving the Joint action plan records from single page
 *                  - Generating a PDF Document
 *                  - Sharing the PDF via Email
 * Created Date:
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 29th, 2015               Noopur                       T-356452: Improve code coverage
 * Jun 19th, 2015               Naresh                       T-405530: Improved code coverage
 =====================================================================*/
 @isTest
private class JointActionPlanExt_Test {

    private static testmethod void testJointAction(){
        Account account = Test_Utils.insertAccount();

        Opportunity opp = Test_Utils.insertOpportunity(account.id);

        Opportunity_Plan__c oppPlan = Test_Utils.insertOpportunityPlan(true,opp.Id);

        Opportunity_Plan_Joint_Action__c Jointap1 = new Opportunity_Plan_Joint_Action__c(Opportunity_Plan__c=oppPlan.Id,Description__c='Test',Type__c='Initial Discussions',Responsibility__c='Experian');
        Opportunity_Plan_Joint_Action__c Jointap2 = new Opportunity_Plan_Joint_Action__c(Opportunity_Plan__c=oppPlan.Id,Description__c='Test',Type__c='Needs Analysis',Responsibility__c='Experian');
        Opportunity_Plan_Joint_Action__c Jointap3 = new Opportunity_Plan_Joint_Action__c(Opportunity_Plan__c=oppPlan.Id,Description__c='Test',Type__c='Solution',Responsibility__c='Experian');
        Opportunity_Plan_Joint_Action__c Jointap4 = new Opportunity_Plan_Joint_Action__c(Opportunity_Plan__c=oppPlan.Id,Description__c='Test',Type__c='Fulfilment',Responsibility__c='Experian');
        List<Opportunity_Plan_Joint_Action__c> listJointap = new List<Opportunity_Plan_Joint_Action__c>{Jointap1,Jointap2,Jointap3,Jointap4};
        insert listJointap;

        PageReference pageRef = Page.JointActionPlan;
        Test.setCurrentPage(pageRef);

        // call the constructor and wrapper classes
        ApexPages.StandardController sc = new ApexPages.standardController(oppPlan);
        JointActionPlanExt jointap = new JointActionPlanExt(sc);
        //JoinActionPlanWrapper jActionPlan = joi
        jointap.toAddresses = 'nojha@testing.com';
        //List<Opportunity_Plan_Joint_Action__c> listJointap = [Select Id from Opportunity_Plan_Joint_Action__c Where Opportunity_Plan__c = :oppPlan.Id];
        System.assertNotEquals(jointap.jActionPlan.aPlans.size(),0);

        //Generate PDF
        /*PageReference PDFName = jointAp.generatePDF();
        System.AssertEquals(pdfName.getURL(),'/apex/jointactionplan_pdf?id='+oppPlan.Id);*/

        jointap.jActionPlan.aPlans[0].cType = 'Initial Discussions';
        jointap.jActionPlan.aPlans[0].initialDiscussion = 'Testing123';

        //Save Plans
        PageReference SavePlan = jointAp.saveActionPlans();
        System.AssertEquals(SavePlan.getURL(),'/'+oppPlan.Id);

        //Cancel button
        PageReference CancelPlan = jointAp.cancleAction();
        System.AssertEquals(CancelPlan.getURL(),'/'+oppPlan.Id);
        
        // generate PDF
        ApexPages.currentPage().getParameters().put('Id',oppPlan.Id);
        PageReference GeneratePDF = jointAp.generatePDF();
        System.AssertEquals(GeneratePDF.getURL(),'/apex/jointactionplan_pdf?id='+oppPlan.Id);
        List<Attachment> att = [SELECT Id FROM Attachment WHERE parentId = :oppPlan.Id];
        system.assert(att.size() > 0);
    }
}