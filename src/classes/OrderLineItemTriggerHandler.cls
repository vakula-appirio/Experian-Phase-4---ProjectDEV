/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineItemTriggerHandler
 * Description: Trigger on Order Line Item
 * Created Date: Feb 06rd, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 10th, 2014       Nathalie Le Guay (Appirio)   Added updateSalesPrice()
 * Feb 12th, 2014       Jinesh Goyal                 Modified Exception Handling with Error log creation 
 *                                                   via creating records for Apex_Log__c
 * Mar 20th, 2014       Megha Agarwal                T-260650 - populate Service Dates on Order Line Item if it is NULL  populateFields()
 *                                                   T-260650 - update Service Dates on Order if changed in OLI updateOtherObjects()
 * Apr 02nd, 2014       Arpita Bose(Appirio)         T-268651: Updated populateFields() method to replace reference to Service Start/End dates
 *                                                   with Contract Start/End dates and removed method updateOtherObjects()
 * Apr 02nd, 2014       Arpita bose                  T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 03rd, 2014       Nathalie Le Guay             Remove commented code - backup attached to T-268651 & S-196967
 * Apr 08th, 2014       Naresh Kr Ojha               T-269235: Added method setOriginalItemValue() 
 * Apr 30th, 2014               Naresh Kr Ojha                           I-113908: Update Currency when inserting, updated populateFields()
 * May 23rd, 2014       Nathalie Le Guay             I-116107: call setOriginalItemValue() on insert
 * Sep 03rd, 2014       Naresh Kr Ojha               T-313547: Update royalty records to order line items, added linkRoyaltyRecordsWithOrderLineItem().
 * Oct 02nd, 2014       Naresh Kr Ojha               T-323664: Adding asset for readonly order lines, added method createAssetsForReadOnlyOrderLines(); for after insert and update calls.
 * Oct 06th, 2014       Naresh kr Ojha               Added more fields to be populated for asset creation. Modified method createAssetsForReadOnlyOrderLines()
 * Oct 08th, 2014       Naresh kr Ojha               T-324792: added createAssetForRenewalAndNonRenewals();
 * Oct 09th, 2014       Naresh Kr Ojha               As per Task T-324973, added method to set OnDemand on order = true setOnDemandFlagOnOrderLineDeleted();
 * Oct 16th, 2014       Arpita Bose                  T-326258: updated method createAssetsForOrderLines() and createAssetForRenewalAndNonRenewals()
 * Oct 20, 2014         Nathalie Le Guay             Remove use of Order__c.Shipping_Address__c field as it needs to be deleted.
 * Oct 22nd, 2014       Arpita Bose                  I-135699: Updated method createAssetForRenewalAndNonRenewals() and createAssetsForOrderLines()
 *                                                   I-135696: removed Mappings of Data__c, Progs__c and Manuals__c
 *                                                   I-135845: Change in Country of Origin Mapping
 * Oct 26th, 2014       Nathalie Le Guay             I-136321: Populate Renewal_List_Price__c and Original_Renewal_List_Price__c
 *                                                   Update the functionality so that the Asset is 'resynced' with the Order Line Item if no significant change
 *                                                   was made (in createAssetForRenewalAndNonRenewals())
 * Oct 27th, 2014       Naresh Kr Ojha               I-135845: updated createAssetForRenewalAndNonRenewald() & populateAsset() to map Country on asset object as per the issue.
 *                                                   => Removed by NLG as final solution is to create a Country_of_Origin__c field on the Order Line Item
 * Nov 04th, 2014       Nathalie Le Guay             I-137609: update incrementation of Renewal_Count__c in OrderLineItemTriggerHandler.updateAssets() 
 * Nov 06th, 2014       Nathalie Le Guay             T-331964: populating Parent_Item_Number__c from Order Line Item to Asset in populateAsset()
 * Nov 20th, 2014       Nathalie Le Guay             I-139656: populate Asset.Renewal_Date__c with asset.Order__r.Opportunity__r.Contract_End_Date__c
 * Nov 25th, 2014       Nathalie Le Guay             T-336504: populate Asset.Order__c
 * Dec 19th, 2014       Richard                      Added logic to form memoline value in orderline item - I-144095
 * Jan 19th, 2015       Naresh Kr Ojha               T-353647: Refactoring: Update memoline functions for code homogeneity
 * Jan 23rd, 2014       Nathalie                     I-146524: Updated createAssetForRenewalAndNonRenewals() so as to take Original_Asset_Id__c and renewal scenario
 *                                                   into consideration.
 * Feb 6th, 2015        Gaurav Kumar Chadha          T-359571: updated method populateAsset to copy SaaS__c from Order_Line_Item__c to Asset
 * Feb 23rd, 2015       Naresh kr Ojha               T-364911: Mapping of SaaS_Product_Code__c to Asset.
 * Feb 23rd, 2015       James Weatherall             Case #540469 added updateAssetIfOrderLineCancelled() method to update the Asset when an Order Line it cancelled
 * Mar 10th, 2015       Sadar Yacob                  Case #582227 to set Asset's Media Type based on Order Lines Data Media when Data Media and Program Media !=null
 * Apr 13th, 2015       Paul Kissick                 Case #607717 - Changed hasRunAssetCreation to Public (for use in OrderTriggerHandler), and check for future in processInsertMemoLine
 * Apr 29th, 2015       Paul Kissick                 Case #607717 - Added ignoreRoyalties - Used when creating a credit note order.
 * May 20th, 2015       Sadar Yacob                  Case #660723 - When an Order Line is deleted, set the cancellation date so the Order Line is cancelled in On Demand System
 * Jun 8th, 2015		James Weatherall			 Case #960623 - Mapped Owner BU on Order Create Date to Order Owner BU Stamp on Asset
 =====================================================================*/
 public without sharing class OrderLineItemTriggerHandler {
  private static Order__c parentOrder;
  public static Boolean hasRunAssetCreation = false; // PK Case #607717 - Made public (from private)
  public static Boolean hasRunMemoline = false;
  public static Boolean ignoreRoyalties = false; // PK Case #607717 - Added
  
  //==========================================================================
  //On before insert trigger method
  //==========================================================================
  public static void onBeforeInsert(List<Order_Line_Item__c> newList) {
    populateFields(newList);
    setOriginalItemValue(newList, null);
  }


  //==========================================================================
  //On after insert trigger method
  //==========================================================================
  public static void onAfterInsert(List<Order_Line_Item__c> newList) {
    linkRoyaltyRecordsWithOrderLineItem(newList);
    if (!hasRunAssetCreation) {
      createAssetForRenewalAndNonRenewals(newList, null);
      hasRunAssetCreation = true;
    }
    //I-144095
    processInsertMemoLine(newList);
  }

  //==========================================================================
  //On before update trigger method
  //==========================================================================
  public static void onBeforeUpdate(Map<Id, Order_Line_Item__c> newMap, 
                                   Map<Id, Order_Line_Item__c> oldMap) { 
    // Change to skip update logic from Memoline Update 
    if (!hasRunMemoline) {
      updateOLITotal(newMap, oldMap);
      setOriginalItemValue(newMap.values(), oldMap);
      // I-144095
      cleanseMemoLineData(newMap, oldMap);
    }
  }

  //==========================================================================
  //On after update trigger method
  //==========================================================================
  public static void onAfterUpdate(List<Order_Line_Item__c> newList, 
                                   Map<Id, Order_Line_Item__c> oldMap) { 
    // Change to skip update logic from Memoline Update 
    if (!hasRunMemoline) {
      linkRoyaltyRecordsWithOrderLineItem(newList);
      if (!hasRunAssetCreation) {
        System.debug('\nRunning createAssetForRenewalAndNonRenewals');
        createAssetForRenewalAndNonRenewals(newList, oldMap);
        hasRunAssetCreation = true;
      }
    }
    updateAssetIfOrderLineCancelled(newList, oldMap); // Case #540469 - 23/02/2015 - JW
  }


//==========================================================================
  //On BEFORE delete trigger method
  //==========================================================================
  public static void onBeforeDelete(Map<Id, Order_Line_Item__c> oldMap) {
    setOnDemandOrderLineToCancelled(oldMap);
  }
  

  //==========================================================================
  //On after delete trigger method
  //==========================================================================
  public static void onAfterDelete(Map<Id, Order_Line_Item__c> oldMap) {
    setOnDemandFlagOnOrderLineDeleted(oldMap);
  }
  
  //----------------------------------------
  //Richard starts here 
  //Richard- to Populate EDQ Memoline value
  //----------------------------------------
  /* This logic is updated to have Async while insert and non-Async while update class*/
  public static void processInsertMemoLine(list< Order_Line_Item__c > newList ){   
    set<ID> orderLnSet = new Set<ID>();
    for (Order_Line_Item__c ordLnRec:newList) {
      orderLnSet.add(ordLnRec.Id);
    } 
    if (!Test.isRunningtest() && !System.isFuture()) {// PK Case #607717 - Added check for Future
             MemoLineCreationAsync(orderLnSet);
    }
  }
  
  @future (callout=false)
  public static void memoLineCreationAsync(Set< ID > ordLnIDSet) {
    OrderLineItemTriggerHandler.hasRunMemoline = true;
    // OrderLineItemTriggerHandler.populateMemoLine(newOrglist);
    List<Order_Line_item__c> newOrdLnList = new list<Order_Line_Item__c> (
                                                    [SELECT Id, Order__c, Order__r.Type__c, Product__r.Name, Product__c, EDQ_On_Demand_Product__c,
                                                            Implementation__c, Data_Usage__c, Product__r.Family, Product_Upgrade__c,
                                                            Start_Date__c, End_Date__c
                                                     FROM Order_Line_Item__c 
                                                     WHERE ID in : ordLnIDSet]);
    OrderLineItemTriggerHandler.populateMemoLine(newOrdLnList);
    update newOrdLnList;
  }

  public static void populateMemoLine (List<Order_Line_Item__c> newlist) {
    try {
        Set<String> prodNameSet = new Set<String>();
        Map<String, Product_Board__c> prodBoardMap = new Map<String, Product_Board__c>();
        //List<Product_Board__c> productBoardList = new List<Product_Board__c> ();
        
        for (Order_Line_Item__c oliRec : newlist) {
          prodNameSet.Add(oliRec.Product__r.name ); 
        }
        
        for (Product_Board__c prodBoard : [SELECT Id, Name, Board_Mapping__c, Use_Data_Usage__c 
                                           FROM Product_Board__c 
                                           WHERE Name IN :prodNameSet]) {
            //productBoardList.add(prodBoard);
            prodBoardMap.put(prodBoard.Name , prodBoard);
        }
        
        /*
        for (Product_Board__c productBoardRec : productBoardList ) {
            prodBoardMap.put(productBoardRec.Name , productBoardRec ); 
                
        }*/
        
        Map<string, Data_Usage_Board_Mapping__c> dataUsageBoardMap=new Map<string, Data_Usage_Board_Mapping__c> ();
        Map<string, Data_Usage_Board_Mapping__c> dataUsageBoardOrginalMap = Data_Usage_Board_Mapping__c.getAll();
        
        for(Data_Usage_Board_Mapping__c dataUsageBoardRec: dataUsageBoardOrginalmap.values()) {
          if (dataUsageBoardRec.Name != null) {
            dataUsageBoardMap.put(dataUsageBoardRec.Name.toUpperCase(),dataUsageBoardRec);
          }
        } 
      
      Map<string, Implementation_Board_Mapping__c> implementationBoardMap = new Map<string, Implementation_Board_Mapping__c>();
      Map<string, Implementation_Board_Mapping__c> implementationBoardOrginalMap = Implementation_Board_Mapping__c.getAll();

      for (Implementation_Board_Mapping__c implementationBoardRec: implementationBoardOrginalMap.values()) {
        if (implementationBoardRec.Name != null) {
          implementationBoardMap.put(implementationBoardRec.Name.toUpperCase(),implementationBoardRec);
        }
      }

      for (Order_Line_Item__c oliRec : newlist) {
        String memoLine = 'QAS';

        memoLine = memoLine + (oliRec.Order__r.Type__c == Constants.ORDER_RENEWAL ? 'R' : 'N');

        if (oliRec.EDQ_On_Demand_Product__c) {
          memoLine= memoLine+ 'Pro On Demand';
        }
        else if (prodBoardMap != null && prodBoardMap.containskey(oliRec.Product__r.Name) &&
                !prodBoardMap.get(oliRec.Product__r.Name).Use_Data_Usage__c  && 
                  prodBoardMap.get(oliRec.Product__r.Name).Board_Mapping__c != null ) {
          memoLine=memoLine+ prodBoardMap.get(oliRec.Product__r.Name).Board_Mapping__c;
        }
        else if (prodBoardMap !=null && prodBoardMap.Containskey(oliRec.Product__r.Name) && 
                 prodBoardMap.get(oliRec.Product__r.Name).Use_Data_Usage__c && 
                 implementationBoardMap != null) {

          if (oliRec.Implementation__c != null && implementationBoardMap.containskey(oliRec.Implementation__c.toUpperCase()))
                      /* && implementationBoardMap.get(oliRec.Implementation__c.toUpperCase()).Board_Mapping__c != null && 
                      !implementationBoardMap.get(oliRec.Implementation__c.toUpperCase()).Board_Mapping__c.equalsIgnoreCase('IGNORE')) */
          {
            if (implementationBoardMap.get(oliRec.Implementation__c.toUpperCase()).Use_Data_Usage__c) {
              if (dataUsageBoardmap!= null && oliRec.Data_Usage__c != null && dataUsageBoardmap.containsKey(oliRec.Data_Usage__c.toUpperCase())
                && dataUsageBoardmap.get(oliRec.Data_Usage__c.toUpperCase()).Board_Mapping__c != null) {
                              
                memoLine=memoLine+dataUsageBoardmap.get(oliRec.Data_Usage__c.toUpperCase()).Board_Mapping__c;
              }
              else {
                memoLine=memoLine+ prodBoardMap.get(oliRec.Product__r.name).Board_Mapping__c;
              }
            }
            else {
              memoLine=memoLine+ implementationBoardMap.get(oliRec.Implementation__c.toUpperCase()).Board_Mapping__c;
            }
          }
          else {
            memoLine=memoLine+ prodBoardMap.get(oliRec.Product__r.name).Board_Mapping__c;
          }
        }

        if ((oliRec.Product__r.Family!= null && oliRec.Product__r.Family.equalsIgnoreCase(Constants.STR_SERVICE)) || 
                      oliRec.Product_Upgrade__c || (oliRec.Start_Date__c != null && oliRec.End_Date__c!= null && 
                      oliRec.Start_Date__c.monthsBetween(oliRec.End_Date__c) == 1)) {
          memoLine = memoLine + 'I';
        } else {
          memoLine = memoLine + 'L';   
        }

        //memoLine=memoLine+( oliRec.Product__r.Family =='Service' ? 'I': 'L');
        oliRec.EDQ_Memo_Line__c = memoLine; 
        System.debug('Memoline value  is ' + memoLine + 'Product Name is '+ oliRec.Product__r.name +'Data Usage is '+ oliRec.Data_Usage__c +'Implementation is '+oliRec.Implementation__c );
        
      }
    } catch (Exception ex) {
      system.debug('Exception Error @ populateMemoLine ' + ex.getStackTraceString() + ex.getMessage());
    }
  }
    
    //=========================================================================
    // Cleans memoline data.
    //=========================================================================
    private static void cleanseMemoLineData(Map<Id,Order_Line_Item__c> newMap, 
                                              Map<Id, Order_Line_Item__c> oldMap) {
           
      List<Order_Line_Item__c> newOLIList = new List<Order_Line_Item__c>();
        
      for(Order_Line_Item__c oliRec: newMap.Values()) {
            
        if(oliRec.Product__c != oldMap.get(oliRec.id).Product__c ||               
          oliRec.Data_Usage__c!= oldMap.get(oliRec.id).Data_Usage__c) {
          newOLIList.add(oliRec);
        }
      }
        
       if (newOLIList.size() > 0) {
         populateMemoLine(newOLIList);
       }
  }
  // Richard changes Ends here
  
  //==========================================================================
  // setting Order Send to On Demand: Order Line Item Trigger
  //==========================================================================
  private static void setOnDemandFlagOnOrderLineDeleted (Map<ID, Order_Line_Item__c> oldMap) {
    Set<String> orderIDs = new Set<String>();
    Map<String, Order__c> orderMap = new Map<String, Order__c>();
   
    
    for (Order_Line_Item__c ordLine : oldMap.values()) 
    {
      if (ordLine.Order__c != null && ordLine.EDQ_On_Demand_Product__c ==true ) 
      //check if the Order Line is for On Demand Product -->05/20/15
      //then add to a map
      {
        orderIDs.add(ordLine.Order__c);
    
       }
    }
    
    
    //Querying order with Number of on demand order line items
    for (Order__c ordr : [SELECT ID, Number_of_On_Demand_Order_Line_Items__c, EDQ_Send_to_On_Demand__c 
                           FROM Order__c 
                           WHERE Number_of_On_Demand_Order_Line_Items__c  > 0 
                           AND ID IN: orderIDs]) {
      if (!orderMap.containsKey(ordr.ID)) {
        ordr.EDQ_Send_to_On_Demand__c = true;
        orderMap.put(ordr.ID, ordr);
      }
    }
    
    try 
    {
      //Update orders
      if (orderMap.size() > 0) 
      {
        update orderMap.values();
      }
    } catch (DMLException ex) {
      System.debug('[OrderLineTriggerHandler:setOnDemandFlagOnOrderLineDeleted]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('OrderLineTriggerHandler','setOnDemandFlagOnOrderLineDeleted', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        oldMap.values().get(0).addError(ex.getDmlMessage(i));
      }     
    }
  }
  
  
  //==========================================================================
  // T-269235: Development needed of Stamping of values
  //==========================================================================
  private static void setOriginalItemValue(List<Order_Line_Item__c> newList, 
                                           Map<Id, Order_Line_Item__c> oldMap) {
    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
    for (Order_Line_Item__c orderLine : newList) {
      if (orderLine.RecordTypeId == orderLineReadOnlyRT_ID && 
                (oldMap == null || orderLine.RecordTypeId != oldMap.get(orderLine.ID).RecordTypeId)) {
        orderLine.Original_Item_value__c = orderLine.Total__c;
      }
    }
  }
  
  //==========================================================================
  // Call to find if any Order Line Item's Recalculate_Sales_Price__c is set. 
  // If so, we will loop through each OLI's Revenue Schedule to recalculate the
  // sales price
  //==========================================================================
  private static void updateOLITotal(Map<Id, Order_Line_Item__c> newMap, Map<Id, Order_Line_Item__c> oldMap) {
    Set<Id> oliToRecalculateIds = new Set<Id>();
    for (Order_Line_Item__c lineItem: newMap.values()) {
      if (lineItem.Recalculate_Sales_Price__c) {
        oliToRecalculateIds.add(lineItem.Id);
        //Commented as this has been moved to workflow on Order_Line_Item__c: nojha
        //lineItem.Recalculate_Sales_Price__c = false;
      }
    }

    // Gather qualifying Order Line Items
    List<Order_Line_Item__c> lineItems = new List<Order_Line_Item__c>();
    if (oliToRecalculateIds.size() > 0) {
      lineItems = [SELECT Id, Name, Total__c,
                                 (SELECT Id, Revenue__c
                                  FROM Order_Revenue_Schedules__r)
                          FROM Order_Line_Item__c
                          WHERE Id in: oliToRecalculateIds];

      if (lineItems.size() > 0) {
        system.debug('\nOrderLineItemTriggerHandler: updateOLITotal] REVENUE: # of Line items'+ lineItems.get(0).Order_Revenue_Schedules__r.size());
      }

      // Loop through all OLI and for each OLI, loop through Revenue Schedules to sum the Revenue__c
      if (lineItems.size() == 0) 
      {
        return;
      }
      Decimal total = 0.00;
      for (Order_Line_Item__c lineItem: lineItems) 
      {
        system.debug('\n[OrderLineItemTriggerHandler: updateOLITotal] ADDING REVENUE: '+ lineItem);
        total = 0.00;
        for (Order_Revenue_Schedule__c revenue: lineItem.Order_Revenue_Schedules__r) 
        {
          system.debug('\n[OrderLineItemTriggerHandler: updateOLITotal] ADDING REVENUE PRIO: '+ total);
          total += revenue.Revenue__c;
          system.debug('\n[OrderLineItemTriggerHandler: updateOLITotal] ADDING REVENUE: '+ total);
        }
        // Find the Order_Line_Item__c and update the Total__c value
        Order_Line_Item__c itemToUpdate = newMap.get(lineItem.Id);
        if (itemToUpdate != null) 
        {
          itemToUpdate.Total__c = total;
        }
        System.debug('\n[OrderLineItemTriggerHandler - updateSalesPrice()] : '+ lineItem.Name + ' : ' + lineItem.Total__c);
      }
    }
  }

  //==========================================================================
  // Will populate the Service Start/End Date if not manually selected by User
  //==========================================================================
  private static void populateFields(List<Order_Line_Item__c> newOrderLineItems){
    Set<String>  orderIds = new Set<String>();
    Map<Id, Order__c> ordID_orderMap = new Map<Id, Order__c>();

    for (Order_Line_Item__c oli : newOrderLineItems) {
     /* // check Service Start Date NULL
      if(oli.Start_Date__c == null) {
        orderIds.add(oli.order__c);
      }
      // check Service End Date NULL
     if(oli.End_Date__c == null) {
        orderIds.add(oli.order__c);
      }*/
      orderIds.add(oli.order__c);
    }
    //T-268651: updated to remove reference to Order's Service Start/end date and replace with Contract Start/End dates
    if (!orderIds.isEmpty()) {
      for (Order__c ord : [SELECT Id, Contract_Start_Date__c, Contract_End_Date__c, CurrencyISOCode
                           FROM Order__c
                           WHERE Id in : orderIds]) {
        ordID_orderMap.put(ord.ID, ord);
      }
      /*
      ordID_orderMap = new Map<Id, Order__c>([SELECT Id, Contract_Start_Date__c, Contract_End_Date__c
                                                   FROM Order__c
                                                   WHERE Id in : orderIds AND (Contract_Start_Date__c != null OR Contract_End_Date__c != null)]);*/
                                                   
      for (Order_Line_Item__c oli : newOrderLineItems) {
        // Populate Service Start Date from Order if it is NULL
        if (oli.Start_Date__c == null && ordID_orderMap.containsKey(oli.Order__c)
                                              && ordID_orderMap.get(oli.Order__c).Contract_Start_Date__c != null) {
          oli.Start_Date__c = ordID_orderMap.get(oli.Order__c).Contract_Start_Date__c;
        }
        // Populate Service End Date from Order if it is NULL
        if (oli.End_Date__c == null && ordID_orderMap.containsKey(oli.Order__c)
                                            && ordID_orderMap.get(oli.Order__c).Contract_End_Date__c != null) {
          oli.End_Date__c = ordID_orderMap.get(oli.Order__c).Contract_End_Date__c;
        }
        // Populating order's currency on order line
        if (ordID_orderMap.containsKey(oli.Order__c) && 
                    oli.CurrencyISOCode != ordID_orderMap.get(oli.Order__c).CurrencyISOCode) {
            oli.CurrencyIsoCode = ordID_orderMap.get(oli.Order__c).CurrencyISOCode;
        }
      }
    }
  }

  //===========================================================================
  // Method to relate Royalty records with Order Line Item
  //===========================================================================
  private static void linkRoyaltyRecordsWithOrderLineItem (List<Order_Line_Item__c> newList) {
    if (ignoreRoyalties) {
      return; // PK Case #607717 - Bail out if told to ignore.
    }
    Set<String> orderIDs = new Set<String>();
    Set<String> opptyIDs = new Set<String>();
    Set<String> itemNumbers = new Set<String>();
    Map<String, Order__c> orderID_OpptyIDMap = new Map<String, Order__c>();
    Map<String, List<OpportunityLineItem>> opptyID_opptyLinesMap = new Map<String, List<OpportunityLineItem>>();
    Map<String, String> opptyLineId_ordLineIdMap = new Map<String, String>();

    List<Royalty__c> royaltyList = new List<Royalty__c>();

    for (Order_Line_Item__c ordLine : newList) {
      if (ordLine.Order__c != null) {
        orderIDs.add(ordLine.Order__c);
      }
    }

    //Getting OpportunityID from order
    for(Order__c order : [SELECT Opportunity__c, ID, (Select Id, Opportunity_Line_Item_Id__c From Order_Line_Items__r) 
                          FROM Order__c 
                          WHERE ID IN: orderIDs]){
       if(order.Opportunity__c != null) {
         opptyIDs.add(order.Opportunity__c);
       }
       orderID_OpptyIDMap.put(order.ID, order);
       //Populating opptyLine with orderLineId
       for (Order_Line_Item__c ordLine : order.Order_Line_Items__r) {
        if (ordLine.Opportunity_Line_Item_Id__c != null && 
              !opptyLineId_ordLineIdMap.containsKey(ordLine.Opportunity_Line_Item_Id__c)) {
          opptyLineId_ordLineIdMap.put(ordLine.Opportunity_Line_Item_Id__c, ordLine.ID);
        }
       }
    }
    
    System.debug('====opptyIDs======'+opptyIDs);
    
    //Getting opportunity line item and opportunity details 
    for (OpportunityLineItem oli : [SELECT Item_Number__c, OpportunityId, Id 
                                    FROM OpportunityLineItem 
                                    WHERE OpportunityID IN : opptyIDs]) {
      if (oli.Item_Number__c != null && oli.Item_Number__c != '') {
        itemNumbers.add(oli.Item_Number__c); 
      }
      if (!opptyID_opptyLinesMap.containsKey(oli.OpportunityID)) {
        opptyID_opptyLinesMap.put(oli.OpportunityID, new List<OpportunityLineItem>());
      }
      opptyID_opptyLinesMap.get(oli.OpportunityID).add(oli);
    }
    
    if (itemNumbers.size() < 1) {
      return;
    }
    System.debug('=====opptyID_opptyLinesMap=='+opptyID_opptyLinesMap);
    //Getting related royalty records
    for (Royalty__c roy : [Select Order_Line_Item__c, Opportunity__c, Line_Item_Reference_Number__c, Id 
                           From Royalty__c
                           WHERE Line_Item_Reference_Number__c IN : itemNumbers AND Opportunity__c in : opptyIDs]) {
      //Associating Royalty record with order line item.

      if (roy.Opportunity__c != null && opptyID_opptyLinesMap.containsKey(roy.Opportunity__c)) {
         for (OpportunityLineItem oli : opptyID_opptyLinesMap.get(roy.Opportunity__c)) {
           if (oli.Item_Number__c == roy.Line_Item_Reference_Number__c && opptyLineId_ordLineIdMap.containsKey(oli.ID)) {
             roy.Order_Line_Item__c = opptyLineId_ordLineIdMap.get(oli.ID);
             royaltyList.add(roy);
             System.debug('=====opptyLineId_ordLineIdMap.get(oli.ID)=='+opptyLineId_ordLineIdMap.get(oli.ID));
           }
         }
      }
    }
    System.debug('=====royaltyList=='+royaltyList); 
    
    //Updating royalty records
    if (!royaltyList.isEmpty()) {
      update royaltyList;
    }
  }

  //===========================================================================
  //Creation of asset by querying order lines.
  //===========================================================================
  private static List<Asset> createAssetsForOrderLines (Map<String, Order_Line_Item__c> orderLines, List<Asset> assets,
                           Map<String, Opportunity_Contact_Address__c> mapOrderAddress,  Map<String, List<Asset>> ordLineID_ListOfAssetMap) {
    
    List<Asset> newAssets = new List<Asset>();
    
    //Create assets
   // if (assets == null) {
      Asset newAsset;
      for (Order_Line_Item__c ordLine : orderLines.values()) {
        List<Asset> existingAssets = new List<Asset>();
        if (!String.isBlank(ordLine.Original_Asset_Id__c)
          && ordLineID_ListOfAssetMap != null && ordLineID_ListOfAssetMap.containsKey(ordLine.Original_Asset_Id__c)) {
          existingAssets = ordLineID_ListOfAssetMap.get(ordLine.Original_Asset_Id__c);
        }
        else if (!String.isBlank(ordLine.Item_Number__c) && !String.isBlank(ordLine.Quote_Number__c) 
          && ordLineID_ListOfAssetMap != null && ordLineID_ListOfAssetMap.containsKey(ordLine.Item_Number__c+ordLine.Quote_Number__c)) {
          existingAssets = ordLineID_ListOfAssetMap.get(ordLine.Item_Number__c+ordLine.Quote_Number__c);
        }
        Asset existingAsset = (existingAssets != null && existingAssets.size() > 0) ? existingAssets.get(0) : null;
        newAsset = populateAsset(ordLine, existingAsset);
        if (mapOrderAddress != null && mapOrderAddress.containsKey(ordLine.Order__c) && 
        mapOrderAddress.get(ordLine.Order__c).Role__c == Constants.OPPTY_CONTACT_ROLE_RENEWAL && mapOrderAddress.get(ordLine.Order__c).Contact__c != null) {
            newAsset.ContactId = mapOrderAddress.get(ordLine.Order__c).Contact__c;
        }
        newAssets.add(newAsset);
      }
    //}
     /*else {
      for (Asset asset: assets) {
        if (asset.Order_Line__c != null && orderLines.keySet().contains(asset.Order_Line__c)) {
          Asset newAsset;
          Order_Line_Item__c ordLine = orderLines.get(asset.Order_Line__c);

          newAsset = populateAsset(ordLine, asset);
          newAssets.add(newAsset);
        }
      }
    }*/

    //Inserting new asset records
    if (newAssets.size() > 0) {
      return newAssets;
    }
    return null;
  }//End of createAsset method


  private static Asset populateAsset(Order_Line_Item__c ordLine, Asset existingAsset) {
    Asset newAsset = new Asset();
    if (existingAsset != null) {
      newAsset.Id = existingAsset.Id;
      newAsset.Renewal_Count__c = existingAsset.Renewal_Count__c;
    }

    newAsset.Cancellation_Date__c = null;
    newAsset.Cancellation_Reason__c = '';
    newAsset.Order_Line__c = ordLine.ID;
    newAsset.Data_Usage__c = ordLine.Data_Usage__c;
    newAsset.Implementation__c = ordLine.Implementation__c;
    newAsset.No_Update__c = ordLine.No_Update__c;
    newAsset.Operating_System__c = ordLine.Operating_System__c;
    newAsset.Product_Data__c = ordLine.Product_Data__c;
    newAsset.Update_Frequency__c = ordLine.Update_Frequency__c;
    newAsset.Name = ordLine.Product__r.Name;
    newAsset.Opportunity__c = ordLine.Order__r.Opportunity__c;
    newAsset.Callidus_Item_Number__c = ordLine.Item_Number__c;
    newAsset.Callidus_Quote_Number__c = ordLine.Quote_Number__c;
    newAsset.Order_Line__c = ordLine.Id;
    newAsset.Part_Number__c = ordLine.Part_Number__c;
    newAsset.Renewal_List_Price__c = ordLine.Renewal_List_Price__c;
    newAsset.Original_Renewal_List_Price__c = ordLine.Renewal_List_Price__c;
    newAsset.Parent_Item_Number__c = ordLine.Parent_Item_Number__c;

    newAsset.AccountId = ordLine.Order__r.Account__c;
    newAsset.Product2ID = ordLine.Product__c;
    newAsset.CurrencyIsoCode = ordLine.CurrencyIsoCode;
    newAsset.Status  = ordLine.Status__c;
    
    //newAsset.Price = ordLine.Sales_Price__c;
    newAsset.Quantity = ordLine.CPQ_Quantity__c;
    newAsset.Description = ordLine.Item_Description__c;
    //T-326258: Code start
    if (ordLine.Program_Media__c == null && ordLine.Data_Media__c != null) {
      newAsset.Media_Type__c = ordLine.Data_Media__c; 
    }
    else if (ordLine.Program_Media__c != null && ordLine.Data_Media__c == null) {
      newAsset.Media_Type__c = ordLine.Program_Media__c;  
    }
    else if (ordLine.Program_Media__c != null && ordLine.Data_Media__c != null) {
      newAsset.Media_Type__c = ordLine.Data_Media__c;  
    }// code Ends
    newAsset.Users_To__c = ordLine.Users_To__c;
    newAsset.Manual_Registration__c = ordLine.Manual_Registration__c;
      
    //T-326258
    newAsset.Application__c = ordLine.Application__c;
    newAsset.Cancellation_Date__c = ordLine.Cancellation_Date__c;
    newAsset.Channel_Type__c = ordLine.Order__r.Channel_Type__c;
    newAsset.Click_Expiry__c = ordLine.Click_Expiry__c;
    newAsset.Compiler__c = ordLine.Compiler__c;
    newAsset.Country_of_Origin__c = ordLine.Country_of_Origin__c; // I-135845
    
    newAsset.Credited__c = ordLine.Order__r.Credited__c;
    newAsset.Credited_Date__c = ordLine.Order__r.Credited_Date__c;
    newAsset.CRM_Product_Name__c = ordLine.CRM_Product_Name__c;
    newAsset.Data_Required__c = ordLine.Data_Required__c;
    newAsset.Discount_Amount__c = ordLine.Discount_Amount__c;
    newAsset.EDQ_Margin__c = ordLine.EDQ_Margin__c;
    newAsset.eRenewal_Exception__c = ordLine.eRenewal_Exception__c;
    newAsset.Hardware__c = ordLine.Hardware__c;
    // NLG Commented below - 2014-10-22
    //newAsset.ID = ordLine.Original_Asset_ID__c;
      
    // I-135696 : removed Mapping
    //newAsset.Manuals__c = ordLine.Manuals__c;
    newAsset.Manuals_Required__c = ordLine.Manuals_Required__c;
    newAsset.On_Demand__c = ordLine.EDQ_On_Demand_Product__c;
    
    if (newAsset.Original_Renewal_Price__c == null) {
      newAsset.Original_Renewal_Price__c = ordLine.Renewal_Sales_Price__c;
    }
    newAsset.Order__c = ordLine.Order__c; // T-336504 - NLG - Nov 25th, 2014
    newAsset.Partner__c = ordLine.Order__r.Partner__c;
    newAsset.Partner_Amount__c = ordLine.Partner_Amount__c;
    newAsset.Partner_Percentage__c = ordLine.Partner__c;
    newAsset.Precise_Day_License__c = ordLine.Precise_Day_License__c;
    newAsset.Price = ordLine.List_Price__c;
    newAsset.SaaS__c = ordLine.SaaS__c;
    newAsset.SaaS_Product_Code__c = ordLine.SaaS_Product_Code__c;
    newAsset.Product_Reference__c = ordLine.Product_Reference__c;
    newAsset.Program_Required__c = ordLine.Program_Required__c;
    newAsset.PurchaseDate = ordLine.Order__r.Close_Date__c;
    newAsset.Quantity_Type__c = ordLine.Quantity_Type__c;
    newAsset.Registration_Key__c = ordLine.Registration_Key__c; 
    newAsset.Release_Version__c = ordLine.Release__c;
    if (ordLine.Order__c != null && ordLine.Order__r.Contract_End_Date__c != null) {
      newAsset.Renewal_Date__c = ordLine.End_Date__c.addDays(1);
      System.debug('\nRenewal_Date__c isssss: '+ newAsset.Renewal_Date__c + ' coming from '+ ordLine.End_Date__c);
    }
    newAsset.Renewal_Discount__c = ordLine.Renewal_Discount__c;
    newAsset.Renewals_Exclude__c = ordLine.Renewals_Exclude__c;
    newAsset.Sales_Price__c = ordLine.Sales_Price__c;
    if (existingAsset == null) {
      newAsset.Start_Date__c = ordLine.Start_Date__c;
    }
    newAsset.Total_Royalty__c = ordLine.Total_Royalty__c;
    newAsset.UsageEndDate = ordLine.End_Date__c;
    newAsset.Users_From__c = ordLine.Users_From__c;
    newAsset.Extended_Amount__c = ordLine.Extended_Amount__c;
    newAsset.Renewal_Discount_Amount__c = ordLine.Renewal_Discount_Amount__c;
    newAsset.Renewal_EDQ_Margin__c = ordLine.Renewal_EDQ_Margin__c;
    newAsset.Renewal_Extended_Amount__c = ordLine.Renewal_Extended_Amount__c;
    newAsset.Renewal_Partner__c = ordLine.Renewal_Partner__c;
    newAsset.Renewal_Partner_Amount__c = ordLine.Renewal_Partner_Amount__c;
    newAsset.Renewal_Total_Royalty__c = ordLine.Renewal_Total_Royalty__c;
    newAsset.Renewal_Sale_Price__c = ordLine.Renewal_Sales_Price__c;
    
    // I-135696 : removed Mapping
    //newAsset.Data__c = ordLine.Data__c;
    //newAsset.Progs__c = ordLine.Progs__c;
    newAsset.Price_Category__c = ordLine.Price_Category__c;
    newAsset.Media_Quantity__c = ordLine.Media_Quantity__c;
    
    // Case 960623 - 8/6/2015 - James Weatherall 
    newAsset.Order_Owner_BU_Stamp__c = ordLine.Order__r.Owner_BU_on_Order_Create_Date__c;
      
    //I-135699
    if (!String.isBlank(ordLine.Order__r.Invoice_to_End_User__c) && ordLine.Order__r.Invoice_to_End_User__c.equalsIgnoreCase('Yes')) {
      newAsset.Direct_Renewal__c = true; 
    }
    else {
      newAsset.Direct_Renewal__c = false;
    }
    return newAsset;
  }

  
  //===========================================================================
  // T-324792: Creates Assets for renewal and non renewals
  //===========================================================================
  private static void createAssetForRenewalAndNonRenewals (List<Order_Line_Item__c> newList, 
                                                          Map<ID, Order_Line_Item__c> oldMap) {
    

    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
    Set<ID> orderLineIDs = new Set<ID>();
    Set<Id> setOrderIds = new Set<Id>();
    
    for (Order_Line_Item__c orderLine : newList) {
      if ((orderLine.RecordTypeId == orderLineReadOnlyRT_ID) && 
                ((oldMap != null)?orderLine.RecordTypeId != oldMap.get(orderLine.ID).RecordTypeId:true)) {
        orderLineIDs.add(orderLine.ID);
        setOrderIds.add(orderLine.Order__c);
      }
    }

    if (orderLineIDs.size() < 1) {
      return;
    }
    
    Map<String, Order_Line_Item__c> renewalOrdLines = new Map<String, Order_Line_Item__c>();
    Map<String, Order_Line_Item__c> nonRenewalOrdLines = new Map<String, Order_Line_Item__c>();
    List<Asset> newAssets = new List<Asset>();
    
    //I-135845
    Map<String, Opportunity_Contact_Address__c> mapOrderAddress = new Map<String, Opportunity_Contact_Address__c>();
    // query Opportunity_Contact_Address__c to Address__r.Country__c  
    // where Opportunity_Contact_Address__c.Order__c is in setOrderIds AND Opportunity_Contact_Address__c.Role = "Ship To" 
    for (Opportunity_Contact_Address__c oppConAddr : [SELECT Order__c, Address__r.Country__c, Address__c ,
                                                             Contact__c ,Role__c
                                                      FROM Opportunity_Contact_Address__c 
                                                      WHERE Role__c = : Constants.OPPTY_CONTACT_ROLE_RENEWAL
                                                      AND Order__c IN : setOrderIds]){
      if (oppConAddr.Order__c != null && oppConAddr.Address__c != null && !mapOrderAddress.containsKey(oppConAddr.Order__c)) {
        mapOrderAddress.put(oppConAddr.Order__c, oppConAddr);                                  
      }                 
    }
    
    for (Order_Line_Item__c ordLine : [SELECT Order__r.Opportunity__r.Type, Order__r.Opportunity__r.Contract_End_Date__c,
                                              Order__c, Opportunity_Line_Item_Id__c, Order__r.Contract_End_Date__c,
                                              ID, Data_Usage__c, Implementation__c, No_Update__c, Operating_System__c, Product__c, Product__r.Name,
                                              Product_Data__c, Update_Frequency__c, Account_Id__c, Name, Order__r.Account__c,
                                              CurrencyIsoCode, Status__c, Quantity__c, Application__c, RecordType.Name , 
                                              Data_Media__c, Users_To__c, Manual_Registration__c, Item_Description__c, 
                                              Item_Number__c, Quote_Number__c, Product__r.Business_Line__c, Order__r.Transactional_Sale__c, 
                                              Part_Number__c, Order__r.Opportunity__c, Sales_Price__c, Cancellation_Date__c,
                                              Order__r.Channel_Type__c, Click_Expiry__c, Compiler__c, // Order__r.Shipping_Address__r.Country__c,
                                              Order__r.Credited__c, Order__r.Credited_Date__c, CRM_Product_Name__c, Data_Required__c,
                                              Discount_Amount__c, EDQ_Margin__c, eRenewal_Exception__c, Hardware__c, Original_Asset_ID__c,
                                              Manuals_Required__c, EDQ_On_Demand_Product__c, Renewal_Sales_Price__c, 
                                              Order__r.Partner__c, Order__r.Type__c ,Partner_Amount__c, Partner__c, Precise_Day_License__c, List_Price__c,
                                              Product_Reference__c, Program_Required__c, Order__r.Close_Date__c, CPQ_Quantity__c, 
                                              Quantity_Type__c, Registration_Key__c, Release__c, Renewal_Discount__c, Renewals_Exclude__c,
                                              Start_Date__c, Total_Royalty__c, End_Date__c, Users_From__c, Extended_Amount__c,
                                              Renewal_Discount_Amount__c, Renewal_EDQ_Margin__c, Renewal_Extended_Amount__c, Renewal_Partner__c,
                                              Renewal_Partner_Amount__c, Renewal_Total_Royalty__c, Country_of_Origin__c,
                                              Price_Category__c, Media_Quantity__c, Program_Media__c, Order__r.Invoice_to_End_User__c, Renewal_List_Price__c,
                                              Parent_Item_Number__c, SaaS__c, SaaS_Product_Code__c, Order__r.Owner_BU_on_Order_Create_Date__c 
                                       FROM Order_Line_Item__c 
                                       WHERE ID IN: newList]) {
      System.debug('====ordLine.Order__r.Opportunity__r.Type==='+ordLine.Order__r.Opportunity__r.Type);
      if (ordLine.Order__r.Opportunity__r.Type == Constants.OPPTY_TYPE_RENEWAL) {
        //if (ordLine.Original_Asset_ID__c == null) { NLG - Jan 23rd, 2015 - I-146524
          renewalOrdLines.put(ordLine.Id, ordLine);
          System.debug('---renewal lines---');
        //}
      } else {
        nonRenewalOrdLines.put(ordLine.Id, ordLine);
      }
    }
    //Creating assets for non renewal order lines
    if (nonRenewalOrdLines.size() > 0) {
      newAssets.addAll(createAssetsForOrderLines(nonRenewalOrdLines, null, mapOrderAddress, null));
    }
    
    Map<String, List<Asset>> ordLineID_ListOfAssetMap = new Map<String, List<Asset>>();
    Set<String> oliMatchedWithAssets = new Set<String>();
    if (renewalOrdLines.size() > 0) {
      ordLineID_ListOfAssetMap = searchExistingAssets(renewalOrdLines.values());
      System.debug('---renewalOrdLines ordLineID_ListOfAssetMap---'+ordLineID_ListOfAssetMap);
    }
    
    Map<String, Order_Line_Item__c> ordlinesToCreateAssets = new Map<String, Order_Line_Item__c>();
    List<Asset> assetsToUpdate = new List<Asset>();
    //If map has some records returned    
      //Checking for existing assets
      for (Order_Line_Item__c ordLine : renewalOrdLines.values()) {
        Boolean checkSignificantChange = true;
        String key = ordLine.Item_Number__c + ordLine.Quote_Number__c;
        if (ordLine.Original_Asset_Id__c == null && !ordLineID_ListOfAssetMap.containsKey(key)) {
          ordlinesToCreateAssets.put(ordLine.ID, ordLine);
          checkSignificantChange = false;
          System.debug('---order line do not contains any asset matching---'+ordlinesToCreateAssets);
          // Create asset here - Missed requirement implementation was to create Asset if Original Asset Id was populated but Asset not found
          ordlinesToCreateAssets.put(ordLine.ID, ordLine); // NLG - Jan 23rd, 2015 - I-146524
        }
        
        if (ordLineID_ListOfAssetMap.containsKey(ordLine.Original_Asset_Id__c) && ordLineID_ListOfAssetMap.get(ordLine.Original_Asset_Id__c).size() > 0) {
          key = ordLine.Original_Asset_Id__c;
        }
        if ((ordLineID_ListOfAssetMap.containsKey(key) && ordLineID_ListOfAssetMap.get(key).size() > 0) &&
                checkSignificantChange == true) {
          System.debug('---order line contains asset---');
          for (Asset asst : ordLineID_ListOfAssetMap.get(key)) {
            if (areThereSignificantChanges(ordLine, asst)) {
              //Create asset for significant change
              ordlinesToCreateAssets.put(ordLine.ID, ordLine);
              System.debug('---Asset is getting created for significant change---'+ordlinesToCreateAssets);
            } else {
              //Update existing
              assetsToUpdate.add(asst);
              System.debug('---assetsToUpdate---'+assetsToUpdate);
            }
          } 
        }
      }
    //Creating assets for non renewal order lines
    if (ordlinesToCreateAssets.size() > 0) {
      newAssets.addAll(createAssetsForOrderLines(ordlinesToCreateAssets, null, mapOrderAddress, null));
      System.debug('-----adding all assets---'+newAssets);
    }
    
    try {
      //If new assets to be created
      if (newAssets.size() > 0) {
        insert newAssets;
      }
      
      //If there is any asset to update.
      if (assetsToUpdate.size() > 0) {
        
        assetsToUpdate = createAssetsForOrderLines(renewalOrdLines, assetsToUpdate, mapOrderAddress, ordLineID_ListOfAssetMap);
        if (assetsToUpdate != null && assetsToUpdate.size() > 0) {
          updateAssets(assetsToUpdate);
        }
      }
    } catch (DMLException ex) {
      System.debug('[OrderLineTriggerHandler:createAssetForRenewalAndNonRenewals]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('OrderLineTriggerHandler','createAssetForRenewalAndNonRenewals', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDmlMessage(i));
      }     
    }
    
  }
  
  //==========================================================================
  // Start: Case #540469 - 23/02/2015 - James Weatherall
  //==========================================================================
  private static void updateAssetIfOrderLineCancelled(List<Order_Line_Item__c> newOrderLines, Map<Id, Order_Line_Item__c> oldMap) {
  
    Map<Id, Date> assetOrdersToUpdateMap = new Map<Id, Date>();
    List<Asset> lstAssetsToUpdate = new List<Asset>();
      
    try {
      //checking for cancelled orderes.    
      for (Order_Line_Item__c ord : newOrderLines) {
        if (ord.Cancellation_Date__c <> null && oldMap.get(ord.Id).Cancellation_Date__c == null) {
          assetOrdersToUpdateMap.put(ord.ID, ord.Cancellation_Date__c);
        }
      }
      List<Asset> assetList = new List<Asset>();
      Map<ID, Asset> assetMap = new Map<ID, Asset>([SELECT Id, Order_Line__c, Cancellation_Date__c, Status, Cancellation_Reason__c
                                                    FROM Asset
                                                    WHERE Order_Line__c IN: assetOrdersToUpdateMap.keySet()]);
      assetList = assetMap.values();
      for (Asset assetToUpdate : assetList)
      {
        assetToUpdate.Status = 'Cancelled'; // Add to Constants class - JW 23/02/2015
        assetToUpdate.Cancellation_Date__c = assetOrdersToUpdateMap.get(assetToUpdate.Order_Line__c); 
        lstAssetsToUpdate.add(assetToUpdate);
      }
      if(lstAssetsToUpdate.size() > 0) {
       update lstAssetsToUpdate;
      }        
    } Catch (Exception ex) {
      System.debug('\n[OrderLineItemTriggerHandler: updateAssetIfOrderLineCancelled]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OrderLineItemTriggerHandler','updateAssetIfOrderLineCancelled', ex.getStackTraceString(), ex); 
      newOrderLines[0].addError(ex.getMessage());
    }
  }
  // End
  
  //==========================================================================
  //Searching existing assets for renewal opportunities
  //==========================================================================
  private static Map<String, List<Asset>> searchExistingAssets(List<Order_Line_Item__c> orderLines) {
    
    Map<String, List<Asset>> ordLineID_ListOfAssetsMap = new Map<String, List<Asset>>();
     
    Set<String> itemNumberSet = new Set<String>();
    Set<String> quoteNumberSet = new Set<String>();
    Set<String> accountIds = new Set<String>();
    Map<String, Asset> assetByCallidusIds = new Map<String, Asset>();
    Set<String> oliCallidusIdSet = new Set<String>();
    Set<String> originalAssetIdsSet = new Set<String>();

    for (Order_Line_Item__c ordLine : orderLines) {
      if ((ordLine.Item_Number__c != null && ordLine.Quote_Number__c != null) || ordLine.Original_Asset_Id__c != null) {
        itemNumberSet.add(ordLine.Item_Number__c);
        quoteNumberSet.add(ordLine.Quote_Number__c);
        oliCallidusIdSet.add(ordLine.Item_Number__c+ordLine.Quote_Number__c);
        accountIds.add(ordLine.Account_Id__c);
        originalAssetIdsSet.add(ordLine.Original_Asset_Id__c); // NLG - Jan 23rd, 2015 - I-146524
      }
    }
    System.debug('------itemnumber:'+itemNumberSet+'       : ***quoteNumberSet****'+quoteNumberSet);
    //Creating map for assets
    if ((itemNumberSet.size() > 0 && quoteNumberSet.size() > 0) || originalAssetIdsSet.size() > 0) {
      for (Asset asst : [SELECT Id, Order__c, Order_Line__c, Callidus_Quote_Number__c, Callidus_Item_Number__c,
                                Part_Number__c, Product2Id, Renewal_Count__c
                         FROM Asset 
                         WHERE (Callidus_Quote_Number__c IN: quoteNumberSet AND Callidus_Item_Number__c IN: itemNumberSet AND AccountId IN: accountIds)
                            OR Id in: originalAssetIdsSet]) {
        String key = asst.Callidus_Item_Number__c+asst.Callidus_Quote_Number__c;
        system.debug('\n\nThe asset order line is ' + key + ' with id '+ asst.id);
        system.debug('asst.Renewal_Count__c===' +asst.Renewal_Count__c);
        
        if (oliCallidusIdSet.contains(key)) {
          if (!ordLineID_ListOfAssetsMap.containsKey(key)) {
            ordLineID_ListOfAssetsMap.put(key, new List<Asset>());
          }
          ordLineID_ListOfAssetsMap.get(key).add(asst);
        }
        // Also store by Asset Id - in case Order_Line_Item__c.Original_Asset_Id__c is populated
        ordLineID_ListOfAssetsMap.put(asst.Id, new List<Asset>{asst});
      }
    }
    System.debug('------ordLineID_ListOfAssetsMap:'+ordLineID_ListOfAssetsMap);
    return ordLineID_ListOfAssetsMap;
  }
  
  //==========================================================================
  // Checking significance change with Order line item and its assets
  // based on part number and products
  //==========================================================================
  private static boolean areThereSignificantChanges(Order_Line_Item__c orderLineItem, Asset asset) {
  
    if (orderLineItem.Product__r.Business_Line__c == Constants.BUSINESSLINE_DATA_QUALITY) { //'UK&I Marketing Services') {//
      if (asset.Part_Number__c != orderLineItem.Part_Number__c) {
        System.debug('---yes there are significant changes with BDQ--');
        return true;
      }
    } else {
        System.debug('--->'+asset.Product2Id + '===>'+orderLineItem.Product__c);
      if (asset.Product2Id != orderLineItem.Product__c) {
       System.debug('---there are significant changes with NONBDQ  Product__c--');
       return true;
      }
    }
     
    return false;
  }
  
  //===========================================================================
  // Assets to get updated with Renewal_Count__c++
  //===========================================================================
  private static void updateAssets (List<Asset> assetList) {
    //Updating values of Renewal count field
    // NLG - 2014-11-06 - this should be commented out because implemented in populateAssets
    for (Asset asset : assetList) {
        system.debug('asset.Renewal_Count__c ===>' +asset.Renewal_Count__c);
      if (asset.Renewal_Count__c != null) {
        system.debug('****IF Block***');
        asset.Renewal_Count__c = asset.Renewal_Count__c + 1;
      } else {
        asset.Renewal_Count__c = 1;
      }
    }
    
    try {
        System.debug('~~~~~~~~~~~~~~~~~'+assetList);
      upsert assetList;
    } catch (DMLException ex) {
      System.debug('[OrderLineTriggerHandler:updateAssets]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('OrderLineTriggerHandler','updateAssets', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        trigger.new.get(0).addError(ex.getDmlMessage(i));
      }     
    } 
  }
  
  //=====================================================================================================
  // Cancel Order Line when Order Line is deleted in SFDC: Send Order to On Demand: Order Line Item Trigger
  //=====================================================================================================
  private static void setOnDemandOrderLineToCancelled (Map<ID, Order_Line_Item__c> oldMap) {
    Set<String> orderIDs = new Set<String>();
    Map<String, Order__c> orderMap = new Map<String, Order__c>();
    //Map<String, Order_Line_Item__c> orderLineMap = new Map<String, Order_Line_Item__c>();
    date canceldate = date.today();
    
    for (Order_Line_Item__c ordLine : oldMap.values()) 
    {
      if (ordLine.Order__c != null && ordLine.EDQ_On_Demand_Product__c ==true ) 
      //check if the Order Line is for On Demand Product -->05/20/15
      //then add to a map
      {
        orderIDs.add(ordLine.Order__c);
        //ordLine.Cancellation_Date__c = canceldate; //cannot set the OrderLine Status to cancelled based on Order Line cancellation date.
        //orderLineMap.put(ordLine.ID,ordLine); //added 05/20/15
       }
    }
    
    
    //Querying order with Number of on demand order line items :make sure # of OrderLines with OD Product > 0
    for (Order__c ordr : [SELECT ID, Number_of_On_Demand_Order_Line_Items__c, EDQ_Send_to_On_Demand__c 
                           FROM Order__c 
                           WHERE Number_of_On_Demand_Order_Line_Items__c  > 0  
                           AND ID IN: orderIDs]) 
                           {
      if (!orderMap.containsKey(ordr.ID)) {
        ordr.EDQ_Send_to_On_Demand__c = true;
        ordr.Cancellation_Date__c = canceldate;
        orderMap.put(ordr.ID, ordr);
      }
    }
    
    try 
    {
      //If Order Lines have been cancelled then Save those Lines
       /* if (orderLineMap.size() > 0)
       {
            Update orderLineMap.values();
       } */

      //Update orders
      if (orderMap.size() > 0) 
      {
        update orderMap.values();
      }
    } catch (DMLException ex) {
      System.debug('[OrderLineTriggerHandler:setOnDemandOrderLineToCancelled]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('OrderLineTriggerHandler','setOnDemandOrderLineToCancelled', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        oldMap.values().get(0).addError(ex.getDmlMessage(i));
      }     
    }
  }
  
  
}