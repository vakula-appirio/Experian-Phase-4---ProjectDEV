/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityKeyDateStatusExt
 * Description: T-258164: Check opportunity dates with revenue schedules
 * Created Date: 10th April, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/

public with sharing class OpportunityKeyDateStatusExt {
  
  public List<String> errorList {get;set;}
  //Constructor
  public OpportunityKeyDateStatusExt(ApexPages.StandardController controller) {
    init ();    
    errorList = OpportunityUtility.checkOpportunityDates(controller.getRecord().ID);
    if (errorList.size() > 0) {
      String err = '';
      for (String e : errorList) {
      	err += e + ', ';
      	//err.substring(0, err.length()-2)
        Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.WARNING, e);
        Apexpages.addmessage(msg);
      }
    }
  }
  
  private void init () {
  	errorList = new List<String>();
  }
}