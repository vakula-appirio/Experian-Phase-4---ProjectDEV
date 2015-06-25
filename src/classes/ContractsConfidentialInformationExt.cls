/******************************************************************************
 * Appirio, Inc
 * Name: ContractsConfidentialInformationExt
 * Description: T-359158: Extension class to show confidential information as RL on CSDA Cases
 * Created Date: Feb 04th, 2015
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 12th, 2015               Arpita Bose(Appirio)         T-361211 : Added code for urlString for mapping Case.Opportunity with CI.Opportunity
 * Feb 13th, 2015               Arpita Bose                  S-277736 : Added CreatedDate in query
 ******************************************************************************/
public with sharing class ContractsConfidentialInformationExt {
  
  public List<Confidential_Information__c> confInfoList {get;set;} 
  public Case myCase {get;set;}
  public Boolean fullView {get;set;}
  public String urlString {get;set;}
  private boolean hasError ;
  
  //==========================================================================
  // Constructor
  //==========================================================================
  public ContractsConfidentialInformationExt(ApexPages.StandardController controller) {
  	urlString = '';
  	hasError = false;
    fullView = false;
    String caseID = controller.getId();
    myCase = (Case) controller.getRecord();
    

    if (myCase.Id != null) {
      myCase = [SELECT Id, Opportunity__c, Opportunity__r.Name, Opportunity__r.Id, CaseNumber 
                FROM Case WHERE ID =: myCase.Id];

      if (myCase.Opportunity__c != null) {
        confInfoList = new List<Confidential_Information__c>();
        for (Confidential_Information__c confInfo : [SELECT RecordTypeId, Opportunity__c, Name, Membership__r.Name,
                                                            Id, Contract__c, Contract_Document__c, Account__c, Account__r.Name,
                                                            CreatedDate //S-277736
                                                     FROM Confidential_Information__c
                                                     WHERE Opportunity__c =: myCase.Opportunity__c
                                                          Order By CreatedDate DESC]) {
          confInfoList.add(confInfo);
          
        }
      }
      if (Apexpages.currentPage().getParameters().get('view') == 'full') {
        fullView = true;
      }
      
      String conInfoObjPrefix = Custom_Object_Prefixes__c.getInstance().Confidential_Information__c;
      
      urlString = '/'+conInfoObjPrefix+'/e?CF' + Custom_Fields_Ids__c.getInstance().Conf_Info_Opportunity__c+'_lkid='+ myCase.Opportunity__r.Id;
      urlString += '&CF' + Custom_Fields_Ids__c.getInstance().Conf_Info_Opportunity__c + '=' + myCase.Opportunity__r.Name;
      urlString += '&' + Custom_Fields_Ids__c.getInstance().Conf_Info_Synch_OTM__c + '=1';
      urlString += '&RecordType=' + Record_Type_Ids__c.getInstance().Confidential_Information_Opportunity__c;
      urlString += '&retURL=' + caseID ;
      urlString += '&saveURL=' + caseID;

    }
  }

}