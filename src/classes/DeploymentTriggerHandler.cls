/**********************************************************************************
 * Appirio, Inc
 * Name: DeploymentTriggerHandler
 * Description: T-360562
 * Created Date: Feb 12th, 2015
 * Created By: Naresh kumar Ojha (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 16th, 2015       Naresh Kr Ojha               T-362362: As per task, updated API name and label as well as all references
 *                                                   of Deployment_Lincense__c to Deployment__c 
 * Feb 19th, 2015       Naresh kr Ojha               T-360567: By default, when a deployment is created, it should be owned by the Experian Global User
 * March 2nd, 2015      Gaurav Kumar Chadha          T-365130: Added beforeDelete and preventDeletionOfActiveDeployments Methods
 **********************************************************************************/
public class DeploymentTriggerHandler {

  //=========================================================================
  // Before Insert call
  //========================================================================= 
  public static void beforeInsert (List<Deployment__c> newList) {
    resetAssetCountOnDeployments(newList); //T-360562 
  }
  //=========================================================================
  // Before Delete call
  //=========================================================================
  public static void beforeDelete (List<Deployment__c> oldList) {
    preventDeletionOfActiveDeployments(oldList);
  }
  //=========================================================================
  // Display error if an active deployment is deleted
  //=========================================================================
  public static void preventDeletionOfActiveDeployments(List<Deployment__c> oldList){
    for (Deployment__c depRec  : oldList) {
      if (depRec.Active__c == true) {
        depRec.addError(System.Label.SaaS_ERR_DELETE_DEPLOYMENT);
      }
    }
  }

  //========================================================================= 
  // T-360562: Reseting Asset Count field to zero on Deployment License,
  //           to cover cloning condition.
  //=========================================================================
  public static void resetAssetCountOnDeployments (List<Deployment__c> newList) {
  
    String EXPERIAN_GLOBAL_UID = Experian_Global__c.getInstance().OwnerId__c;   
    
    system.debug('*******EXPERIAN_GLOBAL_UID::::::::'+EXPERIAN_GLOBAL_UID); 
    for (Deployment__c depLic : newList) {
      depLic.Asset_Count__c = 0;
      depLic.OwnerId = EXPERIAN_GLOBAL_UID;//As per: T-360567
    }
  }
}