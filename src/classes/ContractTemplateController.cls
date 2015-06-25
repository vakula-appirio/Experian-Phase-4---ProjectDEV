/**=====================================================================
 * Appirio, Inc
 * Name: ContractTemplateController
 * Description: Controller class for ContractTemplatePage.page
 * Created Date: Jan 27th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified             Modified By         Description of the update
 * Feb 2nd, 2014             Noopur              Modified the code to use the values
 *                                               from Contract Template Header record
 *                                               selected by the user. And added custom
 *                                               label for the error message.
 * Feb 3rd, 2014             Noopur              Modified the class to fetch the parameters
 *                                               from URL and map membership fields to
 *                                               Contract record.
 * Feb 5th,2015              Gaurav Kumar Chadha   T-359201 Changed the Contract__c.Start_Date__c to Contract__c.Contract_Effective_Date__c
 * Feb 13th,2015             Noopur              T-361567 : Added the logic to populate the Contract Template Name field.
 * Mar 03rd,2015             Noopur              I-149879 : added code to replace '&' with '%26'
 * Mar 25th,2015             Noopur              I-152766: added a method encodeString() and used it to encode the string values being passed in the url
 =====================================================================*/
public class ContractTemplateController {

  public Contract__c contract {get;set;}
  public String urlString {get;set;}
  public Contract__c selectedContract{get;set;}
  private Contract_Template_Field_IDs__c fieldIds ;
  private boolean hasError ;
  private String membershipId;
  private String accId;

  //================================================================================
  // Contructor
  //================================================================================
  public ContractTemplateController() {
    hasError = false;
    contract = new Contract__c();
    fieldIds = Contract_Template_Field_IDs__c.getInstance();
    if ( !String.isBlank(Custom_Object_Prefixes__c.getInstance().Contract__c) ) {
      urlString = '/'+Custom_Object_Prefixes__c.getInstance().Contract__c+'/e?recordtype='+Record_Type_Ids__c.getInstance().Case_CSDA_Contract_Header__c;
    }
    else {
      urlString = '/'+Custom_Object_Prefixes__c.getInstance().Contract__c+'/e?recordtype='+Record_Type_Ids__c.getInstance().Case_CSDA_Contract_Header__c;
    }
    membershipId = Apexpages.currentPage().getParameters().get('memId');
    String membershipName = Apexpages.currentPage().getParameters().get('memName');
    accId = Apexpages.currentPage().getParameters().get('accId');
    String accName = Apexpages.currentPage().getParameters().get('accName');
    String opptyName = Apexpages.currentPage().getParameters().get('oppName');
    String opptyId = Apexpages.currentPage().getParameters().get('oppId');

    // Noopur/Nathalie - T-358300 added code to map fields from membership record
    if (!String.isBlank(membershipId) && !String.isBlank(membershipName)) {
      urlString += '&'+fieldIds.Membership__c+'_lkid='+membershipId + '&'+fieldIds.Membership__c+'='+membershipName;
    }
    if (!String.isBlank(accName)) {
      urlString += '&'+fieldIds.Contract_Company_Name__c+'='+accName;
      if (!String.isBlank(accId)) {
        urlString += '&'+fieldIds.Account__c+'_lkid='+accId + '&'+fieldIds.Account__c+'='+accName;
      }
    }
    if (!String.isBlank(opptyId) && !String.isBlank(opptyName)) {
      urlString += '&'+fieldIds.Opportunity__c+'_lkid='+opptyId + '&'+fieldIds.Opportunity__c+'='+opptyName;
    }
  }

  //================================================================================
  // Select the template and return url as per the selected template
  //================================================================================
  public Pagereference doSelect () {
    fetchSelectedContract();
    if (!hasError) {
    	system.debug('doSelect>>urlString>>'+urlString);
      return new pagereference(urlString);
    }
    else {
      return null;
    }
    
  }

  //================================================================================
  // Return url
  //================================================================================
  public Pagereference doCancel () {
    system.debug('\nMemId is '+ membershipId);
    Pagereference pg;
    if ( !String.isBlank(membershipId) ) {
      pg = new pagereference('/' + membershipId);
    }
    else if ( !String.isBlank(accId) ) {
      pg = new pagereference('/' + accId);
    }
    else {
      pg = new pagereference('/' + Custom_Object_Prefixes__c.getInstance().Contract__c + '/o');
    }
    return pg;
  }

  //================================================================================
  // Fetch the selected Contract
  //================================================================================
  private void fetchSelectedContract () {
    hasError = false;
    if (contract != null && contract.Contract_Template_Name__c != null) {
      selectedContract = [SELECT Id,Contract_Name__c ,Status__c, Contract_Effective_Date__c,
                                 Contract_Type__c,Contract_Filed_Location__c,Initial_Term_Period__c,Renewal_Term_Period__c,
                                 Auto_Renew__c,Next_Auto_Renewal_Date__c,Notice_Period_Days__c,
                                 Payment_Terms__c,Audit_Rights__c,Assignment_Rights__c,Name,
                                 Pricing__c,Tiered_Pricing__c,Template_Status__c,LastModifiedDate
                          FROM Contract__c
                          WHERE Id = :contract.Contract_Template_Name__c];
      prepareURL();
    }
    else {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Contract_Template_Page_Please_Select_a_Template));
      hasError = true;
      return ;
    }
  }

  //================================================================================
  // Prepare URL as per the selected template using the custom setting where all the
  // templates are stored.
  //================================================================================
  private void prepareURL () {
    if ( selectedContract != null ) {
      if ( !String.isBlank(selectedContract.Status__c)) {
        urlString += '&'+fieldIds.Status__c+'='+encodeString(selectedContract.Status__c);
      }
      if ( selectedContract.Contract_Effective_Date__c!= null ) {
        urlString += '&'+fieldIds.Start_Date__c +'='+selectedContract.Contract_Effective_Date__c.format();
      }
      if ( !String.isBlank(selectedContract.Contract_Type__c) ) {
        urlString += '&'+fieldIds.Contract_Type__c+'='+encodeString(selectedContract.Contract_Type__c);
      }
      if ( !String.isBlank(selectedContract.Contract_Filed_Location__c) ) {
        urlString += '&'+fieldIds.Contract_Filed_Location__c+'='+encodeString(selectedContract.Contract_Filed_Location__c);
      }
      /*if ( !String.isBlank(selectedContract.Division__c) ) {
        urlString += '&'+fieldIds.Division__c+'='+selectedContract.Division__c;
      }*/
      if ( selectedContract.Initial_Term_Period__c != null ) {
        urlString += '&'+fieldIds.Initial_Term_Period__c+'='+selectedContract.Initial_Term_Period__c;
      }
      if ( selectedContract.Renewal_Term_Period__c != null ) {
        urlString += '&'+fieldIds.Renewal_Term_Period__c+'='+selectedContract.Renewal_Term_Period__c;
      }
      if ( !String.isBlank(selectedContract.Auto_Renew__c) ) {
        urlString += '&'+fieldIds.Auto_Renew__c+'='+selectedContract.Auto_Renew__c;
      }
      if ( selectedContract.Next_Auto_Renewal_Date__c != null  ) {
        urlString += '&'+fieldIds.Next_Auto_Renew_Date__c+'='+selectedContract.Next_Auto_Renewal_Date__c.format();
      }
      if ( selectedContract.Notice_Period_Days__c != null ) {
        urlString += '&'+fieldIds.Notice_Period__c+'='+selectedContract.Notice_Period_Days__c;
      }
      if ( !String.isBlank(selectedContract.Payment_Terms__c) ) {
        urlString += '&'+fieldIds.Payment_Terms__c+'='+encodeString(selectedContract.Payment_Terms__c);
      }
      if ( !String.isBlank(selectedContract.Audit_Rights__c) ) {
        urlString += '&'+fieldIds.Audit_Rights__c+'='+encodeString(selectedContract.Audit_Rights__c);
      }
      if ( !String.isBlank(selectedContract.Assignment_Rights__c) ) {
        urlString += '&'+fieldIds.Assignment_Rights__c+'='+encodeString(selectedContract.Assignment_Rights__c);
      }
      if ( !String.isBlank(selectedContract.Pricing__c) ) {
        urlString += '&'+fieldIds.Pricing__c+'='+encodeString(selectedContract.Pricing__c);
      }
      if ( !String.isBlank(selectedContract.Tiered_Pricing__c) ) {
        urlString += '&'+fieldIds.Tiered_Pricing__c+'='+encodeString(selectedContract.Tiered_Pricing__c);
      }
      if ( !String.isBlank(selectedContract.Template_Status__c) ) {
        urlString += '&'+fieldIds.Template_Status__c+'='+encodeString(selectedContract.Template_Status__c);
      }
      if ( !String.isBlank(selectedContract.Contract_Name__c) ) {
        urlString += '&'+fieldIds.Contract_Name__c+'='+encodeString(selectedContract.Contract_Name__c);
      }
      
      //urlString += '&'+fieldIds.Template_Version_Date__c +'='+Date.valueOf(selectedContract.LastModifiedDate).format();
      
      // NS - T-361567 Added the code to populate the Contract Template Name field.
      urlString += '&CF'+fieldIds.Contract_Template_Name__c +'='+selectedContract.Name;
      urlString += '&CF'+fieldIds.Contract_Template_Name__c+'_lkid' +'='+selectedContract.Id;
    }
    else {
      return;
    }
    system.debug('prepareUrl>>urlString>>'+urlString);
  }
  
  //================================================================================
  // Method to encode the string being passed as the argument
  //================================================================================
  private string encodeString ( String urlStringValue ) {
  	String encodedString = EncodingUtil.urlEncode(urlStringValue, 'UTF-8');
  	return encodedString;
  }

}