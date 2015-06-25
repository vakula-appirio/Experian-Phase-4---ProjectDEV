/**====================================================================================
 * Experian plc
 * Name: CustomerPortal
 * Description: Case 8587 - Used by the Customer Portal to identify pipeline Opps
 * Created Date: 9th September 2014
 * Created By: James Weatherall
 * 
 * Date Modified        Modified By         Description of the update
 * Oct 22nd, 2014       James Weatherall    Changed the code to match the figures 
                                            in the reporting pipeline
 * Nov 13th, 2014       James Weatherall    Refactored the code to catch any instances
 *                                          where TCV is null. Improved error handling.
====================================================================================**/

global class CustomerPortal {
    
    webservice static Summary[] getPipelineSummary(Id accountId)
    {
      List<Account> lstAccounts = new List<Account>();
      Summary[] summaries = new Summary[]{};

      Set<String> setStages = new Set<String>();
      Map<String, Integer> mapTotalCount = new Map<String, Integer>();
      Map<String, Double> mapTotalAmount = new Map<String, Double>();
      
      String reportingName = '';
      String stage = '';
      Double amount = 0;
      Double conversionRate;
      
      // Get Reporting Name
      CustomerPortal cp = new CustomerPortal();  
      reportingName = cp.getReportingName(accountId);
        
      // Get all Accounts where the Reporting Name matches that of the selected Account
      for(Account accs : [SELECT Id FROM Account WHERE Reporting_Name__c =: reportingName])
      {
        lstAccounts.add(accs);
      }
        
      // Return Current Fiscal Year
      Integer currentFY = 0;
      currentFY = cp.getCurrentFY();
      
      // Identify Current Year
      Integer year = Integer.valueOf(system.today().year()) != currentFY ? currentFY - 1 : currentFY;
      // Start of Fiscal Year
      Date fiscalDate = Date.newInstance(year, 4, 1);
           
      try {
        if(lstAccounts.size() > 0) {          
          // Get the TCV for the Opps with No Product
          for(AggregateResult ar : [SELECT Opportunity.StageName stageName, COUNT_DISTINCT(Id) totalCount, SUM(Amount) totalAmount FROM Opportunity 
                              WHERE Opportunity_Products_Count__c = 0 AND AccountId IN: lstAccounts  
                              AND FISCAL_YEAR(Opportunity.CloseDate) =: currentFY AND Opportunity.IsClosed = false 
                              GROUP BY Opportunity.StageName])
                              {
                                stage = (String) ar.get('stageName');
                                // Determine whether TCV is null and set to 0
                                amount = (Double) ar.get('totalAmount') > 0 ? (Double) ar.get('totalAmount') : 0;

                                if(mapTotalCount.containsKey(stage))
                                {
                                  // Add Count
                                  Integer totalCount = mapTotalCount.get(stage) + (Integer) ar.get('totalCount');
                                  mapTotalCount.put(stage, totalCount);
                                  // Add Amount
                                  Double totalAmount = mapTotalAmount.get(stage) + amount;
                                  mapTotalAmount.put(stage, totalAmount);
                                } else {
                                  setStages.add(stage);
                                  mapTotalCount.put(stage, (Integer) ar.get('totalCount'));
                                  mapTotalAmount.put(stage, amount);
                                }
                              }
          
          // Get the TotalPrice for the Opps with Line Items with no Schedule 
          for(AggregateResult ar : [SELECT Opportunity.StageName stageName, COUNT_DISTINCT(OpportunityId) totalCount, SUM(TotalPrice) totalAmount FROM OpportunityLineItem 
                              WHERE Schedule_Established__c = false AND Opportunity.AccountId IN: lstAccounts  
                              AND FISCAL_YEAR(Opportunity.CloseDate) =: currentFY AND Opportunity.IsClosed = false 
                              GROUP BY Opportunity.StageName])
                              {
                                stage = (String) ar.get('stageName');
                                // Determine whether TCV is null and set to 0 
                                amount = (Double) ar.get('totalAmount') > 0 ? (Double) ar.get('totalAmount') : 0;

                                if(mapTotalCount.containsKey(stage))
                                {
                                  // Add Count
                                  Integer totalCount = mapTotalCount.get(stage) + (Integer) ar.get('totalCount');
                                  mapTotalCount.put(stage, totalCount);
                                  // Add Amount
                                  Double totalAmount = mapTotalAmount.get(stage) + amount;
                                  mapTotalAmount.put(stage, totalAmount);
                                } else {
                                  setStages.add(stage);
                                  mapTotalCount.put(stage, (Integer) ar.get('totalCount'));
                                  mapTotalAmount.put(stage, amount);
                                }
                                
                              }
          // Get the remaining Opportunities where Opp Lines with Schedules exist   
          for(AggregateResult ar : [SELECT OpportunityLineItem.Opportunity.StageName stageName, COUNT_DISTINCT(OpportunityLineItem.OpportunityId) totalCount, SUM(Revenue) totalAmount 
                              FROM OpportunityLineItemSchedule 
                              WHERE FISCAL_YEAR(ScheduleDate) =: currentFY 
                              AND OpportunityLineItem.Opportunity.CloseDate >: fiscalDate 
                              AND OpportunityLineItem.Opportunity.IsClosed = false 
                              AND OpportunityLineItem.Opportunity.AccountId IN: lstAccounts 
                              GROUP BY OpportunityLineItem.Opportunity.StageName])
                              {
                                stage = (String) ar.get('stageName');
                                // Determine whether TCV is null and set to 0 
                                amount = (Double) ar.get('totalAmount') > 0 ? (Double) ar.get('totalAmount') : 0;

                                if(mapTotalCount.containsKey(stage))
                                {
                                  // Add Count
                                  Integer totalCount = mapTotalCount.get(stage) + (Integer) ar.get('totalCount');
                                  mapTotalCount.put(stage, totalCount);
                                  // Add Amount
                                  Double totalAmount = mapTotalAmount.get(stage) + amount;
                                  mapTotalAmount.put(stage, totalAmount);
                                } else {
                                  setStages.add(stage);
                                  mapTotalCount.put(stage, (Integer) ar.get('totalCount'));
                                  mapTotalAmount.put(stage, amount);
                                }
                              }
                                               
          conversionRate = [SELECT ConversionRate FROM CurrencyType WHERE ISOCode = 'GBP' LIMIT 1].ConversionRate;
        }
        
        for(String s : setStages) {       
          summaries.add(new Summary(s, mapTotalCount.get(s), mapTotalAmount.get(s), conversionRate));
        }  
      } catch (Exception e) {
        System.debug('There was an error. Please contact your Support team and provide the following information.');
        System.debug('[CustomerPortal: getPipelineSummary] Exception: ' + e.getMessage());
        ApexLogHandler.createLogAndSave('CustomerPortal','getPipelineSummary', e.getStackTraceString(), e); 
      }
        
      return summaries;
    }
    
    webservice static CollaborationGroupFeed[] getChatterFeed(Id accountId) {
      CollaborationGroupFeed[] feed = new CollaborationGroupFeed[]{};
      String groupId = '';
      String reportingName = '';
      
      // Get Reporting Name
      CustomerPortal cp = new CustomerPortal();
      reportingName = cp.getReportingName(accountId);       
      
      for(Portal_Chatter_Group_Mappings__c cg : [SELECT Name, Chatter_Group_Id__c FROM Portal_Chatter_Group_Mappings__c WHERE Name =: cp.getReportingName(accountId)]) {
        groupId = cg.Chatter_Group_Id__c;
      }
      
      if(groupId != '')
      {
        // feed contains Feed posts and nested comments
        feed = [SELECT Id, Type, CreatedDate, CreatedBy.Name, Parent.Name, Body,
                (SELECT CommentBody, CreatedDate, CreatedBy.Name FROM FeedComments)
                FROM CollaborationGroupFeed
                WHERE ParentId =: groupId
                ORDER BY CreatedDate DESC, Id DESC];
      }        
      return feed;    
    }
    
    // wrapper class to hold aggregate data
    global class Summary {
        webservice String stageName { get; private set; }
        webservice Integer totalCount { get; private set; }
        webservice Double totalAmount { get; private set; }
        
        // Changed the Summary method to parse parameter values rather than AggregateResult
        public Summary(String stage, Integer tCount, Double tAmount, Double conRate) {
            stageName = stage;
            totalCount = tCount;
            totalAmount = tAmount * conRate;
        }
    }
    
    private String getReportingName(Id accountId) {
      String reportingName = [select Reporting_Name__c from Account where Id =: accountId].Reporting_Name__c;
        
      return reportingName;
    }
    
    private Integer getCurrentFY() {
      Organization orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                              FROM Organization
                              WHERE id=:Userinfo.getOrganizationId()];
        
      Date today = system.today();
      
      Integer currentFY;
      if (today.month() >= orgInfo.FiscalYearStartMonth) {
        if (orgInfo.UsesStartDateAsFiscalYearName) {
          currentFY = today.year();
        } else {
          currentFY = today.year() + 1;
        }
      } else {    
        if (orgInfo.UsesStartDateAsFiscalYearName) {
          currentFY = today.year() - 1;
        } else {
          currentFY = today.year();
        }
      }
      return currentFY;
    }   
}