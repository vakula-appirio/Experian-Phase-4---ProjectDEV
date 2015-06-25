/**=====================================================================
 * Appirio, Inc
 * Name: LeadConvertController
 * Description: : T-235362: Leads field "Ready to Convert Status" to move to VF page
 * Created Date: Feb 17th, 2014
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Item #   Date Modified        Modified By                  Description of the update
 *   1      Feb 18, 2014         Naresh Kr Ojha(Appirio)      Updated as per comments on task.
 *   2      March 23, 2015       Nur Azlini                   Split Capability and Budget as additional fields for Opportunity.
 =====================================================================*/
public with sharing class LeadConvertController {

  public List<String> errorOnfields {get;set;}
  public List<String> errorOnfieldsOppt {get;set;}
  public Map<String, Boolean> fieldStatusMap {get;set;}
  //Constructor 
  public LeadConvertController(ApexPages.StandardController controller) {
    Lead leadObj = new Lead();
    fieldStatusMap = new Map<String, Boolean>();
    errorOnfields = new List<String>();
    errorOnfieldsOppt = new List<String>();
    
    leadObj = [SELECT Capability__c, Budget__c, Email, Phone, Street, City,
                      State, Country, PostalCode, ID
               FROM Lead
               WHERE ID =: controller.getId() LIMIT 1];
    //Start Item # 2
    errorOnfieldsOppt.add(Label.CAPABILITY);
    errorOnfieldsOppt.add(Label.BUDGET);
    //End Item # 2
    errorOnfields.add(Label.EMAIL);
    errorOnfields.add(Label.PHONE);
    errorOnfields.add(Label.STREET);
    errorOnfields.add(Label.CITY);
    errorOnfields.add(Label.STATE);      
    errorOnfields.add(Label.COUNTRY);
    errorOnfields.add(Label.POSTALCODE);      
              
    if (String.isBlank(leadObj.Capability__c)) {
      fieldStatusMap.put(Label.CAPABILITY, false);
    } else {
      fieldStatusMap.put(Label.CAPABILITY, true);
    }

    if (String.isBlank(leadObj.Budget__c)) {
      fieldStatusMap.put(Label.BUDGET, false);
    } else {
      fieldStatusMap.put(Label.BUDGET, true);
    }

    if (String.isBlank(leadObj.Email)) {
      fieldStatusMap.put(Label.EMAIL, false);
    } else {
      fieldStatusMap.put(Label.EMAIL, true);
    }

    if (String.isBlank(leadObj.Phone)) {
      fieldStatusMap.put(Label.PHONE, false);
    } else {
      fieldStatusMap.put(Label.PHONE, true);
    }

    if (String.isBlank(leadObj.Street)) {
      fieldStatusMap.put(Label.STREET, false);
    } else {
      fieldStatusMap.put(Label.STREET, true);
    }

    if (String.isBlank(leadObj.City)) {
      fieldStatusMap.put(Label.CITY, false);
    } else {
      fieldStatusMap.put(Label.CITY, true);
    }

    if (String.isBlank(leadObj.State)) {
      fieldStatusMap.put(Label.STATE, false);
    } else {
      fieldStatusMap.put(Label.STATE, true);
    }

    if (String.isBlank(leadObj.Country)) {
      fieldStatusMap.put(Label.COUNTRY, false);
    } else {
      fieldStatusMap.put(Label.COUNTRY, true);
    }

    if (String.isBlank(leadObj.PostalCode)) {
      fieldStatusMap.put(Label.POSTALCODE, false);
    } else {
      fieldStatusMap.put(Label.POSTALCODE, true);
    }

  }//End of the method
}//End of the class