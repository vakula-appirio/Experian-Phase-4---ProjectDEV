/**=====================================================================
 * Appirio, Inc
 * Name: OrderSplitExtension
 * Description: T-269133: To manage order splits
 * Created Date: Apr 4th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 22nd, 2014								Naresh Kr Ojha							 Custom labels added and removed dead code.
 * May 16th, 2014               Nathalie Le Guay             I-115230 - provide validation on who can create Order Splits, and add stamping
 *                                                           If the OwnerId is changed, none of the Credited_To_XX__c field should change
 =====================================================================*/
public without sharing class OrderSplitExtension {
  public Order__c currentOrder {get;set;}
  public orderSplitWrapper ordSplitWrapObj {get;set;}
  public List<orderSplitWrapper> orderSplitList {get;set;}
  public List<orderSplitWrapper> defaultOrdSplits {get;set;} 
  public String toDeleteOrderSplitId {get; set;}
  public String toDeleteOrderSplitRow {get;set;}
  public Map<Integer, orderSplitWrapper> mapIndexToOrderSplitWrapper {get;set;}
  public Map<Integer, orderSplitWrapper> mapIndexToDefaultOrderSplitWrapper {get;set;}
  public String toDeleteOrderSplitRowId {get;set;}
  public Set<Id> setIdsToDelete;
  public Integer max;
  public Integer maxDefault;
  private Map<Id, User> creditedToUsers;
  private Map<Id, Order_Split__c> orderSplitMap = new Map<Id, Order_Split__c>();
  //To check access on page
  public Boolean haveAccess{get;set;}

  //Wrapper class
  public class orderSplitWrapper {
    public Order_Split__c orderSplit {get;set;}
    public String selectedUser {get;set;}
    
    public orderSplitWrapper () {
      selectedUser = '';
      orderSplit = new Order_Split__c();
    }
    public orderSplitWrapper (Order_Split__c ordSplit) {
      orderSplit = ordSplit;
    }
  }

  //Constructor 
  public OrderSplitExtension(ApexPages.StandardController controller) {
    currentOrder = (Order__c)controller.getRecord();
    String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY); 

    Set<String> profileNamesToGrantAccess = new Set<String>{Constants.PROFILE_SYS_ADMIN, Constants.PROFILE_EXP_SALES_ADMIN, Constants.PROFILE_EXP_SALES_SUPPORT};
    Set<ID> profilesHaveAccess_IDs = new Set<ID>();
    for (Profile p : [SELECT ID FROM Profile WHERE Name IN: profileNamesToGrantAccess]) {
      profilesHaveAccess_IDs.add(p.ID);
    }

    init();
    //Check access
    if (!profilesHaveAccess_IDs.contains(UserInfo.getProfileId()) && currentOrder.OwnerId != UserInfo.getUserId()
        || (currentOrder.OwnerId == UserInfo.getUserId() && currentOrder.RecordTypeId == orderReadOnlyRT_ID)) {
      haveAccess = false;
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.WARNING, Label.ORDER_SPLIT_NO_ACCESS);
      Apexpages.addmessage(msg);
      return ;
    }
    haveAccess = true;
    
  }
  
  //init
  private void init () {
  	setIdsToDelete = new Set<Id>();
    currentOrder = [SELECT Opportunity__c, ID, OwnerId, RecordTypeId, Name, Total__c, CurrencyIsoCode FROM Order__c WHERE ID =: currentOrder.ID];
    orderSplitList = new List<orderSplitWrapper>();
    ordSplitWrapObj = new orderSplitWrapper();
    mapIndexToOrderSplitWrapper = new Map<Integer, orderSplitWrapper>();
    mapIndexToDefaultOrderSplitWrapper = new Map<Integer, orderSplitWrapper>();
    //setOrderSplitIds = new Set<Id>();
    orderSplitWrapper newSplit;
    //isDisabled = true;
    Integer CountIndex = 1;
    for (Order_Split__c os : [Select Split_Total__c, Split_Percentage__c, Split_Note__c, OwnerId,
                                     Order__r.Total__c, Order__r.Opportunity__c, Order__r.Name, 
                                     Order__r.Id, Order__c, Credited_To__c, Credited_To__r.Name  
                              From Order_Split__c WHERE Order__c =: currentOrder.ID]) {
      newSplit = new orderSplitWrapper(os);
      orderSplitList.add(newSplit);
      orderSplitMap.put(os.Id, os);
      mapIndexToOrderSplitWrapper.put(CountIndex, newSplit);
      CountIndex++;
  }
    max = CountIndex - 1;
    defaultOrdSplits = new List<orderSplitWrapper>();
    fillBlanks();
  }
  
  private void fillBlanks() {
    maxDefault = 3;
    for (Integer i = 1; i < 4; i++) {
      defaultOrdSplits.add(new orderSplitWrapper());
      mapIndexToDefaultOrderSplitWrapper.put(i, new orderSplitWrapper());
    }
    //return ordSplitList;
  }
  
  //Adding new row to list.
  public Pagereference addNewRow () {
    
    if (orderSplitList.size() > 0) {
      orderSplitList.add(new orderSplitWrapper());
      max = 1;
      for(Integer cnt : mapIndexToOrderSplitWrapper.keySet()){
        if(max < cnt){
            max = cnt;
        }
      }
      mapIndexToOrderSplitWrapper.put(max+1, new orderSplitWrapper());
    } else {
      defaultOrdSplits.add(new orderSplitWrapper());
      maxDefault = 1;
      for(Integer cnt : mapIndexToDefaultOrderSplitWrapper.keySet()){
        if(maxDefault < cnt){
            maxDefault = cnt;
        }
      }
      mapIndexToDefaultOrderSplitWrapper.put(maxDefault+1, new orderSplitWrapper());
    }
    return null;
  }
  
  //Calculate calculateSplits
  public Pagereference calculateSplits() {
    List<Order_Split__c> listOrderSplitToUpsert = new List<Order_Split__c>();
    Boolean isError = false;
    Double totalSplitPercent = 0;
    Boolean userSelected = false;
    
    System.debug('[--setIdsToDelete2--]'+setIdsToDelete);
    
    system.debug('\n[OrderSplitExtension : calculateSplits] : mapIndexToOrderSplitWrapper.size()='+mapIndexToOrderSplitWrapper.size() 
                 + 'mapIndexToDefaultOrderSplitWrapper.size()='+mapIndexToDefaultOrderSplitWrapper);
    if (mapIndexToOrderSplitWrapper.values().size() > 0) {
        //totalSplitPercent = 0;
        creditedToUsers = getUsers(mapIndexToOrderSplitWrapper);

        for (orderSplitWrapper osw : mapIndexToOrderSplitWrapper.values()) {
        	system.debug('\n[OrderSplitExtension : calculateSplits] : osw: '+ osw);
          if (osw.orderSplit.OwnerId != null && osw.orderSplit.Split_Percentage__c != null) {
            userSelected = true;
            totalSplitPercent += osw.orderSplit.Split_Percentage__c;
            osw.orderSplit.Order__c = currentOrder.Id;
            osw.orderSplit.CurrencyISOCode              = currentOrder.CurrencyISOCode;

            if (osw.orderSplit.Id == null) {
              osw.orderSplit.Credited_To__c = osw.orderSplit.OwnerId;
              if (creditedToUsers != null && creditedToUsers.get(osw.orderSplit.Credited_To__c) != null) {
                osw = populateStampFields(osw.orderSplit.Credited_To__c, osw);
              }
            }

            listOrderSplitToUpsert.add(osw.orderSplit);
          }
        }
    } else {   
      //if (defaultOrdSplits.size() > 0) {
        //totalSplitPercent = 0;
      if (mapIndexToDefaultOrderSplitWrapper.values().size() > 0) {
        creditedToUsers = getUsers(mapIndexToDefaultOrderSplitWrapper);
        //for (orderSplitWrapper osw : defaultOrdSplits) {
        for (orderSplitWrapper osw : mapIndexToDefaultOrderSplitWrapper.values()) {
        	system.debug('\n[OrderSplitExtension : calculateSplits] : osw: '+ osw);
          if (osw.orderSplit.OwnerId != null && osw.orderSplit.Split_Percentage__c != null) {
            osw.orderSplit.Credited_To__c = osw.orderSplit.OwnerId;
            userSelected = true;
            totalSplitPercent += osw.orderSplit.Split_Percentage__c;
            osw.orderSplit.Order__c = currentOrder.Id;
            osw.orderSplit.CurrencyISOCode              = currentOrder.CurrencyISOCode;

            if (osw.orderSplit.Id == null) {
              osw.orderSplit.Credited_To__c = osw.orderSplit.OwnerId;
              if (creditedToUsers != null && creditedToUsers.get(osw.orderSplit.Credited_To__c) != null) {
                osw = populateStampFields(osw.orderSplit.Credited_To__c, osw);
              }
            }
            
            listOrderSplitToUpsert.add(osw.orderSplit);
          } /*else {
            //osw.orderSplit.Split_Percentage__c = 0;
          }*/
        }
      }
    }
    System.debug(isError+'[setIdsToDelete:2:]'+setIdsToDelete);
    Pagereference p = Apexpages.Currentpage();  
    if (!userSelected) {
      isError = true;
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, Label.ORD_SPLIT_REQD_ERR_TEAM_PERCENT);
      Apexpages.addmessage(msg);
      return null;        
    } else if(totalSplitPercent != 100){
      isError = true;
      system.debug('\n[OrderSplitExtension : calculateSplits] : totla Split Percent: '+ totalSplitPercent);
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, Label.ORD_SPLIT_PERCENT_REQD_TOBE_100);
      Apexpages.addmessage(msg);
      return null;  
    }
        
    System.debug(isError+'[setIdsToDelete:3:]'+setIdsToDelete);
    if(isError == false) {
			if(setIdsToDelete != null && setIdsToDelete.size() > 0){
      	List<Order_Split__c> listToDeleteOrdedrSplit = [Select Id From Order_Split__c Where Id In: setIdsToDelete];
        delete listToDeleteOrdedrSplit;
        System.debug('[listToDeleteOrdedrSplit::]'+listToDeleteOrdedrSplit);
        init();
          
			}    
      upsert listOrderSplitToUpsert; 
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.INFO, Label.ORD_SPLIT_MSG_SUCCESS);
      Apexpages.addmessage(msg);

      Pagereference pr = new Pagereference('/'+currentOrder.ID);
      pr.setRedirect(true);
      return pr;
    }
    return null;
  }
  
  private Map<Id, User> getUsers(Map<Integer, orderSplitWrapper> orderSplitWrappers) {
    Set<Id> creditedToUserIds = new Set<Id>();
    for (orderSplitWrapper osw : orderSplitWrappers.values()) {
      creditedToUserIds.add(osw.orderSplit.OwnerId);
    }
    return new Map<Id, User>([SELECT Id, Global_Business_Line__c, Business_Unit__c, Business_Line__c, Sales_Team__c, Sales_Sub_Team__c, Country__c, Region__c
                                         FROM User
                                         WHERE Id in: creditedToUserIds]);
  }
  
  private orderSplitWrapper populateStampFields(Id orderSplitOwnerId, orderSplitWrapper osw) {
    User creditedToUser = creditedToUsers.get(orderSplitOwnerId);
    osw.orderSplit.Credited_To_GBL__c           = creditedToUser.Global_Business_Line__c;
    osw.orderSplit.Credited_To_BU__c            = creditedToUser.Business_Unit__c;
    osw.orderSplit.Credited_To_BL__c            = creditedToUser.Business_Line__c;
    osw.orderSplit.Credited_To_Sales_Team__c    = creditedToUser.Sales_Team__c;
    osw.orderSplit.Credited_To_Sales_Sub_Team__c= creditedToUser.Sales_Sub_Team__c;
    osw.orderSplit.Credited_To_Country__c      = creditedToUser.Country__c;
    osw.orderSplit.Credited_To_Region__c        = creditedToUser.Region__c;
    return osw;
  }
 /* //Check for all added users to be team members on related opportunity.
  public Pagereference checkTeamMember() {
    
    Pagereference p = Apexpages.Currentpage();
    Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.INFO,'Selected:'+defaultOrdSplits);
    Apexpages.addmessage(msg);            

    return null;
  }*/
  
  public Pagereference resetSplits () {
    init();
    return null;
  }
  /*
  * Method to delete orderSplit
  */
  public Pagereference deleteOrderSplit(){
    /*if(toDeleteOrderSplitId != null && toDeleteOrderSplitId != ''){
      Order_Split__c toDeleteOrdedrSplit = [Select Id From Order_Split__c Where Id =: toDeleteOrderSplitId];
      delete toDeleteOrdedrSplit;
      init();
    }*/
    if(toDeleteOrderSplitId != null && toDeleteOrderSplitId != ''){
	    setIdsToDelete.add(toDeleteOrderSplitId);
      System.debug('[--setIdsToDelete-del-]'+setIdsToDelete);
    }
    if(toDeleteOrderSplitRowId != null && toDeleteOrderSplitRowId != ''){
	    Integer toDeleteRowIndex = Integer.valueOf(toDeleteOrderSplitRowId);
	    if(toDeleteRowIndex < max){
	        for(Integer i=toDeleteRowIndex ; i < max; i++){  
	          mapIndexToOrderSplitWrapper.put(i, mapIndexToOrderSplitWrapper.get(i+1));
	        }
	        mapIndexToOrderSplitWrapper.remove(max);
	        max = max - 1;
	    } else if(toDeleteRowIndex == max){
	        mapIndexToOrderSplitWrapper.remove(max);
	        max = max - 1;
	    }
    }     
    return null;
  }
  
  public Pagereference deleteDefaultOrderSplitRow(){
    /*if(toDeleteOrderSplitRow != null && toDeleteOrderSplitRow != ''){
      Integer toDeleteRowIndex = Integer.valueOf(toDeleteOrderSplitRow);
      for(Integer i=toDeleteRowIndex - 1; i <defaultOrdSplits.size() - 1; i++){  
        orderSplitWrapper temp = defaultOrdSplits[i + 1];
        defaultOrdSplits[i] = temp;
      }
      defaultOrdSplits[defaultOrdSplits.size() - 1] = null;
    }*/

    if(toDeleteOrderSplitRow != null && toDeleteOrderSplitRow != ''){
      Integer toDeleteRowIndex = Integer.valueOf(toDeleteOrderSplitRow);
      if(toDeleteRowIndex < maxDefault){
        for(Integer i=toDeleteRowIndex ; i < maxDefault; i++){  
          mapIndexToDefaultOrderSplitWrapper.put(i, mapIndexToDefaultOrderSplitWrapper.get(i+1));
        }
        mapIndexToDefaultOrderSplitWrapper.remove(maxDefault);
        maxDefault = maxDefault - 1;
      } else if(toDeleteRowIndex == maxDefault){
        mapIndexToDefaultOrderSplitWrapper.remove(maxDefault);
        maxDefault = maxDefault - 1;
      }
    }
    return null;
  }
}