/**=====================================================================
 * Appirio, Inc
 * Name: SumScheduleRevenueCFYandNFY
 * Description: The following batch class is designed to be scheduled to run once every nigth.
                    This class will get all Opportunity line items related to open opps and fill up the FY revenue
 * Created Date: 6/2/2015
 * Created By: Diego Olarte (Experian)
 * 
 * Date Modified                Modified By                  Description of the update

 =====================================================================*/
global class SumScheduleRevenueCFYandNFY implements Database.Batchable<sObject> {

  global Database.Querylocator start ( Database.BatchableContext bc ) {
  
    String query = 'select id, Current_FY_revenue_impact__c,Next_FY_revenue_impact__c, CFY_SR_April__c,CFY_SR_May__c,CFY_SR_June__c,CFY_SR_July__c,CFY_SR_August__c,CFY_SR_September__c,CFY_SR_October__c,CFY_SR_November__c,CFY_SR_December__c,CFY_SR_January__c,CFY_SR_February__c,CFY_SR_March__c,NFY_SR_April__c,NFY_SR_May__c,NFY_SR_June__c,NFY_SR_July__c,NFY_SR_August__c,NFY_SR_September__c,NFY_SR_October__c,NFY_SR_November__c,NFY_SR_December__c,NFY_SR_January__c,NFY_SR_February__c,NFY_SR_March__c FROM Opportunity';
   
    return Database.getQueryLocator (query);
  }

  global void execute (Database.BatchableContext bc, List<Opportunity> scope) {

    Decimal totalRevCFYApr = 0;
    Decimal totalRevCFYMay = 0;
    Decimal totalRevCFYJun = 0;
    Decimal totalRevCFYJul = 0;
    Decimal totalRevCFYAug = 0;
    Decimal totalRevCFYSep = 0;
    Decimal totalRevCFYOct = 0;
    Decimal totalRevCFYNov = 0;
    Decimal totalRevCFYDec = 0;
    Decimal totalRevCFYJan = 0;
    Decimal totalRevCFYFeb = 0;
    Decimal totalRevCFYMar = 0;
    
    Decimal totalRevNFYApr = 0;
    Decimal totalRevNFYMay = 0;
    Decimal totalRevNFYJun = 0;
    Decimal totalRevNFYJul = 0;
    Decimal totalRevNFYAug = 0;
    Decimal totalRevNFYSep = 0;
    Decimal totalRevNFYOct = 0;
    Decimal totalRevNFYNov = 0;
    Decimal totalRevNFYDec = 0;
    Decimal totalRevNFYJan = 0;
    Decimal totalRevNFYFeb = 0;
    Decimal totalRevNFYMar = 0;
    
    List<Opportunity> oppToUpdate = new List<Opportunity>();
    for(Opportunity opp:[select id,CFY_SR_April__c,CFY_SR_May__c,CFY_SR_June__c,CFY_SR_July__c,CFY_SR_August__c,CFY_SR_September__c,CFY_SR_October__c,CFY_SR_November__c,CFY_SR_December__c,CFY_SR_January__c,CFY_SR_February__c,CFY_SR_March__c,NFY_SR_April__c,NFY_SR_May__c,NFY_SR_June__c,NFY_SR_July__c,NFY_SR_August__c,NFY_SR_September__c,NFY_SR_October__c,NFY_SR_November__c,NFY_SR_December__c,NFY_SR_January__c,NFY_SR_February__c,NFY_SR_March__c,(select id,CFY_SR_April__c,CFY_SR_May__c,CFY_SR_June__c,CFY_SR_July__c,CFY_SR_August__c,CFY_SR_September__c,CFY_SR_October__c,CFY_SR_November__c,CFY_SR_December__c,CFY_SR_January__c,CFY_SR_February__c,CFY_SR_March__c,NFY_SR_April__c,NFY_SR_May__c,NFY_SR_June__c,NFY_SR_July__c,NFY_SR_August__c,NFY_SR_September__c,NFY_SR_October__c,NFY_SR_November__c,NFY_SR_December__c,NFY_SR_January__c,NFY_SR_February__c,NFY_SR_March__c from OpportunityLineItems) from Opportunity where id in :scope])
            {
                for(OpportunityLineItem oli : opp.OpportunityLineItems) 
                    {
                    
                    totalRevCFYApr = totalRevCFYApr + oli.CFY_SR_April__c;
                    totalRevCFYMay = totalRevCFYMay + oli.CFY_SR_May__c;
                    totalRevCFYJun = totalRevCFYJun + oli.CFY_SR_June__c;
                    totalRevCFYJul = totalRevCFYJul + oli.CFY_SR_July__c;
                    totalRevCFYAug = totalRevCFYAug + oli.CFY_SR_August__c;
                    totalRevCFYSep = totalRevCFYSep + oli.CFY_SR_September__c;
                    totalRevCFYOct = totalRevCFYOct + oli.CFY_SR_October__c;
                    totalRevCFYNov = totalRevCFYNov + oli.CFY_SR_November__c;
                    totalRevCFYDec = totalRevCFYDec + oli.CFY_SR_December__c;
                    totalRevCFYJan = totalRevCFYJan + oli.CFY_SR_January__c;
                    totalRevCFYFeb = totalRevCFYFeb + oli.CFY_SR_February__c;
                    totalRevCFYMar = totalRevCFYMar + oli.CFY_SR_March__c;
                    
                    totalRevNFYApr = totalRevNFYApr + oli.NFY_SR_April__c;
                    totalRevNFYMay = totalRevNFYMay + oli.NFY_SR_May__c;
                    totalRevNFYJun = totalRevNFYJun + oli.NFY_SR_June__c;
                    totalRevNFYJul = totalRevNFYJul + oli.NFY_SR_July__c;
                    totalRevNFYAug = totalRevNFYAug + oli.NFY_SR_August__c;
                    totalRevNFYSep = totalRevNFYSep + oli.NFY_SR_September__c;
                    totalRevNFYOct = totalRevNFYOct + oli.NFY_SR_October__c;
                    totalRevNFYNov = totalRevNFYNov + oli.NFY_SR_November__c;
                    totalRevNFYDec = totalRevNFYDec + oli.NFY_SR_December__c;
                    totalRevNFYJan = totalRevNFYJan + oli.NFY_SR_January__c;
                    totalRevNFYFeb = totalRevNFYFeb + oli.NFY_SR_February__c;
                    totalRevNFYMar = totalRevNFYMar + oli.NFY_SR_March__c;
                    }

                opp.CFY_SR_April__c = totalRevCFYApr;
                opp.CFY_SR_May__c = totalRevCFYMay;
                opp.CFY_SR_June__c = totalRevCFYJun;
                opp.CFY_SR_July__c = totalRevCFYJul;
                opp.CFY_SR_August__c = totalRevCFYAug;
                opp.CFY_SR_September__c = totalRevCFYSep;
                opp.CFY_SR_October__c = totalRevCFYOct;
                opp.CFY_SR_November__c = totalRevCFYNov;
                opp.CFY_SR_December__c = totalRevCFYDec;
                opp.CFY_SR_January__c = totalRevCFYJan;
                opp.CFY_SR_February__c = totalRevCFYFeb;
                opp.CFY_SR_March__c = totalRevCFYMar;
                
                opp.NFY_SR_April__c = totalRevNFYApr;
                opp.NFY_SR_May__c = totalRevNFYMay;
                opp.NFY_SR_June__c = totalRevNFYJun;
                opp.NFY_SR_July__c = totalRevNFYJul;
                opp.NFY_SR_August__c = totalRevNFYAug;
                opp.NFY_SR_September__c = totalRevNFYSep;
                opp.NFY_SR_October__c = totalRevNFYOct;
                opp.NFY_SR_November__c = totalRevNFYNov;
                opp.NFY_SR_December__c = totalRevNFYDec;
                opp.NFY_SR_January__c = totalRevNFYJan;
                opp.NFY_SR_February__c = totalRevNFYFeb;
                opp.NFY_SR_March__c = totalRevNFYMar;
                
                oppToUpdate.add(opp);
                
                totalRevCFYApr = 0;
                totalRevCFYMay = 0;
                totalRevCFYJun = 0;
                totalRevCFYJul = 0;
                totalRevCFYAug = 0;
                totalRevCFYSep = 0;
                totalRevCFYOct = 0;
                totalRevCFYNov = 0;
                totalRevCFYDec = 0;
                totalRevCFYJan = 0;
                totalRevCFYFeb = 0;
                totalRevCFYMar = 0;

                totalRevNFYApr = 0;
                totalRevNFYMay = 0;
                totalRevNFYJun = 0;
                totalRevNFYJul = 0;
                totalRevNFYAug = 0;
                totalRevNFYSep = 0;
                totalRevNFYOct = 0;
                totalRevNFYNov = 0;
                totalRevNFYDec = 0;
                totalRevNFYJan = 0;
                totalRevNFYFeb = 0;
                totalRevNFYMar = 0;
                
            } 
  
      
      update oppToUpdate;
          
    }   

    //To process things after finishing batch
    global void finish (Database.BatchableContext bc) {
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];
      
      System.debug('\n[SumScheduleRevenueCFYandNFY: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

      }
    
}