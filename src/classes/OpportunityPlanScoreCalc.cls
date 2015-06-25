/*************************************************************************************************
Created By:    Sunil Gupta
Date:          May 12, 2014
Description:   Helper class for OpporutniyPlanScoreCalc

//Map<String, Decimal> mapResult = OpportunityPlanScoreCalc.calculateScore('a11f0000000FSWc', 'Information Scoring');
**************************************************************************************************/
global class OpportunityPlanScoreCalc {
	private static Id currentOPId;
  /* Calculate Opportuniy Plan Score. */
  public static Map<String, Decimal> calculateScore(Id oppPlanId, String methodName){
  	currentOPId = oppPlanId;
    Map<String, Decimal> mapResult = new Map<String, Decimal>();
    Opp_Plan_Score_Calc__c objMethod = getMasterObjectMap.get(methodName);
    if(objMethod == null){
    	return null;
    }
    Decimal finalScore = 0;
    Decimal percent = 0;
    Decimal maxScore = objMethod.Expected_Score__c;
    
    system.debug('###objMethod.Name>>' +objMethod.Name);
    if(objMethod.Name.equalsIgnoreCase('Buying Centre')){
      finalScore = calculateMethod_BuyingCentre(objMethod);
    }
    else{
      finalScore = calculateMethod(objMethod);	
    }
    
    if(finalScore > maxScore){
    	finalScore = maxScore;
    }
    System.debug('@@@' + finalScore);
    
    if(finalScore > 0 && maxScore > 0){
      percent = (finalScore / maxScore) * 100;
    }
    mapResult.put('Score', finalScore);
    mapResult.put('Percentage', percent);
    return mapResult;
  }
  
  /* Helper method for Method wise calculate Score */
  private static Decimal calculateMethod(Opp_Plan_Score_Calc__c objMethod){
  	Decimal score = 0;
    List<Opp_Plan_Score_Sub_Calc__c> lstScore = getScoreCalculationObject(objMethod.Id);
    
    Map<String, Set<String>> mapFields = new Map<String, Set<String>>();
    for(Opp_Plan_Score_Sub_Calc__c obj :lstScore){
    	if(mapFields.containsKey(obj.Object_API_Name__c) == false){
    		mapFields.put(obj.Object_API_Name__c, new Set<String>());
    	}
    	if(obj.Calculation_Field__c != null){
    	  mapFields.get(obj.Object_API_Name__c).add(obj.Calculation_Field__c);
    	}
    	if(obj.Controlling_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field__c);
      }
      if(obj.Controlling_Field_2__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field_2__c);
      }
    }
    System.debug('@@@' + mapFields);
    
    for(String objectName :mapFields.keySet()){
    	Set<String> setFields = mapFields.get(objectName);
    	List<SObject> relatedObjectList = getSObject(objectName, setFields, currentOPId);
    	if(relatedObjectList == null) continue;
    	// For Action Plan consider 4 records of Task;
    	if(objMethod.Name.equalsIgnoreCase('Action Plan')){
    		for(SObject obj :relatedObjectList){
    		  score = score + calculateFieldsScore(lstScore, obj, setFields);
    		}
    	}
    	else{
    	  score = score + calculateFieldsScore(lstScore, relatedObjectList.get(0), setFields);
    	}
    	System.debug('@@@' + score);
    }
    
    if(objMethod.Name.equalsIgnoreCase('Information Scoring')){
      score += opportunityTeamScore();
    }
    return score;
  }
  
  
  /* Helper method for BuyingCentre */
  private static Decimal calculateMethod_BuyingCentre(Opp_Plan_Score_Calc__c objMethod){
    Decimal score = 0;
    List<Opp_Plan_Score_Sub_Calc__c> lstScore = getScoreCalculationObject(objMethod.Id);
    System.debug('--debug1.0->'+objMethod.Id);
    Map<String, Set<String>> mapFields = new Map<String, Set<String>>();
    for(Opp_Plan_Score_Sub_Calc__c obj :lstScore){
    	System.debug('--debug1.1-->'+obj);
      if(mapFields.containsKey(obj.Object_API_Name__c) == false){
        mapFields.put(obj.Object_API_Name__c, new Set<String>());
      }
      if(obj.Calculation_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Calculation_Field__c);
      }
      if(obj.Controlling_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field__c);
      }
      if(obj.Controlling_Field_2__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field_2__c);
      }
    }
    
    System.debug('@@mapFields@' + mapFields);
    
    Set<String> setOPContactFields = mapFields.get('Opportunity_Plan_Contact__c');
    List<SObject> relatedObjectList = getSObject('Opportunity_Plan_Contact__c', setOPContactFields, currentOPId);
    if(relatedObjectList == null) return 0;
    
    score = score + calculateFieldsScore(lstScore, relatedObjectList.get(0), setOPContactFields);
    Opportunity_Plan_Contact__c objContact = (Opportunity_Plan_Contact__c)relatedObjectList.get(0);
    
    // Calculate Contact's Fields on Opportunity Plan Contact
    if(objContact.Contact__c != null){
    	Set<String> setContactFields = mapFields.get('Contact');
      List<SObject> relatedObjectList2 = getSObject('Contact', setContactFields, objContact.Contact__c);
      if(relatedObjectList2 == null) return 0;
      score = score + calculateFieldsScore(lstScore, relatedObjectList2.get(0), setContactFields);
    }
    System.debug('@@@@@::::: score ::: ' + score);

    // Calculate Opportunity Plan Contact Self Lookup Check Reports_to__c
    Id selfLookupForOpportunityPlan;
    if(objContact.get('Reports_to__c') != null){
      selfLookupForOpportunityPlan = (Id)relatedObjectList.get(0).get('Reports_to__c');
      System.debug('###selfLookupForOpportunityPlan>> ' + selfLookupForOpportunityPlan);
    }
    
    if(selfLookupForOpportunityPlan != null){
      List<SObject> relatedObjectList3 = getSObject('Opportunity_Plan_Contact__c', setOPContactFields, selfLookupForOpportunityPlan);
      system.debug('relatedObjectList3>>' +relatedObjectList3);
      
      if(relatedObjectList3 == null) return 0;
      score = score + calculateFieldsScore(lstScore, relatedObjectList3.get(0), setOPContactFields);
    }
    System.debug('@@@@@::::: score ::: ' + score);
    return score;
  }
  
  /*  Helper method for Calculate Fields Values defined at Opp_Plan_Score_Sub_Calc__c */
  private static decimal calculateFieldsScore(List<Opp_Plan_Score_Sub_Calc__c>lstScore, sObject relatedObject, Set<String> setFields){
    Decimal resultScore = 0;
    for(Opp_Plan_Score_Sub_Calc__c obj : lstScore){
    	if(setFields.contains(obj.Calculation_Field__c) == false){
    		continue;
    	}
    	String calculationField = obj.Calculation_Field__c;
      String controllingField = obj.Controlling_Field__c;
      String controllingField2 = obj.Controlling_Field_2__c;
      Decimal score = obj.Score__c;
      
      System.debug('@@@' + calculationField + ' @@@' + controllingField + ' @@@' + score);
      
      if(relatedObject != null){
        if(controllingField == null && controllingField2 == null){
        	if(relatedObject.get(calculationField) != null){
            resultScore = resultScore + score;
            System.debug('@@@' + resultScore);
        	}
        }
        else if(controllingField != null && controllingField2 == null){
        	if(relatedObject.get(calculationField) != null && relatedObject.get(controllingField) != null){
            resultScore = resultScore + score;
            System.debug('@@@' + resultScore);
          }
        }
        else if(controllingField != null && controllingField2 != null){
          if(relatedObject.get(calculationField) != null && relatedObject.get(controllingField) != null && relatedObject.get(controllingField2) != null){
            resultScore = resultScore + score;
            System.debug('@@@' + resultScore);
          }
        }
      }
    }
    System.debug('@@@' + resultScore);
    return resultScore;
  }
  
  /* Helper method to Build Query */
  private static List<SObject> getSObject(String objectName, Set<String> setFields, String conditionParam){
    try{
    String strQry = 'SELECT ' + String.join(new List<String>(setFields), ',') + ' FROM ' + objectName + ' WHERE ';
    
    if(objectName == 'Opportunity_Plan_Contact__c'){
      strQry = strQry + 'Opportunity_Plan__c = \'' + conditionParam +'\' ORDER BY CreatedDate ASC LIMIT 1';
      // We are considering only Oldest Opportunity Plan Contact.
    }
    else if(objectName == 'Opportunity_Plan_Competitor__c'){
      strQry = strQry + 'Opportunity_Plan__c = \'' + conditionParam +'\' ORDER BY CreatedDate ASC LIMIT 1';
      // We are considering only Oldest Opportunity Plan Competitor.
    }
    else if(objectName == 'Task'){
      strQry = strQry + 'WhatId = \'' + conditionParam +'\' ORDER BY CreatedDate ASC LIMIT 4';
      // We are considering only Oldest Opportunity Plan Competitor.
    }
    else{
      strQry = strQry + 'Id = \'' + conditionParam +'\'';
    }
    System.debug('@@@' + strQry);
    List<SObject> lst = Database.query(strQry);
    if(lst.size() > 0){
      return lst;
    }
    }
    catch(Exception ex){
      
    }
    return null;
  }
    
  
  
  /* Helper method for Calculate Score For Opportunity Team*/
  private static Decimal opportunityTeamScore(){
  	Id currentOpportunityId = [SELECT Id, Opportunity_Name__c FROM Opportunity_Plan__c 
  	                         WHERE Id = :currentOPId].get(0).Opportunity_Name__c;
  	
  	List<OpportunityTeamMember> lstMember = [SELECT TeamMemberRole, OpportunityAccessLevel 
  	                                         FROM OpportunityTeamMember 
  	                                         WHERE OpportunityId = :currentOpportunityId];
    if(lstMember.size() >= 2) // Every member must have the role so counting 2 for each member.
      return (2 * 2); 
    return 0;
  }
  
  /* Helper method to Get Score Calculation Object */
  private static List<Opp_Plan_Score_Sub_Calc__c> getScoreCalculationObject(Id methodId){
    List<Opp_Plan_Score_Sub_Calc__c> lst = [SELECT Id, Name, Calculation_Field__c, Controlling_Field__c, Controlling_Field_2__c,
                                            Object_API_Name__c, Opp_Plan_Score_Calc__c, Score__c 
                                            FROM Opp_Plan_Score_Sub_Calc__c
                                            WHERE Opp_Plan_Score_Calc__c = :methodId];
    return lst;
  }
  
  /* Helper method to Get Score Calculation Master Object */
  private static Map<String, Opp_Plan_Score_Calc__c>getMasterObjectMap{
    get{
      Map<String, Opp_Plan_Score_Calc__c> mapObj = new Map<String, Opp_Plan_Score_Calc__c>();
      for(Opp_Plan_Score_Calc__c obj :[SELECT Id, Name, Expected_Score__c FROM Opp_Plan_Score_Calc__c]){
        mapObj.put(obj.Name, obj);
      }
      return mapObj;
    }
  }
}