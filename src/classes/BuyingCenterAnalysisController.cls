/**=====================================================================
 * Appirio, Inc
 * Name: BuyingCenterAnalysisController
 * Description: Controller for BuyingCenterAnalysis.page
 * Created Date: 
 * Created By: 
 * 
 * Date Modified      Modified By                Description of the update
 * Oct 21st, 2014     Pratibha Chhimpa           T-325983: adding field in fetchContacts()
 * March 31th, 2015   Nur Azlini                 Case #554908: Add information on Opportunity Plan Contact Diagram. Job Title, Role, Primary Owner, Business Goal (First entry), Personal Goal (First Entry), Decision Criteria (First Entry).
 =====================================================================*/
public without sharing class BuyingCenterAnalysisController {
    
    public String planId {get;set;}
    public List<OpportunityPlanContactWrapper> OppPlanContacts {get;set;}
    public List<OpportunityPlanContactWrapper> TopOppPlanContacts {get;set;}
    Map<Id,OpportunityPlanContactWrapper> mapOppPlanContacts;
    public Map<Integer,List<OpportunityPlanContactWrapper>> mapLevels {get;set;}
    public Attachment contactRelationImage {get;set;}
    
    public BuyingCenterAnalysisController(){
        init();        
    }
    
    public BuyingCenterAnalysisController(ApexPages.StandardController stdController) {  
        init();     
    }
    
    private void init(){        
        planId = ApexPages.currentPage().getParameters().get('id');
        OppPlanContacts = new List<OpportunityPlanContactWrapper> ();
        mapOppPlanContacts = new Map<Id,OpportunityPlanContactWrapper> ();
        TopOppPlanContacts = new List<OpportunityPlanContactWrapper>  ();
        
        mapLevels = new Map<Integer,List<OpportunityPlanContactWrapper>>();
        for(Attachment att : [Select Id From Attachment Where ParentId = :planId and Name = 'ContactRelationImage']){
            ContactRelationImage = att;
        }
        fetchContacts();
    }

    private void fetchContacts(){
        
        //prepare map
        List<Opportunity_Plan_Contact__c> lstOppPlanContacts = [
          SELECT Id, Reports_to__c, Opportunity_Plan__c, Name, Contact__c, Contact__r.Name, 
            Role__c, Degree_of_Influence__c, Opinion__c, Urgency__c, Contact__r.Title, Primary_Owner__r.Name,Personal_Goal_1__c, Business_Goal_1__c, Decision_Criteria_1__c
          FROM Opportunity_Plan_Contact__c 
          where Opportunity_Plan__c =: planId
        ];
       
        for(Opportunity_Plan_Contact__c oppPlanContact : lstOppPlanContacts){
            
            OpportunityPlanContactWrapper wrapper = new OpportunityPlanContactWrapper(oppPlanContact);
            OppPlanContacts.add(wrapper);
             
            mapOppPlanContacts.put(oppPlanContact.Id , wrapper);
        }        
        
        //setup hierarchy 
        system.debug('~~Opps in the list~~' + OppPlanContacts);
        for(OpportunityPlanContactWrapper reportTOContact : OppPlanContacts){
            if(mapOppPlanContacts.containsKey(reportTOContact.currentContact.Reports_to__c)){
                mapOppPlanContacts.get(reportTOContact.currentContact.Reports_to__c).reportedBy.add(reportTOContact);
                reportTOContact.reportedTo = mapOppPlanContacts.get(reportTOContact.currentContact.Reports_to__c);
            }else{
                TopOppPlanContacts.add(reportTOContact);   
            }                         
        }      
        
        //check for max level
        Integer maxLevels = 0;
        for(OpportunityPlanContactWrapper reportTOContact : OppPlanContacts){
            integer tempDepth = reportTOContact.getLevelDepth();            
            system.debug( '~~depth~~' + tempDepth + '~~~Current Contact~~~~~~' + reportTOContact);
            maxLevels = maxLevels > tempDepth? maxLevels : tempDepth;
        }        
        system.debug('~~~~~~Max Level~~~~~~~~~~' + maxLevels);     
        
        
        for(Integer level = 1 ; level <= maxLevels ; level++){
            mapLevels.put(level, new List<OpportunityPlanContactWrapper>());
            if(level == 1){
                mapLevels.get(level).addAll(TopOppPlanContacts);
            }else{
                for(OpportunityPlanContactWrapper reportTOContact : mapLevels.get(level - 1)){
                    mapLevels.get(level).addAll(reportTOContact.reportedBy);
                } 
            }
        }
        
      // Here Plan_Contact_Relationship__c records with all contacts of selected Opportunity Plan is fetched.
      // Positive and Negative Relationship endpoints are added in string .
      if(mapOppPlanContacts.size() > 0){
          for(Plan_Contact_Relationship__c pcl: [Select Relationship__c, Contact_2__c, Contact_1__c From Plan_Contact_Relationship__c  where (Contact_2__c IN:mapOppPlanContacts.keyset() and Contact_1__c IN:mapOppPlanContacts.keyset())]){
            if(pcl.Relationship__c == 'Positive'){
                mapOppPlanContacts.get(pcl.Contact_1__c).positiveForSomeone.add(mapOppPlanContacts.get(pcl.Contact_2__c));
                mapOppPlanContacts.get(pcl.Contact_2__c).positiveAboutMyself.add(mapOppPlanContacts.get(pcl.Contact_1__c));
            }else if(pcl.Relationship__c=='Negative'){              
                mapOppPlanContacts.get(pcl.Contact_1__c).negativeForSomeone.add(mapOppPlanContacts.get(pcl.Contact_2__c));
                mapOppPlanContacts.get(pcl.Contact_2__c).negativeAboutMyself.add(mapOppPlanContacts.get(pcl.Contact_1__c));
            }
          }
     }
     
     
    }
 
    public class OpportunityPlanContactWrapper{
        public List<OpportunityPlanContactWrapper> positiveAboutMyself{get;set;}
        public List<OpportunityPlanContactWrapper> negativeAboutMyself{get;set;}
        public List<OpportunityPlanContactWrapper> positiveForSomeone{get;set;}
        public List<OpportunityPlanContactWrapper> negativeForSomeone{get;set;}
        public List<OpportunityPlanContactWrapper> reportedBy{get;set;}
        public Opportunity_Plan_Contact__c currentContact {get;set;}
        public OpportunityPlanContactWrapper reportedTo{get;set;}
        
        public integer getLevelDepth(){
            integer result = 1;          
            integer reporttoLevelDepth = 0;
            for(OpportunityPlanContactWrapper wrapper : reportedBy){
                integer tempDepth = wrapper.getLevelDepth();
                reporttoLevelDepth  = reporttoLevelDepth > tempDepth ? reporttoLevelDepth : tempDepth;
            }
            return reporttoLevelDepth + result;
        }
        
        public integer getLevelSize(){
            integer result = reportedBy.size();         
            integer reporttoLevelSize = 0;
            for(OpportunityPlanContactWrapper wrapper : reportedBy){
                reporttoLevelSize += wrapper.getLevelSize();
            }
            result = result < reporttoLevelSize ? reporttoLevelSize : result;
            result = result == 0 ? 1 : result;
            return result;
        }
        
        public OpportunityPlanContactWrapper(Opportunity_Plan_Contact__c currentContact){           
            this.currentContact = currentContact;
            negativeAboutMyself = new List<OpportunityPlanContactWrapper>();
            positiveAboutMyself = new List<OpportunityPlanContactWrapper>();
            positiveForSomeone = new List<OpportunityPlanContactWrapper>();
            negativeForSomeone = new List<OpportunityPlanContactWrapper>();
            reportedBy = new List<OpportunityPlanContactWrapper>();
            
        }
    }
}