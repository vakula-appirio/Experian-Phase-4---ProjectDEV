/**=====================================================================
 * Experian plc
 * Name: AccountValueAreasExt
 * 
 * Date Modified          Modified By               Description of the update
 * Aug 29, 2014           James Weatherall          Case #7198 Fix issue with Aggregate Sum returning values in Org default Currency
 =====================================================================*/

public class AccountValueAreasExt {

    public Account_Plan__c currentAccPlan {get; set;}
    public List<Account_Plan_Opportunity__c> listAPO {get;set;}
    public list<AggregateResult> result {get;set;}
    
    public AccountValueAreasExt(ApexPages.StandardController stdController) {
        Account_Plan__c ap = (Account_Plan__c)stdController.getRecord();
        for(Account_Plan__c accPlan : [Select CurrencyISOCode From Account_Plan__c Where Id = : ap.id]){
            currentAccPlan = accPlan;
        }
        
        // Case #7918: Get the conversion rate for Acc Plan currency to multiply against the aggregated Sum value
        Double conversionRate = [SELECT ConversionRate FROM CurrencyType WHERE ISOCode =: currentAccPlan.CurrencyISOCode LIMIT 1].ConversionRate;
        
        this.result = [Select Type__c, Sum(Current_Year_Revenue__c) cur, Sum(Year_1_Revenue__c) yr1, SUM(Year_2_Revenue__c) yr2
                       From Account_Plan_Opportunity__c 
                       Where Type__c != null and Account_Plan__c = :ap.Id Group By Type__c
                       ORDER BY Type__c ASC ];
        System.Debug('###'+result);
        listAPO = new List<Account_Plan_Opportunity__c>();
        for(AggregateResult ar: result){
            Account_Plan_Opportunity__c apo = new Account_Plan_Opportunity__c();
            apo.Type__c = String.ValueOf(ar.get('Type__c'));
            apo.Current_Year_Revenue__c = (Decimal)ar.get('cur');
            if (apo.Current_Year_Revenue__c != null) {
                apo.Current_Year_Revenue__c = apo.Current_Year_Revenue__c * conversionRate;
            }
            apo.Year_1_Revenue__c = (Decimal)ar.get('yr1');
            if (apo.Year_1_Revenue__c != null) {
                apo.Year_1_Revenue__c = apo.Year_1_Revenue__c * conversionRate;
            }
            apo.Year_2_Revenue__c = (Decimal)ar.get('yr2');
            if (apo.Year_2_Revenue__c != null) {
                apo.Year_2_Revenue__c = apo.Year_2_Revenue__c * conversionRate;
            }
            apo.CurrencyISOCode = currentAccPlan.CurrencyISOCode; //I-120524
            listAPO.add(apo);
            listAPO.sort(); //T-295627
        }
    	
        this.result = [Select Sum(Current_Year_Revenue__c) cur, Sum(Year_1_Revenue__c) yr1, SUM(Year_2_Revenue__c) yr2
    	               From Account_Plan_Opportunity__c 
    	               Where Type__c != null and Account_Plan__c = :ap.Id];
    	
    	for(AggregateResult ar: result){
    		Account_Plan_Opportunity__c apo = new Account_Plan_Opportunity__c();
    		apo.Type__c = 'Total';
    		apo.Current_Year_Revenue__c = (Decimal)ar.get('cur');
            if (apo.Current_Year_Revenue__c != null) {
            	apo.Current_Year_Revenue__c = apo.Current_Year_Revenue__c * conversionRate;  	   
            }
    		apo.Year_1_Revenue__c = (Decimal)ar.get('yr1');
            if (apo.Year_1_Revenue__c != null) {
                apo.Year_1_Revenue__c = apo.Year_1_Revenue__c * conversionRate;
            }
            apo.Year_2_Revenue__c = (Decimal)ar.get('yr2');
            if (apo.Year_2_Revenue__c != null) {
                apo.Year_2_Revenue__c = apo.Year_2_Revenue__c * conversionRate;
            }
    		apo.CurrencyISOCode = currentAccPlan.CurrencyISOCode; //I-120524
    		listAPO.add(apo);
    		listAPO.sort(); //T-295627
    	}
   	
    }
    
    
}