/*
    Author      : Topcoder Developer
    Description : Class contains field mapping needed for OpportunityPlanData.cls
    
 * Date Modified                 Modified By                  Description of the update
   17th Feb, 2015                Paul Kissick                 Case #554948, change of 'Synthesis of Business Goals' to just 'Business Goals'
    
*/

public class OpportunityPlanMapping {
    
    // Properties
    // Mapping for Opportunity Plan fields, needed for showing data on basis of importance
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOp_SalesObjectiveFields = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan__c.SO_1_Importance__c => Opportunity_Plan__c.Sales_Objective_1__c,
        Opportunity_Plan__c.SO_2_Importance__c => Opportunity_Plan__c.Sales_Objective_2__c,
        Opportunity_Plan__c.SO_3_Importance__c => Opportunity_Plan__c.Sales_Objective_3__c,
        Opportunity_Plan__c.SO_4_Importance__c => Opportunity_Plan__c.Sales_Objective_4__c,
        Opportunity_Plan__c.SO_5_Importance__c => Opportunity_Plan__c.Sales_Objective_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOp_ClientGoalFields = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan__c.CG_1_Importance__c => Opportunity_Plan__c.Client_Goal_1__c,
        Opportunity_Plan__c.CG_2_Importance__c => Opportunity_Plan__c.Client_Goal_2__c,
        Opportunity_Plan__c.CG_3_Importance__c => Opportunity_Plan__c.Client_Goal_3__c,
        Opportunity_Plan__c.CG_4_Importance__c => Opportunity_Plan__c.Client_Goal_4__c,
        Opportunity_Plan__c.CG_5_Importance__c => Opportunity_Plan__c.Client_Goal_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOp_Strengths = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan__c.Strength_1_Rating__c => Opportunity_Plan__c.Exp_Strength_1__c,
        Opportunity_Plan__c.Strength_2_Rating__c => Opportunity_Plan__c.Exp_Strength_2__c,
        Opportunity_Plan__c.Strength_3_Rating__c => Opportunity_Plan__c.Exp_Strength_3__c,
        Opportunity_Plan__c.Strength_4_Rating__c => Opportunity_Plan__c.Exp_Strength_4__c,
        Opportunity_Plan__c.Strength_5_Rating__c => Opportunity_Plan__c.Exp_Strength_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOp_Risks = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan__c.Risk_1_Rating__c => Opportunity_Plan__c.Exp_Risk_1__c,
        Opportunity_Plan__c.Risk_2_Rating__c => Opportunity_Plan__c.Exp_Risk_2__c,
        Opportunity_Plan__c.Risk_3_Rating__c => Opportunity_Plan__c.Exp_Risk_3__c,
        Opportunity_Plan__c.Risk_4_Rating__c => Opportunity_Plan__c.Exp_Risk_4__c,
        Opportunity_Plan__c.Risk_5_Rating__c => Opportunity_Plan__c.Exp_Risk_5__c
        };
        
    // Mapping for Opportunity Plan Contact fields, needed for showing data on basis of importance
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpContact_BusinessGoal = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Contact__c.Importance_BG_1__c => Opportunity_Plan_Contact__c.Business_Goal_1__c,
        Opportunity_Plan_Contact__c.Importance_BG_2__c => Opportunity_Plan_Contact__c.Business_Goal_2__c,
        Opportunity_Plan_Contact__c.Importance_BG_3__c => Opportunity_Plan_Contact__c.Business_Goal_3__c,
        Opportunity_Plan_Contact__c.Importance_BG_4__c => Opportunity_Plan_Contact__c.Business_Goal_4__c,
        Opportunity_Plan_Contact__c.Importance_BG_5__c => Opportunity_Plan_Contact__c.Business_Goal_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpContact_DecisionCriteria = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Contact__c.Importance_DC_1__c => Opportunity_Plan_Contact__c.Decision_Criteria_1__c,
        Opportunity_Plan_Contact__c.Importance_DC_2__c => Opportunity_Plan_Contact__c.Decision_Criteria_2__c,
        Opportunity_Plan_Contact__c.Importance_DC_3__c => Opportunity_Plan_Contact__c.Decision_Criteria_3__c,
        Opportunity_Plan_Contact__c.Importance_DC_4__c => Opportunity_Plan_Contact__c.Decision_Criteria_4__c,
        Opportunity_Plan_Contact__c.Importance_DC_5__c => Opportunity_Plan_Contact__c.Decision_Criteria_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpContact_SolutionDescription = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Contact__c.Solution_Description__c => null
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpContact_SolutionBenefits = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Contact__c.Importance_SB_1__c => Opportunity_Plan_Contact__c.Solution_Benefits_1__c,
        Opportunity_Plan_Contact__c.Importance_SB_2__c => Opportunity_Plan_Contact__c.Solution_Benefits_2__c,
        Opportunity_Plan_Contact__c.Importance_SB_3__c => Opportunity_Plan_Contact__c.Solution_Benefits_3__c,
        Opportunity_Plan_Contact__c.Importance_SB_4__c => Opportunity_Plan_Contact__c.Solution_Benefits_4__c,
        Opportunity_Plan_Contact__c.Importance_SB_5__c => Opportunity_Plan_Contact__c.Solution_Benefits_5__c
        };
        
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpContact_ExpDifferentiator = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Contact__c.Importance_ED_1__c => Opportunity_Plan_Contact__c.Exp_Differentiator_1__c,
        Opportunity_Plan_Contact__c.Importance_ED_2__c => Opportunity_Plan_Contact__c.Exp_Differentiator_2__c,
        Opportunity_Plan_Contact__c.Importance_ED_3__c => Opportunity_Plan_Contact__c.Exp_Differentiator_3__c,
        Opportunity_Plan_Contact__c.Importance_ED_4__c => Opportunity_Plan_Contact__c.Exp_Differentiator_4__c,
        Opportunity_Plan_Contact__c.Importance_ED_5__c => Opportunity_Plan_Contact__c.Exp_Differentiator_5__c
        };
        
    // Mapping for Opportunity Plan Contact fields, needed for showing data on basis of importance
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpCompetitor_ExpAdv = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Competitor__c.Importance_Exp_Adv_1__c => Opportunity_Plan_Competitor__c.Exp_Adv_1__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Adv_2__c => Opportunity_Plan_Competitor__c.Exp_Adv_2__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Adv_3__c => Opportunity_Plan_Competitor__c.Exp_Adv_3__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Adv_4__c => Opportunity_Plan_Competitor__c.Exp_Adv_4__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Adv_5__c => Opportunity_Plan_Competitor__c.Exp_Adv_5__c
        };
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpCompetitor_CompAdv = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Competitor__c.Importance_Comp_Adv_1__c => Opportunity_Plan_Competitor__c.Comp_Adv_1__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Adv_2__c => Opportunity_Plan_Competitor__c.Comp_Adv_2__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Adv_3__c => Opportunity_Plan_Competitor__c.Comp_Adv_3__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Adv_4__c => Opportunity_Plan_Competitor__c.Comp_Adv_4__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Adv_5__c => Opportunity_Plan_Competitor__c.Comp_Adv_5__c
        };
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpCompetitor_CompStart = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Competitor__c.Importance_Comp_Strat_1__c => Opportunity_Plan_Competitor__c.Comp_Strat_1__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Strat_2__c => Opportunity_Plan_Competitor__c.Comp_Strat_2__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Strat_3__c => Opportunity_Plan_Competitor__c.Comp_Strat_3__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Strat_4__c => Opportunity_Plan_Competitor__c.Comp_Strat_4__c,
        Opportunity_Plan_Competitor__c.Importance_Comp_Strat_5__c => Opportunity_Plan_Competitor__c.Comp_Strat_5__c
        };
    public static Map<Schema.Sobjectfield,Schema.Sobjectfield> mapOpCompetitor_ExpStart = 
        new Map<Schema.Sobjectfield,Schema.Sobjectfield> {
        Opportunity_Plan_Competitor__c.Importance_Exp_Strat_1__c => Opportunity_Plan_Competitor__c.Exp_Strat_1__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Strat_2__c => Opportunity_Plan_Competitor__c.Exp_Strat_2__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Strat_3__c => Opportunity_Plan_Competitor__c.Exp_Strat_3__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Strat_4__c => Opportunity_Plan_Competitor__c.Exp_Strat_4__c,
        Opportunity_Plan_Competitor__c.Importance_Exp_Strat_5__c => Opportunity_Plan_Competitor__c.Exp_Strat_5__c
        };
    
    // Method to return comma seperated field names for Competitor
    public static String getOpportunityPlanCompetitorFieldsCsv() {
        List<String> lstString = new List<String>();
        for(Schema.Sobjectfield key: mapOpCompetitor_ExpAdv.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpCompetitor_ExpAdv.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpCompetitor_CompAdv.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpCompetitor_CompAdv.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpCompetitor_CompStart.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpCompetitor_CompStart.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpCompetitor_ExpStart.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpCompetitor_ExpStart.get(key)
            });
        }
        lstString.add('Competitor__r.Account__r.Name');
        return String.join(lstString, ', ');
    }
    
    // Method to return comma seperated field names for Contact
    public static String getOpportunityPlanContactFieldsCsv() {
        List<String> lstString = new List<String>();
        for(Schema.Sobjectfield key: mapOpContact_BusinessGoal.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpContact_BusinessGoal.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpContact_DecisionCriteria.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpContact_DecisionCriteria.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpContact_SolutionDescription.keyset()) {
            lstString.add('' + key);
        }
        for(Schema.Sobjectfield key: mapOpContact_SolutionBenefits.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpContact_SolutionBenefits.get(key)
            });
        }
        for(Schema.Sobjectfield key: mapOpContact_ExpDifferentiator.keyset()) {
            lstString.addAll(new List<String> {
                '' + key,
                '' + mapOpContact_ExpDifferentiator.get(key)
            });
        }
        lstString.add('Contact__r.Name');
        return String.join(lstString, ', ');
    }
    
    
    // Method to return wrapper for Contact
    public static List<OpportunityPlanWrapper.ChildRecordsWrapper>
        getContactConfigWrapper() {
        List<List<String>> emptyList= new List<List<String>>();
        return new List<OpportunityPlanWrapper.ChildRecordsWrapper> {
            new OpportunityPlanWrapper.ChildRecordsWrapper('Business Goals',  // PK Case #554948
                emptyList, 
                mapOpContact_BusinessGoal,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Decision Criteria', 
                emptyList, 
                mapOpContact_DecisionCriteria,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Solution Description', 
                emptyList, 
                mapOpContact_SolutionDescription,
                true),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Benefits of Solution', 
                emptyList, 
                mapOpContact_SolutionBenefits,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Differentiators', 
                emptyList, 
                mapOpContact_ExpDifferentiator,
                false)
        };
    }
    
    // Method to return wrapper for Competitor
    public static List<OpportunityPlanWrapper.ChildRecordsWrapper>
        getCompetitorConfigWrapper() {
        List<List<String>> emptyList= new List<List<String>>();
        return new List<OpportunityPlanWrapper.ChildRecordsWrapper> {
            new OpportunityPlanWrapper.ChildRecordsWrapper('Our Advantages Against Them', 
                emptyList, 
                mapOpCompetitor_ExpAdv,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Their Advantages Over Us', 
                emptyList, 
                mapOpCompetitor_CompAdv,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Competitors Strategy', 
                emptyList, 
                mapOpCompetitor_CompStart,
                false),
            new OpportunityPlanWrapper.ChildRecordsWrapper('Our Strategy To Beat Them', 
                emptyList, 
                mapOpCompetitor_ExpStart,
                false)
        };
    }
}