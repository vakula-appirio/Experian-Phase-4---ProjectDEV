public with sharing class ScoringPlanController {
  
  /* 
  * Date Modified      Modified By                  Description of the update
  * Feb 12th, 2015     Paul Kissick                 Case #383855 - Fixed ScoringPlan attachments check in fetchRadarChartImageId method.
  */
    
    public Class ScoringPlanException extends Exception {}
    public final Opportunity_Plan__c opportunityPlanObj{get;set;}
    public Integer oppStageProgress {get;set;}
    public Integer informationScoringScore {get;set;}
    public Integer qualificationScoringScore {get;set;}
    public Integer buyingCentreScore {get;set;}
    public Integer competitionScoringScore {get;set;}
    public Integer summaryPositionScore {get;set;}
    public Integer solutionAtGlanceScore {get;set;}
    public Integer jointActionPlanScore {get;set;}
    public Integer valuePropositionScore {get;set;}
    public Integer actionPlanScore {get;set;}
    public Integer overallScore {get;set;}
    public String planIds {get;set;}
    public Id radarChartImageFirstId {get;set;}
    public Id radarChartImageSecondId {get;set;}
    /*
    Constructor
    */
    public ScoringPlanController(ApexPages.StandardController stdController){ // Modified for T-295628 by Arpita Bose(Appirio)
        String planId = ApexPages.CurrentPage().getParameters().get('Id');
        planIds = planId;
        //Call to retrive Opportunity Plan Contacts.
        opportunityPlanObj = retrieveOpportunityPlanRecord(planId);
        //Call to retrive Opportunity Stage Progress.
        System.Debug('###'+opportunityPlanObj.Opportunity_Name__r.StageName);
        oppStageProgress = getOpportunityStageProgressNumber(opportunityPlanObj.Opportunity_Name__r.StageName);
        System.Debug('###'+oppStageProgress);
        //Call to Plan Analysis
        calculateAnalysisPercentage(opportunityPlanObj);
        system.debug('opportunityPlanObj ===============>' + opportunityPlanObj);
        fetchRadarChartImageId();
    }
    
    public ScoringPlanController(){
        String planId = ApexPages.CurrentPage().getParameters().get('Id');
        system.debug('###planId##' +planId);
        planIds = planId;
        //Call to retrive Opportunity Plan Contacts.
        opportunityPlanObj = retrieveOpportunityPlanRecord(planId);
        //Call to retrive Opportunity Stage Progress.
        System.Debug('###1##'+opportunityPlanObj.Opportunity_Name__r.StageName);
        oppStageProgress = getOpportunityStageProgressNumber(opportunityPlanObj.Opportunity_Name__r.StageName);
        System.Debug('###2##'+oppStageProgress);
        //Call to Plan Analysis
        calculateAnalysisPercentage(opportunityPlanObj);
        system.debug('opportunityPlanObj ===============>' + opportunityPlanObj);
        fetchRadarChartImageId();
    }
  
  public void fetchRadarChartImageId(){
        // PK: CASE #383855, Issue as this would always fail is there are more than 1 of each image.
        /* List<Attachment> radarChart = [Select Id From Attachment Where ParentId = :planIds and Name IN ('ScoringPlan1','ScoringPlan2')  order By Name]; */
        List<Attachment> radarChart1 = [Select Id From Attachment Where ParentId = :planIds and Name IN ('ScoringPlan1')  order By LastModifiedDate DESC LIMIT 1];
        List<Attachment> radarChart2 = [Select Id From Attachment Where ParentId = :planIds and Name IN ('ScoringPlan2')  order By LastModifiedDate DESC LIMIT 1];
        
        if(radarChart1.size() == 1) {
          radarChartImageFirstId = radarChart1[0].Id;
        }
        if (radarChart2.size() == 1) {
          radarChartImageSecondId = radarChart2[0].Id;
        }
    }
    
    // Method that is called when Cancel button is clicked.
    public Pagereference cancelAction(){

        return new Pagereference('/' +opportunityPlanObj.Id); // Navigates back to the Opportunity Plan record.
    }

    /*
        This private method is responsible to calculate the percentage of the plan analysis by calling existing API's called OpportunityPlanScoreCalc.calculateScore.
        @param : Id oppPlanId : opporutity plan id.
    */
    private void calculateAnalysisPercentage(Opportunity_Plan__c oppPlan){
        //Map<String, Decimal> scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Information Scoring');

        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            informationScoringScore = Math.round(oppPlan.Opportunity_Historypercent__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Qualification Scoring');
       // if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            qualificationScoringScore = Math.round(oppPlan.Qualification_Profile__c);
       // }

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Buying Centre');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            buyingCentreScore = Math.round(oppPlan.Buying_Center_Analysis__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Competition Scoring');
       // if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            competitionScoringScore = Math.round(oppPlan.Competition__c);
        //}

       // scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Summary Position');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            summaryPositionScore = Math.round(oppPlan.Summary_Position_Today__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Solution at a Glance');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            solutionAtGlanceScore = Math.round(oppPlan.Solution_at_a_Glance__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Joint Action Plan');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            jointActionPlanScore = Math.round(oppPlan.Joint_Action_Plan__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Value Proposition');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            valuePropositionScore = Math.round(oppPlan.Value_Propositions__c);
        //}

        //scoreResultMap = OpportunityPlanScoreCalc.calculateScore(oppPlanId, 'Action Plan');
        //if(scoreResultMap != null && scoreResultMap.containsKey('Percentage')){
            actionPlanScore = Math.round(oppPlan.Action_Plan__c);
        //}

        //overallScore = (informationScoringScore + qualificationScoringScore + buyingCentreScore + competitionScoringScore + summaryPositionScore
        //+ solutionAtGlanceScore + jointActionPlanScore + valuePropositionScore + actionPlanScore) / 9;
        
        overallScore = Math.round(oppPlan.Overall_Score__c);

    }

    /*
        This private method is responsible to return the number of opportunity stage progresss number.
        @param : String opportunityStage : Opportunity stage.
    */

    private Integer getOpportunityStageProgressNumber(String opportunityStage){
        //Returns the number according to Opportunity stage
        return Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(opportunityStage);
        
    }

    /*
        This private method is responsible to return Plan record of specified plan id.
        @param : Id planId : Oppotunity plan id of which we need to retrieve record.
    */

    private Opportunity_Plan__c retrieveOpportunityPlanRecord(Id planId){

        //Retrieve Records.
        List<Opportunity_Plan__c> oppPlanList = [Select Opportunity_Owner__r.Name, o.Opportunity_Name__r.Name, o.Opportunity_Name__r.StageName, o.Opportunity_Name__r.CurrencyISOCode, o.Account_Name__r.name,o.Value_Proposition__c, o.Understand_Roles__c, o.SystemModstamp,
             o.Strengths__c, o.Solution__c, o.Solution_Fulfils_Requirements__c, o.Sales_Process__c, o.Sales_Objective_5__c,
              o.SO_5_Importance__c, o.Sales_Objective_4__c, o.SO_4_Importance__c,
              o.Sales_Objective_3__c, o.SO_3_Importance__c, o.Sales_Objective_2__c,
              o.SO_2_Importance__c, o.Sales_Objective_1__c, o.SO_1_Importance__c,
              o.Resources_Available__c, o.Resource_Investment__c, o.Resource_Investment_Confidence__c, o.Reliable_Coach__c, o.Project_High_Priority__c, o.Potential__c, o.OwnerId, o.Opportunity_TCV__c, o.Opportunity_Sales_Stage__c, o.Opportunity_Probability__c, o.Opportunity_Owner__c, o.Opportunity_Name__c, o.Opportunity_History__c, o.Opportunity_Expected_Close_Date__c, o.Opportunity_Client_Budget__c, o.Objectives_and_Requirements__c, o.Name, //o.LastViewedDate,
             //o.LastReferencedDate, 
             o.LastModifiedDate, o.LastModifiedById, o.LastActivityDate, o.Known_Project_Budget__c,
             o.Known_Competition__c, o.Known_Buying_Process__c, o.Justifiable_Investment__c, o.IsDeleted,

             o.Strength_5_Rating__c, o.Strength_4_Rating__c, o.Strength_3_Rating__c, o.Strength_2_Rating__c, o.Strength_1_Rating__c,
             o.Risk_5_Rating__c, o.Risk_4_Rating__c, o.Risk_3_Rating__c, o.Risk_2_Rating__c, o.Risk_1_Rating__c,

             o.Id, o.Goals_and_Decision_Criteria__c,

             o.Exp_Strength_5__c, o.Exp_Strength_4__c, o.Exp_Strength_3__c, o.Exp_Strength_2__c, o.Exp_Strength_1__c,
             o.Exp_Risk_5__c, o.Exp_Risk_4__c, o.Exp_Risk_3__c, o.Exp_Risk_2__c, o.Exp_Risk_1__c,

             o.CreatedDate, o.CreatedById, o.Coach__c,
             o.Client_Goal_5__c, o.CG_5_Importance__c, o.Client_Goal_4__c, o.CG_4_Importance__c,
             o.Client_Goal_3__c, o.CG_3_Importance__c, o.Client_Goal_2__c, o.CG_2_Importance__c, o.Client_Goal_1__c,
             o.CG_1_Importance__c, Overall_Score__c, Qualification_Profile__c, Opportunity_Historypercent__c, Buying_Center_Analysis__c, Value_Propositions__c, Competition__c, Summary_Position_Today__c, Action_Plan__c, Joint_Action_Plan__c, Solution_at_a_Glance__c,
             o.Client_Budget_Confidence__c, o.Benefits__c, o.Annual_Potential_Growth__c, o.Annual_Potential_Growth_Confidence__c, o.Action_Item_Solution_Deadline__c, o.Action_Item_Solution_Completed__c, o.Action_Item_Needs_Analysis_Deadline__c, o.Action_Item_Needs_Analysis_Completed__c, o.Action_Item_Initial_Discussions_Deadline__c, o.Action_Item_Initial_Discussions_Complete__c, o.Action_Item_Fulfillment_Deadline__c, o.Action_Item_Fulfillment_Completed__c, o.Account_Name__c From Opportunity_Plan__c o where id =: planid];
        if(oppPlanList != null && oppPlanList.size() == 1){
            return oppPlanList[0];
        }else{
               ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, 'Sorry, plan not found. Contact your system Administrator for further Assistance.' );
               ApexPages.addMessage(msg);
               return null;
        }
    }

}