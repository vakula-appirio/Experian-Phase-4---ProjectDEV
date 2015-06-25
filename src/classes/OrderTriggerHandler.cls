/**=====================================================================
 * Appirio, Inc
 * Name: OrderTriggerHandler
 * Description: 
 * Created Date: Feb 5th, 2014 
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By       Description of the update
 * Feb 14th, 2014               Jinesh Goyal      Changed to 'without sharing'
 * Mar 18th, 2014               Naresh Kr Ojha    T-260146: Remove Opportunities from orderes if order cancelled.
 * Mar 19th, 2014               Megha Agarwal     T-260645: validate Service Dates and update on Order Line Items 
 *                                                validateServiceDates() , populateServiceDatesOnOLI()
 * Mar 19th, 2014               Naresh Kr Ojha    T-260044: processOrderClosing(), populateOrderAndOrderLineMaps(),
 *                                                createOpportunitiesForClosedOrders(), createOLIs_Team_ContactRoleForNewOppty()
 * Apr 1st, 2014                Naresh Kr Ojha    T-266919: Added describe call for recordType in method processOrderClosing()
 * Apr 02nd, 2014               Arpita Bose       T-268405: Renamed OLI's Service Start/end dates to Start/End dates
 * Apr 02nd, 2014               Arpita Bose       T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 03rd, 2014               Naresh Kr Ojha    T-268662: update validateServiceDates() to be less restrictive (allow date on Opp to
 *                                                overwrite OLI's dates if the Opp's date are outside of OLI's ranges)
 * Apr 03rd, 2014               Mohit Parnami     T-267423: Added createOrderSplitRecord Method to insert split record when order record is inserted.
 * Apr 07th, 2014               Nathalie Le Guay  Update to Order LI.Renewable__c as it becomes a picklist
 * Apr 08th, 2014               Naresh Kr Ojha    T-269988: Multi-Currency Dashboard: Order Trigger (added method multiCurrencyFieldUpdate())
 * Apr 08th, 2014               Arpita Bose       T-269372: Added addError()in try-catch block
 * Apr 08th, 2014               Nathalie Le Guay  Order LI.Renewable__c renamed to Type__c
 * Apr 11th, 2014               Naresh Kr Ojha    //As on T-260044: chatter by NLG dated Apr 11th, 2014 and to make renwable discussed on IM.
                                                  Modified method createOLIs_Team_ContactRoleForNewOppty()
 * Apr 10th, 2014               Nathalie Le Guay  Change oppLineItem.Renewable__c from checkbox to Type__c (picklist)
 * Apr 18th, 2014               Naresh Kr Ojha    Added containsKey check on Map to prevent null pointer exception on line # 446
 * Apr 22nd, 2014               Nathalie Le Guay  Commenting BU Relationship code
 * Apr 24th, 2014               Nathalie Le Guay  Update multiCurrencyFieldUpdate() to reset Conversion field on Order__c.Total__c update as well
 * Apr 28th, 2014               Arpita Bose       T-275717: Added LIMIT in multiCurrencyFieldUpdate() method to fix the Force.com Security Scanner Results
 * Apr 30th, 2014               Naresh Kr Ojha    I-113908: Update child record's currency when Order's currency updated.
 * May 01st, 2014               Arpita Bose       Updated catch(Exception) to catch(DMLException) to use getDMLException
 * Jul 07th, 2014               James Weatherall  Added updateOrderOwnerFields method to stamp the Owner values on creation
 * Sep 18th, 2014               GCS Team          Case #6608 - update to the updateOrderOwnerFields() to take a List as a param instead of a Map, and called on insert
 * Sep 19, 2014                 Nathalie Le Guay  Polymorphism: changed signature of methods defined in OrderInterface (all non-future or not called by future method)
 *                                                and implemented T-315219 to copy previous OLI's Renewal data to the new OLI's data fields
 * Sep 30th, 2014               Noopur            T-321616 : Code refactoring. commented the code for opp line item creation in the method createOLIs_Team_ContactRoleForNewOppty()
 * Oct 17th, 2014               Arpita Bose       T-326528: Updated method createOLIs_Team_ContactRoleForNewOppt()
 * Oct 20th, 2014               Naresh Kr Ojha    T-326947: Automatically Associate the Order Record with Each Opportunity Contact Address Record
                                                  added method updateOpportunityContactAddresses ();
 * Oct 20, 2014                 Nathalie Le Guay  I-135586: checks are made in the trigger because a WF Rule relies on the outcome. As of Winter 15 we cannot order
 *                                                the WF Rules. Adding checkOnDemandSyncRequired()
 * Oct 22nd, 2014               Arpita Bose       I-135839:Renewal Opp: Copy over the Royalty records: Updated method createOLIs_Team_ContactRoleForNewOppty()
 * Oct 28th, 2014               Naresh Kr Ojha    I-136491: added method populateAddressFieldsOnOrders() 
 * Oct 30th, 2014               Nathalie Le Guay  I-136848: copying over Opportunity.eRenewals_Locked__c and Opportunity.eRenewals_Exclude__c to the renewal opp
 * Nov 03rd, 2014               Nathalie Le Guay  I-137454: populating Total_Royalty__c from Renewal_Total_Royalty__c
 * Dec 04th, 2014               Naresh Kr Ojha    I-138599: Copying Opportunity_Contact_Addresses to renewal opportunity. 
 *                                                Updated methods createRenewalsOnUpdate(), createOLIs_Team_ContactRoleForNewOppty()
 * Dec 17th, 2014               Nathalie          I-143342: Update checkOnDemandSyncRequired() so that it won't set Send To EDQ on insert
 * Jan 28th, 2015               Nathalie Le Guay  I-146888: Replace OLI.Discount with OLI.CPQ_Discount__c
 * Feb 20th, 2015               James Weatherall  Case #540469: Created updateAssetIfOrderCancelled method to update Asset when Order is cancelled
 * Mar 03rd, 2015               Arpita Bose       T-366690: Updated createRenewalsOnUpdate() and methodcreateOLIs_Team_ContactRoleForNewOppty() to map 
 *                                                SaaS__c, SaaS_Product_Code__c on OLI
 * Mar 12th, 2015               Paul Kissick      Case #530104: Adding Competitors to EDQ renewals, and a few more fields to opportunity
 * Mar 20th, 2015               Paul Kissick      Case #595338: Only allow active products to be used when creating opp line items
 * Apr 04th, 2015               Naresh            T-374276: Poopulate segment fields on orders
 * Apr 07th, 2015               Arpita Bose       T-376294: Added method recalculateSegmentOnOrder()
 * Apr 13th, 2015               Paul Kissick      Case #607717: Added createCreditOrderIfCredited() method to create 'Credit Note' orders
 * Apr 14th, 2015               Naresh kr         T-377401: Added afterDelete and afterUnDelete methods to recalculate Account Segments
 * Apr 20th, 2015               Paul Kissick      Case #593979: EDQ related "Renewal Owner" changes 
 * Apr 27th, 2015               Nathalie Le Guay  I-156880: Populate renewalOpp.Amount with Order__c.Total__c
 * May 10th, 2015               Naresh Kr Ojha    I-161805: Updated method recalculateSegmentOnOrder() to check RT updated for order for activating order.
 =====================================================================*/
public virtual /*with sharing*/ class OrderTriggerHandler implements OrderInterface {
 
  public static Boolean updateFromOrderLI = false;
  private static Map<Id, Order_Line_Item__c> orderLineItemMap;
  public static String groupName;
  public static OrderInterface orderClass;
  public static Boolean hasRunAccountSegmentation = false;
  private static Map<Id,Id> oppsToNewOwner = new Map<Id,Id>{}; // PK Case #593979

  static {
    if (String.isEmpty(groupName)) {
      groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
      orderClass = newClassInstance();
    }
  }
  
  //==========================================================================
  //On before insert trigger method
  //==========================================================================
  public static void beforeInsert(List<Order__c> newOrders) {
    // commented NLG April 22nd 2014
    //BURelationshipCalculator.populateBUsOnCreate((List<SObject>) newOrders, Constants.SOBJECT_ORDER);

    orderClass.checkAccessOnAccountForUser(newOrders); 
    orderClass.populateAddressFieldsOnOrders(newOrders);//I-136491: Model Shipping and Billing Address on the Order
    orderClass.multiCurrencyFieldUpdate(newOrders, null);//T-269988: Multi-Currency Dashboard: Order Trigger - NLG called by OrderTrigger.Trigger
    orderClass.updateOrderOwnerFields(newOrders, null); // Case #4995 Update Owner fields //***
    //orderClass.checkOnDemandSyncRequired(newOrders, null); // I-135586

    if (!hasRunAccountSegmentation) {
      OrderTrigger_AccountSegmentation.populateSegmentsOnOrders(newOrders, null);//T-374276
      hasRunAccountSegmentation = true;
    }
  }

  //==========================================================================
  //On after insert trigger method
  //==========================================================================
  public static void afterInsert(Map<Id, Order__c> newOrdersMap) {
    //commented NLG April 22nd 2014
    //BURelationshipCalculator.populateParentBUs((Map<Id, SObject>) newOrdersMap, null);
    orderClass.createOrderSplitRecord(newOrdersMap);
    //T-260044: Renewal Opps/Orders: Order Closing behavior
    orderClass.processOrderClosing(newOrdersMap, null);
    //T-326947: Automatically Associate the Order Record with Each Opportunity Contact Address Record
    orderClass.updateOpportunityContactAddresses (newOrdersMap);
    //T-376294
    recalculateSegmentOnOrder (newOrdersMap, null); 
  }

  //==========================================================================
  //On before update trigger method
  //==========================================================================
  public static void beforeUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) {
    /* commented NLG April 22nd 2014
    BURelationshipCalculator.reAlignBUsOnOwnerChange((Map<Id, SObject>) newOrdersMap,
                                                     (Map<Id, SObject>) oldOrdersMap,
                                                     Constants.SOBJECT_ORDER);*/

    orderClass.deleteOppIfOrderCancelled (newOrdersMap, oldOrdersMap); 
    orderClass.updateAssetIfOrderCancelled (newOrdersMap, oldOrdersMap); // Case #540469
    orderClass.validateServiceDates(newOrdersMap, oldOrdersMap);
    orderClass.multiCurrencyFieldUpdate(newOrdersMap.values(), oldOrdersMap);// T-269988: Multi-Currency Dashboard: Order Trigger - NLG called by OrderTrigger.Trigger
    orderClass.updateOrderOwnerFields(newOrdersMap.values(), oldOrdersMap); // Case #4995 Update Owner fields //** 
    orderClass.checkOnDemandSyncRequired(newOrdersMap.values(), oldOrdersMap); // I-135586

    if (!hasRunAccountSegmentation) {
      OrderTrigger_AccountSegmentation.populateSegmentsOnOrders(newOrdersMap.values(), oldOrdersMap);//T-374276
      hasRunAccountSegmentation = true;
    }
  }
  
  //==========================================================================
  //On after update trigger method
  //==========================================================================
  public static void afterUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) {
    /* commented NLG April 22nd 2014
    BURelationshipCalculator.populateParentBUs((Map<Id, SObject>) newOrdersMap,
                                               (Map<Id, SObject>) oldOrdersMap);*/
    //T-260044: Renewal Opps/Orders: Order Closing behavior
    orderClass.processOrderClosing(newOrdersMap, oldOrdersMap); 
    orderClass.populateServiceDatesOnOLI(newOrdersMap, oldOrdersMap);
    orderClass.synchCurrencyISOCodes(newOrdersMap.values(), oldOrdersMap);//I-113908
    // PK 070515: Changed the order to run recalculateSegmentOnOrder last as it was interfering with the creditorder creation.
    // Case #607717 : Time to check for and create a 'Credit' order...
    orderClass.createCreditOrderIfCredited(newOrdersMap, oldOrdersMap);
    //T-376294
    recalculateSegmentOnOrder (newOrdersMap, oldOrdersMap);
    
  }
  
  //===========================================================================
  // On After Delete method
  //===========================================================================
  public static void afterDelete (Map<Id, Order__c> oldMap) {
  	
  	//T-377401 : Calculate Account Segmentations for Orders deleted
  	OrderTrigger_AccountSegmentation.accountSegmentCalculation(oldMap.values());
  }

  //===========================================================================
  // On After unDelete method
  //===========================================================================
  public static void afterUnDelete (Map<Id, Order__c> newMap) {
    
    //T-377401 : Calculate Account Segmentations for Orders undeleted
    OrderTrigger_AccountSegmentation.accountSegmentCalculation(newMap.values());
  }
  
  
  //=============================================================================================================================================
  // Executes on After Insert 
  // Check if Order.Opportunity__c is populated, if Yes, Retrieve the Opportunity Split values and for each record create order Split record.
  // if Order.Opportunity__c is not populated, creates a single order split record.
  //==============================================================================================================================================
  public virtual void createOrderSplitRecord(Map<Id, Order__c> newOrdersMap) {
    Map<Id, Set<Order__c>> mapOppPopulated_Orders = new Map<Id, Set<Order__c>>();
    Set<Order__c> setOrdersOppNotPopulated = new Set<Order__c>();
    Set<Id> setOwnerIds = new Set<Id>();
    for (Order__c order : newOrdersMap.values()) {
      if (order.Opportunity__c != null) {
        if (!mapOppPopulated_Orders.ContainsKey(order.Opportunity__c)) {
          mapOppPopulated_Orders.put(order.Opportunity__c, new set<Order__c>());
        }
        mapOppPopulated_Orders.get(order.Opportunity__c).add(order);
      } else {
        setOrdersOppNotPopulated.add(order);
        setOwnerIds.add(order.OwnerId);
      }
    }

    List<Order_Split__c> listSplitOrderToInsert = new List<Order_Split__c>();
    if (mapOppPopulated_Orders != null && mapOppPopulated_Orders.keySet().size() > 0) {
      for (OpportunitySplit oppSplit : [SELECT SplitNote, SplitOwnerId, SplitPercentage, SplitOwner.Sales_Team__c, SplitOwner.Global_Business_Line__c, 
                        OpportunityId, SplitOwner.Business_Unit__c, SplitOwner.Business_Line__c, SplitOwner.Sales_Sub_Team__c, CurrencyISOCode,
                        SplitOwner.Country__c, SplitOwner.Region__c      
                        FROM OpportunitySplit 
                        WHERE OpportunityId IN : mapOppPopulated_Orders.keySet() 
                        AND SplitType.IsTotalValidated = true]) {

        if (mapOppPopulated_Orders.containsKey(oppSplit.OpportunityId)) {
          for (Order__c orderRelatedToOpp : mapOppPopulated_Orders.get(oppSplit.OpportunityId)) {
            Order_Split__c orderSplit               = new Order_Split__c(); 
            orderSplit.Order__c                     = orderRelatedToOpp.Id;
            orderSplit.Split_Percentage__c          = oppSplit.SplitPercentage;
            orderSplit.OwnerId                      = oppSplit.SplitOwnerId;
            orderSplit.Split_Note__c                = OppSplit.SplitNote;
            orderSplit.Credited_To__c               = oppSplit.SplitOwnerId;
            orderSplit.Credited_To_GBL__c           = oppSplit.SplitOwner.Global_Business_Line__c;
            orderSplit.Credited_To_BU__c            = oppSplit.SplitOwner.Business_Unit__c;
            orderSplit.Credited_To_BL__c            = oppSplit.SplitOwner.Business_Line__c;
            orderSplit.Credited_To_Sales_Team__c    = oppSplit.SplitOwner.Sales_Team__c;
            orderSplit.Credited_To_Sales_Sub_Team__c = oppSplit.SplitOwner.Sales_Sub_Team__c;
            orderSplit.Credited_To_Country__c       = oppSplit.SplitOwner.Country__c;
            orderSplit.Credited_To_Region__c        = oppSplit.SplitOwner.Region__c;
            orderSplit.CurrencyISOCode              = oppSplit.CurrencyISOCOde;
            listSplitOrderToInsert.add(orderSplit);
          }
        }
      }
    }

    Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, Global_Business_Line__c, Business_Unit__c, Business_Line__c,
                                                      Sales_Team__c, Sales_Sub_Team__c, Country__c, Region__c
                                                FROM User
                                                WHERE Id in: setOwnerIds]);
    if (setOrdersOppNotPopulated != null && setOrdersOppNotPopulated.size() > 0) {
      for (Order__c orderWithNoOpp : setOrdersOppNotPopulated) {
        User owner = ownerMap.get(orderWithNoOpp.OwnerId);
        Order_Split__c orderSplit             = new Order_Split__c(); 
        orderSplit.Order__c                   = orderWithNoOpp.Id;
        orderSplit.Split_Percentage__c        = 100;
        orderSplit.OwnerId                    = orderWithNoOpp.OwnerId;
        orderSplit.Split_Note__c              = null;
        orderSplit.Credited_To__c             = orderWithNoOpp.OwnerId;
        orderSplit.Credited_To_GBL__c         = owner.Global_Business_Line__c;
        orderSplit.Credited_To_BU__c          = owner.Business_Unit__c;
        orderSplit.Credited_To_BL__c          = owner.Business_Line__c;
        orderSplit.Credited_To_Sales_Team__c  = owner.Sales_Team__c;
        orderSplit.Credited_To_Sales_Sub_Team__c = owner.Sales_Sub_Team__c;
        orderSplit.CurrencyIsoCode            = orderWithNoOpp.CurrencyIsoCode;
        orderSplit.Credited_To_Country__c     = owner.Country__c;
        orderSplit.Credited_To_Region__c      = owner.Region__c;
        listSplitOrderToInsert.add(orderSplit);
      }
    }

    if (!listSplitOrderToInsert.isEmpty()) {
      insert listSplitOrderToInsert;
    }
  }

  //==========================================================================
  // Check if the user trying to create an order has access to it or not.
  // That person needs to either be on the Account Team, or to be a superior of
  // a person on the Account Team
  //==========================================================================
  public virtual void checkAccessOnAccountForUser(List<Order__c> orderList) {
    List<String> accountIDList = new List<String>();

    String currentUserId = UserInfo.getUserId();
    Map<String, Boolean> hasAccessMap = new Map<String, Boolean>();

    for (Order__c orderRec: orderList) {
      if (orderRec.Account__c != null) {
        accountIDList.add(orderRec.Account__c);
      }
    }

    //Populating hasAccess map to check further access.
    for (UserRecordAccess userAccess  : [SELECT RecordId, HasEditAccess
                                         FROM UserRecordAccess 
                                         WHERE UserId = :currentUserId 
                                           AND RecordId = :accountIDList]) {
      if (!hasAccessMap.containsKey(userAccess.RecordId)) {
        hasAccessMap.put(userAccess.RecordId, userAccess.HasEditAccess);
      }
    }

    //Adding error if user do not have access on the record
    for (Order__c orderRec: orderList) {
      if (orderRec.Account__c != null && hasAccessMap.containsKey(orderRec.Account__c)) {
        if (hasAccessMap.get(orderRec.Account__c) != true) {
          orderRec.addError (Label.ORDER_DONTHAVEACCESS_MSG);
        }
      }
    }
  }


  //===========================================================================
  // Case #607717
  //===========================================================================
  public virtual void createCreditOrderIfCredited (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) {
    Map<Id,String> orderIdsWithTypeMap = new Map<Id,String>();
    for (Order__c ord : newMap.values()) {
      if (oldMap <> null && ord.Type__c == Constants.ORDER_TYPE_CREDITED && oldMap.get(ord.ID).Type__c != ord.Type__c) {
        // this should be the order to credit, so prepare it for cloning....
        orderIdsWithTypeMap.put(ord.Id, oldMap.get(ord.ID).Type__c);
      }
    }
    if (orderIdsWithTypeMap.size() > 0) {
      createCreditOrderIfCreditedInFuture(orderIdsWithTypeMap);
    }
  }
  
  //===========================================================================
  // TBD
  //===========================================================================
  @future
  public static void createCreditOrderIfCreditedInFuture (Map<Id,String> orderIdsWithTypeMap) {
    
    List<Order__c> ordClonesList = new List<Order__c>();
    Map<Order__c,Order__c> clonedOrderMap = new Map<Order__c,Order__c>();
    Set<Id> orderIds = orderIdsWithTypeMap.keySet();
    
    String queryString = 'SELECT ' + fetchObjectFields('Order__c');
    queryString += ',(SELECT '+ fetchObjectFields('Order_Line_Item__c') +' FROM Order_Line_Items__r)';
    queryString += ' FROM Order__c WHERE Id IN :orderIds';
    
    // clone and create new opportunity
    for (Order__c ord : Database.query(queryString) ) {
      Order__c newOrd = ord.clone();
      
      newOrd.EDQ_Integration_Id__c = null;
      // newOrd.Credited_Date__c = null; // Now want to keep this from the original order.
      newOrd.Order_to_Credit__c = ord.Id;
      newOrd.Close_Date__c = Date.today(); // Set close date to today
      // newOrd.Type__c = orderIdsWithTypeMap.get(ord.Id);
      newOrd.Type__c = Constants.ORDER_TYPE_CREDITED;
      newOrd.Finance_Invoice_Export_Batch__c = null;
      if (ord.FYR__c >= 0.0) newOrd.FYR__c = 0 - ord.FYR__c; // Always invert the value...
      if (ord.SYR__c >= 0.0) newOrd.SYR__c = 0 - ord.SYR__c; // Always invert the value...
      String newOrdName = ord.Name;
      if (newOrdName.startsWith('Order: ')) newOrdName = newOrdName.removeStartIgnoreCase('Order: ');
      newOrd.Name = Constants.ORDER_TYPE_CREDIT_NOTE + ': '+newOrdName;
      if (newOrd.Name.length() > 80) {
        newOrd.Name = newOrd.Name.substring(0, 80);
      }
      ordClonesList.add(newOrd);
      clonedOrderMap.put(newOrd,ord);
    }
    
    if ( !ordClonesList.isEmpty() ) {
      insert ordClonesList;
    }
    
    insertRelatedListOfClonedCreditOrd(clonedOrderMap);
  }
  
  //===========================================================================
  // Method to insert related list of the opportunities cloned
  //===========================================================================
  private static void insertRelatedListOfClonedCreditOrd ( Map<Order__c,Order__c> origClonedOrderMap) {
    // Will hold all the order line items from the original orders, to then get the royalties to clone
    Set<Id> orderLineItemIds = new Set<Id>();
    Set<Id> allOrderIds = new Set<Id>();
    
    // PK 070515: Adding a bunch of code because between insertion of the new order and calling of this method, the old order disappears from the map above.
    // PK 070515: I assume this is due to a change in the original old record, to the map is no longer valid.
    Map<Order__c,Order__c> clonedOrderMap = new Map<Order__c,Order__c>();
    
    for(Order__c ord : origClonedOrderMap.keySet()) {
      allOrderIds.add(ord.Id);
      allOrderIds.add(ord.Order_to_Credit__c);
    }
    
    String orderQueryString =  'SELECT ' + fetchObjectFields('Order__c');
    orderQueryString += ',(SELECT '+ fetchObjectFields('Order_Line_Item__c') +' FROM Order_Line_Items__r)';
    orderQueryString += ' FROM Order__c WHERE Id IN :allOrderIds';
    Map<Id,Order__c> ordMap = new Map<Id,Order__c>((List<Order__c>)Database.query(orderQueryString));
    for(Order__c newOrds : origClonedOrderMap.keySet()) {
      Id newOrdId = newOrds.Id;
      Id oldOrdId = newOrds.Order_to_Credit__c;
      clonedOrderMap.put(ordMap.get(newOrdId),ordMap.get(oldOrdId));
    }
    Map<Order_Line_Item__c,Order_Line_Item__c> clonedOrderLinesMap = new Map<Order_Line_Item__c,Order_Line_Item__c>();
    Map<Id,Id> oldToNewOrderItemMap = new Map<Id,Id>();
    
    try {
      
        // insert the related list of new Opportunity created. 
        List<Order_Line_Item__c> orderLineItemsToInsert = new List<Order_Line_Item__c>();
        List<Royalty__c> royaltiesToInsert = new List<Royalty__c>();
        
        //List<Order_Split__c> orderSplitsToInsert = new List<Order_Split__c>();
        OrderLineItemTriggerHandler.hasRunAssetCreation = true; // Used to bypass asset creation for new order lines.
        for ( Order__c newOrd : clonedOrderMap.keySet()) {
          for (Order_Line_Item__c oli : clonedOrderMap.get(newOrd).Order_Line_Items__r ) {
            Order_Line_Item__c oliNew = oli.Clone(false,true);
            orderLineItemIds.add(oli.Id);
            if (oli.Total__c >= 0.0) oliNew.Total__c = 0 - oli.Total__c; // Always invert the value...
            if (oli.EDQ_Margin__c >= 0.0) oliNew.EDQ_Margin__c = 0 - oli.EDQ_Margin__c;
            if (oli.Extended_Amount__c >= 0.0) oliNew.Extended_Amount__c = 0 - oli.Extended_Amount__c;
            if (oli.List_Price__c >= 0.0) oliNew.List_Price__c = 0 - oli.List_Price__c;
            if (oli.Partner_Amount__c >= 0.0) oliNew.Partner_Amount__c = 0 - oli.Partner_Amount__c;
            if (oli.Original_Item_value__c >= 0.0) oliNew.Original_Item_value__c = 0 - oli.Original_Item_value__c; // check this one...
            if (oli.Renewal_Discount_Amount__c >= 0.0) oliNew.Renewal_Discount_Amount__c = 0 - oli.Renewal_Discount_Amount__c;
            if (oli.Renewal_EDQ_Margin__c >= 0.0) oliNew.Renewal_EDQ_Margin__c = 0 - oli.Renewal_EDQ_Margin__c;
            if (oli.Renewal_Extended_Amount__c >= 0.0) oliNew.Renewal_Extended_Amount__c = 0 - oli.Renewal_Extended_Amount__c;
            if (oli.Renewal_List_Price__c >= 0.0) oliNew.Renewal_List_Price__c = 0 - oli.Renewal_List_Price__c;
            if (oli.Renewal_Partner_Amount__c >= 0.0) oliNew.Renewal_Partner_Amount__c = 0 - oli.Renewal_Partner_Amount__c;
            if (oli.Renewal_Sales_Price__c >= 0.0) oliNew.Renewal_Sales_Price__c = 0 - oli.Renewal_Sales_Price__c;
            if (oli.Renewal_Total_Royalty__c >= 0.0) oliNew.Renewal_Total_Royalty__c = 0 - oli.Renewal_Total_Royalty__c;
            if (oli.Total_Royalty__c >= 0.0) oliNew.Total_Royalty__c = 0 - oli.Total_Royalty__c;
            if (oli.Discount_Amount__c >= 0.0) oliNew.Discount_Amount__c = 0 - oli.Discount_Amount__c;
            oliNew.Order__c = newOrd.Id;
            //oliNew.Order_Type__c = Constants.ORDER_TYPE_CREDIT_NOTE;
            //oliNew.Type__c = Constants.ORDER_TYPE_CREDIT_NOTE;
            oliNew.EDQ_Integration_Id__c = null;
            orderLineItemsToInsert.add(oliNew);
            clonedOrderLinesMap.put(oliNew,oli);
          }
        }
        if ( !orderLineItemsToInsert.isEmpty() ) {
          insert orderLineItemsToInsert;
          
          // PK 280415 Pulling from class for now.
          // PK Commenting out 
          /*
          // build old order line id to new order line id map
          for(Order_Line_Item__c oli : clonedOrderLinesMap.keySet()) {
            oldToNewOrderItemMap.put(clonedOrderLinesMap.get(oli).Id,oli.Id);
            system.debug('Old ID : ' + clonedOrderLinesMap.get(oli).Id + ' **** New ID : '+oli.Id);
          }
          // Royalties are not directly linked to the order, but are from the order line item, so we have to query those
          
          String queryStringRoyalties = 'SELECT ' + fetchObjectFields('Royalty__c') + ' FROM Royalty__c WHERE Order_Line_Item__c IN :orderLineItemIds';
          
          for(Royalty__c ordRoyalty : Database.query(queryStringRoyalties)) {
            Royalty__c royNew = ordRoyalty.clone(false,true);
            if (royNew.Amount__c >= 0.0) royNew.Amount__c = 0 - ordRoyalty.Amount__c; // Always invert the value...
            if (royNew.Renewal_Royalty_Amount__c >= 0.0) royNew.Renewal_Royalty_Amount__c = 0 - ordRoyalty.Renewal_Royalty_Amount__c;
            if (royNew.Royalty_Amount__c >= 0.0) royNew.Royalty_Amount__c = 0 - ordRoyalty.Royalty_Amount__c;
            royNew.Order_Line_Item__c = oldToNewOrderItemMap.get(ordRoyalty.Id);
            royNew.EDQ_Integration_Id__c = null;
            royNew.Name = 'Credited: ' + ordRoyalty.Name; // Rename royalty to make it obvious
            royaltiesToInsert.add(royNew);
          } 
          
          */
          insert royaltiesToInsert;
            
          
        }
      }
      catch (DMLException ex) {
        system.debug('[OrderTriggerHandler: insertRelatedListOfClonedCreditOrd] Exception: ' + ex.getMessage());
        ApexLogHandler.createLogAndSave('OrderTriggerHandler','insertRelatedListOfClonedCreditOrd', ex.getStackTraceString(), ex);
      }
  }
 
  //===========================================================================
  // Method to fetch the fields related to an Object to create SQL query.
  //===========================================================================
  private static String fetchObjectFields ( String objName ) {
    Map<String, Schema.Sobjectfield> fieldSetMap = DescribeUtility.getObjectDescribe(objName).fields.getMap();
    List<String> fieldStrings = new List<String>();
    
    for (String str : fieldSetMap.keySet()) {
      fieldStrings.add(str);
    }

    return String.join(fieldStrings,',');
  }


  //T-260146: Remove Opportunities from orderes if order cancelled.
  public virtual void deleteOppIfOrderCancelled (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) {
    
    Set<String> opptiesToDelSet = new Set<String>();
    
    try {
      //checking for cancelled orderes.    
      for (Order__c ord : newMap.values()) {
        if (ord.Cancellation_Date__c <> null && oldMap.get(ord.ID).Cancellation_Date__c == null) {
          opptiesToDelSet.add(ord.Opportunity__c);
          ord.Opportunity__c = null;
        }
      }
      if (opptiesToDelSet.size() > 0) {
        deleteOppties (opptiesToDelSet);
      }
    } Catch (Exception ex) {
      System.debug('\n[OrderTriggerHandler: deleteOppIfOrderCancelled]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OrderTriggerHandler','deleteOppIfOrderCancelled', ex.getStackTraceString(), ex); 
      newMap.values().get(0).addError(ex.getMessage());
      }
  }


  // Start: Case #540469 - 20/02/2015 - James Weatherall
  public virtual void updateAssetIfOrderCancelled (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) {
    
    Map<Id, Date> assetOrdersToUpdateMap = new Map<Id, Date>();
    List<Asset> lstAssetsToUpdate = new List<Asset>();
      
    try {
      //checking for cancelled orderes.    
      for (Order__c ord : newMap.values()) {
        if (ord.Cancellation_Date__c <> null && oldMap.get(ord.ID).Cancellation_Date__c == null) {
          assetOrdersToUpdateMap.put(ord.ID, ord.Cancellation_Date__c);
        }
      }
      for (Asset assetToUpdate : [SELECT Id, Order__c, Cancellation_Date__c, Status, Cancellation_Reason__c
                                 FROM Asset
                                 WHERE Order__c IN: assetOrdersToUpdateMap.keySet()])
      {
        assetToUpdate.Status = 'Cancelled';
        assetToUpdate.Cancellation_Date__c = assetOrdersToUpdateMap.get(assetToUpdate.Order__c); 
        lstAssetsToUpdate.add(assetToUpdate);
      }
      if (lstAssetsToUpdate.size() > 0) {
        update lstAssetsToUpdate;
      }        
    } Catch (Exception ex) {
      System.debug('\n[OrderTriggerHandler: updateAssetIfOrderCancelled]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OrderTriggerHandler','updateAssetIfOrderCancelled', ex.getStackTraceString(), ex); 
      newMap.values().get(0).addError(ex.getMessage());
      }
  }
  // End


  //Deleting opportunities from future, as it do not allow opportunities to delete, when it is
  //associated with any order.
  @future
  public static void deleteOppties (Set<String> opptyIDs) {
    List<Opportunity> opptyListToDelete = new List<Opportunity>();
    //Querying opportunities to get deleted and calling delete
    
    for (Opportunity oppty : [SELECT ID FROM Opportunity WHERE ID IN : opptyIDs]) {
      opptyListToDelete.add(oppty);
    }
    if (!opptyListToDelete.isEmpty()) {
      delete opptyListToDelete;
    }
  }
  
  //T-260044: Renewal Opps/Orders: Order Closing behavior
  //This method is to create new Opportunities, Oppty lines, ContactRole and Team when
  //an order get closed (locked/readonly).
  public virtual void processOrderClosing (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) {
    String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY); 

    Set<ID> closedOrderIDs = new Set<ID>();

    //Filtering locked orders
    for (Order__c ord : newMap.values()) {
      if (oldMap <> null && 
           (ord.RecordTypeID != orderReadOnlyRT_ID
         || ord.Type__c == Constants.ORDERTYPE_TRIAL
         || ord.Type__c == Constants.ORDER_TYPE_CREDIT_NOTE
         || (ord.RecordTypeID == orderReadOnlyRT_ID && oldMap.get(ord.ID).RecordTypeID == orderReadOnlyRT_ID))) {
        continue;
      }
      //When record type changed and current RT is read only
      if (ord.RecordTypeID == orderReadOnlyRT_ID) {
        closedOrderIDs.add(ord.ID);
      }
    }
    //Future call for insert action
    if (closedOrderIDs.size() > 0 && oldMap == null) {
      if (!System.isFuture()) {
        createRenewalsOnInsert(closedOrderIDs);
      } else {
        createRenewalsOnUpdate(closedOrderIDs);
      }
    } else if (closedOrderIDs.size() > 0 && oldMap != null) {
      createRenewalsOnUpdate (closedOrderIDs);
    }
  } 
  
  @future
  public static void createRenewalsOnInsert (Set<ID> closedOrderIDs) {
    createRenewalsOnUpdate (closedOrderIDs);
  }
  
  public static void createRenewalsOnUpdate (Set<ID> closedOrderIDs) {
    Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map = 
                                    new Map<String, List<Order_Line_Item__c>>();
    Map<String, Order__c> ordId_ClosedOrderMap = new Map<String, Order__c>();
    List<Opportunity> opptyListInserted = new List<Opportunity>();
    Set<String> oldOpptyIDs = new Set<String>();
    Map<String, Opportunity> opptyID_oldOpptyMap = new Map<String, Opportunity>();    


    //Populate Closed order map and its order lines to map (grouped by service end date)
    populateOrderAndOrderLineMaps(closedOrderIDs, ordId_ClosedOrderMap, serviceDate_orderLineItemList_Map);

    //Create Opportunities for closed orders
    if (ordId_ClosedOrderMap.size() > 0 && serviceDate_orderLineItemList_Map.size() > 0) {
      opptyListInserted = createOpportunitiesForClosedOrders (ordId_ClosedOrderMap, serviceDate_orderLineItemList_Map);
    }

    //Populate old opportunity map.
    if (opptyListInserted.size() > 0) {
      for (Opportunity newOppty : opptyListInserted) {
        if (newOppty.Previous_Opportunity__c <> null) {
          oldOpptyIDs.add(newOppty.Previous_Opportunity__c);
        }
      }
      for (Opportunity oppty : [SELECT ID, Name, Contract_Start_Date__c, Contract_End_Date__c, CurrencyISOCode, Capability__c, Product_Group__c,
                                  Channel_Type__c, Proposal_Type__c, Budget__c, Invoice_to_End_User__c,
                                  Owner_BU_on_Opp_Close_Date__c, Type, // PO_Required__c,  // PK: Case #593979
                                      (SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, User.IsActive
                                         FROM OpportunityTeamMembers), 
                                      (SELECT Id, OpportunityId, Quantity, UnitPrice, PricebookEntryId, Start_Date__c, End_Date__c,
                                              Renewal_Discount__c, Renewal_Discount_Amount__c, Renewal_EDQ_Margin__c,
                                              Renewal_Extended_Amount__c, Renewal_Partner__c, Renewal_Partner_Amount__c,
                                              Renewal_Registration__c, Renewal_Sale_Price__c, Renewals_Exclude__c,
                                              EDQ_Margin__c, EDQ_On_Demand_Product__c, // T-322945:EDQ specific fields are added
                                              No_Update__c,
                                              Extended_Amount__c, Partner_Amount__c,
                                              Order_Type__c, Program_Required__c, Opportunity_Country__c,
                                              Data_Required__c, Manuals_Required__c, Delivery_Method__c, Program_Media__c,
                                              Data_Media__c, Quantity_Type__c, Data_Usage__c, Product_Family__c, Hardware__c,
                                              Implementation__c, Compiler__c, Update_Frequency__c,
                                              Manual_Registration__c, Click_Expiry__c, Description,
                                              No_Delivery__c, Precise_Day_License__c, //On_Demand__c,  This field removed from the object
                                              Operating_System__c, Part_Number__c, Discount_Amount__c,
                                              Partner__c, 
                                              Item_Quantity__c, Users_From__c, Users_To__c, Application__c,
                                              CRM_Product_Name__c, Product_Code__c, Product_Reference__c, Product_Data__c,
                                              Product_Release_Name__c, Registration_Key__c,
                                              Release__c, Distribution_Notes__c, Despatch_Status__c, Delivery_Time__c,
                                              Major_Version__c, CD_Name__c, Data_Installer_Password__c, Release_Reference__c,
                                              Total_Royalty__c, Renewal_Total_Royalty__c, Item_Number__c, Quote_Number__c,
                                              eRenewal_Exception__c, Original_Asset_ID__c, Product_Upgrade__c, Type__c, 
                                              Price_Category__c, Media_Quantity__c, Renewal_List_Price__c, CPQ_Quantity__c,
                                              SaaS__c, SaaS_Product_Code__c //T-366690
                                         FROM OpportunityLineItems), 
                                      (SELECT Id, OpportunityId, ContactId, Role, IsPrimary, Contact.Inactive__c
                                         FROM OpportunityContactRoles),
                                      (SELECT Id, Account__c, Amount__c, Application__c, Comments__c, Implementation__c, Operating_System__c, Opportunity__c,
                                              Name, Product_Family__c, Product_Name__c, Provider_Code__c, Provider_Name__c, Quantity_From__c, Quantity_To__c,
                                              Quantity_Type__c, Release__c, Renewal_Royalty_Amount__c, Royalty_Amount__c, Royalty_Group_Reference__c,
                                              Quote_Number__c, Line_Item_Reference_Number__c,
                                              Royalty_Type__c From Royalties__r) // I-135839
                                      /*(SELECT Id, Name, CurrencyIsoCode, Opportunity__c, Address__c, Role__c, Contact__c, Update_Record__c, Address_1__c, 
                                              Address_2__c, City__c, State__c, Post_Code__c, Country__c, Order__c, Contact_s_Account__c, Address_CRMOD_Id__c, 
                                              Bar_Code__c, Contact_EDQ_Integration_ID__c, Account_EDQ_Integration_ID__c, Address_EDQ_Integration_ID__c 
                                         FROM Opportunity_Contact_Addresses__r)  // I-138599 - Issue backlogged */
                                         ,(SELECT Id, Opportunity__c, Account__c FROM Competitors__r)
                                FROM Opportunity 
                                WHERE ID IN: oldOpptyIDs]) {
        opptyID_oldOpptyMap.put(oppty.ID, oppty);
      }
      //create:- opportunity Line Items:
      //Create Opportunity Contact Role
      //Copy opportunity team    
      
      createOLIs_Team_ContactRoleForNewOppty (opptyListInserted, opptyID_oldOpptyMap, ordId_ClosedOrderMap, serviceDate_orderLineItemList_Map);
    }
    
  }
  
  //Populate Closed order map and its order lines to map (grouped by service end date)
  public static void populateOrderAndOrderLineMaps (Set<ID> closedOrderIDs, 
                                      Map<String, Order__c> ordId_ClosedOrderMap, 
          Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map
                                      ) {
    
    //Retrieve all Order Line Items where Type__c='Renewal' GROUP BY Service End Date
    for (Order__c ord : [SELECT OwnerId, Name, Opportunity__r.Name, Opportunity__r.Capability__c, Opportunity__r.Budget__c, Opportunity__r.Proposal_Type__c,
                                               Opportunity__r.Channel_Type__c,  Opportunity__r.Invoice_to_End_User__c, Opportunity__r.Product_Group__c,
                                               Opportunity__r.Type, // PK Case 593979
                                               CurrencyISOCode, Opportunity__c, Contact__c, Total__c,
                                               Id, Contract_Start_Date__c, Contract_End_Date__c, Account__c, 
                                               Opportunity__r.eRenewals_Locked__c, Opportunity__r.eRenewals_Exclude__c,
                                               (SELECT Id, Order__c,  Quantity__c, Sales_Price__c, Start_Date__c,
                                                         Type__c, Product__c, End_Date__c, Billing_Product__c,
                                                         Opportunity_Line_Item_Id__c, Item_Number__c, Quote_Number__c,
                                                         Part_Number__c
                                                FROM Order_Line_Items__r 
                                                WHERE Type__c =: Constants.ORDER_RENEWAL) 
                         FROM Order__c 
                        WHERE ID IN : closedOrderIDs]) {
      //Order map for closed orders.
      ordId_ClosedOrderMap.put(ord.ID, ord);
      //Renewable Order lines for closed orders
      for (Order_Line_Item__c orderLine : ord.Order_Line_Items__r) {
        if (orderLine.End_Date__c == null) {
          system.debug('\nOrder Line ENd Date: '+ orderLine.End_Date__c);
          continue;
        }
        
        if (!serviceDate_orderLineItemList_Map.containsKey(String.valueOf(orderLine.End_Date__c))) {
          serviceDate_orderLineItemList_Map.put(String.valueOf(orderLine.End_Date__c), new List<Order_Line_Item__c>());
        }
        serviceDate_orderLineItemList_Map.get(String.valueOf(orderLine.End_Date__c)).add(orderLine);
      }//End of innner for.
    }//End of outer for.
  }
  
  //Create new Opportunity per grouping
  public static List<Opportunity> createOpportunitiesForClosedOrders (Map<String, Order__c> ordId_ClosedOrderMap,
                          Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map) {
    List<Opportunity> opportunityList = new List<Opportunity>();
    Opportunity newOppty;
    Order_Line_Item__c currentOrderLine;
    try {
      //Create new Opportunity per grouping
      for (String key : serviceDate_orderLineItemList_Map.keySet()) {
        //If no order line for the grouped service end date, skip to create oppty
        if (serviceDate_orderLineItemList_Map.get(key).size () < 1) {
          continue;
        }
  
        currentOrderLine = serviceDate_orderLineItemList_Map.get(key).get(0);

        Order__c oldOrder = ordId_ClosedOrderMap.get(currentOrderLine.Order__c);
        newOppty                          = new Opportunity();  
        //First order line to crate Opportunity
        newOppty.OwnerId                  = oldOrder.OwnerId;
        //Query: what exactly should the opportunity name be?
        if (oldOrder.Opportunity__c != null) {
          newOppty.Name                     = (oldOrder.Opportunity__r.Name.length() + 'xx-xxxx'.length() > 80) ?
                                              oldOrder.Opportunity__r.Name.substring(0, 80-' - xx-xxxx'.length()) + ' - ' + Date.today().month() + '-' + Date.today().year() :
                                              oldOrder.Opportunity__r.Name + ' - ' + Date.today().month() + '-' + Date.today().year();
        } else {
          newOppty.Name                     = oldOrder.Name + ' - ' + Date.today().month() + '-' + Date.today().year();
        }
        newOppty.Amount                   = oldOrder.Total__c;
        newOppty.Previous_Opportunity__c  = oldOrder.Opportunity__c;
        newOppty.AccountId                = oldOrder.Account__c; //NLG apr 7th - was Opportunity__r.AccountID;
        newOppty.Previous_Order__c        = currentOrderLine.Order__c;
        newOppty.CloseDate                = currentOrderLine.End_Date__c;
        newOppty.Type                     = Constants.OPPTY_TYPE_RENEWAL;
        newOppty.StageName                = Constants.OPPTY_STAGE_4;
        newOppty.Starting_Stage__c        = Constants.OPPTY_STAGE_4;
        newOppty.CurrencyIsoCode          = oldOrder.CurrencyIsoCode;
        newOppty.eRenewals_Exclude__c     = oldOrder.Opportunity__r.eRenewals_Exclude__c; // I-136848
        newOppty.eRenewals_Locked__c     = oldOrder.Opportunity__r.eRenewals_Locked__c; // I-136848
        newOppty.Capability__c            = oldOrder.Opportunity__r.Capability__c;
        newOppty.Budget__c                = oldOrder.Opportunity__r.Budget__c;
        newOppty.Proposal_Type__c         = oldOrder.Opportunity__r.Proposal_Type__c;
        
        Boolean isEdqUser = false;
        // EDQ Specific code
        String bussUnitName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
        if (String.isNotBlank(bussUnitName) && bussUnitName.equalsIgnoreCase(Constants.EDQ)) isEdqUser = true;
        // if (newOppty.Previous_Opportunity__c != null && oldOpptyMap.containsKey(newOppty.Previous_Opportunity__c)) {
        if (isEdqUser) {
            // Case #530104 - Additional fields to clone
            newOppty.Product_Group__c       = oldOrder.Opportunity__r.Product_Group__c;
            newOppty.Channel_Type__c        = oldOrder.Opportunity__r.Channel_Type__c;
            newOppty.Invoice_to_End_User__c = oldOrder.Opportunity__r.Invoice_to_End_User__c;
        }

        if (oldOrder.Contract_End_Date__c <> null) {
          newOppty.Contract_Start_Date__c = oldOrder.Contract_End_Date__c.addDays(1);
        }
        if (newOppty.Contract_Start_Date__c <> null && oldOrder.Contract_End_Date__c <> null && oldOrder.Contract_Start_Date__c <> null) {
          newOppty.Contract_End_Date__c   = newOppty.Contract_Start_Date__c.addDays(oldOrder.Contract_Start_Date__c.daysBetween(oldOrder.Contract_End_Date__c)); 
        }
          //As on chatter for task T-260044. 
        
        opportunityList.add(newOppty);   
      }
      
      if (!opportunityList.isEmpty()) {
        insert opportunityList;
      }
    } catch (DMLException ex) {
      System.debug('\n[OrderTriggerHandler: createOpportunitiesForClosedOrders]: [' + ex.getMessage() + ']]');
      apexLogHandler.createLogAndSave('OrderTriggerHandler','createOpportunitiesForClosedOrders', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        opportunityList.get(0).addError(ex.getDmlMessage(i));
      }
    }

    return opportunityList;
  }
  
  //populates opportunity lines to insert further.
  public static void createOLIs_Team_ContactRoleForNewOppty (List<Opportunity> newOpptyList, 
                                    Map<String, Opportunity> oldOpptyMap,
                                    Map<String, Order__c> ordId_ClosedOrderMap,
                                    Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map) {
    system.debug('<<<<createOLIs_Team_ContactRoleForNewOppty>>>>');
                                    	
    //Insert is to be processed with below list.
    List<OpportunityLineItem> opptyLinesToInsert = new List<OpportunityLineItem>();
    List<OpportunityContactRole> opptyContactRolesToInsert = new List<OpportunityContactRole>();
    List<OpportunityTeamMember> opptyTeamToInsert = new List<OpportunityTeamMember>();
    // List<Opportunity_Contact_Address__c> opptyContactAddressList = new List<Opportunity_Contact_Address__c>(); I-138599 backlogged
    
    Map<String, String> productID_PriceBookEntryIDMap = new Map<String, String>();
    Set<String> productIDs = new Set<String>();
    List<Opportunity> opportunityList = new List<Opportunity>();
    Map<String, List<Opportunity>> ordId_newOpptyListMap = new Map<String, List<Opportunity>>();
    List<Royalty__c> royaltiesToInsert = new List<Royalty__c>();
    List<Competitor__c> competitorsToInsert = new List<Competitor__c>();

    if (newOpptyList.size() > 0) {
      for (Opportunity oppty : newOpptyList) {
        if (oppty.Previous_Order__c == null) {
         continue;
        }
        if (!ordId_newOpptyListMap.containsKey(oppty.Previous_Order__c)) {
          ordId_newOpptyListMap.put(oppty.Previous_Order__c, new List<Opportunity>());
        }
        ordId_newOpptyListMap.get(oppty.Previous_Order__c).add(oppty);
      }
    }
        
    for (Order__c ord : ordId_ClosedOrderMap.values()) {
      for (Order_Line_Item__c ordLine : ord.Order_Line_Items__r) {
        productIDs.add(ordLine.Product__c);
      }
    }
    for (PricebookEntry pbe : [SELECT Id, Product2ID, CurrencyIsoCode FROM PricebookEntry 
                               WHERE Product2ID IN: productIDs AND
                               Product2.IsActive = true AND      // PK Case #595338 - Only return active products, as opp lines cannot be added for inactive products
                                     Pricebook2.Name =: Constants.STANDARD_PRICE_BOOK]) {
      productID_PriceBookEntryIDMap.put(pbe.Product2ID+'~~'+pbe.CurrencyIsoCode, pbe.ID);
    }
    if (Test.isRunningTest()) {
        for (PricebookEntry pbe : [SELECT Id, Product2ID, CurrencyIsoCode FROM PricebookEntry 
                               WHERE Product2ID IN: productIDs AND PriceBook2Id = :Test.getStandardPricebookId()]) {
      productID_PriceBookEntryIDMap.put(pbe.Product2ID+'~~'+pbe.CurrencyIsoCode, pbe.ID);
        }
    }

    Map<String, OpportunityLineItem> oliMap = new Map<String, OpportunityLineItem>();
    for (Opportunity oppty : oldOpptyMap.values()) {
      for (OpportunityLineItem oppLI: oppty.OpportunityLineItems) {
        oliMap.put(oppLI.Id, oppLI);
      }
    }
    OpportunityLineItem oli;
    OpportunityContactRole opptyContRole;
    OpportunityTeamMember opptyTeamMember;
    Royalty__c newRoyalty;
    Competitor__c newCompetitor;
    
    try {
      Set<String> fieldsToBeSync = getFieldsToBeSynched();
          
      for (String orderId : ordId_ClosedOrderMap.keySet()) {
        if (!ordId_newOpptyListMap.containsKey(orderId)) {
          continue;
        }
        System.debug('===ordId_newOpptyListMap.get(orderId)>>>' +ordId_newOpptyListMap.get(orderId));
        for (Opportunity newOppty : ordId_newOpptyListMap.get(orderId)) {
          Set<String> contactsWithRoles = new Set<String>(); // Will be used to prevent duplication later
          
          Boolean isEdqUser = false;
          // EDQ Specific code
          String bussUnitName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
          if (String.isNotBlank(bussUnitName) && bussUnitName.equalsIgnoreCase(Constants.EDQ)) isEdqUser = true;
          
          for (String keyDate: serviceDate_orderLineItemList_Map.keySet()) {
            for (Order_Line_Item__c ordLine : serviceDate_orderLineItemList_Map.get(keyDate)) { //ordId_ClosedOrderMap.get(orderId).Order_Line_Items__r) 
              
              if (newOppty.CloseDate != ordLine.End_Date__c) {
                continue;
              }
              
              if (ordLine.Product__c <> null && 
                  productID_PriceBookEntryIDMap.containsKey(ordLine.Product__c+'~~'+newOppty.CurrencyISOCode)) {
                oli                 = new OpportunityLineItem();
                
                //oli.Start_Date__c   = ordLine.End_Date__c.addDays(1);
                //oli.End_Date__c     = oli.Start_Date__c.addDays(ordLine.Start_Date__c.daysBetween(ordLine.End_Date__c)); 
                
                //As on T-260044: chatter by NLG dated Apr 11th, 2014 and to make renwable discussed on IM.
                oli.Start_Date__c = newOppty.Contract_Start_Date__c;
                oli.End_Date__c = newOppty.Contract_End_Date__c;
                oli.Type__c = Constants.OPPTY_TYPE_RENEWAL;
                oli.Order_Type__c = Constants.OPPTY_TYPE_RENEWAL;
                oli.Item_Number__c = ordLine.Item_Number__c;
                oli.Quote_Number__c = ordLine.Quote_Number__c;
                oli.Quantity        = ordLine.Quantity__c;
                oli.Part_Number__c = ordLine.Part_Number__c;
                
                oli.OpportunityId   = newOppty.ID;
                oli.Billing_Product__c = ordLine.Billing_Product__c;
                oli.PricebookEntryId = productID_PriceBookEntryIDMap.get(ordLine.Product__c+'~~'+newOppty.CurrencyISOCode);
                oli.Original_Opportunity_Line_Item_Id__c = ordLine.Opportunity_Line_Item_Id__c;
                //T-366690
                if (oliMap.containsKey(ordLine.Opportunity_Line_Item_Id__c)) {
                    OpportunityLineItem originalLI = oliMap.get(ordLine.Opportunity_Line_Item_Id__c);
                    oli.SaaS__c      = originalLI.SaaS__c;
                    oli.SaaS_Product_Code__c = originalLI.SaaS_Product_Code__c;
                }    
                // EDQ Specific code HERE - cannot be added to OrderTriggerHandler_EDQ because this method is called by @future,
                // and future methods cannot be extended
                String buName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
                if (String.isNotBlank(buName) && buName.equalsIgnoreCase(Constants.EDQ)) {
                  if (oliMap.containsKey(ordLine.Opportunity_Line_Item_Id__c)) {
                    OpportunityLineItem originalLI = oliMap.get(ordLine.Opportunity_Line_Item_Id__c);
                    //oli.Renewal_Sale_Price__c = originalLI.Renewal_Sale_Price__c;
                    oli.CPQ_Discount__c /*oli.Discount*/ = originalLI.Renewal_Discount__c; // I-146888
                    oli.Discount_Amount__c    = originalLI.Renewal_Discount_Amount__c;
                    oli.EDQ_Margin__c         = originalLI.Renewal_EDQ_Margin__c;
                    oli.Extended_Amount__c    = originalLI.Renewal_Extended_Amount__c;
                    oli.Partner__c            = originalLI.Renewal_Partner__c;
                    oli.Partner_Amount__c     = originalLI.Renewal_Partner_Amount__c;
                    oli.Manual_Registration__c= originalLI.Renewal_Registration__c;
                    oli.UnitPrice             = originalLI.Renewal_Sale_Price__c;
                    oli.Total_Royalty__c      = originalLI.Renewal_Total_Royalty__c;
                    //Converted field listing to iteration on Set as discussed with Nathalie: Oct 28th, 2014.
                    for (String fieldName : fieldsToBeSync) {
                      oli.put(fieldName, originalLI.get(fieldName));
                    }
                    
                  }
                }
                if ( oli.UnitPrice == null) {
                  oli.UnitPrice       = ordLine.Sales_Price__c;
                }
                
                opptyLinesToInsert.add(oli);
                System.debug('==opptyLinesToInsert>>>' +opptyLinesToInsert);
              }
            }
          }
          System.debug('==OpptyID >>>' +newOppty.Id);
          opptyContRole               = new OpportunityContactRole();
          opptyContRole.ContactId     =  ordId_ClosedOrderMap.get(orderId).Contact__c;
          opptyContRole.OpportunityId = newOppty.Id; //T-326528
          opptyContRole.Role          = Constants.DECIDER;
          opptyContRole.IsPrimary     = true; //nojha: as per comments/discussion NLG with Luke M. S-191796
          opptyContactRolesToInsert.add(opptyContRole);

          System.debug('==opptyContactRolesToInsert >>>' +opptyContactRolesToInsert);
          
          if (newOppty.Previous_Opportunity__c != null && oldOpptyMap.containsKey(newOppty.Previous_Opportunity__c)) {
            for (OpportunityTeamMember otm: oldOpptyMap.get(newOppty.Previous_Opportunity__c).OpportunityTeamMembers) {
              if (otm.User.IsActive) {
                // PK Case #593979 - Find the renewal owner role
                  /* // PK Commenting out for now (28/04/15) until this can be tested again.
                  if (otm.TeamMemberRole != null && otm.TeamMemberRole == Constants.TEAM_ROLE_RENEWAL_OWNER && isEdqUser) {
                    if (oldOpptyMap.get(newOppty.Previous_Opportunity__c).Type != null && oldOpptyMap.get(newOppty.Previous_Opportunity__c).Type.startsWithIgnoreCase('New')) {
                      // now we know the renewal opp owner for new opps...
                      oppsToNewOwner.put(newOppty.Id,otm.UserId);
                    }
                  }
                  */
                opptyTeamMember = new OpportunityTeamMember();
                opptyTeamMember.OpportunityId = newOppty.Id;  // PK Case #593979: Fixed incorrect assignment
                opptyTeamMember.TeamMemberRole = otm.TeamMemberRole;
                opptyTeamMember.UserId = otm.UserId;
                opptyTeamToInsert.add(opptyTeamMember);
              }
            }
            // PK Case #593979
            /* // PK Commenting out for now (28/04/15) until this can be tested again.
            if (isEdqUser && !oppsToNewOwner.containsKey(newOppty.Id)) {
              // missing, so find alternative owner...
              String checkOppBU = oldOpptyMap.get(newOppty.Previous_Opportunity__c).Owner_BU_on_Opp_Close_Date__c;
              if (String.isNotBlank(checkOppBU)) {
                oppsToNewOwner.put(newOppty.Id,BusinessUnitUtility.getAltRenewalOwner(checkOppBU));
              }
            }
            */
          }
          
          // I-135839 : Copy Original Opp's Royalty records on Renewal Oppty
          if (newOppty.Previous_Opportunity__c != null && oldOpptyMap.containsKey(newOppty.Previous_Opportunity__c)) {
            for (Royalty__c royalty : oldOpptyMap.get(newOppty.Previous_Opportunity__c).Royalties__r ) {
              newRoyalty = new Royalty__c();
              newRoyalty.Name = royalty.Name;
              newRoyalty.Royalty_Type__c = royalty.Royalty_Type__c;
              //newRoyalty = royalty.Clone(false,false);
              newRoyalty.Opportunity__c = newOppty.Id;
              newRoyalty.Account__c = royalty.Account__c;
              newRoyalty.Amount__c = royalty.Amount__c;
              newRoyalty.Application__c = royalty.Application__c;
              newRoyalty.Comments__c = royalty.Comments__c;
              newRoyalty.Implementation__c = royalty.Implementation__c;
              newRoyalty.Line_Item_Reference_Number__c = royalty.Line_Item_Reference_Number__c;
              newRoyalty.Operating_System__c = royalty.Operating_System__c;
              newRoyalty.Product_Family__c = royalty.Product_Family__c;
              newRoyalty.Product_Name__c = royalty.Product_Name__c;
              newRoyalty.Provider_Code__c = royalty.Provider_Code__c;
              newRoyalty.Provider_Name__c = royalty.Provider_Name__c;
              newRoyalty.Quantity_From__c = royalty.Quantity_From__c;
              newRoyalty.Quantity_To__c = royalty.Quantity_To__c;
              newRoyalty.Quantity_Type__c = royalty.Quantity_Type__c;
              newRoyalty.Quote_Number__c = royalty.Quote_Number__c;
              newRoyalty.Release__c = royalty.Release__c;
              newRoyalty.Renewal_Royalty_Amount__c = royalty.Renewal_Royalty_Amount__c;
              newRoyalty.Royalty_Amount__c = royalty.Royalty_Amount__c;
              newRoyalty.Royalty_Group_Reference__c = royalty.Royalty_Group_Reference__c;
              
              royaltiesToInsert.add(newRoyalty);
              
              System.debug('royaltiesToInsert>>>>' +royaltiesToInsert);
            }
            // Case #530104 - Requires more information copied over...
            if (isEdqUser) {
              for (Competitor__c competitor : oldOpptyMap.get(newOppty.Previous_Opportunity__c).Competitors__r ) {
                newCompetitor = new Competitor__c();
                newCompetitor.Opportunity__c = newOppty.Id;
                newCompetitor.Account__c = competitor.Account__c;
                competitorsToInsert.add(newCompetitor);
              }
            }
            /*for (Opportunity_Contact_Address__c opptyContAdd : oldOpptyMap.get(newOppty.Previous_Opportunity__c).Opportunity_Contact_Addresses__r) {
              Opportunity_Contact_Address__c newOpptyContAdd = opptyContAdd.clone();
              newOpptyContAdd.Opportunity__c = newOppty.ID;
              opptyContactAddressList.add(newOpptyContAdd);
            }
            for (OpportunityContactRole contactRole: oldOpptyMap.get(newOppty.Previous_Opportunity__c).OpportunityContactRoles) {
              opptyContRole               = new OpportunityContactRole();
              opptyContRole.ContactId     = contactRole.ContactId;
              opptyContRole.OpportunityId = newOppty.Id; //T-326528
              opptyContRole.Role          = contactRole.Role;
              opptyContactRolesToInsert.add(opptyContRole);
              System.debug('\nNEW CONTACT ROLE: '+ opptyContRole);
            } Issue I-138599 and I-144842 backlogged */
          }
          
        }
      }
      
      if (!opptyLinesToInsert.isEmpty()) {
        insert opptyLinesToInsert;
      }
      if (!opptyContactRolesToInsert.isEmpty()) {
        insert opptyContactRolesToInsert;
      }
      if (!opptyTeamToInsert.isEmpty()) {
        insert opptyTeamToInsert;
      }
      if (!royaltiesToInsert.isEmpty()) {
        insert royaltiesToInsert;
      }
      if (!competitorsToInsert.isEmpty()) {
        insert competitorsToInsert;
      }
      /* // PK Commenting out for now (28/04/15) until this can be tested again.
      updateOppOwnersForRenewals(); // PK: Case 593979
      */
      /*if (!opptyContactAddressList.isEmpty()) {
        insert opptyContactAddressList;
      } I-138599 backlogged */
    } catch (Dmlexception ex) {
      apexLogHandler.createLogAndSave('OrderTriggerHandler','createOLIs_Team_ContactRoleForNewOppty', ex.getStackTraceString(), ex);
      
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newOpptyList.get(0).addError(ex.getDmlMessage(i));
      }
    }
  }

    // T-260645 & T-268662 - validate Order Service Dates 
    public virtual void validateServiceDates(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) {
      Set<Id> startDateChangedOrderIds = new Set<Id>();
      Set<Id> endDateChangedOrderIds = new Set<Id>();
      orderLineItemMap = new Map<Id, Order_Line_Item__c>();
      for (Order__c ord : newOrdersMap.values()) {
        if (!updateFromOrderLI && ord.Contract_Start_Date__c != oldOrdersMap.get(ord.Id).Contract_Start_Date__c) {
          startDateChangedOrderIds.add(ord.Id);
        }
        if (!updateFromOrderLI && ord.Contract_End_Date__c != oldOrdersMap.get(ord.Id).Contract_End_Date__c) {
          endDateChangedOrderIds.add(ord.Id);
        }
      }
      
      Date earliestOLIdate, latestOLIdate;
      Map<ID, Date> ordID_latestStartDateMap = new Map<ID, Date>();
      Map<ID, Date> ordID_earlierStartDateMap = new Map<ID, Date>();
      Set<String> orderIDs = new Set<String>();
      //Looping through OLIs
      if (!startDateChangedOrderIds.isEmpty() || !endDateChangedOrderIds.isEmpty()) {
      	
        for (Order_Line_Item__c oli : [SELECT Id, Order__c, Start_Date__c, End_Date__c
                                       FROM Order_Line_Item__c
                                       WHERE (Order__c in : startDateChangedOrderIds OR order__c in : endDateChangedOrderIds)
                                       order by Order__c, Start_Date__c NULLS LAST, End_Date__c NULLS LAST LIMIT 50]) {
          
          if (oli.Start_Date__c < earliestOLIdate || earliestOLIdate == null) {
             earliestOLIdate = oli.Start_Date__c;
             ordID_earlierStartDateMap.put(oli.Order__c, earliestOLIdate);
          }
          if (oli.End_Date__c > latestOLIdate) {
            latestOLIdate = oli.End_Date__c;
            ordID_latestStartDateMap.put(oli.Order__c, latestOLIdate);
          }
          orderIDs.add(oli.Order__c);
          orderLineItemMap.put(oli.id, oli);
        }
      }
      for (String orderId : orderIDs) {
        if (newOrdersMap.get(orderId).Contract_Start_Date__c > ordID_earlierStartDateMap.get(orderId)) {
          newOrdersMap.get(orderId).addError(System.Label.Service_Start_Date_Error_Msg);
          continue;
        }

        if (newOrdersMap.get(orderId).Contract_End_Date__c < ordID_latestStartDateMap.get(orderId)) {
          newOrdersMap.get(orderId).addError(System.Label.Service_Start_Date_Error_Msg);
          continue;
        }
      }
      
    }
    // T-260645 
    public virtual void populateServiceDatesOnOLI(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) {
      if (orderLineItemMap != null && !orderLineItemMap.isEmpty()) {
        try {
          for (Order_Line_Item__c oli : orderLineItemMap.values()) {
            // populate Service Start Date
            if (!updateFromOrderLI && newOrdersMap.containsKey(oli.order__c)
                                   && newOrdersMap.get(oli.order__c).Contract_Start_Date__c
                                   != oldOrdersMap.get(oli.order__c).Contract_Start_Date__c) {
              oli.Start_Date__c = newOrdersMap.get(oli.order__c).Contract_Start_Date__c;
            }
            // populate Service End Date
            if (!updateFromOrderLI && newOrdersMap.containsKey(oli.order__c)
                                   && newOrdersMap.get(oli.order__c).Contract_End_Date__c
                                   != oldOrdersMap.get(oli.order__c).Contract_End_Date__c) {
              oli.End_Date__c = newOrdersMap.get(oli.order__c).Contract_End_Date__c;
            }
          }
          update orderLineItemMap.values();
      } catch (DMLException e) {
        System.debug('\n[OrderTriggerHandler: populateServiceDatesOnOLI]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('OrderTriggerHandler','populateServiceDatesOnOLI', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
         newOrdersMap.values().get(0).addError(e.getDmlMessage(i));
      }
      }
    }
  }
  
  //T-269988: Multi-Currency Dashboard: Order Trigger
  public virtual void multiCurrencyFieldUpdate(List<Order__c> newList, Map<ID, Order__c> oldMap) {
    //Map to hold conversion rates for currency. Key of map is ISO code for currency and value is as a list holds all
    //dated conversion rates.
    Map<String, List<DatedConversionRate>> currencyISO_ListDtConvRateMap = new Map<String, List<DatedConversionRate>>();
     Set<String> currencyISOCodes = new Set<String>();
      
     for (Order__c ord : newList) {
      //Skipping if update call do not changing closeDate of opportunity
      if (oldMap != null && oldMap.get(ord.ID).Close_Date__c == ord.Close_Date__c
                          && oldMap.get(ord.Id).CurrencyIsoCode == ord.CurrencyIsoCode
                          && oldMap.get(ord.Id).Total__c == ord.Total__c) {
        continue;
      }
      currencyISOCodes.add(ord.CurrencyISOCode);
    }            
      
    //If nothing is to do with currencies
    if (currencyISOCodes.size() < 1) {
      return;
    }
    
    List<DatedConversionRate> dcrList = new List<DatedConversionRate>();
    //Retrieving all currency values and populating map
    for (DatedConversionRate dcr : [SELECT StartDate, NextStartDate, IsoCode, 
                                           Id, ConversionRate 
                                    FROM DatedConversionRate
                                    limit 10000
                                    ]) {
      if (!currencyISO_ListDtConvRateMap.containsKey(dcr.IsoCode)) {
        currencyISO_ListDtConvRateMap.put(dcr.IsoCode, new List<DatedConversionRate>());
      }
      currencyISO_ListDtConvRateMap.get(dcr.IsoCode).add(dcr);
      dcrList.add(dcr);
    }
    CurrencyUtility.queryAndLoadAllConversionRate();
    Set<String> opptyFields = Schema.SObjectType.Order__c.fields.getMap().keySet();
    
    //Updating multi-currency fields
    for (Order__c ord : newList) {
      //Skipping if update call do not changing closeDate of opportunity
      if (oldMap != null && oldMap.get(ord.ID).Close_Date__c == ord.Close_Date__c
                         && oldMap.get(ord.Id).CurrencyIsoCode == ord.CurrencyIsoCode
                         && oldMap.get(ord.Id).Total__c == ord.Total__c) {
        continue;
      }
      
      //if (currencyISO_ListDtConvRateMap.containsKey(oppty.CurrencyIsoCode)) {
      for (DatedConversionRate dcr : dcrList) {
        if (dcr.StartDate <= ord.Close_Date__c && dcr.NextStartDate > ord.Close_Date__c) {

          if (opptyFields.contains(String.valueOf(dcr.IsoCode+'_Conversion_Rate__c').toLowerCase())) {
            ord.put(String.valueOf(dcr.IsoCode)+'_Conversion_Rate__c', dcr.ConversionRate);
          }
        }
      }
      if (ord.Total__c <> null && ord.Total__c != 0) { //nojha : Added another check for non zero values. Apr 06th, 2015. 
        ord.Amount_Corp__c = ord.Total__c / Double.valueOf(ord.get(String.valueOf(ord.CurrencyISOCode)+'_Conversion_Rate__c'));
      }
    }
  }
  
  //I-113908: Order not reflecting currency selected
  public virtual void synchCurrencyISOCodes (List<Order__c> newOrders, Map<ID, Order__c> oldOrderMap) {
    Set<ID> orderIDs = new Set<ID>();
    //Set<ID> orderLines = new Set<ID>();
    
    List<Order_Line_Item__c> orderLines = new List<Order_Line_Item__c>();
    List<Order_Split__c> orderSplits = new List<Order_Split__c>();
    List<Order_Revenue_Schedule__c> orderRevSchedules = new List<Order_Revenue_Schedule__c>();

    Order_Line_Item__c ordLineObj;
    Order_Split__c ordSplitObj;
    Order_Revenue_Schedule__c ordRevScheduleObj;    
    
    for (Order__c ord : newOrders) {
      //Skipping if update call do not changing closeDate of opportunity
      if (oldOrderMap != null && oldOrderMap.get(ord.Id).CurrencyIsoCode == ord.CurrencyIsoCode) {
        continue;
      }
      orderIDs.add(ord.ID);
    }
    
    //Iterating through all orders got updated for currency iso code    
    if (orderIDs.size() > 0) {
      for (Order__c ord : [SELECT Id, CurrencyIsoCode, (SELECT Id, CurrencyIsoCode From Order_Splits__r), 
                                                       (Select Id, CurrencyIsoCode From Order_Line_Items__r) 
                           From Order__c 
                           WHERE ID IN: orderIDs]) {
        //New Currency ISO Code for order lines
        for (Order_Line_Item__c ordLine : ord.Order_Line_Items__r) {
          ordLineObj = new Order_Line_Item__c(ID = ordLine.ID, CurrencyISOCode = ord.CurrencyIsoCode);
          orderLines.add(ordLineObj);
        }
        //New Currency Iso code for Splits
        for (Order_Split__c split : ord.Order_Splits__r) {
          ordSplitObj = new Order_Split__c(ID = split.ID, CurrencyISOCode = ord.CurrencyIsoCode);
          orderSplits.add(ordSplitObj);
        }

      }
      try {
        //Update order lines and splits
        if (orderLines.size() > 0) {
          update orderLines;
        }
        if (orderSplits.size() > 0) {
          update orderSplits;
        }
      } catch (Dmlexception ex) {
        System.debug('[OrderTriggerHandler:synchCurrencyISOCodes]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('OrderTriggerHandler','synchCurrencyISOCodes', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newOrders.get(0).addError(ex.getDmlMessage(i));
        }
      }
      //Update revenue schedules for order lines updated above.
      for (Order_Revenue_Schedule__c schedule : [SELECT Order_Line_Item__r.CurrencyISOCode, Id, CurrencyIsoCode 
                                                 FROM Order_Revenue_Schedule__c 
                                                 WHERE Order_Line_Item__c IN: orderLines]) {
        ordRevScheduleObj = new Order_Revenue_Schedule__c(ID = schedule.ID);
        ordRevScheduleObj.CurrencyIsoCode = schedule.Order_Line_Item__r.CurrencyIsoCode;
        orderRevSchedules.add(ordRevScheduleObj);
      }
      
      try {
        //update revenue schedule
        if (orderRevSchedules.size() > 0) {
          update orderRevSchedules;
        }
      } catch (Dmlexception ex) {
        System.debug('[OrderTriggerHandler:synchCurrencyISOCodes]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('OrderTriggerHandler','synchCurrencyISOCodes', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newOrders.get(0).addError(ex.getDmlMessage(i));
        }
      }
    }
  }
  
  // Case #4995 Creation of Order owner stamped fields
  public virtual void updateOrderOwnerFields(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
      Set<Id> setUsers = new Set<Id>();
      Map<Id, User> mapUsers = new Map<Id, User>();
      
      for (Order__c orders : newOrders)  {
        if(!setUsers.contains(orders.OwnerId) && orders.Locked__c == true) {
         setUsers.add(orders.OwnerId);
        }
      }
      
      for (User users : [SELECT Id, Business_Line__c, Business_Unit__c, Country__c, Global_Business_Line__c, 
                                Name, Region__c, Sales_Sub_Team__c, Sales_Team__c 
                         FROM User WHERE Id IN: setUsers]) {
        mapUsers.put(users.Id, users);
      }
      
      system.debug('\n[OrderTriggerHandler : updateOrderOwnerFields] : ====mapUsers==' + mapUsers);
      
      for (Order__c orders : newOrders) {
        if (orders.Locked__c == true && ((oldOrdersMap == null && orders.Opportunity__c != null) ||oldOrdersMap.get(orders.Id).Locked__c == false)) {
          orders.Owner_GBL_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Global_Business_Line__c;
          orders.Owner_BU_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Business_Unit__c;
          orders.Owner_BL_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Business_Line__c;
          orders.Owner_Sales_Team_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Sales_Team__c; 
          orders.Owner_Sales_SubTeam_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Sales_Sub_Team__c;
          orders.Owner_Country_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Country__c;
          orders.Owner_Region_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Region__c;
          orders.Owner_Name_on_Order_Create_Date__c = mapUsers.get(orders.OwnerId).Name;             
        }
      }
  }
  
  //===========================================================================
  //T-326947: Automatically Associate the Order Record with Each Opportunity Contact Address Record
  //===========================================================================
  public virtual void updateOpportunityContactAddresses (Map<Id, Order__c> newOrdersMap) {
    
    Set<ID> orderOpptySet = new Set<ID>();
    Map<String, String> opptyId_OrderIdMap = new Map<String, String>();
    Map<String, Opportunity_Contact_Address__c> opptyContAddMap = new Map<String, Opportunity_Contact_Address__c>();

    for (Order__c ord : newOrdersMap.values()) {
      if (ord.Opportunity__c != null) {
        orderOpptySet.add(ord.Opportunity__c);
        opptyId_OrderIdMap.put(ord.Opportunity__c, ord.ID);
      }
    }

    //If no order with opportunity. Return without processing
    if (orderOpptySet.size() < 1) {
      return;
    }

    //querying and update opportunity contact addresses
    for (Opportunity_Contact_Address__c opptyContactAddress : [SELECT Order__c, Opportunity__c, Id 
                                                               FROM Opportunity_Contact_Address__c 
                                                               WHERE Opportunity__c IN: orderOpptySet]) {
      if (opptyContactAddress.Opportunity__c != null && opptyId_OrderIdMap.containsKey(opptyContactAddress.Opportunity__c)) {
        opptyContactAddress.Order__c = opptyId_OrderIdMap.get(opptyContactAddress.Opportunity__c);
        opptyContAddMap.put(opptyContactAddress.ID, opptyContactAddress);
      }
    }

    //update opportunity contact address.
    if (opptyContAddMap.size() > 0) {
      try {
        update opptyContAddMap.values();
      } catch (Dmlexception ex) {
        System.debug('[OrderTriggerHandler:updateOpportunityContactAddresses]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('OrderTriggerHandler','updateOpportunityContactAddresses', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newOrdersMap.values().get(0).addError(ex.getDmlMessage(i));
        }
      }
    }
  }
  
  public virtual void checkOnDemandSyncRequired(List<Order__c> orders, Map<Id, Order__c> oldOrders) {
    for (Order__c orderRecord: orders) {
      if (oldOrders != null && orderRecord.Locked__c  &&
                                 (orderRecord.Account__c != oldOrders.get(orderRecord.Id).Account__c ||
                                  orderRecord.Contract_Start_Date__c != oldOrders.get(orderRecord.Id).Contract_Start_Date__c ||
                                  orderRecord.Contract_End_Date__c != oldOrders.get(orderRecord.Id).Contract_End_Date__c ||
                                  orderRecord.PO_Number__c != oldOrders.get(orderRecord.Id).PO_Number__c ||
                                  orderRecord.Type__c != oldOrders.get(orderRecord.Id).Type__c ||
                                  orderRecord.Cancellation_Date__c != oldOrders.get(orderRecord.Id).Cancellation_Date__c ||
                                  orderRecord.EDQ_Integration_Id__c != oldOrders.get(orderRecord.Id).EDQ_Integration_Id__c)
                                 && orderRecord.Number_of_On_Demand_Order_Line_Items__c > 0
                                  ) {
        orderRecord.EDQ_Send_to_On_Demand__c = true;
      }
    }
  }
  
   // Return the appropriate class instance based on className
  public static OrderInterface newClassInstance() {
    Type t;
    //String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
     
    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ)) {
      t = Type.forName('OrderTriggerHandler_EDQ');
    }
    else {
      t = Type.forName('OrderTriggerHandler');
    }
    return (OrderInterface) t.newInstance();
  }
  
  //Fields to be synch on new OpportunityLineItem from Old OpportunityLineItem
  private static Set<String> getFieldsToBeSynched () {
    Set<String> oliFields = new Set<String>{'Type__c', 'CPQ_Quantity__c', 'Renewal_EDQ_Margin__c', 'Product_Upgrade__c', 
             'Renewal_List_Price__c', 'Opportunity_Country__c', 'Application__c', 'Compiler__c', 'CD_Name__c', 
             'Click_Expiry__c', 'CRM_Product_Name__c', 'Data_Installer_Password__c', 'Data_Media__c', 'Data_Required__c', 'Data_Usage__c', 
             'Delivery_Method__c', 'Despatch_Status__c', 'Delivery_Time__c', 'Distribution_Notes__c', 'EDQ_On_Demand_Product__c', 
             'eRenewal_Exception__c', 'Hardware__c', 'Implementation__c', 'Description', 'Item_Quantity__c', 'Item_Number__c', 
             'Major_Version__c', 'Manuals_Required__c', 'Media_Quantity__c', 'No_Delivery__c', 'No_Update__c', //'On_Demand__c', field removed from object 
             'Operating_System__c', 'Original_Asset_ID__c', 'Part_Number__c', 'Precise_Day_License__c', 'Price_Category__c', 
             'Product_Code__c', 'Product_Data__c', 'Product_Family__c', 'Product_Reference__c', 'Product_Release_Name__c', 
             'Program_Media__c', 'Program_Required__c', 'Quantity_Type__c', 'Quote_Number__c', 'Registration_Key__c', 'Release__c', 
             'Release_Reference__c', 'Renewal_Discount__c', 'Renewal_Discount_Amount__c', 'Renewal_Extended_Amount__c', 
             'Renewal_Partner_Amount__c', 'Renewal_Partner__c', 'Renewal_Registration__c', 'Renewal_Total_Royalty__c', 
             'Renewals_Exclude__c', 'Update_Frequency__c', 'Users_From__c', 'Users_To__c', 'Renewal_Sale_Price__c'};
    
    return oliFields;  
  }
  
  //Issue: I-136491 : Model Shipping and Billing Address on the Order
  public virtual void populateAddressFieldsOnOrders (List<Order__c> newOrders) {
    Set<ID> opptyIDs = new Set<ID>();
    Map<ID, List<Opportunity_Contact_Address__c>> opptyID_opptyContAddrMap = new Map<ID, List<Opportunity_Contact_Address__c>>();
    for (Order__c ordr : newOrders) {
      if (ordr.Opportunity__c != null) {
        opptyIDs.add(ordr.Opportunity__c);
      }
    }
    //If Opties are on Order, fetch Shipto and Bill-To (previously called Purchase Ledger) Oppty contact addresses.
    if (opptyIDs.size() > 0) {
      for (Opportunity_Contact_Address__c opptyContAddrs : [SELECT Role__c, Id, Address__c, Opportunity__c, Contact__c 
                                                            FROM Opportunity_Contact_Address__c 
                                                            WHERE Opportunity__c IN: opptyIDs AND 
                                                                (Role__c =: Constants.OPPTY_CONTACT_ROLE_SHIPTO OR Role__c =: Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER)]) {
        if (!opptyID_opptyContAddrMap.containsKey(opptyContAddrs.Opportunity__c)) {
          opptyID_opptyContAddrMap.put(opptyContAddrs.Opportunity__c, new List<Opportunity_Contact_Address__c>());
        }
        opptyID_opptyContAddrMap.get(opptyContAddrs.Opportunity__c).add(opptyContAddrs);
      }//End of Loop
    }//End of If
    
    if (opptyID_opptyContAddrMap.size() > 0) {
      for (Order__c ord : newOrders) {
        if (opptyID_opptyContAddrMap.containsKey(ord.Opportunity__c)) {
          for (Opportunity_Contact_Address__c opptyContAdd : opptyID_opptyContAddrMap.get(ord.Opportunity__c)) {
            if (opptyContAdd.Role__c == Constants.OPPTY_CONTACT_ROLE_SHIPTO) {
              ord.Shipping_Address__c = opptyContAdd.Address__c;
              ord.Shipping_Contact__c = opptyContAdd.Contact__c;
            } else if (opptyContAdd.Role__c == Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER) {
              ord.Billing_Address__c = opptyContAdd.Address__c;
              ord.Billing_Contact__c = opptyContAdd.Contact__c;
            }
          }
        }
      }
    }//end of If
  }
  
  // PK Case #593979 : Update the owners on the renewal opps from new business opps.
  public static void updateOppOwnersForRenewals() {
    system.debug('CALLING updateOppOwnersForRenewals' + oppsToNewOwner);
    if (oppsToNewOwner.size() > 0) {
      if (System.isFuture()) updateOppOwnersForRenewalsNow(oppsToNewOwner);
      else updateOppOwnersForRenewalsFuture(oppsToNewOwner);
    }
  }
  
  @future
  public static void updateOppOwnersForRenewalsFuture(Map<Id,Id> oppToNewOwners) {
    updateOppOwnersForRenewalsNow(oppToNewOwners);
  }
  
  public static void updateOppOwnersForRenewalsNow(Map<Id,Id> oppToNewOwners) {
    List<Opportunity> oppsToUpdateList = new List<Opportunity>();
    for(Id oppId : oppToNewOwners.keySet()) {
      Id newOwnerId = oppToNewOwners.get(oppId);
      if (newOwnerId != null) {
        Opportunity oppToUpdate = new Opportunity(Id = oppId, OwnerId = newOwnerId);
        oppsToUpdateList.add(oppToUpdate);
      }
    }
    try {
      update oppsToUpdateList;
    } catch (Dmlexception ex) {
      System.debug('[OrderTriggerHandler:oppsToUpdateList]'+ex.getMessage()); 
      ApexLogHandler.createLogAndSave('OrderTriggerHandler','oppsToUpdateList', ex.getStackTraceString(), ex);
    }
  } 
  
  //============================================================================
  // T-376294 : Method to recalculate Segment fields on order
  //============================================================================
  public static void recalculateSegmentOnOrder (Map<Id, Order__c>newMap, Map<Id, Order__c>oldMap) {
  	system.debug('[\nOrderTriggerHandler: recalculateSegmentOnOrder]');
    Set<Id> accSegIDs = new Set<Id>();
    List<String> updatedSegFields = AccountSegmentationUtility.ordOwnerToOppOrderField.values();
    Set<String> valueSet = new Set<String>();
    String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);

    System.debug('[\nOrderTriggerHandler: recalculateSegmentOnOrder] OldMap: ' + oldMap);
    for (Order__c ordr : newMap.values()) {
      Order__c oldOrder = (oldMap == null) ? null : oldMap.get(ordr.Id);
      //When record type changed and current RT is read only and Order fields and Order.Segment_* fields are changed
      if (oldMap == null || (oldMap <> null &&
                            ((ordr.RecordTypeId         != oldOrder.RecordTypeId) ||//Added for I-161805: nojha May 10th, 2015
                             (ordr.Amount_Corp__c       != oldOrder.Amount_Corp__c) ||
                             (ordr.Account__c           != oldOrder.Account__c) ||
                             (ordr.Contract_End_Date__c != oldOrder.Contract_End_Date__c) ||
                             (ordr.Type__c               != oldOrder.Type__c) ||
                             (ordr.Cancellation_Date__c  != oldOrder.Cancellation_Date__c) ||
                              isOrderSegFieldUpdated(updatedSegFields, ordr, oldOrder)))
       ) {
         accSegIDs.addAll(addSegmentValues(updatedSegFields, ordr, oldOrder));
       }
    }
    system.debug('[\nOrderTriggerHandler: recalculateSegmentOnOrder]====accSegIDs>>>>' +accSegIDs);

    //call @manintenance method to recalculate Segment
    // PK 070515: Added check for in the future, as this was causing an exception (FATAL_ERROR|System.LimitException: Too many queueable jobs added to the queue: 2)
    if ( !accSegIDs.isEmpty() && !System.isFuture() ) {
      System.enqueueJob(new SegmentMaintenanceQueue(accSegIDs, null));
    }
    
  }
  
  //============================================================================
  // Returns true if field has updated value in new record.
  //============================================================================
  private static Boolean isOrderSegFieldUpdated (List<String> fieldSet, Order__c newRec, Order__c oldRec) {
    for (String fieldName : fieldSet) {
      if (newRec.get(fieldName) != oldRec.get(fieldName)) {
        return true;
      }
    }
    return false;
  }
  
  //============================================================================
  // Returns a set of Account Segment Ids if order fields are not blank
  //============================================================================
  private static Set<Id> addSegmentValues(List<String> fieldSet, Order__c newRec, Order__c oldRec) {
    Set<Id> accSegIds = new Set<Id>();
    for (String fieldName: fieldSet) {
      if (newRec.get(fieldName) != null) {
        accSegIds.add((Id) newRec.get(fieldName));
      }
      if (oldRec != null && oldRec.get(fieldName) != null) {
        accSegIds.add((Id) oldRec.get(fieldName));
      }
    }
    return accSegIds;
  }
}