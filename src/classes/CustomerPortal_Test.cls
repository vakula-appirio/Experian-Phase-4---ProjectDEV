/**==============================================================================
 * Experian plc
 * Name: CustomerPortal_Test
 * Description: Case 8587 - Test class for Customer Portal webservice
 * Created Date: 17th September 2014
 * Created By: James Weatherall
 * 
 * Date Modified 		Modified By			Description of the update
 * 28 Oct, 2014			James Weatherall	Added code to test new version of Code
==============================================================================**/

@IsTest
public class CustomerPortal_Test {

    static testmethod void test_PipelineSummary() {
    	Id masterId;
        Id childId;
        Integer oppAmount = 10000; 
        
        Test.startTest();
        
        // Create Test Master Account
    	Account masterAccount = new Account();
        masterAccount = Test_Utils.insertAccount();	    
        masterId = masterAccount.Id;
        
        // Create Test Child Account
        Account childAccount = new Account();
        childAccount = Test_Utils.insertAccount();
        childId = childAccount.Id;
        
        // Update Parent of Child to be Master
        childAccount.ParentId = masterAccount.Id;
        update childAccount;
        
        // Create Test Opportunities linked to Master and Child Accounts
        Opportunity opp1 = Test_Utils.createOpportunity(masterId);
        Opportunity opp2 = Test_Utils.createOpportunity(childId);
        Opportunity opp3 = Test_Utils.createOpportunity(childId);
        
        opp1.Amount = oppAmount;
        opp1.Type = Constants.OPPTY_TYPE_FREE_TRIAL;
        opp2.Amount = oppAmount;
        opp2.Type = Constants.OPPTY_NEW_FROM_NEW;
        opp3.Amount = oppAmount;
        opp3.Type = Constants.OPPTY_TYPE_RENEWAL;
        
        List<Opportunity> lstOppsToInsert = new List<Opportunity>();
        lstOppsToInsert.add(opp1);
        lstOppsToInsert.add(opp2);
        lstOppsToInsert.add(opp3);
        insert lstOppsToInsert;
        
        // Create associated records
        Product2 prod = Test_Utils.insertProduct();
        prod.CanUseRevenueSchedule = true;
        update prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry = Test_Utils.insertPricebookEntry(prod.Id, pricebookId, Constants.CURRENCY_USD);
		
		List<OpportunityLineItem> lstOLIs = new List<OpportunityLineItem>(); 
		lstOLIs.add(Test_Utils.createOpportunityLineItem(lstOppsToInsert[0].Id, priceBookEntry.Id, lstOppsToInsert[0].Type));
		lstOLIs.add(Test_Utils.createOpportunityLineItem(lstOppsToInsert[1].Id, priceBookEntry.Id, lstOppsToInsert[1].Type));
		insert lstOLIs;
		
		OpportunityLineItem oli = lstOLIs[0];
		OpportunityLineItemSchedule olis = Test_Utils.insertOpportunityLineItemSchedule(oli.Id);

		System.debug('opp1.Probability = ' + opp1.Probability);
        System.debug('opp1.Amount = ' + opp1.Amount);
        System.debug('opp1.CurrencyIsoCode = ' + opp1.CurrencyIsoCode);
        
        System.debug('oli.TotalPrice = ' + oli.TotalPrice);
		        
        Test.stopTest();
        
        CustomerPortal.Summary[] results = CustomerPortal.getPipelineSummary(masterId);
        System.Debug('results.size() = ' + results.size());
        
        Double totalAmount = 0;
        for(CustomerPortal.Summary ar : results)
        {
          System.Debug('ar ' + ar.stageName + ' ' + ar.totalCount + ' ' + ar.totalAmount); 
          System.assertEquals(Constants.OPPTY_STAGE_3, ar.stageName);
          totalAmount += ar.totalAmount;
        }
        // As the TCV is being returned in GBP need to multiply by Conversion rate to get correct total amount
        Double conversionRate = [SELECT ConversionRate FROM CurrencyType WHERE ISOCode = 'GBP' LIMIT 1].ConversionRate;
        System.debug('conversionRate = ' + conversionRate);
		//System.assertEquals(totalAmount, 20000 * conversionRate);        
    }
}