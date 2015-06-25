/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanTriggerHandler
 * Description: T-282464
 * Created Date: May 29th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 11th, 2014               Arpita Bose(Appirio)         I-120524: Added synchCurrencyISOCodes() in afterUpdate
 * Oct 16, 2014                 Sonal Shrivastava (Appirio)  T-325950: update Opportunity query in createAccountPlanOpps()
 * Mar 6th, 2015                Tyaga Pati                   Case #00552946 Retrive Revenue by Year from Opty Lines to Populate Opty    
 =====================================================================*/
public with sharing class AccountPlanTriggerHandler {
  
  //After insert 
  public static void afterInsert(List<Account_Plan__c> newList) {
    createAccountPlanOpps(newList);
  }
  
  //After update
  public static void afterUpdate(Map<Id, Account_Plan__c> newAPlanMap, Map<Id, Account_Plan__c> oldAPlanMap){
    synchCurrencyISOCodes(newAPlanMap.values(), oldAPlanMap); //I-120524    
  }
  
  //T-282464: Create Account Plan Opportunity records.
  private static void createAccountPlanOpps (List<Account_Plan__c> newList) {
    //declare Vars for Tyaga Pati
    DateTime CurrentDate = DateTime.now();
    Integer CurrentYear;
    if((CurrentDate.Month())<4)
        {
          CurrentYear =  CurrentDate.year()-1;
        }
    else 
        {    
          CurrentYear = CurrentDate.year();
        }
    Integer Year1 = CurrentYear +1;
    Integer Year2= CurrentYear + 2;
    Integer MonthSt = 4;
    Integer DateSt = 1;

    //All the Start and End Dates for the three fiscals
    Date Fiscalst1 = date.newinstance(CurrentYear, MonthSt, DateSt);
    Date FiscalEnd1_temp = Fiscalst1.addMonths(12);
    Date FiscalEnd1 = FiscalEnd1_temp.addDays(-1);
    Date FiscalSt2 = date.newinstance(Year1, MonthSt, DateSt);
    Date FiscalEnd2_temp = FiscalSt2.addMonths(12);
    Date FiscalEnd2 = FiscalEnd2_temp.addDays(-1);
    Date FiscalSt3 = date.newinstance(Year2, MonthSt, DateSt);
    Date FiscalEnd3_temp = FiscalSt3.addMonths(12);
    Date FiscalEnd3 = FiscalEnd3_temp.addDays(-1);
    //Declaration for all the variables to hold the currency information.
      
    Decimal RevCurrYear = 0; 
    Decimal RevYear1 = 0; 
    Decimal RevYear2 = 0;
    //End of Vars
    
    Set<ID> accountIDs = new Set<ID>();
    Map<ID, List<Opportunity>> accID_OpptyListMap = new Map<ID, List<Opportunity>>();
    //Declare Map to hold Opty ID vs Current Year and Yar1 and Year2 Revenues
    //Map<ID, Map<String, Integer>> OptyRevenueByYear = new Map<ID, Map<String, Integer>>();
    Map<ID, List<OpportunityLineItem>> OptyLineItemMap = new Map<Id, List<OpportunityLineItem>>();
    Map<ID, Map<Integer, Decimal>> OptyRevenueByYear = new Map<ID, Map<Integer, Decimal>>();
    Map<ID, List<OpportunityLineItemSchedule>> OptyLineItemSchedlMap = new Map<Id, List<OpportunityLineItemSchedule>>();
    
    List<Account_Plan_Opportunity__c> accPlanOpptyList = new List<Account_Plan_Opportunity__c>();
    //Loop through Account plans
    for (Account_Plan__c ap : newList) {
        if (ap.Account__c != null) {
            accountIDs.add(ap.Account__c);
        }
    }
    //Fetching related opportunities
    for (Opportunity oppty : [SELECT ID, Name, Contract_Start_Date__c, Contract_End_Date__c, Amount, StageName, CloseDate, AccountId FROM Opportunity WHERE (IsWon = true OR isClosed = false) AND AccountId IN: accountIDs AND Contract_End_Date__c > TODAY]) {
        if (!accID_OpptyListMap.containsKey(oppty.AccountID)) {
            accID_OpptyListMap.put(oppty.AccountID, new List<Opportunity>());
        }
        accID_OpptyListMap.get(oppty.AccountID).add(oppty);
    }
    
    Set<Opportunity > OptyList = New Set<Opportunity >();
    for(List<Opportunity> OppLsti:accID_OpptyListMap.Values()){
           for(Opportunity oppi:OppLsti){
                   OptyList.add(oppi);
           }
    }
    
    //Fetching Related OptyLineItems
    for(OpportunityLineItem Optyline:[Select ID, Name, OpportunityID FROM OpportunityLineItem WHERE OpportunityID IN: OptyList]){
          if (!OptyLineItemMap.containsKey(Optyline.OpportunityID)) {
                OptyLineItemMap.put(Optyline.OpportunityID, new List<OpportunityLineItem>());
             }
                OptyLineItemMap.get(Optyline.OpportunityID).add(Optyline);
       }
    
    Set<OpportunityLineItem> OptyLineList = New Set<OpportunityLineItem>();
    for(List<OpportunityLineItem> OppLineItemLsti:OptyLineItemMap.Values()){
        for(OpportunityLineItem opplni:OppLineItemLsti){
            OptyLineList.add(opplni);
            }
       }
    
    //Fetching Related OptyLineRevenue Schedules
    for(OpportunityLineItemSchedule OptyRevSchedl:[Select OpportunityLineItemId, Id, Revenue, ScheduleDate FROM OpportunityLineItemSchedule 
                                                    WHERE OpportunityLineItemId IN:OptyLineList]){
          if (!OptyLineItemSchedlMap.containsKey(OptyRevSchedl.OpportunityLineItemId)) {
                OptyLineItemSchedlMap.put(OptyRevSchedl.OpportunityLineItemId,new List<OpportunityLineItemSchedule>());
             }
             OptyLineItemSchedlMap.get(OptyRevSchedl.OpportunityLineItemId).add(OptyRevSchedl);
        }

    Set<ID> OptyLineRevList = New Set<ID>();
    for(List<OpportunityLineItemSchedule> OppLnItemRevLsti:OptyLineItemSchedlMap.Values()){
        for(OpportunityLineItemSchedule oppRevSchi:OppLnItemRevLsti){
            OptyLineRevList.add(oppRevSchi.Id);
        }
      }

    //Building Map for holding all the Revenue Lines
    
    for (Opportunity Opty1 : OptyList){       
        for (OpportunityLineItem oppLineItem :OptyLineList){
                if(!(oppLineItem.OpportunityID == Opty1.Id))
                    {Continue;} 
                    List<OpportunityLineItemSchedule> Schedule1 = OptyLineItemSchedlMap.get(oppLineItem.Id);
                    if(Schedule1 ==null) {Continue;}
                         for(OpportunityLineItemSchedule OptyRevSchedl1:Schedule1 ){  
                                Integer year = OptyRevSchedl1.ScheduleDate.year();
                                
                                     //if (Year == CurrentYear)
                                     if(OptyRevSchedl1.ScheduleDate >= Fiscalst1 && OptyRevSchedl1.ScheduleDate <= FiscalEnd1)
                                        { 
                                            RevCurrYear+= OptyRevSchedl1.Revenue;   
                                            System.debug('Tyaga I am here '+OptyRevSchedl1.Revenue+'Total: ' +RevCurrYear);
                                            System.debug('Tyaga I am here222 The date is '+OptyRevSchedl1.ScheduleDate +'Total: ' +RevCurrYear);                                                         
                                        }
                                     //if (Year == Year1)
                                      if(OptyRevSchedl1.ScheduleDate >= Fiscalst2 && OptyRevSchedl1.ScheduleDate <= FiscalEnd2) 
                                        {
                                            RevYear1+=OptyRevSchedl1.Revenue;
                        
                                        }   
                                     //if (Year == Year2)
                                      if(OptyRevSchedl1.ScheduleDate >= Fiscalst3 && OptyRevSchedl1.ScheduleDate <= FiscalEnd3)
                                        {
                                            RevYear2+=OptyRevSchedl1.Revenue;
                                        }
                            }//End of Iteration for Revnue Lines for the Opty Line Item

                }//End if Iteration for Opty Lines for Opty
                    
                if (!OptyRevenueByYear.containsKey(Opty1.Id)) {
                        Map<Integer,Decimal> YearByRevmap = New Map<Integer,Decimal>();
                        YearByRevmap.put(CurrentYear,RevCurrYear);
                        YearByRevmap.put(Year1,RevYear1);
                        YearByRevmap.put(Year2,RevYear2);
                        OptyRevenueByYear.Put(Opty1.Id,YearByRevmap);   
                        RevCurrYear = 0;
                        RevYear1 = 0;
                        RevYear2 = 0;
                           
                    }
                else
                    {
                        Map<Integer,Decimal> YearByRevmap = OptyRevenueByYear.get(Opty1.Id);
                        YearByRevmap.put(CurrentYear,RevCurrYear);
                        YearByRevmap.put(Year1,RevYear1);
                        YearByRevmap.put(Year2,RevYear2);
                        OptyRevenueByYear.put(Opty1.Id,YearByRevmap );
                        RevCurrYear = 0;
                        RevYear1 = 0;
                        RevYear2 = 0;
                    }
    }///End of Iteration for all Optys.

    Account_Plan_Opportunity__c accPlanOppty;
    //Creating new account plan opportunity records
    for (Account_Plan__c ap : newList) {
        if (accID_OpptyListMap.containsKey(ap.Account__c)) {
            for (Opportunity opp : accID_OpptyListMap.get(ap.Account__c)) {
                Integer monthDiff = 1;
                accPlanOppty = new Account_Plan_Opportunity__c();
                accPlanOppty.Opportunity__c = opp.ID;
                accPlanOppty.Opportunity_Name__c = opp.Name;
                accPlanOppty.Account_Plan__c = ap.ID;
                
                //if(OptyRevenueByYear.containskey(opp.Id)){
                    //system.debug('Tyaga I am here for opty id:'+ opp.Id );
                    Map<Integer,Decimal> RevenueByYear = OptyRevenueByYear.get(opp.Id);
                    accPlanOppty.Current_Year_Revenue__c = RevenueByYear.get(CurrentYear);
                    accPlanOppty.Year_1_Revenue__c = RevenueByYear.get(Year1);
                    accPlanOppty.Year_2_Revenue__c = RevenueByYear.get(Year2);
               // }
                
                
                if (opp.Contract_Start_Date__c != null && opp.Contract_End_Date__c != null) {
                  monthDiff = (opp.Contract_Start_Date__c.monthsBetween(opp.Contract_End_Date__c));
                }
                
          if(opp.Amount == null) {
            accPlanOppty.Annualised_Revenue__c = 0;
          } else {
                  accPlanOppty.Annualised_Revenue__c = opp.Amount / (monthDiff < 1 ? 1 : monthDiff)*12;
          }
                accPlanOppty.Sales_Stage__c = opp.StageName;
                if (opp.CloseDate != null) {
                    accPlanOppty.Close_Date__c = opp.CloseDate;
                }
                accPlanOppty.TCV__c = opp.Amount;
                
                accPlanOpptyList.add(accPlanOppty);
                
            }
        }
    }
    //insert accPlanOpptyList
    if (accPlanOpptyList.size() > 0) {
        insert accPlanOpptyList;
    }
  }
  
  //I-120524: Currency should be same between related objects - Account plan
  private static void synchCurrencyISOCodes (List<Account_Plan__c> newAPlan, Map<ID, Account_Plan__c> oldAPlanMap){
    Set<ID> aPlanIDs = new Set<ID>();
    
    List<Account_Plan_Competitor__c> aPCompetitor = new List<Account_Plan_Competitor__c>();
    List<Account_Plan_Contact__c> aPContact = new List<Account_Plan_Contact__c>();
    List<Account_Plan_Critical_Success_Factor__c> aPCsfactor = new List<Account_Plan_Critical_Success_Factor__c>();
    List<Account_Plan_Opportunity__c> aPOppty = new List<Account_Plan_Opportunity__c>();
    List<Account_Plan_Parent_Opportunities__c> aPParentOppty = new List<Account_Plan_Parent_Opportunities__c>();
    List<Account_Plan_Penetration__c> aPPenetratn = new List<Account_Plan_Penetration__c>();
    List<Account_Plan_SWOT__c> aPSwot = new List<Account_Plan_SWOT__c>();
    List<Account_Plan_Team__c> aPlanTeam = new List<Account_Plan_Team__c>();
    
    Account_Plan_Competitor__c apCompeObj;
    Account_Plan_Contact__c apContObj;
    Account_Plan_Critical_Success_Factor__c apCSFactorObj;
    Account_Plan_Opportunity__c apOppObj;
    Account_Plan_Parent_Opportunities__c apParentOppObj;
    Account_Plan_Penetration__c apPeneObj;
    Account_Plan_SWOT__c apSwotObj;
    Account_Plan_Team__c apTeamObj;
    
    for(Account_Plan__c ap : newAPlan){
        if(oldAPlanMap != null && oldAPlanMap.get(ap.Id).CurrencyIsoCode == ap.CurrencyIsoCode) {
        continue;
      }
      aPlanIDs.add(ap.ID);
    }
    
    //Iterating through all acc plan got updated for currency iso code    
    if (aPlanIDs.size() > 0) {
      for (Account_Plan__c ap : [SELECT Id, CurrencyIsoCode, (SELECT Id, CurrencyIsoCode From Account_Plan_Competitors__r), 
                                 (Select Id, CurrencyIsoCode From Account_Plan_Contacts__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_Critical_Success_Factors__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_Opportunity__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_Parent_Opportunities__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_Penetrations__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_SWOT__r),
                                 (Select Id, CurrencyIsoCode From Account_Plan_Teams__r)
                                 From Account_Plan__c 
                                 WHERE ID IN: aPlanIDs]) {
                                    
        //New Currency ISO Code for account plan competitor
        for (Account_Plan_Competitor__c apCompe : ap.Account_Plan_Competitors__r) {
          apCompeObj = new Account_Plan_Competitor__c(ID = apCompe.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPCompetitor.add(apCompeObj);
        }
        //New Currency Iso code for Account Plan Contact
        for (Account_Plan_Contact__c apCon : ap.Account_Plan_Contacts__r) {
          apContObj = new Account_Plan_Contact__c(ID = apCon.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPContact.add(apContObj);
        }
        //New Currency Iso code for Account Plan Critical Success Factor
        for (Account_Plan_Critical_Success_Factor__c apCsf : ap.Account_Plan_Critical_Success_Factors__r) {
          apCSFactorObj = new Account_Plan_Critical_Success_Factor__c(ID = apCsf.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPCsfactor.add(apCSFactorObj);
        }
        //New Currency Iso code for Account Plan Opportunity
        for (Account_Plan_Opportunity__c apOpp : ap.Account_Plan_Opportunity__r) {
          apOppObj = new Account_Plan_Opportunity__c(ID = apOpp.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPOppty.add(apOppObj);
        }
        //New Currency Iso code for Account Plan Opportunity
        for (Account_Plan_Parent_Opportunities__c apParentOpp : ap.Account_Plan_Parent_Opportunities__r) {
          apParentOppObj = new Account_Plan_Parent_Opportunities__c(ID = apParentOpp.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPParentOppty.add(apParentOppObj);
        }
        //New Currency Iso code for Account Plan Opportunity
        for (Account_Plan_Penetration__c apPen : ap.Account_Plan_Penetrations__r) {
          apPeneObj = new Account_Plan_Penetration__c(ID = apPen.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPPenetratn.add(apPeneObj);
        }
        //New Currency Iso code for Account Plan Opportunity
        for (Account_Plan_SWOT__c apSw : ap.Account_Plan_SWOT__r) {
          apSwotObj = new Account_Plan_SWOT__c(ID = apSw.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPSwot.add(apSwotObj);
        }
        //New Currency Iso code for Account Plan Opportunity
        for (Account_Plan_Team__c apTeam : ap.Account_Plan_Teams__r) {
          apTeamObj = new Account_Plan_Team__c(ID = apTeam.ID, CurrencyISOCode = ap.CurrencyIsoCode);
          aPlanTeam.add(apTeamObj);
        }

      }
      try {
        //Update currency on related objects
        if (aPCompetitor.size() > 0) {
          update aPCompetitor;
        }
        if (aPContact.size() > 0) {
          update aPContact;
        }
        if (aPCsfactor.size() > 0) {
          update aPCsfactor;
        }
        if (aPOppty.size() > 0) {
          update aPOppty;
        }
        if (aPParentOppty.size() > 0) {
          update aPParentOppty;
        }
        if (aPPenetratn.size() > 0) {
          update aPPenetratn;
        }
        if (aPSwot.size() > 0) {
          update aPSwot;
        }
        if (aPlanTeam.size() > 0) {
          update aPlanTeam;
        }
      } catch (Dmlexception ex) {
        System.debug('[OrderTriggerHandler:synchCurrencyISOCodes]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('OrderTriggerHandler','synchCurrencyISOCodes', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newAPlan.get(0).addError(ex.getDmlMessage(i));
        }
      }
      
      
     

    }
    
    
  }
}