/**=====================================================================
 * Appirio, Inc
 * Name: ARIASupplementalPlanTreeController
 * Description: THIS CLASS WAS CREATED FROM A TOP CODER CHALLENGE
 *              Controller class for ARIASupplementalPlanTree page
 * Created Date: April 07, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 13, 2014                 Jinesh Goyal                 Fixed the Apex CPU limit error
 * Apr 15, 2014                 Nathalie Le Guay             Fixed createFieldValue()
 * May 15, 2014                 Nathalie Le Guay             Setting Master_Plan__c to null if unselected on the page
 * Aug 05, 2014                 Arpita Bose(Appirio)         T-286337: Refactoring of ARIA Classes
 =====================================================================*/
global class ARIASupplementalPlanTreeController {
  public ApexPages.standardController stdController {get; set;}
  private ARIA_Billing_Account__c billingAccountObj {get;set;}
  
  //=====================================================================
  // Constructor taking standard controller as a parameter
  //=====================================================================
  public ARIASupplementalPlanTreeController(ApexPages.standardController controller) {
    stdController = controller;
    String billlingAccountId = ApexPages.currentPage().getParameters().get('id');
    if(String.isNotBlank(billlingAccountId)) {
      billingAccountObj = [Select Id, Billing_Account_Country__c, Pre_Paid_Ind__c, 
                                  Master_Plan__c, Master_Plan_Name__c  
                           From ARIA_Billing_Account__c 
                           Where Id = :billlingAccountId
                           LIMIT 1];
    }
  }
  
  //=====================================================================
  // Constructor
  //===================================================================== 
  public ARIASupplementalPlanTreeController() {}
  
  //=====================================================================
  // Method used to create a tree view html. 
  // @return String  generated tree html
  //===================================================================== 
  public String getPlanTreeHierarchy(){
    List<Aria_Plan__c> masterPlansList = new List<Aria_Plan__c>();
    // Get the masterplanIds 
    /*- If Aria_Billing_Account__c.Pre_Paid_Ind__c =false, filter for Aria_Plan__c.Status='Active'
      - if Aria_Billing_Account__c.Pre_Paid_Ind__c =true, filter for Aria_Plan__c.Status='Active' and ARIA_Plan__c.Pre_Paid_Indicator__c =32*/
    for (Aria_Plan__c plan : ARIASupplementalPlanTreeHelper.mapAriaPlans.values()){
      if (!plan.Supplimental_Plan_Ind__c && plan.Status__c != null 
           && plan.Status__c.equalsIgnoreCase('Active')) { 
          if(billingAccountObj.Pre_Paid_Ind__c) {
            if(plan.Pre_Paid_Indicator__c == '32') {
                masterPlansList.add(plan);
            }
          }
          else {
              if(plan.Pre_Paid_Indicator__c != '32') {
                masterPlansList.add(plan);
              }
          }
      }
    }

    masterPlansList.sort();
    // Create a outputTree
    system.debug('+++++++masterPlansList in controller '+masterPlansList);
    String tempTree = ARIASupplementalPlanTreeHelper.createPlanTreeHierarchy(masterPlansList);
    Integer counter = 0;
    
    Integer countMatchMax = tempTree.countMatches('text-');
    countMatchMax = tempTree.countMatches('checkbx-') > countMatchMax ? tempTree.countMatches('checkbx-') : countMatchMax;
    countMatchMax = tempTree.countMatches('label-') > countMatchMax ? tempTree.countMatches('label-') : countMatchMax;
    system.debug('countMatchMax ++++++++++ '+countMatchMax);
    for ( ; countMatchMax > -1; countMatchMax--) { 
      tempTree = tempTree.replaceFirst('text-', ++counter+'-');
      tempTree = tempTree.replaceFirst('checkbx-', ++counter+'-');
      tempTree = tempTree.replaceFirst('label-', ++counter+'-');
    }
    return tempTree;
  }
  public Boolean noMasterPlan {get;set;} 
  
  //========================================================================
  // Method used to get all the supplemental plan ids for the selected 
  // billing account
  // @ Param accId id of the billing account
  // @ return Set<Id> set of supplemental plan ids for the selected 
  // billing account
  //========================================================================
  @RemoteAction
  global static Set<Id> getSupplementalPlans(String accId){ 
    Set<Id> supplementalPlans = new Set<Id>();
    Set<Id> relationshipIds = new Set<Id>();
    try{
      if (String.isNotBlank(accId)){
        // Get the supplemental plan Ids 
        for (Aria_Plan_Relationship__c plan : [SELECT Id, Child_Plan__c 
                                               FROM Aria_Plan_Relationship__c 
                                               WHERE Child_Plan__c != null 
                                               AND Id IN (SELECT ARIA_Plan_Relationship__c 
                                                          FROM ARIA_Billing_Account_Supplimental_Plans__c 
                                                          WHERE ARIA_Billing_Account__c = :accId
                                                          AND ARIA_Plan_Relationship__c != null)
                                               LIMIT 10000]){
          supplementalPlans.add(plan.Child_Plan__c);
        }
      }
    }catch(Exception ex){
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
    }
    system.debug('++++++++++++++++++supplementalPlans '+supplementalPlans);
    return supplementalPlans;
  }

  //=======================================================================
  // Method used to get all the supplemental plans for the 
  // selected billing account and put it in ObjectStructureMap 
  // @ return List<ObjectStructureMap> List of all the supplemental plans 
  // for the selected billing account
  //=======================================================================
  public List<ObjectStructureMap> getSelectedPlans(){
    List<ObjectStructureMap> objMap = new List<ObjectStructureMap>();
    try{
      String accountId = ApexPages.currentPage().getParameters().get('id');
      System.debug('\n[ARIASupplementalPlanTreeController : getSelectedPlans] : Account Id: '+ accountId);
      if (!String.isBlank(accountId)){
        Map<Id, Aria_Plan__c> mapAriaPlans = new Map<Id, Aria_Plan__c>(
                                                 [SELECT Id, Name, Plan_Currency__c, Aria_Id__c, Status__c, OwnerId, Country__c,
                                                         Plan_Name__c, Supplimental_Plan_Ind__c, Plan_Number__c, Pre_Paid_Indicator__c
                                                  FROM Aria_Plan__c 
                                                  LIMIT 10000]);
        Aria_Billing_Account__c billingAccount = [SELECT Id, Master_Plan__c, Master_Plan_Name__c 
                                                  FROM Aria_Billing_Account__c 
                                                  WHERE Id=: accountId 
                                                  LIMIT 1];

        if (billingAccount != null){
          if (billingAccount.Master_Plan__c != null){
            System.debug('\n[ARIASupplementalPlanTreeController : getSelectedPlans] : This is a parent_end: '+ billingAccount.Id);
            // Get the master plan
            objMap.add(new ObjectStructureMap('0','parent_end',mapAriaPlans.get(billingAccount.Master_Plan__c)));
          }
        } 
        // Get the supplimental plans 
        List<ARIA_Billing_Account_Supplimental_Plans__c> rsSupplementalPlans = [SELECT Id, Supplemental_Plan_Id__c, ARIA_Plan_Relationship__c, Supplimental_Plan_Name__c 
                                                                                FROM ARIA_Billing_Account_Supplimental_Plans__c 
                                                                                WHERE ARIA_Billing_Account__c=:accountId 
                                                                                ORDER BY Supplimental_Plan_Name__c 
                                                                                LIMIT 10000];
        for (Integer i=0;i<rsSupplementalPlans.size();i++){ 
          if (rsSupplementalPlans[i].Supplemental_Plan_Id__c != null){
            String typeOfchild = (i < rsSupplementalPlans.size()) ? 'child' : 'child_end';
            System.debug('\n[ARIASupplementalPlanTreeController : getSelectedPlans] : This is a : '+ typeOfchild + ' : '+ rsSupplementalPlans[i].Supplemental_Plan_Id__c);
            objMap.add(new ObjectStructureMap('0.'+i,(i < rsSupplementalPlans.size() ? 'child' : 'child_end'),mapAriaPlans.get(rsSupplementalPlans[i].Supplemental_Plan_Id__c)));
          }
        }
      }
    }catch(Exception ex){
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
    }
    return objMap;
  }

  //=======================================================================
  // Method used to update the selected master plan for the billing account.
  // Delete the old supplements plans and create a new supplements plans
  // for the billing account
  // @ return PageReference Detail page of the billing account
  //=======================================================================
  public PageReference savePlansRelated () {
    Aria_Billing_Account__c account = (Aria_Billing_Account__c)stdController.getRecord();
    List<ARIA_Billing_Account_Supplimental_Plans__c> supPlansToDelete = new List<ARIA_Billing_Account_Supplimental_Plans__c>();
    List<ARIA_Billing_Account_Supplimental_Plans__c> supPlansToInsert = new List<ARIA_Billing_Account_Supplimental_Plans__c>();
    String masterPlanId = ApexPages.currentPage().getParameters().get('masterPlanId');
    Map <String, String> mapParentToChildProcessed = new Map <String, String>();
    try{
      // Update billing account
      if (!String.isBlank(masterPlanId)){
        System.debug('testing saving master plan id '+ApexPages.currentPage().getParameters().get('masterPlanId'));
        account.Master_Plan__c = String.valueOf(masterPlanId).substringAfterLast('-');
        masterPlanId = account.Master_Plan__c;
        system.debug('+++++++++++++++++++++++++++ account.Master_Plan__c '+account.Master_Plan__c);
      } else {
        account.Master_Plan__c = null;
      }
      update account;

      supPlansToDelete = [SELECT Id 
                          FROM ARIA_Billing_Account_Supplimental_Plans__c 
                          WHERE ARIA_Billing_Account__c=:account.Id];
      if (!supPlansToDelete.isEmpty()) delete supPlansToDelete;

      // Create a new relationships 
      if (String.isNotBlank(ApexPages.currentPage().getParameters().get('selectedPlans'))){
        system.debug('+++++++++++++++++++++++++++ selectedPlans '+ApexPages.currentPage().getParameters().get('selectedPlans'));
        Map<Id, Id> mapPlansToId = new Map<Id, Id> ();

        List<String> selectedPlans = new List<String> ();
        
        for(String childPlanId : ApexPages.currentPage().getParameters().get('selectedPlans').split(',')){
          selectedPlans.add(childPlanId.substringAfterLast('-'));
        }

        // Check if selected ids is not null
        if (!selectedPlans.isEmpty()){
        	// create Set to avoid duplicates
          Set<String> selectedPlansSet = new Set<String>(selectedPlans); 
          Map<Id, ARIA_Plan_Relationship__c> mapAriaPR = ARIASupplementalPlanTreeHelper.mapAriaPlanRelationships;
          //create map for child plan id to ARIA Plan Relationship Id
          system.debug('+++++++++++++ mapPlansToId 1 '+mapPlansToId);
          system.debug('+++++++++++++ masterPlanId '+masterPlanId);
          for (String planId : selectedPlansSet){
              for (ARIA_Plan_Relationship__c ariaPR : mapAriaPR.values()) {
                if(ariaPR.Parent_Plan__r.Supplimental_Plan_Ind__c == false 
                    && ariaPR.Parent_Plan__c == masterPlanId
                    && ariaPR.Child_Plan__c == planId){
                  system.debug('+++++++++++master to child ');
                  mapPlansToId.put(ariaPR.Child_Plan__c, ariaPR.Id);
                  break;
                } else if (selectedPlansSet.contains(ariaPR.Parent_Plan__c) && ariaPR.Child_Plan__c == planId) {
                    mapPlansToId.put(ariaPR.Child_Plan__c, ariaPR.Id);
                    break;
                }
              }
          }
          system.debug('+++++++++++++ mapPlansToId 2 '+mapPlansToId);
          for (String planId : selectedPlansSet){
            if (mapPlansToId.get(planId) != null){
              supPlansToInsert.add(new ARIA_Billing_Account_Supplimental_Plans__c(ARIA_Billing_Account__c = account.Id, ARIA_Plan_Relationship__c = mapPlansToId.get(planId)));
            }
            // NLG - we need to add the Master Plan as well in the case the Master Plan is the only item selected
            else {
              system.debug('\nThis plan was not found in the map: '+ planId);
            }
          }
        }

        if (!supPlansToInsert.isEmpty()) insert supPlansToInsert;
      }
    }catch(Exception ex){
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ARIABillingAccount_Error_Saving_Plans));
       return null;
    }
    return new PageReference('/'+billingAccountObj.Id);
  }

  //=====================================================================
  // Wrapper class
  //=====================================================================
  public with sharing class ObjectStructureMap{
    public String nodeId {get; set;}
    public Boolean[] levelFlag {get; set;}
    public Boolean[] closeFlag {get; set;}
    public String nodeType {get; set;}
    public String recordName {get; set;}
    public String fieldValue {get; set;}
    public Boolean currentNode {get; set;}
    
    public ObjectStructureMap(String nodeId,String nodeType, Aria_Plan__c ariaPlan){
      this.nodeId = nodeId;
      this.nodeType = nodeType;
      this.levelFlag = new Boolean[]{false};
      this.closeFlag = new Boolean[]{};
      this.recordName = ariaPlan.Plan_Name__c; 
      this.currentNode = false;
      this.fieldValue = '';

      // Selected Field values
      createFieldValue(ariaPlan);
    } 

    //Method used to get field values for the selected fields
    private void createFieldValue(Aria_Plan__c ariaPlan){
      // Loop through fields 
      String fieldName;
      List<Schema.FieldSetMember> fieldsList = SObjectType.ARIA_Plan__c.FieldSets.ARIA_Supplemental_Plan_Tree.getFields();
      for (Schema.FieldSetMember field : fieldsList) {
         fieldName = field.getFieldPath();
         if (fieldName.toLowerCase() != 'plan_name__c'){
           this.fieldValue += (ariaPlan.get(fieldName.toLowerCase().trim()) != null ? ', ('+ariaPlan.get(fieldName.toLowerCase().trim())+ ')' : '');
         }
      }
    }
  }
  //=======================================================================
  // Method to return back to ARIA Billing Account
  //=======================================================================
  public PageReference goBack() {
    return new PageReference('/' + stdController.getRecord().Id);
  }
}