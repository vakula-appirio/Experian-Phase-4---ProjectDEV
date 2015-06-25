/**=====================================================================
 * Appirio, Inc
 * Name: ContactOppRolesController_Test
 * Description: Test case for the component controller
 * 
 * @author Antenna (reused from Appirio's Asset "Contact Role Summarizer Related List"
 * Created Date: Feb 24th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Mar 05th, 2014       Arpita Bose(Appirio)         Fixed error and Added Constants in place of String.
 * Mar 14th, 2014       Arpita Bose(Appirio)         T-253906: Fixed error
 * May 21st, 2014       Nathalie Le Guay             Fix test class due to validation rule: Opportunity.Must_be_Stage_3_if_not_a_renewal
 =====================================================================*/
@isTest
private class ContactOppRolesController_Test {

    /**
        As functionality is trivial we are testing it all(positive+negative) in single test case 
    */
    static testMethod void testItAll() {
        //
        // Create SEED data
        //
				Global_Settings__c gSetting = new Global_Settings__c(Name = Constants.GLOBAL_SETTING, Opp_Stage_4_Name__c = Constants.OPPTY_STAGE_4);
				insert gSetting;
				
        Opportunity opp1 = new Opportunity(Name ='Opp1', CloseDate = System.today().addDays(10), StageName = Constants.OPPTY_STAGE_3);
        Opportunity opp2 = new Opportunity(Name ='Opp2', CloseDate = System.today().addDays(20), StageName = Constants.OPPTY_STAGE_3);
        insert new Opportunity[] {opp1, opp2};
        
        Contact anjan = new Contact(FirstName = 'Anjan', LastName = 'J');
        insert anjan;
        
        //
        // Negative Test : No contact roles in place either for Account or Opp, the code shouldn't crash
        //
        ContactOppRolesController cont = new ContactOppRolesController();
        cont.contactId = anjan.id;
                
        OpportunityContactRole[] oppRoles = cont.getOpportunityRoles();
        // Nothing should come back
        System.assert(oppRoles == null || oppRoles.isEmpty());
        
        //
        // Positive Tests : Lets create some roles for Opp, and then assert
        //
        
        OpportunityContactRole anjanOpp1Role = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = anjan.Id, 
                                                                    Role = 'Executive Sponsor', IsPrimary = true );
        OpportunityContactRole anjanOpp2Role = new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = anjan.Id, 
                                                                    Role = 'Decision Maker', IsPrimary = false );
        insert new OpportunityContactRole [] {anjanOpp1Role, anjanOpp2Role};
        
        // Create new instance of controller and test it all again
        cont = new ContactOppRolesController();
        cont.contactId = anjan.id;
        
        oppRoles = cont.getOpportunityRoles();
        // 2 opp roles should comeback
        System.assertEquals(2, oppRoles.size());
        
    }
}