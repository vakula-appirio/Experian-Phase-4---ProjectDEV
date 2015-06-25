/**=====================================================================
 * Appirio, Inc
 * Name: ARIABillingAccount_ChooseParentCont 
 * Description: controller for page ARIABillingAccount_ChooseParent.page
 * Created Date: March 31st, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified            Modified By                  Description of the update
 * Mar 31, 2014             Nathalie Le Guay (Appirio)   Change class name
 * Apr 07, 2014             Arpita Bose(Appirio)         T-269372: Added addError()in try-catch block
 * Apr 17, 2014             Nathalie Le Guay             Added condition in query: ARIA_Billing_Account_Status__c to be 'Active'
 * Apr 18, 2014             Naresh Kr Ojha               Updated goBack() method to use setRedirect(true) and used it as actionFunc on page
 * May 1st, 2014            Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException Line#67
 * aug 05th, 2014           Arpita Bose                  T-286337: Refactoring of ARIA classes
 =====================================================================*/
public with sharing class ARIABillingAccount_ChooseParentCont {

  // Declare variables
  String parentAccountId;
  String currentARIABillingAccountId;
  public ARIA_Billing_Account__c currentARIABillingAccount {get;set;}
  public String parentARIABillingAccountSelectedId {get;set;}
  public String responsibilityLevel {get;set;}
  public Map <String, ARIA_Billing_Account__c> mapIdToEligibleParents {get;set;}
  
  //====================================================================== 
  // Constructor
  //======================================================================
  public ARIABillingAccount_ChooseParentCont() {
    parentAccountId = ApexPages.currentPage().getParameters().get('acctId');
    currentARIABillingAccountId = ApexPages.currentPage().getParameters().get('Id');

    //return and display error on page if the query string parameters are missing from page URL
    if (String.isBlank(parentAccountId) || String.isBlank(currentARIABillingAccountId)) {
      return;
    }
    for (ARIA_Billing_Account__c ariaBA : [SELECT Id, Name, Billing_Account_Name__c,
                                                  Account__r.Name , Aria_Parent_Account_Number__c,
                                                  Responsibility_Level__c, ARIA_Billing_Account_Status__c,
                                                  Parent_Billing_Account_Name__c, Parent_Billing_Account_Name__r.Responsibility_Level__c
                                           FROM ARIA_Billing_Account__c 
                                           WHERE Id =: currentARIABillingAccountId
                                           LIMIT 1]) {
      currentARIABillingAccount = ariaBA;
      currentARIABillingAccount.Responsibility_Level__c = ariaBA.Responsibility_Level__c;
      parentARIABillingAccountSelectedId = ariaBA.Parent_Billing_Account_Name__c;
    }
    system.debug('+++++++++++++++++++++++currentARIABillingAccount '+currentARIABillingAccount);
    system.debug('+++++++++++++++++++++++parentARIABillingAccountSelectedId '+parentARIABillingAccountSelectedId);
    system.debug('+++++++++++++++++++++++responsibilityLevel '+responsibilityLevel);
    mapIdToEligibleParents = new Map <String, ARIA_Billing_Account__c> ();
    findEligibleParents(parentAccountId);
  }
  
  //=====================================================================
  // Save method
  //=====================================================================
  public PageReference save() {
    System.debug('\n[parentARIABillingAccountSelectedId : save] +++++++++++++++++ '+parentARIABillingAccountSelectedId);
    System.debug('\n[responsibilityLevel : save] +++++++++++++++++ '+responsibilityLevel);
    if (parentARIABillingAccountSelectedId == '') {
      parentARIABillingAccountSelectedId = null;
    }
    if (responsibilityLevel == '') {
      responsibilityLevel = null;
    }
    currentARIABillingAccount.Parent_Billing_Account_Name__c = parentARIABillingAccountSelectedId;
    currentARIABillingAccount.Responsibility_Level__c = responsibilityLevel;
    System.debug('\n[ARIABillingAccount_ChooseParentCont : save] +++++++++++++++++ '+currentARIABillingAccount);
    try {
        update currentARIABillingAccount;
    } catch (DMLException ex) {
    for (Integer i=0; i < ex.getNumDml(); i++) {
      currentARIABillingAccount.addError(ex.getDMLMessage(i));
    }
      return null;
    }
    return (new PageReference('/'+currentARIABillingAccountId));
  }
  
  //======================================================================
  //Method to find eligible parent 'ARIA Billing Accounts'
  //======================================================================
  private void findEligibleParents (String accId) {
    String tempParentAccountId = accId;
    Boolean foundChildARIAForCurrentAccount, noParentAccount;
    while (tempParentAccountId != null) {
      foundChildARIAForCurrentAccount = noParentAccount = false;
      for (ARIA_Billing_Account__c ariaBA : [SELECT Id, Name, CRM_ID__c, Billing_Account_Number__c, Billing_Account_Name__c,
                                                    Parent_Accnt_Name__c, Aria_Parent_Account_Number__c,
                                                    Responsibility_Level__c, Account__r.ParentId,
                                                    Account_Name__c, ARIA_Billing_Account_Status__c
                                             FROM ARIA_Billing_Account__c 
                                             WHERE Account__c = :tempParentAccountId AND Billing_System_Ref__c != null
                                             AND Id != :currentARIABillingAccountId //to exclude the current ARIA Billing Account
                                             AND ARIA_Billing_Account_Status__c =: Constants.STATUS_ACTIVE]) {
        foundChildARIAForCurrentAccount = true;
        mapIdToEligibleParents.put (ariaBA.Id, ariaBA);
        tempParentAccountId = ariaBA.Account__r.ParentId;
      }
      //when the above query returns 0 results
      if (!foundChildARIAForCurrentAccount) {
        for (Account acc : [SELECT Id, ParentId FROM Account WHERE Id = :tempParentAccountId LIMIT 1]) {
          tempParentAccountId = acc.ParentId;  
          noParentAccount = true;
        }
      }
      //if there is no sibling or eligible parent candidate
      if (!foundChildARIAForCurrentAccount && !noParentAccount) {
        tempParentAccountId = null;
      }
      //check query limits
      if (checkQueryLimits()) {
        break;
      }
    }
    //Find all the children - those are ARIA Billing Account that will not be eligible 
    //to prevent recursive hierarchy
    for (ARIA_Billing_Account__c ariaBA : [SELECT Id FROM ARIA_Billing_Account__c 
                                           WHERE (Parent_Billing_Account_Name__c = :currentARIABillingAccountId OR
                                                  Parent_Billing_Account_Name__r.Parent_Billing_Account_Name__c = :currentARIABillingAccountId)
                                           AND ARIA_Billing_Account_Status__c =: Constants.STATUS_ACTIVE]){
      if (mapIdToEligibleParents.containsKey(ariaBA.Id)) {
        mapIdToEligibleParents.remove (ariaBA.Id);
      }
    }
  }
  //========================================================================
  //Method to return to parent page
  //========================================================================
  public PageReference goBack() {
    Pagereference pg = new PageReference('/' + currentARIABillingAccountId);
    pg.setRedirect(true);
    return pg;
  }
  //========================================================================
  //Method to check query limits
  //========================================================================
  private static Boolean checkQueryLimits() {
    if (Integer.valueOf(Limits.getQueries()) >= 80) {
      return true;
    }
    return false;
  }
}