public class AccountPlanTaskController {
    private static final string NONE = '--None--';
    private static final string RECORD_TYPE_TASK_ACCOUNT_PLAN = 'Account Plan';
    private static final string TASK_URL_FORMAT = '/00T/e?what_id={acc_plan_id}&retURL=%2Fapex%2FAccountPlanTask%3Fid%3D{acc_plan_id}&RecordType={record_type_id}&ent=Task&tsk5={subject}&saveURL=%2F{acc_plan_id}';
  private static final string ERROR_MESSAGE_ACTION_ITEM = 'Either Action item or if Other value is required to progress further';
  private static final string ERROR_MESSAGE_RECORD_TYPE_NOT_EXIST = 'Record type Account Plan does not exist';
  public string accountPlanId{get;set;}
  public Map<String, Set<String>> categoryToActionItemsMap{get;set;}
  public string selectedCategory{get;set;}
  public string selectedActionItem{get;set;}
  public string selectedIfOther{get;set;}
  public List<SelectOption> categoryOptions{get;set;} 
  public List<SelectOption> actionItemsOptions{get;set;} 
    
  public AccountPlanTaskController(){
    // initialize all the properties in constructor
    this.accountPlanId = ApexPages.currentPage().getParameters().get('id');    
    this.categoryToActionItemsMap = new Map<String, Set<String>>();
    this.selectedCategory = '';
    this.selectedActionItem = '';
    this.selectedIfOther = '';
    this.categoryOptions = new List<SelectOption>();
    this.actionItemsOptions = new List<SelectOption>();
  }
  
  public PageReference doPageAction(){
    // this method gets invoked on the action attribute of page tag     
    // and populates the map of sales stages with its dependent action items
    List<Action_Items__c> listActions = [Select category__c, action_item__c From Action_Items__c Where category__c != null];
    for(Action_Items__c actionItem : listActions){      
        if(!this.categoryToActionItemsMap.containsKey(actionItem.Category__c)){
            this.categoryToActionItemsMap.put(actionItem.Category__c, new Set<String>());
        }
        this.categoryToActionItemsMap.get(actionItem.Category__c).add(actionItem.Action_Item__c);          
    }
    // populate options for sales stages and action item options.
    this.categoryOptions = getCategories();
    this.actionItemsOptions = getActionItems();
    return null;
  }
  
  
  public void onChangeCategories(){
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
    string taskAccPlanRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_TASK, RECORD_TYPE_TASK_Account_PLAN);
    if(taskAccPlanRecordTypeId == NULL){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_MESSAGE_RECORD_TYPE_NOT_EXIST));
      return null;
    }
    string pageReferenceURL = TASK_URL_FORMAT.replace('{acc_plan_id}', this.accountPlanId)
                                     .replace('{record_type_id}', taskAccPlanRecordTypeId).replace('{subject}', subject);
    return new pageReference(pageReferenceURL);
  }
  
  public PageReference cancelAction(){
    // this method is invoked on click of cancel button
    string pageReferenceURL = '/' + this.accountPlanId;
    return new pageReference(pageReferenceURL);
  }
  
  private List<SelectOption> getCategories(){
    // utility method that returns the options for sales stages
    List<SelectOption> categoriesOption = new List<SelectOption>();
    categoriesOption.add(new SelectOption('', NONE));
    List<String> categories = new List<String>();      
    categories.addAll(this.categoryToActionItemsMap.keyset());

    // populate option values for sales stages dropdown
    for(String cat : categories){
        categoriesOption.add(new SelectOption(cat, cat));
    }
    return categoriesOption; 
  }  
  
  private List<SelectOption> getActionItems(){ 
    // utility method that returns the options for action items based on selected sales stage.  
    List<SelectOption> actionItemsOption = new List<SelectOption>();
    // give the default/first option as NONE
    actionItemsOption.add(new SelectOption('', NONE));
    // retreive the list of dependent options
    if(this.categoryToActionItemsMap.containsKey(this.selectedCategory)){
        List<String> actionItems = new List<String>();
        actionItems.addAll(this.categoryToActionItemsMap.get(this.selectedcategory));
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