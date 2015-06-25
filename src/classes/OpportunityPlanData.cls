/*
    Author      : Topcoder Developer
    Description : Controller for generating Opportunity Plan PDF
    
    Date Modified      Modified By                  Description of the update
    Jul 23rd, 2014     Arpita Bose(Appirio)         T-295628: Modified method init() to include all Oppty Plan Contact
                                                    and all Opp Plan Competitor records 
*/

public class OpportunityPlanData {
    
    // Variables
    // limit the records for Contact and Competitor and contact
    // public transient static Integer LIMIT_CONTACT_RECORDS = 3;
    // public transient static Integer LIMIT_COMPETITOR_RECORDS = 3;
        
    // Properties
    public Opportunity_Plan__c objOpportunityPlan { get; set; }
    public List<String> lstSalesObjective { get; set; }
    public List<String> lstClientGoals { get; set; }
    public List<OpportunityPlanWrapper.RatingWrapper> lstOpportunityDetails { get; set; }
    public List<OpportunityPlanWrapper.TableWrapper> lstProjectQualification { get; set; }
    public List<OpportunityPlanWrapper.TableWrapper> lstPositionSummary { get; set; }
    public List<Task> lstTask { get; set; }
    public List<OpportunityTeamMember> lstOtm { get; set; } 
    public List<OpportunityPlanWrapper.ChildRecordsWrapper> lstContactWrapper { get; set;}
    public List<OpportunityPlanWrapper.ChildRecordsWrapper> lstCompetitorWrapper { get; set;}
    public List<Opportunity_Plan_Competitor__c> lstOpCompetitor { get; set; } 
    public List<Opportunity_Plan_Contact__c> lstOpContact { get; set; } 
    //new
    public List<List<Opportunity_Plan_Contact__c>> lstParentOpContact { get; set; }
    public List<List<Opportunity_Plan_Competitor__c>> lstParentOpComp { get; set;}
    
    // Constructor
    public OpportunityPlanData(ApexPages.StandardController stdCtrl) {
        objOpportunityPlan = (Opportunity_Plan__c) stdCtrl.getRecord();
        init();
    }
    
    // init method - called from constructor's action attribute
    public void init() {
        try {
            String opportuityPlanId = objOpportunityPlan.Id;
            
            // Query Opportunity Plan record
            String soql = OpportunityPlanDataUtility.getSoqlQuery(
                OpportunityPlanDataUtility.getAllFields(),
                '' + Opportunity_Plan__c.getSobjectType(),
                'Id= :opportuityPlanId');
            objOpportunityPlan = (Opportunity_Plan__c) database.query(soql)[0];
            
            // Populate the properties using OpportunityPlanDataUtility.cls
            this.lstSalesObjective = OpportunityPlanDataUtility.fetchFieldApiNamesBasedOnRating(
                OpportunityPlanMapping.mapOp_SalesObjectiveFields, 
                objOpportunityPlan,
                false);
            this.lstClientGoals = OpportunityPlanDataUtility.fetchFieldApiNamesBasedOnRating(
                OpportunityPlanMapping.mapOp_ClientGoalFields, 
                objOpportunityPlan,
                false); 
            
            this.lstOpportunityDetails = OpportunityPlanDataUtility.getOpportunityDetails();
            this.lstProjectQualification = OpportunityPlanDataUtility.getProjectQualification();
            
            this.lstTask = OpportunityPlanDataUtility.getTasks(objOpportunityPlan); 
            
            this.lstOtm = OpportunityPlanDataUtility.getOpportunityTeamMember(objOpportunityPlan);
            
            this.lstOpCompetitor = OpportunityPlanDataUtility.getOpportunityPlanCompetitor(objOpportunityPlan);
            
            this.lstOpContact = OpportunityPlanDataUtility.getOpportunityPlanContact(objOpportunityPlan); //old
            
            //T-295628: new code to include all Opp Plan Contact
            List<Opportunity_Plan_Contact__c> tempListOPC = new List<Opportunity_Plan_Contact__c> (); 
            this.lstParentOpContact = new List<List<Opportunity_Plan_Contact__c>> ();
            System.debug('++++++++++++++++++++lstOpContact.size ++++++++++ '+lstOpContact.size());
            System.debug('++++++++++++++++++++lstOpContact.values ++++++++++ '+lstOpContact);
            for(Opportunity_Plan_Contact__c opc : lstOpContact){
            	tempListOPC.add(opc);
            	if(tempListOPC.size() == 3){
            		this.lstParentOpContact.add(tempListOPC);
            		tempListOPC = new List<Opportunity_Plan_Contact__c> (); 
            	}           	
            }
            if(!tempListOPC.isEmpty()){
            	this.lstParentOpContact.add(tempListOPC);
            }
            
            System.debug('++++++++++++++++++++lstParentOpContact.size ++++++++++ '+lstParentOpContact.size());
            System.debug('++++++++++++++++++++lstParentOpContact.values ++++++++++ '+lstParentOpContact);
         //   System.debug('++++++++++++++++++++child1.size ++++++++++ '+lstParentOpContact.get(0).size());
         //   System.debug('++++++++++++++++++++child2.size ++++++++++ '+lstParentOpContact.get(1).size());
            
            //T-295628: new code to include all Opp Plan competitor
            List<Opportunity_Plan_Competitor__c> tempListOPComp = new List<Opportunity_Plan_Competitor__c> (); 
            this.lstParentOpComp = new List<List<Opportunity_Plan_Competitor__c>> ();
            System.debug('++++++++++++++++++++lstOpCompetitor.size ++++++++++ '+lstOpCompetitor.size());
            System.debug('++++++++++++++++++++lstOpCompetitor.values ++++++++++ '+lstOpCompetitor);
            for(Opportunity_Plan_Competitor__c opc : lstOpCompetitor){
                tempListOPComp.add(opc);
                if(tempListOPComp.size() == 3){
                    this.lstParentOpComp.add(tempListOPComp);
                    tempListOPComp = new List<Opportunity_Plan_Competitor__c> (); 
                }               
            }
            if(!tempListOPComp.isEmpty()){
                this.lstParentOpComp.add(tempListOPComp);
            }
            System.debug('++++++++++++++++++++lstParentOpCompetitor.size ++++++++++ '+lstParentOpComp.size());
            System.debug('++++++++++++++++++++lstParentOpCompetitor.values ++++++++++ '+lstParentOpComp);
            
            
            this.lstCompetitorWrapper = OpportunityPlanDataUtility.getChildWrapper(
                (List<SObject>) this.lstOpCompetitor,
                OpportunityPlanMapping.getCompetitorConfigWrapper());
            
            this.lstContactWrapper = OpportunityPlanDataUtility.getChildWrapper(
                (List<SObject>) this.lstOpContact,
                OpportunityPlanMapping.getContactConfigWrapper());
            
            // Apply ascending sorting for rating's List!
            OpportunityPlanWrapper.sortAsc = true;
            
            this.lstPositionSummary = OpportunityPlanDataUtility.getPositionSummary(objOpportunityPlan);

        } catch(Exception objEx) {
            Apexpages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error: ' + objEx
            ));
        } 
    }

        /*Save pdf as an attachment to oppty confidential information*/
    public PageReference saveAttachment(){
        PageReference pdfPage =  Page.OpportunityPlanData;
        pdfPage.getParameters().put('id',(String)objOpportunityPlan.id);       
        pdfPage.getParameters().put('mode','pdf'); 
        Attachment attachment = new Attachment();
        attachment.Body = pdfPage.getContentAsPDF();
        attachment.Name = String.valueOf('OpportunityPlan.pdf');  //TODO : change the name of file.
        attachment.ParentId = objOpportunityPlan.id;
        insert attachment; 
        return null;
   }
    
}