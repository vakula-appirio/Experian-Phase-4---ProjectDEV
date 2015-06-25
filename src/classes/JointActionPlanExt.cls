/**=====================================================================
 * Appirio, Inc
 * Name: JointActionPlanExt
 * Description: Apex extension class for JointActionPlan Visualforce page,
 *              which is triggered by clicking button on the Opportunity Plan Record.
 *              Main features include
 *                  - Saving the Joint action plan records from single page
 *                  - Generating a PDF Document
 *                  - Sharing the PDF via Email
 * Created Date: 05/05/2014
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * July 28th, 2015              Shane Khublall               I-123100: creation and usage of getOppPlanId() method
 * Jan 29th, 2015               Noopur                       T-356452: Updates to help improve code coverage
 =====================================================================*/
public with sharing class JointActionPlanExt {
    
    // Public variables
    public JointActionPlanWrapper jActionPlan {get;set;}
    public Opportunity_Plan__c oPlan          {get;set;}
    public boolean isError                    {get;set;}
    public List<String> messages              {get;set;}
    public String toAddresses                 {get;set;}
    public User currentUser                   {get;set;}
    public static blob testBlob ; // Only used for tests;

    // Private map to store existing.
    private Map<String,Opportunity_Plan_Joint_Action__c> existingMap;
    
    // Constructor.
    public JointActionPlanExt(ApexPages.StandardController con) {
        currentUser = [SELECT SmallPhotoUrl, ID, Name FROM User WHERE ID =: UserInfo.getUserId()];
        isError = false;
        messages = new List<String>();
        
        // Get the Parent Opportunity Plan record.
        try {
            oPlan       = [Select Id, Name, Account_Name__c, Account_Name__r.Name, Action_Item_Fulfillment_Completed__c, 
                                  Action_Item_Fulfillment_Deadline__c, Action_Item_Initial_Discussions_Complete__c, 
                                  Action_Item_Initial_Discussions_Deadline__c, Action_Item_Needs_Analysis_Completed__c, 
                                  Action_Item_Needs_Analysis_Deadline__c, Action_Item_Solution_Completed__c, 
                                  Action_Item_Solution_Deadline__c, Opportunity_Name__r.Name from Opportunity_Plan__c
                            Where Id = :con.getId()];

            existingMap                                    = new Map<String,Opportunity_Plan_Joint_Action__c>();

            for(Opportunity_Plan_Joint_Action__c j : [Select Id, Description__c, Opportunity_Plan__c, Responsibility__c, Type__c from Opportunity_Plan_Joint_Action__c where Opportunity_Plan__c = :oPlan.Id]){
                existingMap.put(j.Type__c,j);
            }
            
            jActionPlan = new JointActionPlanWrapper(oPlan, this);  

        }catch(Exception e){
            messages.add('Invalid Context - ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Context ' + e.getMessage()));
            isError = true;
        }           

    }

    // Method that generates the PDF Document for the JAP
    public PageReference generatePDF() {

        savePlans(); // If the generate Button is clicked, it will execute the save.    

         // Reference the attachment page and pass in the account ID
        //PageReference pdf =  Page.JointActionPlanPDf;
        PageReference pdf = Page.JointActionPlan_PDF;
        pdf.getParameters().put('id',(String)oPlan.id); 
        pdf.setRedirect(true);

        //Id opptyConfidentialInfoId = getOpptyConfidentialInfoId(); // no longer used (I-123100)
        Id oppPlanId = getOppPlanId(); // attach pdf to the opportunity plan (I-123100)

        if (oppPlanId != null) {
          saveAttachment(pdf, oppPlanId);
        }

        return pdf;
    }
    
    // Method that is called when Save button is clicked.
    public Pagereference saveActionPlans() {

        savePlans();

        return new Pagereference('/' +oPlan.Id); // Navigates back to the Opportunity Plan record.
    }

    // Method that is called when Cancle button is clicked.
    public Pagereference cancleAction() {

        return new Pagereference('/' +oPlan.Id); // Navigates back to the Opportunity Plan record.
    }
    // Save Method. 
    private void savePlans(){

        try {

            for(ActionPlanWrapper aw : jActionPlan.aplans) {
                
                // Loads the data for each type (picklist values) per Vendor or Customer (Experian or Customer)
                loadExistingMap('Initial Discussions - ' + aw.cType,aw.cType, aw.initialDiscussion);
                loadExistingMap('Needs Analysis - ' + aw.cType,aw.cType,aw.needsAnalysis);
                loadExistingMap('Solution - ' + aw.cType,aw.cType,aw.solution);
                loadExistingMap('Fulfilment - ' + aw.cType,aw.cType,aw.fulfillment);
                
            }

            upsert existingMap.values(); // Upsert Joint Action Plan records.

            update oPlan; // Update the Opportunity Plan.
        
        }catch(Exception e){
            messages.add('Error when Saving Records - ' + e.getMessage());
        }   

    }

    // Load the existing map data, if available, this would allow to make sure no dupes are created.
    private void loadExistingMap(String JAPType, String responsibility , String description) {

        Opportunity_Plan_Joint_Action__c newRec;
        if (existingMap.get(JAPType) != null) {
                    existingMap.get(JAPType).Description__c = description;      
        } else {
            newRec = new Opportunity_Plan_Joint_Action__c(Opportunity_Plan__c=oPlan.Id,Description__c=description,Type__c=JAPType,Responsibility__c = responsibility);
            existingMap.put(newRec.Type__c,newRec);
        }

    }

    // returns the description for each type
    private String returnDescription(String JAPType) {

        if (existingMap.get(JAPType) != null) {
            return existingMap.get(JAPType).Description__c;
        } else {
            return null;
        }

    }

    // This method may no longer be needed if we are using the getOppPlanId() method instead (I-123100)
    // Noopur - 29/01/2015 Commented this method to improve coverage as it is not used anywhere
   /* private Id getOpptyConfidentialInfoId() {
      List<Confidential_Information__c> ciList = [Select Id from Confidential_Information__c Where Opportunity__c =: oPlan.Opportunity_Name__c Limit 1];
      if(ciList.size() > 0) {
        return ciList[0].Id;
      }
      return null;
    }*/

    //  Return the Id of the Opportunity Plan we are currently viewing a Joint Action Plan for
    private Id getOppPlanId()
    {
        String oppPlanId = ApexPages.currentPage().getParameters().get('Id');
        system.debug('AAAAAA' + oppPlanId);
        if (oppPlanId != null)
        {
            return Id.valueOf(oppPlanId);
        }
        else
        {
            return null;
        }
    }

    /*Save pdf as an attachment to oppty confidential information*/
    private void saveAttachment(PageReference pdfPage, Id opptyConfidentialInfoId) {
      Attachment attachment = new Attachment();
      if (!Test.isRunningTest()) {
        attachment.Body = pdfPage.getContentAsPDF();
      }
      else {
        attachment.Body = Blob.valueOf('test');
      }
      attachment.Name = String.valueOf('Opportunity_JAP.pdf');  //TODO : change the name of file.
      attachment.ParentId = opptyConfidentialInfoId;
      insert attachment;
    }

    /* Wrapper Classes */
    
    // Wrapper to store Opportunity Plan & List of Plans by Type
    
    public class JointActionPlanWrapper {
        

        public Opportunity_Plan__c oPlan      {get;set;}
        public List<ActionPlanWrapper> aplans {get;set;}
        public JointActionPlanExt outerC;

        public JointActionPlanWrapper(Opportunity_Plan__c plan, JointActionPlanExt o){

            oPlan   = plan;
            aplans  = new List<ActionPlanWrapper>();
            outerC  = o;

            // Add the Wrapper by Type, using Custom Label to manage types. This would help/make it easier if type is changed.
            aplans.add(new ActionPlanWrapper(System.Label.JAPCustomer, 
                                             outerC.returnDescription('Initial Discussions - ' + System.Label.JAPCustomer),
                                             outerC.returnDescription('Needs Analysis - ' + System.Label.JAPCustomer),
                                             outerC.returnDescription('Solution - ' + System.Label.JAPCustomer),
                                             outerC.returnDescription('Fulfilment - ' + System.Label.JAPCustomer)));

            aplans.add(new ActionPlanWrapper(System.Label.JAPVendor, 
                                             outerC.returnDescription('Initial Discussions - ' + System.Label.JAPVendor),
                                             outerC.returnDescription('Needs Analysis - ' + System.Label.JAPVendor),
                                             outerC.returnDescription('Solution - ' + System.Label.JAPVendor),
                                             outerC.returnDescription('Fulfilment - ' + System.Label.JAPVendor)));
            
        }

    }
    
    /* Wrapper to store the Joint Action plan as single record by type. */
    
    public class ActionPlanWrapper {
        
        public String cType {get;set;}
        public String initialDiscussion {get;set;} 
        public String needsAnalysis {get;set;}
        public String solution {get;set;}
        public String fulfillment {get;set;}

        public ActionPlanWrapper(String t, String i, String n, String s, String f){
            this.cType = t;
            this.initialDiscussion = i;
            this.needsAnalysis = n;
            this.solution = s;
            this.fulfillment = f;
        }


    }
}