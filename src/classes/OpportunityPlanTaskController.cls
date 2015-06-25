/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanTaskController
 * Description: Controller class for OpportunityPlanTask.page (for T-273784)
 * Created Date: May 2nd, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 * Jan 13th, 2015     Arpita Bose(Appirio)       T-349831: Account Planning Refactoring
 =====================================================================*/
public class OpportunityPlanTaskController {    
    private static final string NONE = '--None--';
    private static final string RECORD_TYPE_TASK_OPPORTUNITY_PLAN = 'Opportunity Plan';
    private static final string TASK_URL_FORMAT = '/00T/e?what_id={opp_plan_id}&retURL=%2Fapex%2FOpportunityPlanTask%3Fid%3D{opp_plan_id}&RecordType={record_type_id}&ent=Task&tsk5={subject}&saveURL=%2F{opp_plan_id}';
  private static final string ERROR_MESSAGE_ACTION_ITEM = 'Either Action item or if Other value is required to progress further';
  private static final string ERROR_MESSAGE_RECORD_TYPE_NOT_EXIST = 'Record type Opportunity Plan does not exist';
  public string opportunityPlanId{get;set;}
  public Map<String, Set<String>> salesStageToActionItemsMap{get;set;}
  public string selectedSalesStage{get;set;}
  public string selectedActionItem{get;set;}
  public string selectedIfOther{get;set;}
  public List<SelectOption> salesStagesOptions{get;set;} 
  public List<SelectOption> actionItemsOptions{get;set;} 
  public String SalesStage {get;set;}
    
  public OpportunityPlanTaskController(){
    // initialize all the properties in constructor
    this.opportunityPlanId = ApexPages.currentPage().getParameters().get('id');    
    List<Opportunity_Plan__c> listPlans = [SELECT Opportunity_Sales_Stage__c FROM Opportunity_Plan__c WHERE id= :opportunityPlanID];
    this.SalesStage = listPlans[0].Opportunity_Sales_Stage__c;
    this.salesStageToActionItemsMap = new Map<String, Set<String>>();
    this.selectedSalesStage = '';
    this.selectedActionItem = '';
    this.selectedIfOther = '';
    this.salesStagesOptions = new List<SelectOption>();
    this.actionItemsOptions = new List<SelectOption>();
  }
  
  public PageReference doPageAction(){
    // this method gets invoked on the action attribute of page tag     
    // and populates the map of sales stages with its dependent action items
    List<Action_Items__c> listActions = [SELECT Sales_Stage__c, Action_Item__c FROM Action_Items__c WHERE Sales_Stage__c != null];
    for(Action_Items__c actionItem : listActions){      
        if(!this.salesStageToActionItemsMap.containsKey(actionItem.Sales_Stage__c)){
            this.salesStageToActionItemsMap.put(actionItem.Sales_Stage__c, new Set<String>());
        }
        this.salesStageToActionItemsMap.get(actionItem.Sales_Stage__c).add(actionItem.Action_Item__c);          
    }
    // populate options for sales stages and action item options.
    this.salesStagesOptions = getSalesStages();
    this.actionItemsOptions = getActionItems();
    return null;
  }
  
  
  public void onChangeSalesStages(){
    // this method is inovked when sales stage is changed on the dropdown
    this.actionItemsOptions = getActionItems();
  }
  
  public PageReference nextAction(){
    // this method is invoked on click of next button.    
    string subject = this.selectedActionItem;
    if((this.selectedActionItem == NULL || this.selectedActionItem.trim().length() == 0) && (this.selectedIfOther == NULL || this.selectedIfOther.trim().length() == 0)){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_MESSAGE_ACTION_ITEM));
      return null;
    }    
    if((subject == NULL || subject.trim().length() == 0) && this.selectedIfOther <> NULL && this.selectedIfOther.trim().length() <> 0){
      subject = this.selectedIfOther;
    }
    string taskOppPlanRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_TASK, RECORD_TYPE_TASK_OPPORTUNITY_PLAN);
    if(taskOppPlanRecordTypeId == NULL){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_MESSAGE_RECORD_TYPE_NOT_EXIST));
      return null;
    }
    string pageReferenceURL = TASK_URL_FORMAT.replace('{opp_plan_id}', this.opportunityPlanId)
                                     .replace('{record_type_id}', taskOppPlanRecordTypeId).replace('{subject}', subject);
    return new pageReference(pageReferenceURL);
  }
  
  public PageReference cancelAction(){
    // this method is invoked on click of cancel button
    string pageReferenceURL = '/' + this.opportunityPlanId;
    return new pageReference(pageReferenceURL);
  }
  
  private List<SelectOption> getSalesStages(){
    // utility method that returns the options for sales stages
    List<SelectOption> salesStagesOption = new List<SelectOption>();
    List<String> salesStages = new List<String>();      
    salesStages.addAll(this.salesStageToActionItemsMap.keyset());
    // set selected sales stage and sort
    if(!salesStages.isEmpty()){      
      this.selectedSalesStage = this.SalesStage;
      salesStages.sort();
    }

    // populate option values for sales stages dropdown
    /*for(String salesStage : salesStages){
        salesStagesOption.add(new SelectOption(salesStage, salesStage));
    }*/
    
    //T-349831 
    for (Opportunity_Sales_Process__c osp : [SELECT Id, Name 
                                             FROM Opportunity_Sales_Process__c 
                                             WHERE Sales_Process_Name__c = :Constants.SALES_PROCESS_STANDARD 
                                             OR Sales_Process_Name__c = :Constants.SALES_PROCESS_LEAD
                                             ORDER BY Sales_Process_Name__c ASC ]) {
       salesStagesOption.add(new SelectOption(osp.Name, osp.Name));
    }
    salesStagesOption.sort();
    
    return salesStagesOption; 
  }  
  
  private List<SelectOption> getActionItems(){ 
    // utility method that returns the options for action items based on selected sales stage.  
    List<SelectOption> actionItemsOption = new List<SelectOption>();
    // give the default/first option as NONE
    actionItemsOption.add(new SelectOption('', NONE));
    // retreive the list of dependent options
    if(this.salesStageToActionItemsMap.containsKey(this.selectedSalesStage)){
        List<String> actionItems = new List<String>();
        actionItems.addAll(this.salesStageToActionItemsMap.get(this.selectedSalesStage));
        // sort the list 
        actionItems.sort();
        // add options with the action items        
        for(String actionItem : actionItems){
          actionItemsOption.add(new SelectOption(actionItem, actionItem));
        }
    }   
    return actionItemsOption; 
  }
  
  
    
}