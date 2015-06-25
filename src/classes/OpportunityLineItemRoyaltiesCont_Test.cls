/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityLineItemRoyaltiesController_Test
 * Description: Test case for the OpportunityLineItemRoyaltiesController: T-313541
 * 
 * Created Date: August 28th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Aug 28, 2014         Nathalie Le Guay             Created
 * Sep 05, 2014         Arpita Bose(Appirio)         T-315815: Updated method testItAll() to fix the failure
 * Nov 12th, 2014       Arpita Bose                  Added Type in test data of Opportunity and OLI
 =====================================================================*/
@isTest(seealldata=false)
private class OpportunityLineItemRoyaltiesCont_Test {

    /*
        As functionality is trivial we are testing it all(positive+negative) in single test case 
    */
    @isTest
    static void testItAll() {
        // Create data
        Account acc = Test_Utils.createAccount();
        acc.Name ='testAcc';
        insert acc;
        Opportunity oppty = new Opportunity(Name = 'Opp1', CloseDate = date.today().addDays(10),    
                                                StageName = Constants.OPPTY_STAGE_3, AccountId = acc.ID,    
                                                CurrencyIsoCode = Constants.CURRENCY_USD, Type = 'New From New');
        insert oppty;
        
        Product2 product = new Product2(Name = '_test_Prod1');
        product.Global_Business_Line__c = 'Credit Services';
        insert product;
        
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
    
        OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(oppty.Id, stdPricebookEntry.Id, oppty.Type);
        opptyLineItem.Item_Number__c='1234';
        insert opptyLineItem;
        
        // Negative Test : No Royalty in place either for OLI
        OpportunityLineItemRoyaltiesController cont = new OpportunityLineItemRoyaltiesController(
                                                            new ApexPages.StandardController(new OpportunityLineItem(Id=opptyLineItem.id)));
        System.assert(cont.royalties == null || cont.royalties.isEmpty());
        
        
        // Positive Tests : Lets create some Royalty records        
        Royalty__c royalty1 = new Royalty__c(Name = 'test royalty #1', Line_Item_Reference_Number__c='1234');
        insert royalty1;
        Royalty__c royalty2 = new Royalty__c(Name = 'test royalty #1', Line_Item_Reference_Number__c='1234');
        insert royalty2;
        
        // Create new instance of controller and test it all again
        cont = new OpportunityLineItemRoyaltiesController(new ApexPages.StandardController(new OpportunityLineItem(Id=opptyLineItem.id)));
        cont.oliId = opptyLineItem.id;

        // 2 royalties should come back
        System.assertEquals(2, cont.royalties.size());
    }
}