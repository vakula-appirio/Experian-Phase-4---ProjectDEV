/**********************************************************************************
 * Appirio, Inc
 * Name: AssetTriggerHandler
 * Description: T-320731
 * Created Date: Sep 18th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 *
 * Date Modified        Modified By                  Description of the update
 * Sept 23rd, 2014      Naresh Kr Ojha               As per T-321480, removed Update Contact fields and updated createUpdateRecords() method
 * Sept 24th, 2014      Naresh Kr Ojha               Added methods populateAssetMapAndOpptyContactRoleMaps(), createUpdateRecord(), Added try{} catch()
 * Oct 3rd, 2014        Naresh Kr Ojha               Added method trackAssetFieldHistory() for the task T-324044
 * Oct 9th, 2014        Arpita Bose (Appirio)        T-324663: Added method createRegistrationRecords()
 * Oct 13th, 2014       Arpita Bose                  T-325339: Moved the Method createUpdateRecords() to AssetTriggerHandler_EDQ.cls and updated class
 *                                                   for Polymorphism design
 * Oct 16th, 2014       Arpita Bose                  I-134978: Updated createRegistrationRecords() and insertRegistrationRec()
 *                                                   to populate Registration_Key__c on Registration__c
 * Oct 20th, 2014       Arpita Bose                  Updated method trackAssetFieldHistory() for task T-326528
 * Nov 04th, 2014       Nathalie Le Guay             I-137705: Update to the query createRegistrationRecords() to limit to "Experian Data Quality" products only
 * Dec 12th, 2014       Noopur                       I-138947: Fixed the condition to check if a new Registration should be recreated, in createRegistrationRecords()
 * Dec 23rd, 2014       Nathalie                     I-144099: Creating Registration__c only if Implementation__c !=: Constants.ASSET_IMPLEMENTATION_ON_DEMAND
 * Jan 6th, 2014        Nathalie                     I-144099: update to above line's logic to create Registration__c if
 *                                                   Data Usage and Implementation DOES NOT contains 'On Demand'
 * Feb 12th, 2015       Naresh                       T-360562: Calculating Count of Assets Related To Deployment, adde method, updateAssetCountOnDeployment()
 * Feb 16th, 2015       Naresh Kr Ojha               T-362362: As per task, updated API name and label as well as all references
 *                                                   of Deployment_Lincense__c to Deployment__c
 * Mar 2nd, 2015        Gaurav Kumar Chadha          T-366782: Added method populateAccountSaas
 * Mar 5th, 2015        Naresh Kr Ojha               T-366852: Clear Account.SaaS__c with clearSaaSOnAccount()
 * Mar 7th, 2015        Naresh kr Ojha               T-364293: added method validateAssetDelete();
 * Mar 7th, 2015        Terri Kellough               T-360562: added checks if deployment was removed from an asset http://screencast.com/t/sr4ZCjI0t
 * Mar 10th, 2015       Terri kellough               added validateActiveDeploymentsAssetCount and checkAndUpdateAssetCount
 * Mar 12th, 2015       Terri Kellough               fixed validateActiveDeploymentsAssetCount
 *                                                   Updated comments to include references to SaaS Use Case Identifiers
 *                                                   For documentation on SaaS Use Cases please review:
 *                                                   - SaaS Use Case Matrix: https://docs.google.com/a/appirio.com/spreadsheets/d/1WF5CX7x6kJZHaJlzM8zzMVl5L0qt7HuLuVn3Puq3xI8/edit#gid=0
 * Mar 20th, 2015       Richard Joseph               Case #00584542: To change the process of creating Update records for renewal Opportunity
 *                                                   Instead retain the old Update record and update the End Date.Method updatetheUpdateRecord
 *  Apr 23th, 2014      Richard Joseph               Case # 00607940- To Process RPI % when ever there is and update or to remove RPI values whenever an Asset is retaged. 
 **********************************************************************************/
public without sharing virtual class AssetTriggerHandler implements AssetInterface {
  public static AssetInterface assetClass; // T-325339
  public static String groupName; // T-325339

  static {
    if (String.isEmpty(groupName)) {
      groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
      assetClass = newClassInstance();
    }
  } // T-325339

  public AssetTriggerHandler() {}


  public virtual void createUpdateRecords (List<Asset> newList, Map<ID, Asset> oldMap) {

  } // T-325339
  
  //RJ - Case#00584542: Included updatetheUpdateRecord
  public virtual void updatetheUpdateRecord (Map<ID, Asset> newMap, Map<ID, Asset> oldMap) {}  


  //===========================================================================
  // After Insert
  //===========================================================================
  public static void afterInsert(List<Asset> newList) {
    assetClass.createUpdateRecords(newList, null);
    assetClass.createRegistrationRecords(newList, null);
    assetClass.updateAssetCountOnDeployment (newList, null);//T-360562
    assetClass.populateAccountSaas(newList);
  }//END: METHOD afterInsert

  //===========================================================================
  // Before Update Call
  //===========================================================================
  public static void beforeUpdate (Map<ID, Asset> newMap, Map<ID, Asset> oldMap) {
    //RJ Case - 00607940
    assetClass.resetRPIFields(newMap,oldMap);
    assetClass.validateActiveDeploymentsAssetCount(newMap, oldMap);
  }

  //===========================================================================
  // After Update
  //===========================================================================
  public static void afterUpdate(Map<ID, Asset> newMap, Map<ID, Asset> oldMap) {
    // RJ - Case#00584542: Commented the CreateUpdateRecords and included updatetheUpdateRecord
    //assetClass.createUpdateRecords(newMap.values(), oldMap);
    assetClass.updatetheUpdateRecord(newMap,oldMap); // RJ

    assetClass.trackAssetFieldHistory(newMap, oldMap);
    assetClass.createRegistrationRecords(newMap.values(), oldMap);
    assetClass.updateAssetCountOnDeployment (newMap.values(), oldMap);//T-360562
  }//END: METHOD afterUpdate

  //===========================================================================
  // Before Delete Call
  //===========================================================================
  public static void beforeDelete (Map<ID, Asset> oldMap) {
    assetClass.validateAssetDelete(oldMap);
  }

  //=========================================================================
  // After Delete call
  //=========================================================================
  public static void afterDelete (Map<ID, Asset> oldMap) {
    assetClass.updateAssetCountOnDeployment (null, oldMap); //T-360562
    assetClass.clearSaaSOnAccount(oldMap);//T-366852
  }

  //=========================================================================
  // After Undelete call
  //=========================================================================
  public static void afterUndelete (List<Asset> newList) {
    assetClass.updateAssetCountOnDeployment (newList, null); //T-360562
  }

//=============================================================================
//The purpose of this class is to ensure the deployments associated with active 
//deployments will have at least one SaaS asset associated with it prior to 
//updating an asset associated with an active deployment
//Covers SaaS Deployment Use Cases: D-16 
//=============================================================================  
public virtual void validateActiveDeploymentsAssetCount(Map<ID, Asset>  newMap, Map<ID, Asset> oldMap){
  Map<String, Double> deploymentAssetCountMap = new Map<String, Double>();
  List<Id> deploymentIds = new List<Id>();
  
  //Get asset's deployments
  for (Asset asset : oldMap.values()){
    if (asset.Deployment__c != null){
      deploymentIds.add(asset.Deployment__c);
    }
  }
  
  List<Deployment__c> activeDeployments = [Select Id, Asset_Count__c From Deployment__c where Active__c = True AND Id In:deploymentIds];
  
  //create lookup of Active Deployment's Asset Count
  for(Deployment__c d: activeDeployments){
    deploymentAssetCountMap.put(d.Id, d.Asset_Count__c);
  }
  
  //check previous active deployment on asset doesn't match the current deployment
  //if not matched, then check if the previous active deployment's asset count > 1
  //if true, then decrement the count, if not, then throw an error
  checkAndUpdateAssetCount(oldMap, newMap, deploymentAssetCountMap);
  
  
}

  //=============================================================================
  // The purpose of this method is to track the decrease of asset count as we loop through the 
  // trigger records. If we ever are about to reach 0, we will output an error message, as an 
  // active deployment should have at least 1 Asset related to it. (EDQ.com requirement)
  // Covers SaaS Deployment Use Cases: D-16 
  //=============================================================================
  private static void checkAndUpdateAssetCount(Map<ID, Asset> oldMap, Map<ID, Asset> newMap, Map<String, Double> deploymentAssetCountMap) {
    for(Asset a: oldMap.values()){

      if (a.Deployment__c != null 
          && a.Deployment__c != newMap.get(a.Id).Deployment__c && deploymentAssetCountMap.containsKey(a.Deployment__c)) {
        Double currentAssetCount = deploymentAssetCountMap.get(a.Deployment__c);
        if (currentAssetCount > 1) {
          //check if the asset is associated with an active deployment and get the current asset count
          currentAssetCount--;
          deploymentAssetCountMap.put(a.Deployment__c, currentAssetCount);
        } 
        else {
          newMap.get(a.Id).addError(System.Label.SaaS_ERR_UPDATE_ASSET);
        }
      }
    }
  }


  //===========================================================================
  // If deleted asset is associated with an active deployment, it should not get deleted and
  // display error as per : T-364293
  // Covers SaaS Asset Use Cases: AS-20, AS-21
  //===========================================================================
  public virtual void validateAssetDelete (Map<ID, Asset> deletedAssets) {

    Map<ID, Deployment__c> deploymentMap = new Map<ID, Deployment__c>();


    for (Asset delAsset : deletedAssets.values()) {
      if (delAsset.Deployment__c <> null && !deploymentMap.containsKey(delAsset.Deployment__c)) {
        deploymentMap.put(delAsset.Deployment__c, null);
      }
    }

    //Fetching deployments
    for (Deployment__c deployment : [SELECT Active__c, ID FROM Deployment__c
                                         WHERE ID IN: deploymentMap.keySet()]) {
      deploymentMap.put(deployment.ID, deployment);
    }

    //Putting errors on assets with active deployments
    for (Asset delAsset : deletedAssets.values()) {
      if (delAsset.Deployment__c <> null &&
             deploymentMap.containsKey(delAsset.Deployment__c) &&
                deploymentMap.get(delAsset.Deployment__c).Active__c == true) {
        delAsset.addError(System.Label.SaaS_ERR_DELETE_ASSET);
      }
    }

  }
  //===========================================================================
  //Method Name :  populateAccountAsset
  //Method Purpose : to populate Asset.Account.Saas__c if Asset.Saas__c = true
  //Covers SaaS Account Use Cases: AC-19 
  //===========================================================================
  public virtual void populateAccountSaas(List<Asset> newList){
    List<Asset> assetsToUpdate = new List<Asset>();
    Map<ID, Account> accountsToUpdate = new Map<ID, Account>();

    for (Asset newAsset : newList) {
      if (newAsset.AccountID != null && newAsset.SaaS__c == true && !accountsToUpdate.containsKey(newAsset.AccountID)) {
        accountsToUpdate.put(newAsset.AccountID, new Account(ID = newAsset.AccountID, SaaS__c = true));
      }
    }

    try{
      if(accountsToUpdate.values().size() > 0){
        update accountsToUpdate.values();
      }
     } catch (DMLException ex) {
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','createUpdateRecords', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
     }
  }

  //=========================================================================
  // As per : T-360562, calculates Assets on Deployment on Asset creation, updation, deletion and Undelete.
  // Covers SaaS Deployment Use Cases: D-7, D-8, D-9, D-10, 
  // Covers Part of SaaS Asset Use Cases, due to changing the Asset Count on the deployment: 
  //              AS-8, AS-2, AS-6, AS-7, AS-9, AS-10, AS-11, AS-12, AS-14, AS-15
  //=========================================================================
  public virtual void updateAssetCountOnDeployment (List<Asset> newAssets, Map<ID, Asset> oldMap) {

    Map<String, Deployment__c> deploymentLicMap = new Map<String, Deployment__c>();
    Set<String> deplLicsIDs = new Set<String>();

    // Insert, Update and Undelete Case
    if (newAssets != null) {
      for (Asset assetObj : newAssets) {
        if (assetObj.Deployment__c != null &&
              (oldMap != null ? oldMap.get(assetObj.ID).Deployment__c != assetObj.Deployment__c : true)) {
          deplLicsIDs.add(assetObj.Deployment__c);

          // Added old Deployment to set, so that it can get updated too.
          if (oldMap != null) {
            deplLicsIDs.add(oldMap.get(assetObj.ID).Deployment__c);
          }
        }
        // checks if deployment was removed from an asset - else if assetObj.Deployment__c == null implied
        if (oldMap != null) {
          if (oldMap.get(assetObj.ID).Deployment__c != null && assetObj.Deployment__c == null){
             deplLicsIDs.add(oldMap.get(assetObj.ID).Deployment__c);
          }
        }
      }
    } else { // Delete Case
      for (Asset assetObj : oldMap.values()) {
        if (assetObj.Deployment__c != null) {
          deplLicsIDs.add(assetObj.Deployment__c);
        }
      }
    }

    for (Deployment__c depLic : [SELECT ID, (SELECT Id FROM Assets__r)
                                         FROM Deployment__c
                                         WHERE ID IN: deplLicsIDs]) {
      if (!deploymentLicMap.containsKey(depLic.ID)) {
        depLic.Asset_Count__c = depLic.Assets__r.size();
        deploymentLicMap.put(depLic.ID, depLic);
      }
    }

    if (deploymentLicMap.size() > 0) {
      try {
        update deploymentLicMap.values();
      } catch(Exception ex) {
        System.debug('[AssetTriggerHandler:updateAssetCountOnDeployment]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','updateAssetCountOnDeployment', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          if (newAssets != null) {
            newAssets.get(0).addError(ex.getDmlMessage(i));
          } else if (oldMap != null) {
            oldMap.values().get(0).addError(ex.getDmlMessage(i));
          }
        }
      }
    }
  }

  //===========================================================================
  // Clear SaaS when last SaaS asset removed from account as per T-366852
  // Covers SaaS Account Use Cases: AC-20
  //===========================================================================
  public virtual void clearSaaSOnAccount (Map<ID, Asset> oldMap) {
    Set<String> accountIDs = new Set<String>();
    Map<ID, Account> accountsToUpdate = new Map<ID, Account>();

    // Deleted SaaS Asset
    for (Asset deletedAsset : oldMap.values()) {
      if (deletedAsset.SaaS__c == true && deletedAsset.AccountId != null) {
        accountIDs.add(deletedAsset.AccountId);
      }
    }

    // Fetching SaaS Accounts and checking whether have any remaining asset
    for (Account acc : [SELECT ID, SaaS__c, (Select Id, SaaS__c From Assets WHERE SaaS__c = true)
                        FROM Account
                        WHERE ID IN: accountIDs
                          AND SaaS__c = true]) {
      if (acc.Assets.size() == 0) {
        acc.SaaS__c = false;
        accountsToUpdate.put(acc.ID, acc);
      }
    }

    try {
      if (accountsToUpdate.values().size() > 0) {
        update accountsToUpdate.values();
      }
    }  catch (DMLException ex) {
       System.debug('[AssetTriggerHandler:clearSaaSOnAccount]'+ex.getMessage());
       ApexLogHandler.createLogAndSave('AssetTriggerHandler','clearSaaSOnAccount', ex.getStackTraceString(), ex);
       for (Integer i = 0; i < ex.getNumDml(); i++) {
         oldMap.values().get(0).addError(ex.getDmlMessage(i));
       }
     }
  }

  //===========================================================================
  // Tracking field history of Asset
  //===========================================================================
  public virtual void trackAssetFieldHistory (Map<Id, Asset> newMap, Map<ID, Asset> oldMap) {
    List <Audit_Trail__c> audits = new List <Audit_Trail__c>();

    //T-324837
    Set<String> assetFieldNameSet = new Set<String>{Constants.ASSET_DATA_USAGE, Constants.ASSET_DIRECT_RENEWAL,
                                                    Constants.ASSET_INSTALL_DATE, /*Constants.ASSET_LAST_MODIFIED_DATE,*/
                                                    Constants.ASSET_OPERATING_SYSTEM, Constants.ASSET_ORDER_LINE,
                                                    //Constants.ASSET_OS_VERSION, T-326528
                                                    Constants.ASSET_PARTNER,
                                                    Constants.ASSET_PARTNER_AMOUNT, Constants.ASSET_PRICE,
                                                    Constants.ASSET_PURCHASE_DATE, Constants.ASSET_QUANTITY,
                                                    Constants.ASSET_RELEASE_VERSION, Constants.ASSET_RENEWAL_DISCOUNT,
                                                    //Constants.ASSET_RENEWAL_VAR, T-326528
                                                    Constants.ASSET_START_DATE,
                                                    Constants.ASSET_STATUS, Constants.ASSET_TOTAL_ROYALTY,
                                                    Constants.ASSET_USAG_END_DATE,
                                                    Constants.ASSET_ITEM_NUMBER,
                                                    Constants.ASSET_RPI,Constants.ASSET_RPI_AMOUNT, // RJ Case 00607940 - Added two new field to track History
                                                    Constants.ASSET_QUOTE_NUMBER
                                                    };
    try {
      for (Asset asset : newMap.values()) {
        Asset oldobject = oldMap.get(asset.ID);
        Asset newobject = newMap.get(asset.ID);
        for (String assetField : assetFieldNameSet) {
          Audit_Trail__c audit = new Audit_Trail__c();
          // Determine which fields have changed by comparing the old and new maps
          // For each field that has changed: create a new audit record, and add to the audit list
          if ((oldobject.get(assetField) != newobject.get(assetField))
            /*&& (assetField != 'lastmodifiedbyid' && assetField != 'systemmodstamp' && assetField != 'lastmodifieddate')*/) {
            audit.Object_Name__c = Constants.SOBJECT_ASSET;
            audit.Asset__c = asset.Id;
            String tempFieldName = assetField;
            audit.Field_Name__c = tempFieldName;
            audit.Old_Value__c = String.valueof(oldobject.get(assetField));
            audit.New_Value__c = String.valueof(newobject.get(assetField));
            audit.Last_Modified_Date__c = datetime.now();
            audit.Last_Modified_By__c = newobject.LastModifiedById;
            audit.Record_Id__c = String.valueof(oldobject.Id);
            // Uncomment the following section if a Reason for Change field is present
                  /*
                  if (newobject.Other_Reason_for_Change__c != Null) {
                      audit.Reason_for_Change__c = (newobject.Reason_for_Change__c + '-' + newobject.Other_Reason_for_Change__c);
                  } else {
                      audit.Reason_for_Change__c = (newobject.Reason_for_Change__c);
                  }
                  */
            audits.add(audit);
          } else {
            system.debug('Field '+assetField+' did not change');
          }
        } //end of inner For Loop
        // end of outer For Loop
      }
    } catch (DMLException ex) {
       System.debug('[AssetTriggerHandler:trackAssetFieldHistory]'+ex.getMessage());
       ApexLogHandler.createLogAndSave('AssetTriggerHandler','trackAssetFieldHistory', ex.getStackTraceString(), ex);
       for (Integer i = 0; i < ex.getNumDml(); i++) {
         newMap.values().get(0).addError(ex.getDmlMessage(i));
       }
     }

     //Inserting asset's audit trail records
     if (audits.size() > 0) {
       try {
         insert audits;
       } catch (DMLException ex) {
         System.debug('[AssetTriggerHandler:trackAssetFieldHistory]'+ex.getMessage());
         ApexLogHandler.createLogAndSave('AssetTriggerHandler','trackAssetFieldHistory', ex.getStackTraceString(), ex);
         for (Integer i = 0; i < ex.getNumDml(); i++) {
           newMap.values().get(0).addError(ex.getDmlMessage(i));
         }
       }
     }
  }


  //==========================================================================
  // T-324663: Method to create Registration__c Records
  //==========================================================================
  public virtual void createRegistrationRecords (List<Asset> newList, Map<ID, Asset> oldMap) {
    Set<Id> assetIDs = new Set<Id>();
    List<Registration__c> registrationLstToInsert = new List<Registration__c>();

    //get all the Asset records where Data_Usage__c != null || asset.Manual_Registration__c = true on insert/update
    for (Asset asset : newList) {
      if ((asset.Data_Usage__c != null || asset.Manual_Registration__c == true)){/* && (
           (oldMap != null ? asset.Data_Usage__c != oldMap.get(asset.ID).Data_Usage__c : true) ||
           (oldMap != null ? asset.Manual_Registration__c != oldMap.get(asset.ID).Manual_Registration__c : true))) {*/
        assetIDs.add(asset.ID);
      }
    }

    if (assetIDs.size() < 1) {
      return;
    }

    //get all Asset that do NOT have a Registration__c record
    for (Asset asset : [SELECT Id, Users_To__c, Manual_Registration__c, Data_Usage__c, Registration_Key__c,
                               Order_Line__r.Order__r.Owner.Email, Implementation__c, SaaS__c,
                         (SELECT Id, Asset__c, Manual_Registration__c, Number_of_Users__c, Account__c
                          FROM Registrations__r)
                        FROM Asset
                        WHERE Id IN :assetIDs AND Product2.Business_Line__c =: Constants.BUSINESSLINE_DATA_QUALITY
                                              AND (NOT Data_Usage__c LIKE '%On Demand%') AND (NOT Implementation__c LIKE '%On Demand%')]) {
      if (asset.Registrations__r.size() == 0 && asset.SaaS__c == false) {
        registrationLstToInsert.add(insertRegistrationRec(asset));
      }
    }

    try {
      //Inserting new Registration record
      if (registrationLstToInsert.size() > 0) {
        insert registrationLstToInsert;
      }
    } catch(DMLException ex) {
        System.debug('[AssetTriggerHandler:createRegistrationRecords]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','createRegistrationRecords', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
    }
  }

  //==============================================================================
  // Create Registration Record
  //==============================================================================
  private static Registration__c insertRegistrationRec(Asset newAsset){
    Registration__c newRegistration = new Registration__c();
    newRegistration.Asset__c = newAsset.ID;
    newRegistration.Number_of_Users__c = newAsset.Users_To__c;
    newRegistration.Manual_Registration__c = newAsset.Manual_Registration__c;
    newRegistration.Registration_Key__c = newAsset.Registration_Key__c;// I-134978
    return newRegistration;
  }

  // T-325339: Return the appropriate class instance based on className
  public static AssetInterface newClassInstance() {
    Type t;

    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ)) {
      t = Type.forName('AssetTriggerHandler_EDQ');
    }
    else {
      t = Type.forName('AssetTriggerHandler');
    }
    return (AssetInterface) t.newInstance();
  }

  //RJ Case # 00607940 - Method to validate if the asset is getting retaged and if so then reset RPI values.
  public virtual void resetRPIFields(Map<Id, Asset> newMap, Map<ID, Asset> oldMap) {
    for (Asset assetRec : newMap.values()) {
      try {
        if (assetRec.RPI__c != null && assetRec.RPI__c >0 && !assetRec.Exclude_from_RPI__c && assetRec.RPI__c != oldMap.get(assetRec.Id).RPI__c){
          if (assetRec.Renewal_Extended_Amount__c != null && assetRec.Renewal_Extended_Amount__c != 0 )
            assetRec.RPI_Amount__c = assetRec.Renewal_Extended_Amount__c * assetRec.RPI__c/100; 

            //if (assetRec.Renewal_Sale_Price__c != null && assetRec.Renewal_Sale_Price__c != 0 )
            //(assetRec.Renewal_Sale_Price__c = assetRec.Renewal_Sale_Price__c + (assetRec.Renewal_Sale_Price__c * assetRec.RPI__c / 100));
            if (assetRec.Renewal_List_Price__c != null && assetRec.Renewal_List_Price__c != 0 ) {
              assetRec.Renewal_List_Price__c = assetRec.Renewal_List_Price__c + (assetRec.Renewal_List_Price__c * assetRec.RPI__c / 100);
            }
            //if (assetRec.Renewal_EDQ_Margin__c != null && assetRec.Renewal_EDQ_Margin__c != 0 )
            //assetRec.Renewal_EDQ_Margin__c = assetRec.Renewal_EDQ_Margin__c + (assetRec.Renewal_EDQ_Margin__c * assetRec.RPI__c / 100);


            if (assetRec.Renewal_Extended_Amount__c != null && assetRec.Renewal_Extended_Amount__c != 0 ) {
              assetRec.Renewal_Extended_Amount__c = assetRec.Renewal_Extended_Amount__c + (assetRec.Renewal_Extended_Amount__c * assetRec.RPI__c / 100);
            }
            if (assetRec.Renewal_Extended_Amount__c != null && assetRec.Renewal_Extended_Amount__c != 0 ) {
              assetRec.Renewal_Sale_Price__c = assetRec.Renewal_Extended_Amount__c;
            }

            if (assetRec.Renewal_Extended_Amount__c != null && assetRec.Renewal_Extended_Amount__c != 0 )
            {
              if (assetRec.Renewal_Partner__c != null && assetRec.Renewal_Partner__c !=0) {
                assetRec.Renewal_Partner_Amount__c = ( (assetRec.Renewal_Extended_Amount__c
                                                        - (
                                                          (assetRec.Renewal_Total_Royalty__c != null && assetRec.Renewal_Total_Royalty__c > 0) ?
                                                           assetRec.Renewal_Total_Royalty__c : 0))
                                                     * assetRec.Renewal_Partner__c / 100);
                assetRec.Renewal_EDQ_Margin__c = assetRec.Renewal_Extended_Amount__c
                                                 - assetRec.Renewal_Partner_Amount__c
                                                 - ((
                                                    assetRec.Renewal_Total_Royalty__c != null && assetRec.Renewal_Total_Royalty__c > 0) ?
                                                    assetRec.Renewal_Total_Royalty__c : 0);
            } else {
              assetRec.Renewal_EDQ_Margin__c = assetRec.Renewal_Extended_Amount__c
                                              - (
                                                  (assetRec.Renewal_Total_Royalty__c != null && assetRec.Renewal_Total_Royalty__c >0) ?
                                                  assetRec.Renewal_Total_Royalty__c : 0
                                                );
            }
          }
        }

        if (assetRec.Order_Line__c != oldMap.get(assetRec.Id).Order_Line__c) {
	        assetRec.RPI__c= null;
	        assetRec.RPI_Amount__c= null;
        }
      } catch(DMLException ex) {
        System.debug('[AssetTriggerHandler:resetRPIFields]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('AssetTriggerHandler','resetRPIFields', ex.getStackTraceString(), ex);
      }
    }
  }
}