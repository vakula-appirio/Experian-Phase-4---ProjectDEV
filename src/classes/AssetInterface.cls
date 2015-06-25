/**=====================================================================
 * Appirio, Inc
 * Name: AssetInterface
 * Description: T-325339 : Interface class for AssetTriggerHandler.cls 
 * Created Date: Oct 13th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 13th, 2015       Naresh kr Ojha               T-360562: Updated interface for updateAssetCountOnDeployment() method.
 * Feb 16th, 2015       Naresh Kr Ojha               T-362362: As per task, updated API name and label as well as all references
 *                                                   of Deployment_Lincense__c to Deployment__c
 * March 2nd, 2015      Gaurav Kr Chadha             T-366782: Added method populateAccountSaas
 * March 4th, 2015      Naresh Kr Ojha               T-366852: last saas asset delete should set account saas = false, added method clearSaaSOnAccount();
 * Mar 20th, 2015       Richard Joseph               Case#00584542: To change the process of creating Update records for renewal Opportunity
 *                                                   Instead retain the old Update record and update the End Date.
 * Apr 29th, 2015       Richard Joseph               Case #00607940: Added resetRPIFields()
 =====================================================================*/
 public interface AssetInterface {

  // declaring methods to be implemented in class

  void trackAssetFieldHistory (Map<Id, Asset> newMap, Map<ID, Asset> oldMap);
  void createRegistrationRecords (List<Asset> newList, Map<ID, Asset> oldMap);
  void createUpdateRecords (List<Asset> newList, Map<ID, Asset> oldMap);
  void updateAssetCountOnDeployment (List<Asset> newList, Map<ID, Asset> oldMap);
  void populateAccountSaas(List<Asset> newList);
  void clearSaaSOnAccount(Map<ID, Asset> oldMap);
  void validateActiveDeploymentsAssetCount(Map<Id,Asset> newMap, Map<Id, Asset> oldMap);
  void validateAssetDelete(Map<Id, Asset> oldMap);
  //RJ - Case#00584542: Included updatetheUpdateRecord
  void updatetheUpdateRecord (Map<Id, Asset> newMap, Map<ID, Asset> oldMap);
  //RJ - Case#00607940: Included updatetheUpdateRecord
  void resetRPIFields (Map<Id, Asset> newMap, Map<ID, Asset> oldMap);

/*
   void afterInsert(List<Asset> newList);
   void afterUpdate(Map<ID, Asset> newMap, Map<ID, Asset> oldMap);
*/
}