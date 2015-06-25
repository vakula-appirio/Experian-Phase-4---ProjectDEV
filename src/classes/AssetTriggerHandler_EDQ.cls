/**********************************************************************************
 * Appirio, Inc
 * Name: AssetTriggerHandler_EDQ
 * Description: T-325339
 * Created Date: Oct 13th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Oct 13th, 2014       Arpita Bose(Appirio)         T-325339:Copied from AssetTriggerHandler, added method createUpdateRecords()
 * Oct 14th, 2014       Arpita Bose                  Added method updateOppConAddrs() as per task T-325309
 * Oct 15th, 2014       Naresh Ojha                  Modified method updateOppConAddrs() as per task T-325309
 * Nov 4th, 2014        Nathalie Le Guay             I-137519: populateAssetMapAndOpptyContactRoleMaps() update to query on Role__c = 'Updates'
 * Feb 12th, 2015       Naresh                       T-360562: Calculating Count of Assets Related To Deployment License, adde method, updateAssetCountOnDeployment()
 * March 4th, 2015      Naresh Kr Ojha               T-366852: last saas asset delete should set account saas = false, added method clearSaaSOnAccount();
 * Mar 7th, 2015        Naresh kr Ojha               T-364293: added method validateAssetDelete();
 * March 10th, 2015     Terri Kellough               added validateActiveDeploymentsAssetCount
 * Mar 10th, 2015       Sadar Yacob                  Case# 583718: Use Order Line's Product Family (CPQ) on the Update record instead of the SFDC Product Family 
 * Mar 12th, 2015       Sadar Yacob                  Case# 585179: For the Update Record, dont use hte SFDC Product name, use the CPQ Product Name from Asset record
 * Mar 20th, 2015       Richard Joseph               Case #00584542: To change the process of creating Update records for renewal Opportunity. Instead retain the
 *                                                   old Update record and update the End Date.  
 * Apr 23th, 2014       Richard Joseph               Case # 00607940- To remove RPI whenever an Asset is retaged.  
 **********************************************************************************/
public without sharing class  AssetTriggerHandler_EDQ extends AssetTriggerHandler implements AssetInterface {


  public override void trackAssetFieldHistory (Map<Id, Asset> newMap, Map<ID, Asset> oldMap){
    super.trackAssetFieldHistory(newMap, oldMap);
  }

  public override void createRegistrationRecords (List<Asset> newList, Map<ID, Asset> oldMap){
    super.createRegistrationRecords(newList, oldMap);
  }

  //RJ - case 00607940 
  public override void resetRPIFields (Map<Id, Asset> newMap, Map<ID, Asset> oldMap) {
    super.resetRPIFields(newMap, oldMap);
  }

  public override void updateAssetCountOnDeployment (List<Asset> newList, Map<ID, Asset> oldMap){
    super.updateAssetCountOnDeployment(newList, oldMap);
  }    

  public override void populateAccountSaas (List<Asset> newList){
    super.populateAccountSaas(newList);
  }
  
  public override void clearSaaSOnAccount(Map<ID, Asset> oldMap) {
    super.clearSaaSOnAccount(oldMap);
  }  

  public override void validateAssetDelete (Map<ID, Asset> oldMap) {
    super.validateAssetDelete(oldMap);
  }  
  
  public override void validateActiveDeploymentsAssetCount(Map<ID, Asset> newMap, Map<ID, Asset> oldMap){
    super.validateActiveDeploymentsAssetCount(newMap, oldMap);
  }
  
  //===========================================================================
  //T-320731: Create Update__c records for Asset with meeting criteria
  //===========================================================================
  public override void createUpdateRecords (List<Asset> newList, Map<ID, Asset> oldMap) {
    List<Update__c> newUpdateRecords = new List<Update__c>();
    Map<String, Asset> assetOrdLineOrderOppty_AssetMap = new Map<String, Asset>();
    Map<String, List<Opportunity_Contact_Address__c>> opptyID_ListOpptyContactRoleMap = new Map<String, List<Opportunity_Contact_Address__c>>();
   
    //Populates maps by iterating and checking required conditions    
    populateAssetMapAndOpptyContactRoleMaps(newList, oldMap, assetOrdLineOrderOppty_AssetMap, opptyID_ListOpptyContactRoleMap);
    System.debug(assetOrdLineOrderOppty_AssetMap+'====opptyID_ListOpptyContactRoleMap=====>'+opptyID_ListOpptyContactRoleMap);
    try {    
      //Creation of update records for selected assets
      if (assetOrdLineOrderOppty_AssetMap.size() > 0) {
        for (String key : assetOrdLineOrderOppty_AssetMap.keySet()) {
          Asset newAsset = assetOrdLineOrderOppty_AssetMap.get(key);
          System.debug('====newAsset======'+newAsset);
          if (newAsset.Order_Line__r.Order__r.Opportunity__c != null && 
                opptyID_ListOpptyContactRoleMap.containsKey(newAsset.Order_Line__r.Order__r.Opportunity__c) &&
                opptyID_ListOpptyContactRoleMap.get(newAsset.Order_Line__r.Order__r.Opportunity__c).size() > 0) {
            //Create Update__c record here
            for (Opportunity_Contact_Address__c ocr : opptyID_ListOpptyContactRoleMap.get(newAsset.Order_Line__r.Order__r.Opportunity__c)) {
              newUpdateRecords.add(createUpdateRecord(newAsset, ocr));
            }
          } 
        }//End for Loop
      }//End if
    } catch (Exception ex) {
        apexLogHandler.createLogAndSave('AssetTriggerHandler','createUpdateRecords', ex.getStackTraceString(), ex);
    }
    
    try {
      //Inserting new Update__c records
      if (newUpdateRecords.size() > 0) {
        insert newUpdateRecords;
        //T-325309
        updateOppConAddrs(newUpdateRecords, newList); 
      }
    } catch (DMLException ex) {
        System.debug('[AssetTriggerHandler:createUpdateRecords]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','createUpdateRecords', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
    }
  }
  
  //===========================================================================
  //Populates maps used to create new Update records
  //===========================================================================
  private static void populateAssetMapAndOpptyContactRoleMaps (List<Asset> newList, Map<ID, Asset> oldMap, 
                                                               Map<String, Asset> assetOrdLineOrderOppty_AssetMap, 
                                                               Map<String, List<Opportunity_Contact_Address__c>> opptyID_ListOpptyContactRoleMap) {
    Set<ID> opptyIDs = new Set<ID>();
     
    for (Asset asset : [SELECT ID, No_Update__c, Product2.Business_Line__c, Order_Line__r.Order__r.Locked__c,
                               Order_Line__r.Order__r.Type__c, Order_Line__c, Product2Id, Order_Line__r.Order__r.Opportunity__c,
                               Product2.Name, Data_Usage__c, Implementation__c, Operating_System__c,
                               Release_Version__c, UsageEndDate, Name, Media_Type__c, Media_Quantity__c, Product_Data__c,
                               Update_Frequency__c, Order_Line__r.Part_Number__c, Part_Number__c, Order_Line__r.Product_Family__c ,CRM_Product_Name__c
                        FROM Asset
                        WHERE ID IN: newList]) {
      if (asset.Order_Line__r.Order__r.Opportunity__c != null) {
        opptyIDs.add(asset.Order_Line__r.Order__r.Opportunity__c); 
      } else {
          continue;
      }
      //First condition if inserted asset or updated asset for Order line or UsageEnddate
      if (asset.Order_Line__c != null && asset.Product2Id != null && (
            (oldMap != null ? asset.Order_Line__c != oldMap.get(asset.ID).Order_Line__c : true ) ||
            (oldMap != null ? asset.UsageEndDate != oldMap.get(asset.ID).UsageEndDate : true ))) {
            
            //Second condition Order type should be or not should be Renewal
        if (isMeetingConditions(asset)) {
          if (asset.Order_Line__c != null && asset.Order_Line__r.Order__c != null && String.isNotEmpty(asset.Order_Line__r.Order__r.Type__c)
                // If it is a Renewal, we check whether the Part Number between the Asset/Order Line Item matches or not
                && ((asset.Order_Line__r.Order__r.Type__c.equalsIgnoreCase(Constants.ORDER_RENEWAL) && asset.Part_Number__c == asset.Order_Line__r.Part_Number__c) ||
                !asset.Order_Line__r.Order__r.Type__c.equalsIgnoreCase(Constants.ORDER_RENEWAL))) {
            system.debug('\n\nASSET_EQD: Made it through the conditions, adding to map: ' + asset.Order_Line__c+'~~'+asset.Order_Line__r.Order__r.Opportunity__c);
            if (!assetOrdLineOrderOppty_AssetMap.containsKey(asset.Order_Line__c+'~~'+asset.Order_Line__r.Order__r.Opportunity__c)) {
              assetOrdLineOrderOppty_AssetMap.put(asset.Order_Line__c+'~~'+asset.Order_Line__r.Order__r.Opportunity__c, asset);
            }
          } 
        }
      }
    }//End of For loop

    for (Opportunity_Contact_Address__c ocr : [Select ID, Role__c, Address__c, Contact__r.Name, Contact__c, Opportunity__c
                                       From Opportunity_Contact_Address__c 
                                       WHERE Opportunity__c IN: opptyIDs AND Role__c =: Constants.OPPTY_CONTACT_ROLE_UPDATE]) {
      if (!opptyID_ListOpptyContactRoleMap.containsKey(ocr.Opportunity__c)) {
        opptyID_ListOpptyContactRoleMap.put(ocr.Opportunity__c, new List<Opportunity_Contact_Address__c>());
      }
      opptyID_ListOpptyContactRoleMap.get(ocr.Opportunity__c).add(ocr);
    }
    
  }


  // RJ - Case#00584542: To change the process of creating Update records for renewal Opportunity. Instead retain the old Update record and update the End Date.  
  //===========================================================================
  // Update the Update record on Asset Update.
  //===========================================================================
  public override  void updatetheUpdateRecord(Map<ID, Asset> newMap, Map<ID, Asset> oldMap) {
      
    List<Update__c> assetUpdateRecordList = new List<Update__c>();
    for (Update__c updateRec: [SELECT Id, End_date__c, Asset__c, Asset__r.UsageEndDate, Asset__r.Id 
                               FROM Update__c
                               WHERE Asset__c in :newMap.KeySet()] )
      {
      if (updateRec.End_date__c != newMap.get(updateRec.Asset__r.id).UsageEndDate ) {
        assetUpdateRecordList.add(
            new Update__c(Id = updateRec.Id,
                          End_date__c = newMap.get(updaterec.Asset__r.id).UsageEndDate,
                          Opportunity__c = newMap.get(updaterec.Asset__r.id).Opportunity__c ));
      }
    }
    if (assetUpdateRecordList.size() > 0) {
      try {
        update assetUpdateRecordList;
      } catch (Exception e) {
        System.debug('[AssetTriggerHandler:updatetheUpdateRecord]'+e.getMessage()); 
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','updatetheUpdateRecord', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
          newMap.values().get(0).addError(e.getDmlMessage(i));
        }
      }
    }
  }

  //===========================================================================
  //Create Update record
  //===========================================================================
  private static Update__c createUpdateRecord(Asset newAsset, Opportunity_Contact_Address__c ocr) {
    Update__c newUpdate = new Update__c();
    //newUpdate.Product_Name__c = newAsset.Product2.Name;
    newUpdate.Product_Name__c = newAsset.CRM_Product_Name__c; //Case #585179 :03/12/15
    newUpdate.Data_Usage__c = newAsset.Data_Usage__c;
    newUpdate.Implementation__c = newAsset.Implementation__c;
    newUpdate.Operating_System__c = newAsset.Operating_System__c;
    newUpdate.Product_Family__c = newAsset.Order_Line__r.Product_Family__c; //newAsset.Product2.Family; // Case#583718:03/10/15
    newUpdate.Release_Version__c = newAsset.Release_Version__c;
    newUpdate.Name = newAsset.Name + ' - ' + ocr.Contact__r.Name;
    newUpdate.Asset__c = newAsset.ID;
    newUpdate.Opportunity__c = newAsset.Order_Line__r.Order__r.Opportunity__c;
    newUpdate.Update_Contact__c = ocr.Contact__c;
    newUpdate.Media_Type__c = newAsset.Media_Type__c;
    newUpdate.End_Date__c = newAsset.UsageEndDate;
    newUpdate.Media_Quantity__c = newAsset.Media_Quantity__c;
    newUpdate.Product_Data__c = newAsset.Product_Data__c;
    newUpdate.Update_Frequency__c = newAsset.Update_Frequency__c;
    newUpdate.Address__c = ocr.Address__c;
    return newUpdate;     
  }
  
  //===========================================================================
  //Checks weather meeting condition provided by T-320731
  //===========================================================================
  private static Boolean isMeetingConditions(Asset newAsset) {
    
    return (newAsset.No_Update__c == false && newAsset.Product2 != null && newAsset.Product2.Business_Line__c != null &&
            newAsset.Product2.Business_Line__c.equalsIgnoreCase(Constants.BUSINESSLINE_DATA_QUALITY) &&
            newAsset.Order_Line__c != null && newAsset.Order_Line__r.Order__r.Locked__c == true);
  }

  //============================================================================
  // T-325309: Update Opportunity_Contact_Address__c records
  //============================================================================
  private static void updateOppConAddrs(List<Update__c> newUpdates, List<Asset> newList) {
    Opportunity_Contact_Address__c oppConAdrsRec;
    Set<ID> contactIDs = new Set<ID>();
    Set<ID> opptyIDs = new Set<ID>();
    Map<String, Opportunity_Contact_Address__c> contIdOpptyId_opptyContAddMap 
                            = new Map<String, Opportunity_Contact_Address__c>();
    Map<String, Opportunity_Contact_Address__c> opptyContAddressToUpdateMap 
                            = new Map<String, Opportunity_Contact_Address__c>();
     
    for (Update__c up : newUpdates) {
      if (up.Update_Contact__c != null && up.Opportunity__c != null ) {
        contactIDs.add(up.Update_Contact__c);
        opptyIDs.add(up.Opportunity__c);
      }
    }
     
    
    //Querying opportunity contact addresses for matching oppties and contacts
    for (Opportunity_Contact_Address__c oppConAdrs : [SELECT Id, Update_Record__c, Contact__c, Opportunity__c
                                                      FROM Opportunity_Contact_Address__c
                                                      WHERE Contact__c = :contactIDs
                                                      AND Opportunity__c = :opptyIDs]) {
      //populating map to be used further to update OpptyContactAddresses
      if (oppConAdrs.Contact__c != null && oppConAdrs.Opportunity__c != null &&  
            !contIdOpptyId_opptyContAddMap.containsKey(oppConAdrs.Contact__c + '~' + oppConAdrs.Opportunity__c)) {
        contIdOpptyId_opptyContAddMap.put(oppConAdrs.Contact__c + '~' + oppConAdrs.Opportunity__c, oppConAdrs);
      }
    }
     
    
    for (Update__c up : newUpdates) {
      //populating map to be used further to update OpptyContactAddresses
      if (up.Update_Contact__c != null && up.Opportunity__c != null &&  
           contIdOpptyId_opptyContAddMap.containsKey(up.Update_Contact__c + '~' + up.Opportunity__c)) {
        Opportunity_Contact_Address__c opptyContAddrs = contIdOpptyId_opptyContAddMap.get(up.Update_Contact__c + '~' + up.Opportunity__c);
        opptyContAddrs.Update_Record__c = up.ID;
        opptyContAddressToUpdateMap.put(opptyContAddrs.ID, opptyContAddrs);
      }
    }
    try {
      if (opptyContAddressToUpdateMap.size() > 0) {
       update opptyContAddressToUpdateMap.values();
      }
      System.debug('========================>'+opptyContAddressToUpdateMap);
    } catch (DMLException ex) {
        System.debug('[AssetTriggerHandler:updateOppConAddrs]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','updateOppConAddrs', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
      }  
    } 

/*
  public override void afterInsert (List<Asset> newList) {
    super.afterInsert(newList);
  } 

  public override void afterUpdate (Map<ID, Asset> newMap, Map<ID, Asset> oldMap){
    super.afterUpdate(newMap, oldMap);
  } 
*/
}