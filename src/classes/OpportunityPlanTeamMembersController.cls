/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanTeamMembersController
 * Description: Controller class for OpportunityPlanTeamMembers vf page (for T-273984)
 * Created Date: April 28th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 =====================================================================*/
public without sharing class OpportunityPlanTeamMembersController {
	public string opportunityId{get;set;}
	public string addButtonURL{get;set;}
	public transient List<OpportunityTeamMember> oppTeamMembers{get;set;}
	private Opportunity_Plan__c oppPlan{get;set;}
	private static final string ADD_BUTTON_FORMAT = '/ui/opportunity/team/MultiOpportunityTeamMemberEdit?oppId={opp_id}&retURL=%2F{opp_plan_id}&saveURL=%2F{opp_plan_id}';
	// constructor
  public OpportunityPlanTeamMembersController(ApexPages.StandardController stdController){
  	this.oppPlan = (Opportunity_Plan__c)stdController.getRecord();  
  }
    
  public PageReference doPageAction(){
  	this.opportunityId = oppPlan.Opportunity_Name__c; 
    this.addButtonURL = ADD_BUTTON_FORMAT.replace('{opp_id}', this.opportunityId).replace('{opp_plan_id}', this.oppPlan.id);
    this.oppTeamMembers = this.retrieveOpportunityTeamMembers();
    return null;
  }
  
  public List<OpportunityTeamMember> retrieveOpportunityTeamMembers(){
    // get list of opportunity team members based on opportunity id.
    List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();   
    if(this.opportunityId <> NULL){
      oppTeamMembers = [SELECT User.Name, UserId, TeamMemberRole
                        From OpportunityTeamMember
                        WHERE OpportunityId =: this.opportunityId
                        ORDER BY createddate asc]; 
    }
    return oppTeamMembers;
  }
     
}