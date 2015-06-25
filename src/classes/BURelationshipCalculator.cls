/*******************************************************************
* Name  : BURelationshipCalculator
* Author: Pankaj Mehra
* Date  : Nov 6, 2013
* Description : Calculate both Type and Amount fields on BU Relationship records. 
              1. The Class takes as input a Set of  BU Relationship Ids and:
                 Retrieves all Opps that point to the BU Relationships
              2. From 2 fields on the Opp: Business_Unit__c and Global_Line_of_Business__c
                 Cycles through the Opps for each BU Relationship
                 Keeps 2 totals:
                   a. Total Open Pipeline
                     If the Opp field "IsClosed" = false, add to Total Open Pipeline
                  b. Total Won
                     If the Opp field "IsClosed" = true and "Is Won" = true, add to Total Won
              3. These totals update fields of the same name on the BU Relationship 
              4. Checks Closed Won Opportunities
                 a. If any of these Opps Contract End Date was in the last 12 months, 
                    BU Relationship Relationship_Type__c field set to Client
                 b. Else If there are no Opps with the criteria above, and any of 
                    these Opps has a Contract End Date was between 13 and 36 months ago, 
                    BU Relationship Relationship_Type__c field set to Former Client
                 c. Else If there are no Opps with either of the criteria above, 
                    Relationship_Type__c field set to Prospect
              5. Returns list of SObjects (BU Relationships) with Id, Relationship_Type__c , 
                 Total Won and Total Open Pipeline fields filled in

 * Date Modified      Modified By                Description of the update
 * Feb 4, 2014        Nathalie Le Guay (Appirio) Total Won coming from Order's Total__c instead
 *                                               of Opportunities' Amount field - T-245766
 *                                               Created generic functionality for T-246522
 * March 04, 2014     Nathalie Le Guay           Update to contractEndDate (became serviceEndDate) logic and getStatus() for T-249365
 * March 05, 2014     Naresh Kr Ojha             T-255982: Refactoring to use CurrencyUtility
 * March 05, 2014     Nathalie Le Guay           Update to updateTypeAndAmountFieldOnBU() to take currency into account for totalWon
 * March 11th, 2014     Naresh Kr Ojha (Appirio)     Updated for optimizing purpose for T-257854
 * March 26th, 2014   Nathalie Le Guay           Updated logic to use Order's Service_End_Date__c instead of Contract_End_Date__c
 * April 2nd, 2014    Nathalie Le Guay           Replaced order.Service_End_Date__c with order.Contract_End_Date__c
 * April 3rd, 2014	  Mohit Parnami(Appirio)	   T-266502: updated updateTypeAndAmountFieldOnBU method to use the constructor of currencyUtility 
                                                   having parameter as set of ISO codes
 * April 23rd, 2014   Nathalie Le Guay           Commented the class, getting it ready for retirement
 *************************************************************************/
public without sharing class BURelationshipCalculator {
  /*public static final String BU_RELATIONSHIP_TYPE_PROSPECT = 'Prospect';
  public static final String BU_RELATIONSHIP_TYPE_CLIENT = 'Client';
  public static final String BU_RELATIONSHIP_TYPE_FORMER_CLIENT = 'Former Client';
    public static final String GLOBAL_SETTING = 'Global';
    
  //Commented to use CurrencyUtility class: T-255982. nojha Mar 5th, 14
  //public static Map<String,Double> conversion_rates = new Map<String,Double>();
  
  /* Populate Type and Amount fields on BU Relationship records
  *
  public List<BU_Relationship__c> updateTypeAndAmountFieldOnBU(Set<Id> setBURelationship) {

    // Get all currency for conversion (Commented By mohit to change it to query on DatedConversionRate object and using the constructor passing set of ISO codes)
    //CurrencyUtility currencyUtil = new CurrencyUtility();
    
    //Commented to use CurrencyUtility class: T-255982. nojha Mar 5th, 14
     
    List<BU_Relationship__c> lstBURelationship = [SELECT Id , Relationship_Type__c ,Total_Open_Pipeline__c,
                                                   Total_Won__c ,
                                                         (SELECT Id,Amount,Contract_End_Date__c,isClosed,isWon,
                                                          CurrencyIsoCode, CloseDate 
                                                          FROM  Opportunities__r), // Business Unit
                                                         (SELECT Id,Amount,Contract_End_Date__c ,isClosed,isWon,
                                                          CurrencyIsoCode, CloseDate 
                                                          FROM Opportunities1__r), // Global Business Line 
                                                         (SELECT Id, Total__c, CurrencyIsoCode, Contract_End_Date__c, Close_Date__c
                                                          FROM BU_Orders__r),      // Business Unit
                                                         (SELECT Id, Total__c, CurrencyIsoCode, Contract_End_Date__c
                                                          FROM Global_Line_Orders__r) // Global Business Line 
                                                  FROM BU_Relationship__c 
                                                  WHERE Id in :setBURelationship];
    
    System.debug('[BURelationshipCalculator.updateTypeAndAmountFieldOnBU]:lstBURelationship->'+lstBURelationship);
    for(BU_Relationship__c bu : lstBURelationship) {
      double totalOpenPipeline;
      double totalWon;
      Date contractEndDate;
      //DW 08/12 Fixing for type calculation
      Boolean hasOrder = false;
      List<Opportunity> opportuntiyList = new List<Opportunity>();
      List<Order__c> orderList = new List<Order__c>();

      opportuntiyList.addAll(bu.Opportunities__r);
      opportuntiyList.addAll(bu.Opportunities1__r); 
      orderList.addAll(bu.Global_Line_Orders__r);
      orderList.addAll(bu.BU_Orders__r);
      
      /*********Edited By Mohit Parnami to get Currency Converted From DatedConversionRate object******************
      	Set<String> setOppCurrencyISOCode = new Set<String>();
      	for(Opportunity opportunity : opportuntiyList) {
      		setOppCurrencyISOCode.add(opportunity.CurrencyIsoCode);
      	}
      	CurrencyUtility currencyUtil = new CurrencyUtility(setOppCurrencyISOCode);
      /************Block Edited by mohit ends**********************************************************************
      
      // Cycle through all Business Unit Opportunities
      for(Opportunity opportunity : opportuntiyList) {
        //double amount = opportunity.CurrencyIsoCode == 'USD' ? opportunity.Amount : convertCurrency(opportunity.CurrencyIsoCode , 'USD',double.valueOf(opportunity.Amount));
        double amount = opportunity.CurrencyIsoCode == 'USD' ? opportunity.Amount : currencyUtil.convertCurrency(opportunity.CurrencyIsoCode, double.valueOf(opportunity.Amount), 'USD', opportunity.CloseDate);
        amount = amount == NULL ? 0 : amount;
        if(!opportunity.isClosed) {
          totalOpenPipeline = (totalOpenPipeline == NULL) ? amount : totalOpenPipeline + amount;
        }
      }
      System.debug('[BURelationshipCalculator.updateTypeAndAmountFieldOnBU]:orderList->'+orderList);
      for (Order__c orderRec: orderList) {
        double orderAmount = (orderRec.CurrencyIsoCode == 'USD') ?
                              orderRec.Total__c : 
                              currencyUtil.convertCurrency(orderRec.CurrencyIsoCode, double.valueOf(orderRec.Total__c), 'USD', orderRec.Close_Date__c);  
        orderAmount = (orderAmount == NULL) ? 0 : orderAmount;
        
        totalWon = (totalWon == null) ? orderAmount : totalWon + orderAmount;
        if (orderRec.Total__c > 0.00) {
          hasOrder = true;
          if (contractEndDate == null) {
            contractEndDate = orderRec.Contract_End_Date__c;
          } else if (orderRec.Contract_End_Date__c > contractEndDate) {
              contractEndDate = orderRec.Contract_End_Date__c;
          }
        }
      }
      System.debug('\n[BURelationshipCalculator: updateTypeAndAmountFieldOnBU]: \nTotal Won: '+ totalWon + '\nContract End Date: '+ contractEndDate);
      // Populate Bu_Relationship field
      if(totalOpenPipeline != NULL) {
        bu.Total_Open_Pipeline__c = totalOpenPipeline;
      }
      
      bu.Total_Won__c = (totalWon != NULL) ? totalWon : 0.00;
      //DW 08/12 Fixing for type calculation
      bu.Relationship_Type__c = getStatus(hasOrder, contractEndDate);
    }
    // Update BU_Relationship Record
    //update lstBURelationship;
    return lstBURelationship;
  } 
  

  /* retrieve status of the basis of Opportunity serviceEndDate
  *  DW 08/12 Fixing for type calculation
  *
  public String getStatus(Boolean hasOrder, Date contractEndDate){
    if(contractEndDate == NULL) {
      return BU_RELATIONSHIP_TYPE_PROSPECT;
    }
    System.debug('\n[BURelationshipCalculator: getStatus]: ' + (contractEndDate > System.today().addYears(-1))+'---contractEndDate--'+contractEndDate);
    if(contractEndDate != null && contractEndDate > System.today().addYears(-1) && hasOrder) {
      return BU_RELATIONSHIP_TYPE_CLIENT;
    }
    
    if(contractEndDate != null && contractEndDate < System.today().addYears(-1) && hasOrder) {
      return BU_RELATIONSHIP_TYPE_FORMER_CLIENT;
    }
    return BU_RELATIONSHIP_TYPE_PROSPECT;
  }


/**************************************************************
 * Section added by NLG, copied from OpportunityTriggerHandler,
 * and updated to work with multiple objects 
 *************************************************************
  //Method to check Onwer change and align BU lookup fields.
  public static void populateBUsOnCreate(List<SObject> lstNewRecords, String objectName) {
    Set<Id> setOwnerIds = new Set<Id>();
    Set<Id> setAccountIds = new Set<Id>();
    String accountIdField = objectName.equalsIgnoreCase('Opportunity') ? 'AccountId': 'Account__c';

    Global_Settings__c custSettings = Global_Settings__c.getValues(GLOBAL_SETTING);
    system.debug('########newMap########'+lstNewRecords);
    for (SObject newRec:lstNewRecords) {
      //Get Owner and Acc Ids.
      setOwnerIds.add((String) newRec.get('OwnerId'));
      setAccountIds.add((String) newRec.get(accountIdField));
    }//END: FOR oldRec

       //Retrieve Old+New User data.
    Map<Id,User> mapUsers = new Map<Id,User>([select id,Business_Unit__c,Global_Business_Line__c from User where id=:setOwnerIds]);
    Map<String,Id> mapAccBUs= new Map<String,Id>();

    //Retrieve Account Related BUs.
    for (Account accRec:[SELECT  id, (SELECT Id, Account__c, Global_Line_of_Business_or_BU__c FROM BU_Relationships__r where Global_Line_of_Business_or_BU__c!=null) from Account where Id=:setAccountIds])
    {
      for (BU_Relationship__c buRec:accRec.BU_Relationships__r)
      {
        mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c,buRec.id);
      }
    }

    Map<String,BU_Relationship__c> mapBUsToCreate = new Map<String,BU_Relationship__c>();

    String ownerId = '';
    String accountId = '';
    //Iterate through Owner changed Records.
    for (SObject newRec:lstNewRecords) {
      ownerId = (String) newRec.get('OwnerId');
      accountId = (String) newRec.get(accountIdField);
      //Add new BUs if does not exist for Accounts.
      String BURelName ='';  // 31/10/13 Shane Khublall           
      system.debug('EEEEEEEE BURelName before any mods: '+ BURelName);
      if (mapUsers.containsKey(ownerId)) {
        if (mapUsers.get(ownerId).Business_Unit__c!=null && !mapAccBUs.containsKey(accountId+mapUsers.get(ownerId).Business_Unit__c))
        {
          if(mapUsers.get(ownerId).Global_Business_Line__c!=null)
            BURelName += mapUsers.get(ownerId).Global_Business_Line__c;
            system.debug('FFFFFFFF BURelName after adding Owner GBL: '+ BURelName);
            BURelName += ('/' + mapUsers.get(ownerId).Business_Unit__c);
            BU_Relationship__c buTmpRec = new BU_Relationship__c(Account__c=accountId,CurrencyISOCode=custSettings.BU_Default_Currency__c, Name=BURelName,   // 31/10/13 Shane Khublall
            Global_Line_of_Business_or_BU__c=mapUsers.get(ownerId).Business_Unit__c);

            mapBUsToCreate.put(buTmpRec.Account__c+buTmpRec.Global_Line_of_Business_or_BU__c,buTmpRec); 

            system.debug('GGGGGGGG BURelName after adding Owner BU: '+ BURelName);
          }

          if(mapUsers.get(ownerId).Global_Business_Line__c!=null  && !mapAccBUs.containsKey(accountId+mapUsers.get(ownerId).Global_Business_Line__c))
            {
            BU_Relationship__c buTmpRec = new BU_Relationship__c(Account__c=accountId, CurrencyISOCode=custSettings.BU_Default_Currency__c,Name = mapUsers.get(ownerId).Global_Business_Line__c,  // 31/10/13 Shane Khublall
            Global_Line_of_Business_or_BU__c=mapUsers.get(ownerId).Global_Business_Line__c);

            mapBUsToCreate.put(buTmpRec.Account__c+buTmpRec.Global_Line_of_Business_or_BU__c,buTmpRec);         
          }
        }//END: IF newOwner in mapUsers

       }//END: FOR oppId

       //Create new BUs
       if(mapBUsToCreate.size()>0) {
         insert mapBUsToCreate.values();    
       }
       //Add newly created BU record ids to map.
       //for(BU_Relationship__c buRec:lstBUsToCreate)
       for (BU_Relationship__c buRec:mapBUsToCreate.values()) {
         mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c,buRec.id);
       }

       //Populate OwnerChanged Opportunities BU lookup fields.
       //for(Id oppId:setOwnerChangeOppIds)
       for (SObject newRec:lstNewRecords)
       {
         //Flush old values.
         newRec.put('Business_Unit__c', null);
         newRec.put('Global_Line_of_Business__c', null);
         if (mapUsers.get(ownerId).Business_Unit__c!=null && mapAccBUs.containsKey(accountId+mapUsers.get(ownerId).Business_Unit__c))
         {
           newRec.put('Business_Unit__c', mapAccBUs.get(accountId+mapUsers.get(ownerId).Business_Unit__c));
         }

         if (mapUsers.get(ownerId).Global_Business_Line__c!=null  && mapAccBUs.containsKey(accountId+mapUsers.get(ownerId).Global_Business_Line__c))
         {
           newRec.put('Global_Line_of_Business__c', mapAccBUs.get(accountId+mapUsers.get(ownerId).Global_Business_Line__c));
         }
       }//END: FOR oppId
   }//END: Method populateBUsOnCreate


   //For new/updated records, Update Child BU's Parent Lookup with GLB Id.
  public static void populateParentBUs(Map<Id,SObject> newMap, Map<Id,SObject> oldMap) {
     List<BU_Relationship__c> lstBUsToUpdate = new List<BU_Relationship__c>();
     Map<Id,BU_Relationship__c> mapBUsToUpdate = new Map<Id,BU_Relationship__c>();

    String newRecBU = '';
    String newRecGLB = '';
     //If record is New or BUs lookup field values has changed then update the BU records to reflect correct relationship.
     for (SObject newRec: newMap.values()) {
       newRecBU = (String) newRec.get('Business_Unit__c');
       newRecGLB = (String) newRec.get('Global_Line_of_Business__c');
       if (oldMap == null || isValueChanged('Business_Unit__c', newRec, oldMap.get((String) newRec.get('id'))) ||  
            isValueChanged('Global_Line_of_Business__c', newRec, oldMap.get((String) newRec.get('id'))))
         {
         if (newRecBU != null) {
           mapBUsToUpdate.put(newRecBU,new BU_Relationship__c(id = newRecBU,Parent__c = newRecGLB));
           //lstBUsToUpdate.add(new BU_Relationship__c(id=newOppRec.Business_Unit__c,Parent__c=newOppRec.Global_Line_of_Business__c));
         }
       }
     }

     if (mapBUsToUpdate.size() > 0) {
       update mapBUsToUpdate.values();
     }

   }//END: Method populateParentBUs

  //Method to check Onwer change and align BU lookup fields.
  public static void reAlignBUsOnOwnerChange(Map<Id, SObject> newMap, Map<Id, SObject> oldMap, String objectName) {
    Set<Id> setOwnerIds = new Set<Id>();
    Set<Id> setOwnerChangeOppIds = new Set<Id>();
    Set<Id> setAccountIds = new Set<Id>();
    String accountIdField = objectName.equalsIgnoreCase('Opportunity') ? 'AccountId': 'Account__c';

    for (SObject oldRec:oldMap.values()) {
      SObject newRec = newMap.get((String) oldRec.get('id'));
      //Check if Owner has changed.
      if (oldRec.get('OwnerId') != newRec.get('OwnerId')) {
        setOwnerIds.add((String) oldRec.get('OwnerId'));
        setOwnerIds.add((String) newRec.get('OwnerId'));
        setAccountIds.add((String) newRec.get(accountIdField));
        setOwnerChangeOppIds.add((String) newRec.get('id'));
      }
    }//END: FOR oldOppRec

    //Retrieve Old+New User data.
    Map<Id,User> mapUsers = new Map<Id,User>([SELECT Id, Business_Unit__c, Global_Business_Line__c
                                              FROM User
                                              WHERE Id =: setOwnerIds]);
    Map<String,Id> mapAccBUs= new Map<String,Id>();

    //Retrieve Account Related BUs.
    for (Account accRec:[SELECT  id, 
                                (SELECT Id, Account__c, Global_Line_of_Business_or_BU__c
                                 FROM BU_Relationships__r
                                 WHERE Global_Line_of_Business_or_BU__c!=null)
                        FROM Account
                        WHERE Id =: setAccountIds]) {
      for (BU_Relationship__c buRec: accRec.BU_Relationships__r) {
        mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c, buRec.id);
      }
    }

    List<BU_Relationship__c> lstBUsToCreate = new List<BU_Relationship__c>();
    Set<Id> setBUsToDelete = new Set<Id>();

    //Iterate through Owner changed Records.
    for (Id oppId: setOwnerChangeOppIds) {
      SObject oldRec = oldMap.get(oppId);
      SObject newRec = newMap.get(oppId);
      String ownerId = (String) newRec.get('OwnerId');
      String accountId = (String) newRec.get(accountIdField);

      //Add new BUs if does not exist for Accounts.

      // Updated 31/10/13 Shane Khublall , naming convention for new BU Relationship records
      String BURelName ='';  // 31/10/13 Shane Khublall
      if (mapUsers.containsKey(ownerId)) {
        if (mapUsers.get(ownerId).Business_Unit__c != null &&
           !mapAccBUs.containsKey(accountId + mapUsers.get(ownerId).Business_Unit__c)) {
          if (mapUsers.get(ownerId).Global_Business_Line__c!=null) { // 31/10/13 Shane Khublall
            BURelName += mapUsers.get(ownerId).Global_Business_Line__c;  // 31/10/13 Shane Khublall
          }
          BURelName += ('/' + mapUsers.get(ownerId).Business_Unit__c);  // 31/10/13 Shane Khublall
          lstBUsToCreate.add(new BU_Relationship__c(Account__c=accountId, Name=BURelName,   // 31/10/13 Name field. Shane Khublall
                             Global_Line_of_Business_or_BU__c=mapUsers.get(ownerId).Business_Unit__c));
        }

        if (mapUsers.get(ownerId).Global_Business_Line__c != null  &&
           !mapAccBUs.containsKey(accountId+mapUsers.get(ownerId).Global_Business_Line__c)) {
          lstBUsToCreate.add(new BU_Relationship__c(Account__c = accountId, Name = mapUsers.get(ownerId).Global_Business_Line__c,  // 31/10/13 Name field. Shane Khublall
                             Global_Line_of_Business_or_BU__c = mapUsers.get(ownerId).Global_Business_Line__c));
        }
      }//END: IF newOwner in mapUsers

      //Identify previous Owner's BU records to delete. Only when BU value of old and new User is different. 
      String oldOwnerId = (String) oldRec.get('OwnerId');
      String oldAccountId = (String) oldRec.get(accountIdField);
      if (mapUsers.containsKey(oldOwnerId)) {
        if (mapUsers.get(oldOwnerId).Business_Unit__c != null &&
            mapAccBUs.containsKey(oldAccountId + mapUsers.get(oldOwnerId).Business_Unit__c) &&
            mapUsers.get(oldOwnerId).Business_Unit__c != mapUsers.get(ownerId).Business_Unit__c) {
          setBUsToDelete.add(mapAccBUs.get(oldAccountId + mapUsers.get(oldOwnerId).Business_Unit__c));
        }

        if (mapUsers.get(oldOwnerId).Global_Business_Line__c != null  &&
            mapAccBUs.containsKey(oldAccountId + mapUsers.get(oldOwnerId).Global_Business_Line__c) && 
            mapUsers.get(oldOwnerId).Global_Business_Line__c != mapUsers.get(ownerId).Global_Business_Line__c) {
          setBUsToDelete.add(mapAccBUs.get(oldAccountId + mapUsers.get(oldOwnerId).Global_Business_Line__c));
        }
      }//END: IF oldOwner in mapUsers
    }//END: FOR oppId

    //Create new BUs
    if (lstBUsToCreate.size() > 0) {
      insert lstBUsToCreate;
    }

    //Add newly created BU record ids to map.
    for (BU_Relationship__c buRec:lstBUsToCreate) {
      mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c,buRec.id);
    }  

    //Populate OwnerChanged Opportunities BU lookup fields.
    for (Id recId: setOwnerChangeOppIds) {
      SObject newRec = newMap.get(recId);
      String ownerId = (String) newRec.get('OwnerId');
      String accountId = (String) newRec.get(accountIdField);

      //Flush old values.
      newRec.put('Business_Unit__c', null);
      newRec.put('Global_Line_of_Business__c', null);

      if (mapUsers.get(ownerId).Business_Unit__c != null && 
          mapAccBUs.containsKey(accountId + mapUsers.get(ownerId).Business_Unit__c)) {
        newRec.put('Business_Unit__c', mapAccBUs.get(accountId + mapUsers.get(ownerId).Business_Unit__c));
      }

      if (mapUsers.get(ownerId).Global_Business_Line__c != null  && 
          mapAccBUs.containsKey(accountId + mapUsers.get(ownerId).Global_Business_Line__c)) {
        newRec.put('Global_Line_of_Business__c', mapAccBUs.get(accountId + mapUsers.get(ownerId).Global_Business_Line__c));
      }
    }//END: FOR oppId

    //Check the BUs to delete against Opportunities if there are any other Opps linked then should NOT be deleted.
    Set<Id> setBUsWithoutParentToDelete = new Set<Id>();
    if (objectName.equalsIgnoreCase('Opportunity')) {
      for (AggregateResult agrRec: [SELECT  Business_Unit__c, count(Id)
                                 FROM Opportunity 
                                 WHERE Business_Unit__c =: setBUsToDelete
                                 group by Business_Unit__c having count(Id) < 2]) {
        setBUsWithoutParentToDelete.add((Id)agrRec.get('Business_Unit__c'));
      }

      for(AggregateResult agrRec: [SELECT  Global_Line_of_Business__c, count(Id)
                                 FROM Opportunity
                                 WHERE Global_Line_of_Business__c =: setBUsToDelete
                                 group by Global_Line_of_Business__c having count(Id) < 2]) {
        setBUsWithoutParentToDelete.add((Id)agrRec.get('Global_Line_of_Business__c'));
      }
    }
    if (objectName.equalsIgnoreCase('Order__c')) {
      for (AggregateResult agrRec: [SELECT  Business_Unit__c, count(Id)
                                 FROM Order__c 
                                 WHERE Business_Unit__c =: setBUsToDelete
                                 group by Business_Unit__c having count(Id) < 2]) {
        setBUsWithoutParentToDelete.add((Id)agrRec.get('Business_Unit__c'));
      }

      for(AggregateResult agrRec: [SELECT  Global_Line_of_Business__c, count(Id)
                                 FROM Order__c
                                 WHERE Global_Line_of_Business__c =: setBUsToDelete
                                 group by Global_Line_of_Business__c having count(Id) < 2]) {
        setBUsWithoutParentToDelete.add((Id)agrRec.get('Global_Line_of_Business__c'));
      }
    }
    //Delete BUs
    if (setBUsWithoutParentToDelete.size() > 0)  {
      List<BU_Relationship__c> lstBUsToDel = new List<BU_Relationship__c>();
      for(Id buId:setBUsWithoutParentToDelete) {
        lstBUsToDel.add(new BU_Relationship__c(Id=buId));
      }

      //Delete records.
      delete lstBUsToDel;    
    }//END: If
  }//END: Method reAlignBUsOnOwnerChange

  private static Boolean isValueChanged(String fieldName, SObject newRec, SObject oldRec) {
    return newRec.get(fieldName) != oldRec.get(fieldName);
  }*/
}