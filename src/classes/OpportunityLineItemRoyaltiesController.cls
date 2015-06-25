/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityRoyaltiesController
 * Description: Controller class for OpportunityRoyalties vf page (for T-313541)
 * Created Date: August 28th, 2014
 * Created By: Nathalie LE GUAY (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 =====================================================================*/
public without sharing class OpportunityLineItemRoyaltiesController {

  public String oliId {get;set;}
  public OpportunityLineItem oli {get;set;}
  public List<Royalty__c> royalties {get;set;}

  public OpportunityLineItemRoyaltiesController(ApexPages.StandardController controller){
      oliId = controller.getId();
      oli = [SELECT Id, Name, Item_Number__c
             FROM OpportunityLineItem
             WHERE Id = :oliId];
      if (String.isEmpty(oli.Item_Number__c)) {
        royalties = new List<Royalty__c>();
      }
      else {
        royalties = [SELECT Id, Name, Line_Item_Reference_Number__c, Product_Name__c,
                          Quantity_Type__c, Amount__c, Renewal_Royalty_Amount__c, Provider_Name__c
                   FROM Royalty__c
                   WHERE Line_Item_Reference_Number__c = :oli.Item_Number__c 
                   ORDER BY Name];
      }
  }
}