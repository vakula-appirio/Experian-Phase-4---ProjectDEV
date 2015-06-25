/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanIndicatorExtension
 * Description: To show AccountPlanIndicatorPage's stages with hover tooltip.
 * Created Date: Jan 07th 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class AccountPlanIndicatorExtension {

  public List<Opportunity_Sales_Process__c> lstStages {get;set;}
  public static final String ACCOUNTPLAN_SALES_PROCESS = 'Account Plan';
  
  public AccountPlanIndicatorExtension(ApexPages.StandardController controller) {
    lstStages = new List<Opportunity_Sales_Process__c>();
    
    for (Opportunity_Sales_Process__c sp : [SELECT Sales_Process_Name__c, Name, Tooltip1__c, Tooltip2__c
                                               FROM Opportunity_Sales_Process__c
                                               WHERE Sales_Process_Name__c =: ACCOUNTPLAN_SALES_PROCESS 
                                               ORDER BY Sequence__c]) {
      lstStages.add(sp);
    } 
  }
}