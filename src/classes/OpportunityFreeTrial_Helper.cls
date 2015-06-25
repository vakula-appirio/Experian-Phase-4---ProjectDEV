/******************************************************************************
 * Appirio, Inc
 * Name: OpportunityFreeTrial_Helper.cls
 * Description: T-323154: Clone opportunity as Free Trial
 * Created Date: Sept 30th, 2014
 * Created By: Naresh Kr Ojha;l (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Oct 16th, 2014     Pallavi Sharma               T-326259(Free Trials: new fields & Logic)
 * Oct 29th, 2014     Nathalie Le Guay             Populating Free_Trial_Parent_Opportunity__c instead of Previous_Opportunity__c
 * Nov 2nd, 2014      Nathalie Le Guay             Commenting query of the Previous_Opportunity__c field so it doesn't get copied over
 * Nov 06th, 2014     Nathalie Le Guay             OLI Type__c will be set to "One-off.." instead of "Free Trial"
 * Jan 27th, 2015     Nathalie Le Guay             I-146698: Use OLI.List_Price__c instead of OLI.ListPrice
 * Mar 04th, 2015     Arpita Bose                  T-366690: Added SaaS__c, SaaS_Product_Code__c to map on OLI
 ******************************************************************************/
global class OpportunityFreeTrial_Helper {
  webservice static String createFreeTrialOppty(String opptyID) { 
    Opportunity oppty = [Select (Select Id, OpportunityId, SortOrder, PricebookEntryId, CurrencyIsoCode, Quantity, Discount, TotalPrice, 
                                 UnitPrice, /*ListPrice,*/ List_Price__c, ServiceDate, HasRevenueSchedule, HasQuantitySchedule, Description, HasSchedule, 
                                 Product_Type_of_Sale__c, Billing_Product__c, CRMOD_ID__c, Schedule_Established__c, DE_Product_Name__c,
                                 Revenue_Schedule_Amt_Per_Period__c, Revenue_Schedule_Num_of_Periods__c, Revenue_Schedule_Period_Type__c, 
                                 Type_of_Sale__c, End_Date__c, Finance_BU__c, Global_Business_Line__c, Opportunity_Country__c, Order_Item_ID_18__c, 
                                 Start_Date__c, Type__c,  Product_Billing_Product__c, CPQ_Quantity__c, EDQ_On_Demand_Product__c, 
                                 No_Update__c, EDQ_Margin__c, Renewal_EDQ_Margin__c, Renewal_Sale_Price__c, 
                                 Extended_Amount__c, Renewal_Extended_Amount__c, Partner_Amount__c, Renewal_Partner_Amount__c, Order_Type__c, 
                                 Program_Required__c, Data_Required__c, Manuals_Required__c, Delivery_Method__c, Program_Media__c, Data_Media__c, 
                                 Quantity_Type__c, Data_Usage__c, Product_Family__c, Hardware__c, Implementation__c, Compiler__c, Update_Frequency__c, 
                                 Renewals_Exclude__c, Manual_Registration__c, Renewal_Registration__c, Click_Expiry__c, No_Delivery__c, 
                                 Precise_Day_License__c , Operating_System__c, Part_Number__c, Renewal_Discount__c, 
                                 Discount_Amount__c, Renewal_Discount_Amount__c, Partner__c, Renewal_Partner__c, Item_Quantity__c, Users_From__c, 
                                 Users_To__c, Application__c, CRM_Product_Name__c, Product_Code__c, Product_Reference__c, Product_Data__c, 
                                 Product_Release_Name__c, Registration_Key__c, Release__c, Distribution_Notes__c, 
                                 Despatch_Status__c, Delivery_Time__c, Major_Version__c, CD_Name__c, Data_Installer_Password__c, Release_Reference__c, 
                                 Total_Royalty__c, Renewal_Total_Royalty__c, Item_Number__c, Quote_Number__c, eRenewal_Exception__c, Original_Asset_ID__c,
                                 SaaS__c, SaaS_Product_Code__c //T-366690
                                 From OpportunityLineItems),
                                 (Select Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, CurrencyIsoCode From OpportunityTeamMembers),
                                 (Select Id, OpportunityId, ContactId, Role, IsPrimary From OpportunityContactRoles),
                          o.ZAR_Conversion_Rate__c, o.Win_Back_Date__c, o.USD_Conversion_Rate__c, 
                          o.Type, o.Turn_Off_Contact_Role_Criteria_Check__c, o.TotalOpportunityQuantity, 
                          o.Tech_Support_Maintenance_Tiers__c, o.TWD_Conversion_Rate__c, o.TCV_GBP__c, 
                          o.SystemModstamp, o.Starting_Stage__c, o.Stage_prior_to_closed_lost_no_decision__c, 
                          o.Stage_Number__c, o.Stage_6_Duration__c, o.Stage_5_Duration__c, o.ForecastCategoryName,
                          o.Stage_4_Duration__c, o.Stage_3_Duration__c, o.Stage_3_Approver__c, o.StageName, 
                          o.Senior_Approver__c, o.SGD_Conversion_Rate__c, o.SEK_Conversion_Rate__c, 
                          o.Revenue_Type__c, o.RecordTypeId, o.Reached_Stage_7__c, o.Reached_Stage_6__c, 
                          o.Reached_Stage_5__c, o.Reached_Stage_4__c, o.Reached_Stage_3__c, o.External_Contract_ID__c,
                          o.RUB_Conversion_Rate__c, o.Proposal_Type__c, o.Product_Service_Tiers__c, 
                          o.Product_Group__c, o.Prod_Id__c, o.Probability, o.Primary_Winning_Competitor__c, 
                          o.Primary_Reason_W_L__c, o.Pricebook2Id, o.Previous_Order__c, o.Forecast_Category__c, 
                          /*o.Previous_Opportunity__c, */o.PO_Required__c, o.PO_Number__c, o.FiscalYear, o.FiscalQuarter,
                          o.PLN_Conversion_Rate__c, o.PCU__c, o.Owner_s_Sales_team__c, o.Owner_s_Region__c, 
                          o.Owner_s_Country__c, o.Owner_s_Business_Unit__c, o.Owner_s_Business_Line__c, 
                          o.Owner_Sales_Team_on_Opp_Close_Date__c, o.Owner_Sales_Sub_Team_on_Opp_Close_Date__c, 
                          o.Owner_Region_on_Opp_Close_Date__c, o.Owner_Office_Location__c, o.Fiscal, o.External_ID_Source__c,
                          o.Owner_Name_on_Opp_Close_Date__c, o.Owner_GBL_on_Opp_Close_Date__c, 
                          o.Owner_Country_on_Opp_Close_Date__c, o.Owner_BU_on_Opp_Close_Date__c, 
                          o.Owner_BL_on_Opp_Close_Date__c, o.OwnerId, o.Other_Closed_Reason__c, 
                          o.Other_Capability__c, o.Originating_Task_ID__c, o.Originating_Contact_Id__c, 
                          o.Option_To_Terminate__c, o.Option_To_Terminate_Date__c, 
                          o.Oppty_ID_18_chars__c, o.Opportunity_Status_Last_Modified__c, o.Opportunity_Products_Count__c, 
                          o.Opportunity_Name_PCU__c, o.Number_of_Times_Value_Reduced__c, o.ForecastCategory,
                          o.Number_of_Times_Stage_Moved_Backwards__c, o.Number_of_Times_Probability_Reduced__c, 
                          o.Number_of_Times_Close_Date_Moved_Back__c, 
                          o.NextStep, o.Name, o.NZD_Conversion_Rate__c, o.NOK_Conversion_Rate__c, o.LeadSource,
                          o.MYR_Conversion_Rate__c, o.Lost_to__c, o.Legacy_Opportunity_Status__c, o.Lead_Referrer_Email__c, 
                          o.Key_Deal__c, o.KRW_Conversion_Rate__c, o.JPY_Conversion_Rate__c, o.Is_There_Legal_Risk__c, 
                          o.Is_There_Financial_Risk__c, o.Is_There_Delivery_Risk__c, o.Is_There_Commercial_Risk__c, o.IsWon, 
                          o.IsSplit, o.IsInApproval__c, o.IsClosed, o.Invoice_to_End_User__c, o.Id, 
                          o.INR_Conversion_Rate__c, o.Has_There_Been_Significant_Change__c, o.Has_Stage_3_Approval__c, 
                          o.Has_Senior_Approval__c, o.Has_Complex_Product__c, o.HasOpportunityLineItem, o.HKD_Conversion_Rate__c, 
                          o.GBP_Conversion_Rate__c, o.Free_Trial_Parent_Opportunity__c, o.Forecast__c, 
                          o.Forecast_Category_on_Close__c, o.External_Account_ID__c, o.Experian_ID__c, o.ExpectedRevenue, 
                          o.EUR_Conversion_Rate__c, o.EEK_Conversion_Rate__c, o.Description, o.Delivery_Status__c, 
                          o.Delivery_Requirements__c, o.Delivery_Location__c, o.Delivery_Email_Alert__c, o.Delivery_Dates_Planned__c, 
                          o.Delivery_Country__c, o.Delivery_City__c, o.Delivery_Address_1__c, 
                          o.Days_in_Stage_6__c, o.Days_in_Stage_5__c, o.Days_in_Stage_4__c, o.Days_in_Stage_3__c, 
                          o.Days_To_Close__c, o.DKK_Conversion_Rate__c, o.DB_Competitor__c, 
                          o.CurrencyIsoCode, o.Creator_Managers_Email__c, o.Created_Date_2__c,
                          o.Count_of_Renewal_Products__c, o.Count_of_Products__c, o.Contract_Term__c, o.Contract_Start_Date__c, 
                          o.Contract_End_Date__c, o.Competitor_Count__c, o.Commit__c, o.Close_Date_Range__c, o.CloseDate, 
                          o.Channel_Type__c, o.Capability__c, o.CampaignId, o.CNY_Conversion_Rate__c, o.CHF_Conversion_Rate__c,
                           o.CAD_Conversion_Rate__c, o.Budget__c, o.BRL_Conversion_Rate__c, o.Annual_Contract_Value__c, 
                           o.Amount_PCU__c, o.Amount_Corp__c, o.Amount, o.AccountId, o.Accept_Account_is_Do_Not_Deal__c, 
                           o.AUD_Conversion_Rate__c
                        From Opportunity o WHERE ID =: opptyID];
    //Save point
    Savepoint sp = Database.setSavepoint();
    
    DescribeUtility du = new DescribeUtility('Opportunity');
    Opportunity newOppty = oppty.Clone(false, false, false, false);
      try {
        newOppty.Name = 'FT: ' + newOppty.Name; // Note the Test class has this hardcoded as well
        if (newOppty.Name.length() > 80) {
          newOppty.Name = newOppty.Name.substring(0, 80);
        }
        newOppty.Type = Constants.OPPTY_TYPE_FREE_TRIAL;
        newOppty.Contract_Start_Date__c = Date.today();
        newOppty.Contract_End_Date__c = Date.today();
        newOppty.RecordTypeId = du.recordTypeId_Map.get(Constants.OPPTY_TYPE_FREE_TRIAL);
        newOppty.Originating_Contact_Id__c = '';
        newOppty.Originating_Task_Id__c = '';
        newOppty.Prod_Id__c  = '';
        newOppty.StageName = Constants.OPPTY_STAGE_SETUP;
        newOppty.Free_Trial_Parent_Opportunity__c = oppty.Id;
        newOppty.Amount = 0.00;
        insert newOppty;
        
        OpportunityLineItem newOli;
        OpportunityContactRole newOcr;
        OpportunityTeamMember  newTeam;
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        List<OpportunityTeamMember> opptyTeamList = new List<OpportunityTeamMember>();
        
        //OpportunityLineItems.
        for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
            newOli = oli.Clone(false, false, false, false);
            newOli.Type__c = Constants.ORDER_LINE_ITEM_RENEWAL_ONE_OFF;
            newOli.Start_Date__c = Date.today();
            newOli.End_Date__c = Date.today();
            newOli.OpportunityId = newOppty.ID;
            newOli.TotalPrice = null;
            newOli.UnitPrice = 0.00;
            newOli.Order_Type__c = Constants.OPPTY_TYPE_FREE_TRIAL;
            oliList.add(newOli);
        }
        
        //OpportunityContactRoles.
        for (OpportunityContactRole ocr : oppty.OpportunityContactRoles) {
            newOcr = ocr.Clone(false, false, false, false);
          newOcr.OpportunityId = newOppty.ID;
          ocrList.add(newOcr);
        }
    
        //OpportunityTeamMember    
        for (OpportunityTeamMember team : oppty.OpportunityTeamMembers) {
          newTeam = team.Clone(false, false, false, false);
          newTeam.OpportunityId = newOppty.ID;
          opptyTeamList.add(newTeam);
        }
        
        insert oliList;
        insert ocrList;
        insert opptyTeamList;
    } catch (Exception e) {
        Database.rollback(sp);
      system.debug('[OpportunityFreeTrial_Helper: OpportunityFreeTrial_Helper] Exception: ' + e.getMessage());
      ApexLogHandler.createLogAndSave('OpportunityFreeTrial_Helper','OpportunityFreeTrial_Helper', e.getStackTraceString(), e);
    }
    return newOppty.ID;
  }
}