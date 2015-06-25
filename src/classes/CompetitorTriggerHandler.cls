/**=====================================================================
 * Appirio, Inc
 * Name        : CompetitorTriggerHandler
 * Description : Handler class for CompetitorTrigger (for T-291592)
 * Created Date: Jul 4th, 2014
 * Created By  : Sonal Shrivastava (Appirio JDC)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 11th, 2014               Arpita Bose(Appirio)         I-120496: Added method updateOppCompeName() to update Competitor Name
 *                                                           with relevant Account Name
 * Jul 11th, 2014               Arpita Bose(Appirio)         I-120496: Commented the code as the requirement is changed as per the chatter
 * Oct 06th, 2014               Diego olarte                 Added deleteOppCompetitorName method to remove comp name from opps
 =====================================================================*/
public class CompetitorTriggerHandler {
  
  //============================================================================
  // Method called on After Insert
  //============================================================================
  public static void afterInsert(List<Competitor__c> newList){
    createOppPlanComp(newList);
  }
  // I-120496: Commented this code as the requirement is changed
  /*
  //========================================================================================
  // Before Insert Call
  //========================================================================================
  public static void beforeInsert(List<Competitor__c> newList){
    updateOppCompeName(newList, null); 
  }
  //========================================================================================
  // Before Update Call
  //========================================================================================
  public static void beforeUpdate(List<Competitor__c> newList, Map<Id, Competitor__c> oldMap){
    updateOppCompeName(newList, oldMap); 
  } */
  
  //============================================================================
  // Method called on Before Detete
  //============================================================================
  public static void beforeDelete(Map<Id, Competitor__c> oldMap){
    deleteOppPlanComp(oldMap);
    deleteOppCompetitorName(oldMap.values());//Added by DO    
  }
  
  //============================================================================
  // Method to create Opportunity Plans Competitors
  //============================================================================
  private static void createOppPlanComp(List<Competitor__c> newList){
    Map<String, List<Opportunity_Plan__c>> mapOppId_OppPlanList = findOpportunityPlans(newList);
    List<Opportunity_Plan_Competitor__c> lstOppPlanComp = new List<Opportunity_Plan_Competitor__c>();
    
    //Iterate throgh Competitors and create Opportunity Plan Competitor records
    for(Competitor__c comp : newList){
        if(mapOppId_OppPlanList.containsKey(comp.Opportunity__c)){
            //Create Opportunity Plan Competitor for each Opportunity Plan
            for(Opportunity_Plan__c oppPlan : mapOppId_OppPlanList.get(comp.Opportunity__c)){
                lstOppPlanComp.add(new Opportunity_Plan_Competitor__c( Opportunity_Plan__c = oppPlan.Id,
                                                                       Competitor__c = comp.Id));
            }
        }
    }
    if(!lstOppPlanComp.isEmpty()){
        insert lstOppPlanComp;
    }
  }
  
  //============================================================================
  // Method to return Opportunity Plans related to Competitor's Opportunities
  //============================================================================
  private static Map<String, List<Opportunity_Plan__c>> findOpportunityPlans(List<Competitor__c> compList){
    Set<String> oppIdsSet = new Set<String>();
    Map<String, List<Opportunity_Plan__c>> mapOppId_OppPlanList = new Map<String, List<Opportunity_Plan__c>>();
    
    //Find opportunity Ids related to competitors
    for(Competitor__c comp : compList){
      oppIdsSet.add(comp.Opportunity__c);
    }
    //Find Opportunity Plans related to Opportunities
    for(Opportunity_Plan__c oppPlan : [SELECT Id, Opportunity_Name__c 
                                       FROM Opportunity_Plan__c 
                                       WHERE Opportunity_Name__c IN :oppIdsSet]){
      if(!mapOppId_OppPlanList.containsKey(oppPlan.Opportunity_Name__c)){
        mapOppId_OppPlanList.put(oppPlan.Opportunity_Name__c, new List<Opportunity_Plan__c>());
      }
      mapOppId_OppPlanList.get(oppPlan.Opportunity_Name__c).add(oppPlan);
    }
    return mapOppId_OppPlanList;
  }
  
  //============================================================================
  // Method to delete Opportunity Plan Competitors
  //============================================================================
  private static void deleteOppPlanComp(Map<Id, Competitor__c> oldMap){
    List<Opportunity_Plan_Competitor__c> oppPlanCompList = new List<Opportunity_Plan_Competitor__c>();
    
    for(Opportunity_Plan_Competitor__c opm : [SELECT Id 
                                              FROM Opportunity_Plan_Competitor__c
                                              WHERE Competitor__c IN :oldMap.keySet()]){
        oppPlanCompList.add(opm);
    }
    if(!oppPlanCompList.isEmpty()){
        delete oppPlanCompList;
    }
  }
  
  // I-120496: Commented this code as the requirement is changed as per the chatter
  /*
  //============================================================================
  // I-120496: Method to update Competitor Name to the related Account Name
  //============================================================================
  private static void updateOppCompeName( List<Competitor__c> newList, Map<Id, Competitor__c> oldMap){
    Set<String> accIDs = new Set<String>();
    List<Competitor__c> lstCompetitor = new List<Competitor__c>();
    Map<String, Account> mapAccId_Acc = new Map<String, Account>();
    
    //Find account Ids related to competitors
    for(Competitor__c comp : newList){
        if(oldMap == null || (oldMap.get(comp.Id).Account__c != comp.Account__c)){
            lstCompetitor.add(comp);
            accIDs.add(comp.Account__c);
        }
    }
    
    if(!accIDs.isEmpty()){
        for(Account acc : [SELECT Id, Name FROM Account WHERE Id IN :accIDs]){
            mapAccId_Acc.put(acc.Id, acc);
        }
        // Update Competitor's Name from account name
        for(Competitor__c comp : lstCompetitor){
            comp.Name = mapAccId_Acc.get(comp.Account__c).Name;
        }
    }
  } */

  private static void deleteOppCompetitorName(List<Competitor__c> oldCompetitors) { //Add by DO to remove competitor name in an opp after competitor has been deleted
    List<ID> oppIDs = new List<ID>();
    List<Opportunity> updateOppList = new List<Opportunity>();
    String m1;
    String m2;
    
    for(Competitor__c comp : oldCompetitors){
      m1 = comp.Competitor_name__c;
      m2 = ', ,';
 
      OppIDs.add(comp.Opportunity__c);
    }
        
    Map<ID,Opportunity> oppUpdateMap = new Map<ID,Opportunity>();
    for(Opportunity opp : [Select ID , Competitor_name_s__c , Competitor_Count__c from Opportunity where ID in:OppIDs])
    {
      oppUpdateMap.put(opp.ID ,opp );
    }
    for( Competitor__c comp : oldCompetitors){
 
        Opportunity updateopp = OppUpdateMap.get(comp.Opportunity__c);

        String s1 = updateopp.Competitor_name_s__c;
 
        String target = m1;
 
        String replacement = '';
 
        String s2 = s1.replace(target, replacement);
 
        updateopp.Competitor_name_s__c = s2;
 
        String s3 = updateopp.Competitor_name_s__c;
 
        String target2 = m2;
 
        String replacement2 = '';
 
        String s4 = s3.replace(target2, replacement2);
 
        updateopp.Competitor_name_s__c = s4;
 
        updateOppList.add(updateopp); 

    }//for

    if(updateOppList!=null && updateOppList.size()>0)
    update updateOppList; 
  
  }
 
}