/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger_OrderHelper
 * Description: T-264797: Refactoring of OpportunityTriggerHelper class
 *              The following methods were moved from OpportunityTriggerHelper:
 *                - createOrderAndOrderLineItems
 *                - getContactRoleForOppties
 *                - deleteExistingOrders
 *                - createOrders
 *                - createOrder
 *                - populateOrderDetails
 *                - createOrderLines
 *                - createRevenueSchedules
 *                - deleteOrderAndOppIfOppIsReopened
 *              FOR HISTORY, REFER TO OpportunityTriggerHandler.cls
 * Created Date: Mar 26th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified          Modified By               Description of the update
 * Mar 28, 2014           Nathalie Le Guay          Changed to 'without sharing'
 * Apr 01st, 2014          Naresh kr Ojha            T-266919: Added record type ID from describe call 
                                                    (update createOrderAndOrderLineItems() method)
 * Apr 01st, 2014         Arpita Bose(Appirio)      T-268402: Replaced reference to Opp's Service Start/End Dates with Opp's Contract Start/End Dates
 * Apr 02nd, 2014         Arpita Bose               T-268405: Renamed OLI's Service Start/end dates to Start/End dates
 * Apr 02nd, 2014         Arpita Bose               T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 07th, 2014         Nathalie Le Guay          Update to Order LI.Renewable__c as it becomes a picklist
 * Apr 08th, 2014         Arpita Bose               T-269372: Added addError() in try-catch block
 * Apr 08th, 2014         Naresh Kr Ojha            T-269235: populate Order.Original_Order_Value__c when Order activated
 * Apr 08th, 2014         Nathalie Le Guay          Order LI.Renewable__c renamed to Type__c
 * Apr 09th, 2014         Nathalie Le Guay          T-270470: update createRevenueSchedules(): Order Revenue Schedules RT = 'Read Only'
 * Apr 10th, 2014         Nathalie Le Guay          Change oppLineItem.Renewable__c from checkbox to Type__c (picklist)
 * Apr 24, 2014           Nathalie Le Guay          Removing reference to Business_Unit__c & Global_Line_of_Business__c (old BU Relationship logic)
 * May 01, 2014           Arpita Bose               Updated catch(Exception) to catch(DMLException) to use getDMLException
 * Aug 18th, 2014         Arpita Bose               T-313163: Updated method createOrderLines()so that the Order_Line_Item__c.CPQ_Quantity__c == OpportunityLineItem.CPQ_Quantity__c
 * Sep 08th, 2014         Naresh Kr Ojha            T-317883: EDQ Order Line Margin Visibility: Trigger on Opp when Close/Won, 
                                                    Up    dated methods populateOpptyVsLineMapAndOpptyLineList(), createOrderLines()
 * Sep 29th, 2014         Arpita Bose               T-322945: EDQ Field Mapping: Updated method createOrder(), createOrderLines() and populateOpptyVsLineMapAndOpptyLineList()                                                   
 * Oct 13th,14th 2014     Arpita Bose               T-324899 : Populate the Order__c.Partner__c field for EDQ : Updated method createOrder() and createOrders()
 * Oct 16, 2014           Nathalie                  I-135168: Adding new fields to OLI->OrderLineItem mapping
 * Oct 17th, 2014         Arpita Bose               T-326349: updated createOrderLines() to populate Order_Type__c
 * Oct 17th, 2014         Pallavi                   T-326540: Refactoring: Improve Opp Trigger
 * Oct 20th, 2014         Tyaga Pati                Case#00010129: Added Finance BU Name and Product Finance BU to Opp object retrival and addition to the New Order lines.
 * Oct 22nd, 2014         Arpita Bose               I-135696 : removed Mappings of Data__c, Progs__c and Manuals__c
 * Oct 22nd, 2014         Naresh Kr Ojha            T-327046: updated method deleteOrderAndOppIfOppIsReopened() to delete Account plan and orders 
 * Oct 23rd, 2014         James Weatherall          Case #8566: added Reporting Sales Team into createOrder method
 * Oct 29th, 2014         Nathalie Le Guay          I-136891: remove check of BU when stamping fields from OLI to Order Line Item
 * Nov 06th, 2014         Nathalie Le Guay          T-331964: populating Parent_Item_Number__c from the Order Line Item to the Asset in createOrderLines()
 * Jan 27th, 2015         Nathalie Le Guay          I-146698: Use OLI.List_Price__c instead of OLI.ListPrice
 * Jan 28th, 2015         Nathalie Le Guay          I-146888: Replace OLI.Discount with OLI.CPQ_Discount__c
 * Feb 6th, 2015          Gaurav Kumar Chadha       T-359571: updated method createOrderLines to copy SaaS__c from OpportunityLineItem to Order_Line_Item__c
 * Feb 17th, 2015         James Weatherall          Case #7603: update CreateOrder to map FYR__c and SYR__c fields
 * Feb 23rd, 2015         Naresh kr Ojha            T-364911: Mapping of SaaS_Product_Code__c to Order Line Item. 
 * Mar 5th, 2015          Paul Kissick              Case #583351 : Added fix at start of createOrderAndOrderLineItems to always check for isExecuted, ignoring the test state.
 * May 12th, 2015         Terri Kellough            I-162285: modified CreateOrder and createOrderLines to map CSDA specific opportunity and line fields to the order
 * May 14th, 2015         Terri Kellough            I-162285: modified populateOpptyVsLineMapAndOpptyLineList to add CSDA specific fields to oli query
 =====================================================================*/
public without sharing class OpportunityTrigger_OrderHelper {

  public static String orderReadOnlyRT_ID;
  public static String orderLineReadOnlyRT_ID;
  public static String orderScheduleRT_Id;

  public static Boolean isExecuted = false;
  public static List<OpportunityLineItem> opptyLineList;
  public static Map<ID, List<OpportunityLineItem>> opptyID_OpptyLinesMap;
  
  //============================================================================================
  // Create orders and its line items when Opportunity goes close won.
  //============================================================================================
  public static void createOrderAndOrderLineItems (Map<ID, Opportunity> newMap, 
                                                      Map<ID, Opportunity> oldMap) {
      // PK: Case #583351 - 5/3/15 - Replacing this line as it caused doubling up of queries when testing...
      // if (isExecuted && !Test.isRunningTest()) {
      if (isExecuted) {
        return;
      }
      isExecuted = true;

      Map<ID, Order__c> opptyID_order = new Map<ID, Order__c>();
      Map<ID, Order__c> orderId_OrderMap = new Map<ID, Order__c>();
      Map<ID, Order_Line_Item__c> optyLineId_orderLineItemMap = new Map<ID, Order_Line_Item__c>();
      // List<Asset> assetListToInsert = new List<Asset>();
      

      //Populating Opportunities to get latest value of closed and won fields.
      Map<ID, Opportunity> opportunityID_OpptyMap = new Map<ID, Opportunity>();
      for (Opportunity oppty : [SELECT ID, isWon, isClosed, StageName FROM Opportunity WHERE ID IN : newMap.keySet()]) {
        opportunityID_OpptyMap.put(oppty.ID, oppty);
      }
      System.debug('\n[OpportunityTrigger_OrderHelper: createOrderAndOrderLineItems] opportunityID_OpptyMap: '+ opportunityID_OpptyMap);
      List<Opportunity> oppList = new List<Opportunity>();
      Set<String> opptyIDs = new Set<String>();

      Map<ID, OpportunityContactRole> opptyId_ContactRoleMap = new Map<ID, OpportunityContactRole>();
      for (Opportunity oppty : newMap.values()) {
        if (oppty.isClosed == true && oppty.isWon == true &&
                                      oldMap.get(oppty.ID).isWon != true) {
          opptyIDs.add(oppty.ID);
        }
      }      
      
      //Pallavi Sharma @ Oct 17th 2014 - NLG Uncomment on same day (breaks Order creation)
      //Refactoring Code for improvement
      //No Need to check Primary Contact Role here
      //Already validated on before update on validateOpptyContactRoleOnClosedWon method
      if (opptyIDs.size() > 0) {
        opptyId_ContactRoleMap = getContactRoleForOppties (opptyIDs);
      } else { // Added NLG March 5th, 2014 - Return if no Opp qualifies
         return;
      }
      
      //Process closed won opportunities only for order creation
      for (Opportunity oppty : newMap.values()) {
      
        System.debug('\n[OpportunityTrigger_OrderHelper: createOrderAndOrderLineItems] is closed: '+ oppty.StageName + ' & isWon  : '+ oldMap.get(oppty.ID).StageName);
        
        if (oppty.isClosed == true && oppty.isWon == true && 
                                      oldMap.get(oppty.ID).isWon != true) {
          System.debug('\n[OpportunityTrigger_OrderHelper: createOrderAndOrderLineItems] oppty: '+ oppty.StageName );
          //if (opptyId_ContactRoleMap.containsKey(oppty.ID)) {
            oppList.add(oppty);
          //} else {
          //  oppty.addError (Label.Opp_Needs_Primary_Contact);
          //  return;
          //}
        }
      }
      //End Changes by Pallavi Sharma @ Oct 17th 2014
      
      // Prior to create any order, we want to delete existing Orders, if any  
      deleteExistingOrders(oppList);
      
      orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
      orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
      orderScheduleRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER_REVENUE_SCHEDULE, Constants.READ_ONLY);
      
      populateOpptyVsLineMapAndOpptyLineList(oppList);

      //Calling method to create orders for each closed won opportunity
      if (opptyId_ContactRoleMap.size() > 0) {
        opptyID_order = createOrders (oppList, opptyId_ContactRoleMap);
      }
      try {
        if (opptyID_order.size() > 0) {
          insert opptyID_order.values();
          populateOrderDetails(orderId_OrderMap, opptyID_order);
        }
      } catch (DMLException e) {
        System.debug('[OpportunityTrigger_OrderHelper: createOrderAndOrderLineItems]: ['+e.getMessage()+']]');
        for (Integer i=0; i < e.getNumDml(); i++) {
         newMap.values().get(0).addError('\nCould not create the Order. Please contact your admin.' + e.getDMLMessage(i));
        }
        return;
      }

      //Creating order lines.
      if (opptyID_order.size() > 0) {
        optyLineId_orderLineItemMap = createOrderLines(oppList, opptyID_order);
      }
      
      //Creating revenue schedule for Order Lines
      //Feb 17th, 2014       Jinesh Goyal (Appirio)  added the null pointer check
      if (optyLineId_orderLineItemMap != null && optyLineId_orderLineItemMap.size() > 0) {
        createRevenueSchedules(optyLineId_orderLineItemMap);
      }      
      //Creating Assets for Order Lines
      /*if (orderId_OrderMap.size() > 0) {
        assetListToInsert = generateAssets (orderId_OrderMap.values());
        if (!assetListToInsert.isEmpty()) {
          insert assetListToInsert;
        }
      }*/
  }
  
  //===========================================================================
  // To populate oppty and line map and opptyline list.
  //Oct 20, 2014 Tyaga Pati Case#00010129: Added Finance BU Name and Product Finance BU
  //===========================================================================  
  public static void populateOpptyVsLineMapAndOpptyLineList (List<Opportunity> oppList) {
    if (oppList.size() > 0) {
      opptyLineList = new List<OpportunityLineItem>();
      opptyID_OpptyLinesMap = new Map<ID, List<OpportunityLineItem>>();
      for (OpportunityLineItem oli : [SELECT ID, Billing_Product__c, PricebookEntry.Product2Id, Start_Date__c, CPQ_Discount__c, Description, 
                                              Quantity, UnitPrice, Type_of_Sale__c, OpportunityId, End_Date__c, /*ListPrice,*/ List_Price__c,
                                              PricebookEntry.Product2.Name, CurrencyIsoCode ,Type__c, CPQ_Quantity__c,
                                              EDQ_Margin__c, Renewal_EDQ_Margin__c, EDQ_On_Demand_Product__c, // T-322945:EDQ specific fields are added
                                              No_Update__c, Renewal_Sale_Price__c,
                                              Extended_Amount__c, Renewal_Extended_Amount__c, Partner_Amount__c,
                                              Renewal_Partner_Amount__c, Order_Type__c, Program_Required__c, Opportunity_Country__c,
                                              Data_Required__c, Manuals_Required__c, Delivery_Method__c, Program_Media__c,
                                              Data_Media__c, Quantity_Type__c, Data_Usage__c, Product_Family__c, Hardware__c,
                                              Implementation__c, Compiler__c, Update_Frequency__c, Renewals_Exclude__c,
                                              Manual_Registration__c, Renewal_Registration__c, Click_Expiry__c, 
                                              No_Delivery__c, Precise_Day_License__c, //On_Demand__c,  Removed ths field from the object
                                              Operating_System__c, Part_Number__c, Renewal_Discount__c, Discount_Amount__c,
                                              Renewal_Discount_Amount__c, Partner__c, Renewal_Partner__c, 
                                              Item_Quantity__c, Users_From__c, Users_To__c, Application__c,
                                              CRM_Product_Name__c, Product_Code__c, Product_Reference__c, Product_Data__c,
                                              Product_Release_Name__c, Registration_Key__c, //Manuals__c,
                                              Release__c, Distribution_Notes__c, Despatch_Status__c, Delivery_Time__c,
                                              Major_Version__c, CD_Name__c, Data_Installer_Password__c, Release_Reference__c,
                                              Total_Royalty__c, Renewal_Total_Royalty__c, Item_Number__c, Quote_Number__c,
                                              eRenewal_Exception__c, Original_Asset_ID__c, Product_Upgrade__c, //Data__c, Progs__c,
                                              Price_Category__c, Media_Quantity__c, Renewal_List_Price__c, Parent_Item_Number__c,
                                              Product_Finance_BU__c, Finance_BU_Name__c, SaaS__c, SaaS_Product_Code__c
                                              //, Product_Finance_BU__c, Finance_BU_Name__c
                                              ,Adj_Amount__c, Adj_Percentage__c, AE_Discount__c, Annual_Sales_Price__c, Auto_Quote__c,
                                              Bill_Plan_Product_Name__c, Bundle_Discount_Category__c, Bundle_Discount_Name__c,
                                              CSDA_Estimated_Annual_Volume__c, CSDA_List_Price__c, CSDA_Product_Group__c, CSDA_Product_Org__c,
                                              CSDA_Product_Suite__c, CSDA_Unit_Type__c, Escalate__c, Final_Price__c, Manager_Discount__c,
                                              Manual_Adj_Amount__c, Manual_Discount__c, Manual_Price_Override__c, Maximum_Price__c,
                                              Max_Volume__c, Minimum_Price__c, Min_Volume__c, Original_Price__c, Plan__c, Quotable__c,
                                              Quote_Sheet_Type__c, Requested_Adjustment_Amount__c, Requested_Unit_Price__c, SA_Discount__c
                                      FROM OpportunityLineItem 
                                      WHERE OpportunityID IN: oppList]) {
        opptyLineList.add(oli);
        if (!opptyID_OpptyLinesMap.containsKey(oli.OpportunityID)) {
          opptyID_OpptyLinesMap.put(oli.OpportunityID, new List<OpportunityLineItem>());
        }
        opptyID_OpptyLinesMap.get(oli.OpportunityID).add(oli);
      }
    }
    System.debug('[**opptyID_OpptyLinesMap**]'+opptyID_OpptyLinesMap);
  }
  
  //Commented code by Pallavi Sharma @ Oct 17th 2014 - uncommented by NLG
  //============================================================================================
  // Get OpportunityContactRole record for the opportunities
  //============================================================================================
  private static Map<ID, OpportunityContactRole> getContactRoleForOppties (Set<String> opptyIDs) {
      Map<ID, OpportunityContactRole> opptyId_ContRoleMap = new Map<ID, OpportunityContactRole>();
        
    for (OpportunityContactRole contactRole : [SELECT IsPrimary, Id, ContactId, 
                                                        OpportunityId 
                                               FROM OpportunityContactRole 
                                               WHERE OpportunityId IN: opptyIDs]) {
        if (!opptyId_ContRoleMap.containsKey(contactRole.OpportunityId) && 
              contactRole.IsPrimary == true && contactRole.ContactId <> null) {
        opptyId_ContRoleMap.put(contactRole.OpportunityId, contactRole);
      }
      
    }

    return opptyId_ContRoleMap;
  }
  //End Changes Pallavi Shasma @ Oct 17 2014
  
  //============================================================================================
  // Deletes orders related to given opportunities.
  //============================================================================================
  private static void deleteExistingOrders(List<Opportunity> opps) {
    // Order Revenue Schedule has master detail with Order Line Item
    // Order Line Item has master detail with Order
    // If ASSETS ARE CREATED at any time, we will have to delete them separately as they can't
    // support master detail
    List<Order__c> existingOrders = new List<Order__c>();
    List<Order_Split__c> orderSplits = new List<Order_Split__c>();
    
    for (Order__c ord : [SELECT Id, (Select Id From Order_Splits__r) 
                                     FROM Order__c
                                     WHERE Opportunity__c IN: opps]) {
      existingOrders.add(ord);
      for (Order_Split__c split : ord.Order_Splits__r) {
        orderSplits.add(split);
      }
    }
    
    try {
      if (orderSplits.size() > 0) {
        delete orderSplits;
      }
      
      if (existingOrders.size() > 0) {
        delete existingOrders;
      }
    } catch (DMLException e) {
      for (Integer i=0; i < e.getNumDml(); i++) {
        opps.get(0).addError('\nCannot proceed as we encountered an error deleting existing Orders. Please contact an admin.' +e.getDMLMessage(i));
      }
    }
  }

  //=========================================================================
  //To create orders from closed won Opportunities(passed as parameter)
  //=========================================================================
  public static Map<ID, Order__c> createOrders (List<Opportunity> opptyList,
                      Map<ID, OpportunityContactRole> opptyId_ContactRoleMap) {

    Map<ID, Order__c> opptyID_newOrder = new Map<ID, Order__c>();
    Map<String, String> oppId_AccIdMap = new Map<String, String>();
    
    //T-324899
    for (OpportunityPartner oppPrtnr : [SELECT AccountToId, OpportunityId
                                        FROM OpportunityPartner 
                                        WHERE OpportunityId IN :opptyList AND IsPrimary =: true]) {
      oppId_AccIdMap.put(oppPrtnr.OpportunityId, oppPrtnr.AccountToId);
    }
      
    for (Opportunity oppty : opptyList) {
      if (opptyID_OpptyLinesMap.size() < 1) {
        continue;
      }
      //Putting newOrder to map for further processing and inserts
      opptyID_newOrder.put(oppty.ID, createOrder (oppty, opptyId_ContactRoleMap.get(oppty.ID).ContactId, oppId_AccIdMap));
    }

    return opptyID_newOrder;
  }

  //==========================================================================
  //To create individual order from passed opportunity
  //==========================================================================
  public static Order__c createOrder (Opportunity oppty, ID opptyContact, 
                                        Map<String, String> oppId_AccIdMap) {
    String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId()); //T-322945: EDQ specific

    Order__c newOrder = new Order__c();
    newOrder.Name                   = 'Order: '+oppty.Name;
    if (newOrder.Name.length() > 80) {
      newOrder.Name = newOrder.Name.substring(0, 80);
    }
    //newOrder.Original_Order_Value__c
    Double originalOrderValue = 0;

    System.debug('[OpportunityTrigger_OrderHelper][***opptyID_OpptyLinesMap**]' + opptyID_OpptyLinesMap.size());
    System.debug('[OpportunityTrigger_OrderHelper][***oppty.ID**]' + oppty.ID);
    for (OpportunityLineItem oli : opptyID_OpptyLinesMap.get(oppty.ID)) {
      originalOrderValue = originalOrderValue + (oli.UnitPrice * oli.Quantity);
    }

    newOrder.Original_Order_Value__c = originalOrderValue;
    newOrder.CurrencyIsoCode        = oppty.CurrencyIsoCode;
    newOrder.Account__c             = oppty.AccountId;
    //newOrder.Business_Unit__c       = oppty.Business_Unit__c;
    newOrder.Campaign__c            = oppty.CampaignId;
    //newOrder.Global_Line_of_Business__c = oppty.Global_Line_of_Business__c;
    newOrder.Opportunity__c         = oppty.ID;
    newOrder.Contract_Start_Date__c = oppty.Contract_Start_Date__c;
    newOrder.Contract_End_Date__c   = oppty.Contract_End_Date__c;
    newOrder.Contact__c             = opptyContact;
    newOrder.Type__c                = oppty.Type;
    newOrder.Locked__c              = true;
    newOrder.RecordTypeId           = orderReadOnlyRT_ID;
    newOrder.OwnerId                = oppty.OwnerId;
    newOrder.Reporting_Sales_Team__c = oppty.Reporting_Sales_Team__c;  // JW - Case #8566
    newOrder.Invoice_to_End_User__c = oppty.Invoice_to_End_User__c; // NLG - I-135699
    newOrder.FYR__c                 = oppty.FYR__c; // JW - Case 7603
    newOrder.SYR__c                 = oppty.SYR__c; // JW - Case 7603
    newOrder.Quote_Active__c               = oppty.Quote_Active__c; //TTK I-162285 
    newOrder.Quote_Bill_Plan_Code__c       = oppty.Quote_Bill_Plan_Code__c; //TTK I-162285 
    newOrder.Quote_Close_Date__c           = oppty.Quote_Close_Date__c; //TTK I-162285 
    newOrder.Quote_Created_Date__c         = oppty.Quote_Created_Date__c; //TTK I-162285 
    newOrder.Quote_Effective_As_Of__c      = oppty.Quote_Effective_As_Of__c; //TTK I-162285 
    newOrder.Quote_Effective_Through__c    = oppty.Quote_Effective_Through__c; //TTK I-162285 
    newOrder.Quote_Last_Modified_Date__c   = oppty.Quote_Last_Modified_Date__c; //TTK I-162285 
    newOrder.Quote_Number__c               = oppty.Quote_Number__c; //TTK I-162285 
    newOrder.Quote_Primary__c              = oppty.Quote_Primary__c; //TTK I-162285 
    newOrder.Quote_Revision__c             = oppty.Quote_Revision__c; //TTK I-162285 
    newOrder.Quote_Status__c               = oppty.Quote_Status__c; //TTK I-162285 
    newOrder.Quote_Type__c                 = oppty.Quote_Type__c; //TTK I-162285 
    newOrder.Requested_Bill_Plan__c        = oppty.Requested_Bill_Plan__c; //TTK I-162285 
    newOrder.Suggested_Bill_Plan__c        = oppty.Suggested_Bill_Plan__c; //TTK I-162285 
    newOrder.CSDA_Annual_Contract_Value__c = oppty.CSDA_Annual_Contract_Value__c; //TTK I-162285 
    newOrder.Quote_Created_by__c           = oppty.Quote_Created_by__c; //TTK I-162285 

    //As per T-269796
    if (oppty.Option_To_Terminate_Date__c != null) {
      newOrder.Option_To_Terminate_Date__c = oppty.Option_To_Terminate_Date__c;
    }
    //T-324899
    Id accId;
    if (oppId_AccIdMap.containsKey(oppty.Id)) {
      accId = oppId_AccIdMap.get(oppty.Id);
    }   

    //As per T-322945 : EDQ Specific code
    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ)) {
      newOrder.PO_Required__c       = oppty.PO_Required__c;
      newOrder.PO_Number__c         = oppty.PO_Number__c;
      newOrder.Partner__c           = accId; //T-324899
    }
      
    return newOrder;
  }

  //============================================================================================
  //Populate Order details on maps provided
  //============================================================================================
  private static void populateOrderDetails (Map<ID, Order__c> orderId_OrderMap, 
                                                  Map<ID, Order__c> opptyID_order) {
    for (Order__c ord : [SELECT o.RecordTypeId, o.OwnerId, o.Opportunity__c, 
                                o.Id, o.Account__c,
                                o.Contract_Start_Date__c, o.Contract_Number__c, 
                                o.Contract_End_Date__c, o.Contact__c, o.Close_Date__c, 
                                o.Cancellation_Date__c, o.Campaign__c //, o.Business_Unit__c, o.Global_Line_of_Business__c
                        FROM Order__c o 
                        WHERE ID IN: opptyID_order.values()]) {
      //Populating orderId and Order map
      if (!orderId_OrderMap.containsKey(ord.ID)) {
        orderId_OrderMap.put(ord.ID, ord);
      }
      //Populating opptyId and order map
      if (ord.Opportunity__c <> null && !opptyID_order.containsKey(ord.Opportunity__c)) {
        opptyID_order.put(ord.Opportunity__c, ord);
      }
    }
  }

  //============================================================================================
  //To create order lines for closed won Opportunities (Passed as parameter)
  //============================================================================================
  public static Map<ID, Order_Line_Item__c> createOrderLines (List<Opportunity> oppList,
                                         Map<ID, Order__c> opptyID_order) {
    List<Order_Line_Item__c> orderLineItemList = new List<Order_Line_Item__c>();
    Map<ID, Order_Line_Item__c> oliId_ordLIMap = new Map<ID, Order_Line_Item__c>(); 
    Order_Line_Item__c ordLine;

    try {
      //Fetching opportunityLineItems
      /*for (OpportunityLineItem oli : [SELECT ID, Billing_Product__c, PricebookEntry.Product2Id, Start_Date__c,
                                               Quantity, UnitPrice, Type_of_Sale__c, OpportunityId, End_Date__c, 
                                               PricebookEntry.Product2.Name, CurrencyIsoCode ,Renewable__c
                                        FROM OpportunityLineItem 
                                        WHERE OpportunityID IN: oppList]) {*/
        for (OpportunityLineItem oli : opptyLineList) { 
          if (opptyID_order.containsKey(oli.OpportunityId) == true) {
            ordLine = new Order_Line_Item__c();
  
            if (oli.Billing_Product__c <> null) {
              ordLine.Billing_Product__c = oli.Billing_Product__c;
            }
            //ordLine.Cancellation_Date__c
            ordLine.Order__c                = opptyID_order.get(oli.OpportunityId).ID;
            ordLine.CurrencyIsoCode         = oli.CurrencyIsoCode;
            ordLine.Product__c              = oli.PricebookEntry.Product2Id;
            ordLine.Quantity__c             = oli.Quantity;
            ordLine.Type_of_Sale__c         = oli.Type_of_Sale__c;
            ordLine.Opportunity_Line_Item_Id__c = oli.ID;
            ordLine.Start_Date__c           = oli.Start_Date__c;
            ordLine.End_Date__c             = oli.End_Date__c;
            ordLine.RecordTypeId            = orderLineReadOnlyRT_ID;
            ordLine.Total__c                = oli.UnitPrice * oli.Quantity;
            ordLine.Type__c                 = oli.Type__c;
            ordLine.SaaS__c                 = oli.SaaS__c;
            ordLine.SaaS_Product_Code__c    = oli.SaaS_Product_Code__c;
            ordLine.Product_Finance_BU__c   = oli.Product_Finance_BU__c; //Oct 20, 2014 Tyaga Pati Case#00010129: Added Finance BU Name and Product Finance BU
            ordLine.Finance_BU_Name__c      = oli.Finance_BU_Name__c;
            ordLine.CPQ_Quantity__c         = oli.CPQ_Quantity__c; // T-313163
            ordLine.EDQ_Margin__c           = oli.EDQ_Margin__c; //T-317883
            ordLine.Renewal_EDQ_Margin__c   = oli.Renewal_EDQ_Margin__c; //T-317883
            ordLine.Product_Upgrade__c      = oli.Product_Upgrade__c;
            ordLine.Order_Type__c           = oli.Order_Type__c; //T-326349
            ordLine.Renewal_List_Price__c   = oli.Renewal_List_Price__c;
            ordLine.Country_of_Origin__c    = oli.Opportunity_Country__c;
            //As per T-322945 : EDQ Specific code
              ordLine.Application__c             = oli.Application__c;
              ordLine.Compiler__c                = oli.Compiler__c;
              ordLine.CD_Name__c                 = oli.CD_Name__c;
              ordLine.Click_Expiry__c            = oli.Click_Expiry__c;
              ordLine.CRM_Product_Name__c        = oli.CRM_Product_Name__c;
              //I-135696 : removed Mappings
              //ordLine.Data__c                    = oli.Data__c;
              ordLine.Data_Installer_Password__c = oli.Data_Installer_Password__c;
              ordLine.Data_Media__c              = oli.Data_Media__c;
              ordLine.Data_Required__c           = oli.Data_Required__c;
              ordLine.Data_Usage__c              = oli.Data_Usage__c;
              ordLine.Delivery_Method__c         = oli.Delivery_Method__c;
              ordLine.Despatch_Status__c         = oli.Despatch_Status__c;
              ordLine.Delivery_Time__c           = oli.Delivery_Time__c;
              ordLine.Discount__c                = oli.CPQ_Discount__c; /*oli.Discount;*/ // I-146888
              ordLine.Discount_Amount__c         = oli.Discount_Amount__c;
              ordLine.Distribution_Notes__c      = oli.Distribution_Notes__c;
              ordLine.EDQ_On_Demand_Product__c   = oli.EDQ_On_Demand_Product__c;
              ordLine.eRenewal_Exception__c      = oli.eRenewal_Exception__c;
              ordLine.Extended_Amount__c         = oli.Extended_Amount__c;
              ordLine.Hardware__c                = oli.Hardware__c;
              ordLine.Implementation__c          = oli.Implementation__c;
              ordLine.Item_Description__c        = oli.Description;
              ordLine.Item_Quantity__c           = oli.Item_Quantity__c;
              ordLine.Item_Number__c             = oli.Item_Number__c;
              ordLine.List_Price__c              = oli.List_Price__c; //oli.ListPrice; - I-146698
              ordLine.Major_Version__c           = oli.Major_Version__c;
              ordLine.Manual_Registration__c     = oli.Manual_Registration__c;
              //I-135696 : removed Mappings 
              //ordLine.Manuals__c                 = oli.Manuals__c;
              ordLine.Manuals_Required__c        = oli.Manuals_Required__c;
              ordLine.Media_Quantity__c          = oli.Media_Quantity__c;
              ordLine.No_Delivery__c             = oli.No_Delivery__c;
              ordLine.No_Update__c               = oli.No_Update__c;
              
             // I-137435 - Removed these fields from OLI and OrderLI
             // ordLine.OnDemand__c                = oli.On_Demand__c;
           
              ordLine.Operating_System__c        = oli.Operating_System__c;
              ordLine.Original_Asset_ID__c       = oli.Original_Asset_ID__c;
              ordLine.Parent_Item_Number__c      = oli.Parent_Item_Number__c;
              ordLine.Part_Number__c             = oli.Part_Number__c;
              ordLine.Partner_Amount__c          = oli.Partner_Amount__c;
              ordLine.Partner__c                 = oli.Partner__c;
              ordLine.Precise_Day_License__c     = oli.Precise_Day_License__c;
              ordLine.Price_Category__c          = oli.Price_Category__c;
              ordLine.Product_Code__c            = oli.Product_Code__c;
              ordLine.Product_Data__c            = oli.Product_Data__c;
              ordLine.Product_Family__c          = oli.Product_Family__c;
              ordLine.Product_Reference__c       = oli.Product_Reference__c;
              ordLine.Product_Release_Name__c    = oli.Product_Release_Name__c;
              ordLine.Program_Media__c           = oli.Program_Media__c;
              ordLine.Program_Required__c        = oli.Program_Required__c;
              //I-135696 : removed Mappings
              //ordLine.Progs__c                   = oli.Progs__c;
              ordLine.Quantity_Type__c           = oli.Quantity_Type__c;
              ordLine.Quote_Number__c            = oli.Quote_Number__c;
              ordLine.Registration_Key__c        = oli.Registration_Key__c;
              ordLine.Release__c                 = oli.Release__c;
              ordLine.Release_Reference__c       = oli.Release_Reference__c;
              ordLine.Renewal_Discount__c        = oli.Renewal_Discount__c;
              ordLine.Renewal_Discount_Amount__c = oli.Renewal_Discount_Amount__c;
              ordLine.Renewal_Extended_Amount__c = oli.Renewal_Extended_Amount__c;
              ordLine.Renewal_Partner_Amount__c  = oli.Renewal_Partner_Amount__c;
              ordLine.Renewal_Partner__c         = oli.Renewal_Partner__c;
              ordLine.Renewal_Registration__c    = oli.Renewal_Registration__c;
              ordLine.Renewal_Sales_Price__c     = oli.Renewal_Sale_Price__c;
              ordLine.Renewal_Total_Royalty__c   = oli.Renewal_Total_Royalty__c;
              ordLine.Renewals_Exclude__c        = oli.Renewals_Exclude__c;
              //ordLine.Sale_Price__c              = oli.UnitPrice; // NLG update to 'unitPrice' 2014-09-30 - field deleted 2014-10-09
              ordLine.Total_Royalty__c           = oli.Total_Royalty__c;
              ordLine.Update_Frequency__c        = oli.Update_Frequency__c;
              ordLine.Users_From__c              = oli.Users_From__c;
              ordLine.Users_To__c                = oli.Users_To__c;
              ordLine.Adj_Amount__c              = oli.Adj_Amount__c; //TTK - I-162285
              ordLine.Adj_Percentage__c          = oli.Adj_Percentage__c; //TTK - I-162285
              ordLine.AE_Discount__c             = oli.AE_Discount__c; //TTK - I-162285
              ordLine.Annual_Sales_Price__c      = oli.Annual_Sales_Price__c; //TTK - I-162285
              ordLine.Auto_Quote__c              = oli.Auto_Quote__c; //TTK - I-162285
              ordLine.Bill_Plan_Product_Name__c  = oli.Bill_Plan_Product_Name__c; //TTK - I-162285
              ordLine.Bundle_Discount_Category__c= oli.Bundle_Discount_Category__c; //TTK - I-162285
              ordLine.Bundle_Discount_Name__c    = oli.Bundle_Discount_Name__c; //TTK - I-162285
              ordLine.CSDA_Estimated_Annual_Volume__c = oli.CSDA_Estimated_Annual_Volume__c; //TTK - I-162285
              ordLine.CSDA_List_Price__c         = oli.CSDA_List_Price__c; //TTK - I-162285
              ordLine.CSDA_Product_Group__c      = oli.CSDA_Product_Group__c; //TTK - I-162285
              ordLine.CSDA_Product_Org__c        = oli.CSDA_Product_Org__c; //TTK - I-162285
              ordLine.CSDA_Product_Suite__c      = oli.CSDA_Product_Suite__c; //TTK - I-162285
              ordLine.CSDA_Unit_Type__c          = oli.CSDA_Unit_Type__c; //TTK - I-162285
              ordLine.Escalate__c                = oli.Escalate__c; //TTK - I-162285
              ordLine.Final_Price__c             = oli.Final_Price__c; //TTK - I-162285
              ordLine.Manager_Discount__c        = oli.Manager_Discount__c; //TTK - I-162285
              ordLine.Manual_Adj_Amount__c       = oli.Manual_Adj_Amount__c; //TTK - I-162285
              ordLine.Manual_Discount__c         = oli.Manual_Discount__c; //TTK - I-162285
              ordLine.Manual_Price_Override__c   = oli.Manual_Price_Override__c; //TTK - I-162285
              ordLine.Maximum_Price__c           = oli.Maximum_Price__c; //TTK - I-162285
              ordLine.Max_Volume__c              = oli.Max_Volume__c; //TTK - I-162285
              ordLine.Minimum_Price__c           = oli.Minimum_Price__c; //TTK - I-162285
              ordLine.Min_Volume__c              = oli.Min_Volume__c; //TTK - I-162285
              ordLine.Original_Price__c          = oli.Original_Price__c; //TTK - I-162285
              ordLine.Plan__c                    = oli.Plan__c; //TTK - I-162285
              ordLine.Quotable__c                = oli.Quotable__c; //TTK - I-162285
              ordLine.Quote_Sheet_Type__c        = oli.Quote_Sheet_Type__c; //TTK - I-162285
              ordLine.Requested_Adjustment_Amount__c = oli.Requested_Adjustment_Amount__c; //TTK - I-162285
              ordLine.Requested_Unit_Price__c    = oli.Requested_Unit_Price__c; //TTK - I-162285
              ordLine.SA_Discount__c             = oli.SA_Discount__c; //TTK - I-162285
            orderLineItemList.add(ordLine);
          }
        }
      //Insert of Order Line Items
      if (orderLineItemList.size() > 0) {
        insert orderLineItemList;

        for (Order_Line_Item__c oLine : orderLineItemList) {
          if (!oliId_ordLIMap.containsKey(oLine.Opportunity_Line_Item_Id__c)) {
            oliId_ordLIMap.put(oLine.Opportunity_Line_Item_Id__c, oLine);
          }
        }
        if (oliId_ordLIMap.size() > 0) {
          return oliId_ordLIMap;
        }
      }
    } catch (DMLException e) {
        System.debug('[OpportunityTrigger_OrderHelper: createOrderLines]: ['+e.getMessage()+']]');
        for (Integer i=0; i<e.getNumDml(); i++) {
          oppList.get(0).addError('\nCould not create the Order Line Items. Please contact your admin: ' + e.getDMLMessage(i));
        }
    } 
     
    return null;
  }
   
  //============================================================================================
  //To create order revenue schedules form Opportunity line items
  //============================================================================================
  public static void createRevenueSchedules (Map<ID, Order_Line_Item__c> oliId_ordLIMap) {
    List<Order_Revenue_Schedule__c> ordRevenueList = new List<Order_Revenue_Schedule__c>();
    Order_Revenue_Schedule__c ordRevenue;

    try {
      if (oliId_ordLIMap.keySet().size() > 0) {
        for (OpportunityLineItemSchedule olis : [SELECT o.ScheduleDate, o.Revenue, 
                                                        o.OpportunityLineItemId, o.Id, 
                                                        o.Description, CurrencyIsoCode
                                                 FROM OpportunityLineItemSchedule o
                                                 WHERE OpportunityLineItemId IN : oliId_ordLIMap.keySet()]) {
          ordRevenue                      = new Order_Revenue_Schedule__c();
          ordRevenue.CurrencyIsoCode      = olis.CurrencyIsoCode;
          ordRevenue.Comment__c           = olis.Description;
          ordRevenue.Order_Line_Item__c   = oliId_ordLIMap.get(olis.OpportunityLineItemId).ID;
          ordRevenue.Revenue__c           = olis.Revenue;
          ordRevenue.Scheduled_Date__c    = olis.ScheduleDate;
          ordRevenue.RecordTypeId         = orderScheduleRT_ID;
          ordRevenueList.add(ordRevenue);
        }

        //Insert order revenue schedules
        if (ordRevenueList.size() > 0) {
          insert ordRevenueList;
        }
      }
    } catch (DMLException e) {
        System.debug('[OpportunityTrigger_OrderHelper: createRevenueSchedules]: ['+e.getMessage()+']]');
        for (Integer i=0; i < e.getNumDml(); i++) {
          oliId_ordLIMap.values().get(0).addError('\nCould not create the Order Revenue Schedules. Please contact your admin.' +e.getDMLMessage(i));
        }
    }
  }

  //============================================================================================
  // Will delete related Orders and Opportunities if the lead Opportunity is reopened
  // Only goes one level, meaning if the Opp is reopened, it will delete all Orders and all Opps
  // related to that reopened opp, but not orders of the opp linked to the reopened opp.
  //============================================================================================
  //T-260145: delete related orders and related renewal opportunites for reopened opportunities
  public static void deleteOrderAndOppIfOppIsReopened(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    Set<Id> oppIds = new Set<Id>();
    Set<Id> relatedOpptyIDs = new Set<Id>();
    Map<String, Opportunity> opptiesToDelMap = new Map<String, Opportunity>();
    List<Opportunity> opptyListToDelOrders = new List<Opportunity>();
    List<Account_Plan_Opportunity__c> accPlanOppsToDel = new List<Account_Plan_Opportunity__c>();////As per task T-327046
    List<Order__c> orderToDelete = new List<Order__c>();
    
    for (Opportunity opp: newMap.values()) {
      // If opp is reopened
      if ((opp.isClosed == false && oldMap.get(opp.Id).isClosed == true) && 
            (opp.IsWon == false && oldMap.get(opp.Id).IsWon == true)) {
        oppIds.add(opp.Id);
        opptyListToDelOrders.add(opp);
      }
    }
    //Fetching related renewal opportunities to delete
    for (Opportunity oppty : [SELECT ID, Previous_Opportunity__c,
                                     (Select Id From Account_Plan_Opportunity__r),
                                     (Select Id From Orders__r) 
                              FROM Opportunity
                              WHERE Previous_Opportunity__c IN: oppIds
                              AND Type =: Constants.OPPTY_TYPE_RENEWAL]) {
      opptiesToDelMap.put(oppty.ID, oppty);
      
      //As per task T-327046
      if (oppty.Account_Plan_Opportunity__r.size() > 0) {
        accPlanOppsToDel.addAll(oppty.Account_Plan_Opportunity__r);
      }
      if (oppty.Orders__r.size() > 0) {
        orderToDelete.addAll(oppty.Orders__r);
      }
      //opptyListToDelOrders.add(oppty); NLG - "Do not cater for the deletion of an order on a renewal opportunity" per Luke Mar 21st, 2014 (from daily demo)
    }
    //System.assertEquals('===.>'+accPlanOppsToDel, '****'+opptiesToDelMap.values());
    //Deleting orders and opportunities
    if (opptyListToDelOrders.size() > 0) {
      try {
        //As per task T-327046
        if (accPlanOppsToDel.size() > 0) {
            delete accPlanOppsToDel;
        }
        if (orderToDelete.size() > 0) {
            delete orderToDelete;
        }
        deleteExistingOrders(opptyListToDelOrders);
        delete opptiesToDelMap.values();
      } catch (DMLException e) {
        for (Integer i=0; i < e.getNumDml(); i++) {
          newMap.values().get(0).addError(Label.OPP_ERROR_DELETING_ORDER);
        }
      }
    }
  }

}