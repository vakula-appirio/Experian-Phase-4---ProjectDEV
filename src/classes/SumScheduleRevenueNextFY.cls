/**=====================================================================
 * Appirio, Inc
 * Name: SumScheduleRevenueNextFY
 * Description: The following batch class is designed to be scheduled to run once every nigth.
                    This class will get all Opportunity line items related to open opps and fill up the FY revenue for the next FY
 * Created Date: 5/6/2015
 * Created By: Diego Olarte (Experian)
 * 
 * Date Modified                Modified By                  Description of the update

 =====================================================================*/
global class SumScheduleRevenueNextFY implements Database.Batchable<sObject> {

  global Database.Querylocator start ( Database.BatchableContext bc ) {
  
    String query = 'select id, Next_FY_revenue_impact__c,NFY_SR_April__c,NFY_SR_May__c,NFY_SR_June__c,NFY_SR_July__c,NFY_SR_August__c,NFY_SR_September__c,NFY_SR_October__c,NFY_SR_November__c,NFY_SR_December__c,NFY_SR_January__c,NFY_SR_February__c,NFY_SR_March__c FROM OpportunityLineItem';
   
    return Database.getQueryLocator (query);
  }

  global void execute (Database.BatchableContext bc, List<OpportunityLineItem> scope) {

    Decimal totalRevNFY = 0;
    Decimal totalRevApr = 0;
    Decimal totalRevMay = 0;
    Decimal totalRevJun = 0;
    Decimal totalRevJul = 0;
    Decimal totalRevAug = 0;
    Decimal totalRevSep = 0;
    Decimal totalRevOct = 0;
    Decimal totalRevNov = 0;
    Decimal totalRevDec = 0;
    Decimal totalRevJan = 0;
    Decimal totalRevFeb = 0;
    Decimal totalRevMar = 0;
    Integer month = 0;
    
    List<OpportunityLineItem> oppLineItemtoUpdate = new List<OpportunityLineItem>();
    for(OpportunityLineItem oli:[select id, Next_FY_revenue_impact__c,NFY_SR_April__c,NFY_SR_May__c,NFY_SR_June__c,NFY_SR_July__c,NFY_SR_August__c,NFY_SR_September__c,NFY_SR_October__c,NFY_SR_November__c,NFY_SR_December__c,NFY_SR_January__c,NFY_SR_February__c,NFY_SR_March__c,(select id,Revenue,ScheduleDate,OpportunityLineItemId
                                from OpportunityLineItemSchedules where ScheduleDate = NEXT_FISCAL_YEAR) from OpportunityLineItem where id in :scope])
            {
                for(OpportunityLineItemSchedule olis : oli.OpportunityLineItemSchedules) 
                    {
                    totalRevNFY = totalRevNFY + olis.Revenue;
                    month = olis.ScheduleDate.month();                    
                        if (month == 4) {
                            totalRevApr = totalRevApr + olis.Revenue;
                        } else if (month == 5) {
                            totalRevMay = totalRevMay + olis.Revenue;
                        } else if (month == 6) {
                            totalRevJun = totalRevJun + olis.Revenue;
                        } else if (month == 7) {
                            totalRevJul = totalRevJul + olis.Revenue;
                        } else if (month == 8) {
                            totalRevAug = totalRevAug + olis.Revenue;
                        } else if (month == 9) {
                            totalRevSep = totalRevSep + olis.Revenue;
                        } else if (month == 10) {
                            totalRevOct = totalRevOct + olis.Revenue;
                        } else if (month == 11) {
                            totalRevNov = totalRevNov + olis.Revenue;
                        } else if (month == 12) {
                            totalRevDec = totalRevDec + olis.Revenue;
                        } else if (month == 1) {
                            totalRevJan = totalRevJan + olis.Revenue;
                        } else if (month == 2) {
                            totalRevFeb = totalRevFeb + olis.Revenue;
                        } else {
                            totalRevMar = totalRevMar + olis.Revenue;
                        }
                    }

                oli.Next_FY_revenue_impact__c = totalRevNFY;
                oli.NFY_SR_April__c = totalRevApr;
                oli.NFY_SR_May__c = totalRevMay;
                oli.NFY_SR_June__c = totalRevJun;
                oli.NFY_SR_July__c = totalRevJul;
                oli.NFY_SR_August__c = totalRevAug;
                oli.NFY_SR_September__c = totalRevSep;
                oli.NFY_SR_October__c = totalRevOct;
                oli.NFY_SR_November__c = totalRevNov;
                oli.NFY_SR_December__c = totalRevDec;
                oli.NFY_SR_January__c = totalRevJan;
                oli.NFY_SR_February__c = totalRevFeb;
                oli.NFY_SR_March__c = totalRevMar;
                
                oppLineItemtoUpdate.add(oli);
                
                totalRevNFY = 0;
                totalRevApr = 0;
                totalRevMay = 0;
                totalRevJun = 0;
                totalRevJul = 0;
                totalRevAug = 0;
                totalRevSep = 0;
                totalRevOct = 0;
                totalRevNov = 0;
                totalRevDec = 0;
                totalRevJan = 0;
                totalRevFeb = 0;
                totalRevMar = 0;
                month = 0;
            } 
  
      
      update oppLineItemtoUpdate;    
    }   

    //To process things after finishing batch
    global void finish (Database.BatchableContext bc) {
      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];
      
      System.debug('\n[SumScheduleRevenueNextFY: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

      }
    
}