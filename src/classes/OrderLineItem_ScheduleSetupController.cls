/**=====================================================================
 * Appirio, Inc 
 * Name: OrderLineItem_ScheduleSetupController
 * Description: Order Line Item revenue scheduling
 * Created Date: Feb 03rd, 2014
 * Created By: Jinesh Goyal (Appirio)
 *  
 * Date Modified      Modified By                  Description of the update
 * Feb 10th, 2014     Nathalie Le Guay (Appirio)   Remove Order_Line_Item__c.Sales_Price__c recalculation
 *                                                 (Added to triggers instead)
 * Feb 11th, 2014     Nathalie Le Guay             Removing 'Daily' and 'Weekly' options
 * Feb 12th, 2014     Jinesh Goyal                 Modified Exception Handling with Error log creation 
 *                                                 via creating records for Apex_Log__c
 * Feb 12th, 2014     Nathalie Le Guay             Remove scheduleTypeSelected
 * Feb 13th, 2014     Jinesh Goyal                 Added debug messages in Exception Handling
 * Apr 02nd, 2014     Arpita Bose(Appirio)         T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 08th, 2014     Arpita Bose                  T-269372: Added addError()in try-catch block
 * May 01st, 2014     Arpita Bose                  Updated getDMLMessage to getMessage for catch(Exception)
 =====================================================================*/
public with sharing class OrderLineItem_ScheduleSetupController {
  private String parentOLIId = '';
  //public String scheduleTypeSelected { get; set; }
  public String installmentPeriodSelected { get; set; }
  public Integer numberOfInstallments { get; set; }
  public Contact conStartDate { get; set; }
  public Decimal revenue { get; set; }
  public String orderName { get; set; }
  public String orderId { get; set; }
  public Order_Line_Item__c oli { get; set; }
//step2
  public List<Order_Revenue_Schedule__c> lstORS { get; set; }
  public Boolean step1 { get; set; }
  public Boolean editModeNoRecords { get; set; }
  public List<Order_Revenue_Schedule__c> lstORSToSave { get; set; }
  private List<Order_Revenue_Schedule__c> tempLstORSDelete;
 
  //===========================================================================
  //constructor
  //===========================================================================
  public OrderLineItem_ScheduleSetupController () {
    parentOLIId = ApexPages.currentPage().getParameters().get ('id');
    oli = new Order_Line_Item__c ();
    for(Order_Line_Item__c o : [SELECT Id, Name, Order__c,
                                     Total__c, Order__r.Name,
                                     Start_Date__c, CurrencyISOCode
                              FROM Order_Line_Item__c 
                              WHERE Id = :parentOLIId LIMIT 1]){
      oli = o; 
      break;
    }
    revenue = (oli != null) ? oli.Total__c : null;  
    orderName = (oli != null && oli.Order__c != null) ? oli.Order__r.Name : '';
    orderId = (oli != null && oli.Order__c != null) ? oli.Order__c : '';
    //scheduleTypeSelected = 'multiple';
    installmentPeriodSelected = '';
    //numberOfInstallments = null;
    conStartDate = new Contact();
    conStartDate.BirthDate = (oli != null && oli.Start_Date__c != null) ? oli.Start_Date__c : null;
    lstORS = new List<Order_Revenue_Schedule__c> ();
    //
    try {
      step1 = ( Boolean.valueOf (ApexPages.currentPage().getParameters().get ('editMode') ) ) ? false : true; 
    } catch (Exception ex) {
      step1 = false;
      System.debug('\n[OrderLineItem_Schedule - constructor] : '+ ex.getMessage());
      apexLogHandler.createLogAndSave('OrderLineItem_Schedule','constructor', ex.getStackTraceString(), ex);
      //Showing invalid message for exception: commented below code to fix it.
    	oli.addError(ex.getMessage());
    }
  
    if ( !step1 ) {
      revenue = 0;   
      for( Order_Revenue_Schedule__c o : [SELECT Id, Name, Comment__c,
                                               Revenue__c, Scheduled_Date__c,
                                               Order_Line_Item__c
                                        FROM Order_Revenue_Schedule__c
                                       WHERE Order_Line_Item__c = :parentOLIId 
                                       ORDER BY Scheduled_Date__c]) {
        lstORS.add (o);
        revenue = revenue + o.Revenue__c;
      }
      editModeNoRecords = (lstORS.size() == 0) ? true : false;
      addORSRows (12-lstORS.size());
    } else {
      tempLstORSDelete = new List<Order_Revenue_Schedule__c>();
      for (Order_Revenue_Schedule__c o : [SELECT Id FROM Order_Revenue_Schedule__c 
                                         WHERE Order_Line_Item__c =: parentOLIId]){
         tempLstORSDelete.add(o);
      }
    }
  }//END of constructor
 
  //===========================================================================
  //method to generate picklist
  //===========================================================================
  /*public List<SelectOption> getScheduleTypes () {
    List<SelectOption> options = new List<SelectOption> ();
    options.add (new SelectOption ('none','--None--') );
    options.add (new SelectOption ('multiple','Divide Amount into multiple installments') );
    options.add (new SelectOption ('repeat','Repeat Amount for each installment') );
    return options;
  }//END of getScheduleTypes method
  */
 
  //===========================================================================
  //method to generate picklist
  //===========================================================================
  public List<SelectOption> getInstallmentPeriods () {
    List<SelectOption> options = new List<SelectOption> ();
    options.add (new SelectOption ('none','--None--'));
    //options.add (new SelectOption (Constants.INSTALLMENT_PERIOD_DAILY, Constants.INSTALLMENT_PERIOD_DAILY));
    //options.add (new SelectOption (Constants.INSTALLMENT_PERIOD_WEEKLY, Constants.INSTALLMENT_PERIOD_WEEKLY));
    options.add (new SelectOption (Constants.INSTALLMENT_PERIOD_MONTHLY, Constants.INSTALLMENT_PERIOD_MONTHLY));
    options.add (new SelectOption (Constants.INSTALLMENT_PERIOD_QUATERLY, Constants.INSTALLMENT_PERIOD_QUATERLY));
    options.add (new SelectOption (Constants.INSTALLMENT_PERIOD_YEARLY, Constants.INSTALLMENT_PERIOD_YEARLY));
    return options;
  }//END of getInstallmentPeriods method
 
  //===========================================================================
  //method to return link to parent Order Line Item
  //===========================================================================
  public PageReference parentURL () {  
    return new PageReference ('/'+parentOLIId);
  }//END of parentURL method
 
  //===========================================================================
  //method to save Order Schedule and open page 2
  //===========================================================================
  public PageReference save () {
    if (!validateSchedulingData()) {
      return null;
    }
    step2ORP ();
    addORSRows (12-numberOfInstallments);
    return null;
  }//END of save method
 
  //===========================================================================
  //method to save Order Revenue Schedule records
  //===========================================================================
  public PageReference saveORS () {  
    if ( !validateORSData () ) {
      return null;
    }
    //delete existing records in edit mode
    try {
      if ( tempLstORSDelete != null && tempLstORSDelete.size()>0 ) {
        delete tempLstORSDelete;
      }
      lstORSToSave = new List<Order_Revenue_Schedule__c> ();
      tempLstORSDelete = new List<Order_Revenue_Schedule__c>();
      for (Order_Revenue_Schedule__c o : lstORS ) {
        if (o.Revenue__c != null && o.Scheduled_Date__c != null) {
          lstORSToSave.add (o);
        }
        // condition to remove the delete the records removed from edit page
        else if (o.Id != null && o.Revenue__c == null && o.Scheduled_Date__c == null) {
          tempLstORSDelete.add (o);
        }
      }
      System.debug('\nOrderLineItem_ScheduleSetupController : saveORS : TESTING' + lstORS);
      if (lstORSToSave.size() > 0) {
        //reCalculateRevenue ();
        upsert lstORSToSave;
        if (tempLstORSDelete.size() > 0) {
          delete tempLstORSDelete;
        }
        return parentURL();
      }
    } catch (Dmlexception ex) {
    	  System.debug('\n[OrderLineItem_Schedule - saveORS()] : '+ ex.getMessage());
    	  //Common_Utils.createApexLog(ex, 'OrderLineItem_Schedule', 'saveORS', ex.getMessage());
    	  for (Integer i=0; i < ex.getNumDml(); i++) {
    	  	lstORSToSave.get(0).addError(ex.getDMLMessage(i));
    	  }
    } catch (Exception ex) { 
    	  System.debug('\n[OrderLineItem_Schedule - saveORS()] : '+ ex.getMessage());
        //Common_Utils.createApexLog(ex, 'OrderLineItem_Schedule', 'saveORS', ex.getMessage());
        lstORSToSave.get(0).addError(ex.getMessage());
    }
   return null;
  }//END of saveORS method
 
  //===========================================================================
  //method to generate Order Revenue Schedule rows on basis of Order Schedule
  //===========================================================================
  public PageReference step2ORP () {
    step1 = false;
    Order_Revenue_Schedule__c tempORS;
    //Decimal tempRevenue = 0.00;
    for ( Integer temp = 0; temp < numberOfInstallments; ++temp) {
      tempORS = new Order_Revenue_Schedule__c();
      tempORS.CurrencyIsoCode = oli.CurrencyIsoCode;
      tempORS.Order_Line_Item__c = parentOLIId;
      tempORS.Comment__c = '';
      tempORS.Revenue__c = Decimal.valueOf(String.valueOf(Integer.valueOf(revenue/numberOfInstallments))).setScale(2);
      if (/* scheduleTypeSelected.equalsIgnoreCase('multiple') && */temp ==  numberOfInstallments-1 ) {
        tempORS.Revenue__c = Integer.valueOf(revenue/numberOfInstallments) + 
                         Math.mod(Integer.valueOf(revenue),numberOfInstallments) +
                         revenue.setScale(2) - Integer.valueOf(revenue);
      }
      /*if (installmentPeriodSelected.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_DAILY)) {
        tempORS.Scheduled_Date__c = conStartDate.Birthdate.addDays(temp) ;
      } else if (installmentPeriodSelected.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_WEEKLY)) {
        tempORS.Scheduled_Date__c = conStartDate.Birthdate.addDays(temp * 7);
      } else */
      if (installmentPeriodSelected.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_MONTHLY)) {
        tempORS.Scheduled_Date__c = conStartDate.Birthdate.addMonths(temp);
      } else if (installmentPeriodSelected.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_QUATERLY)) {
        tempORS.Scheduled_Date__c = conStartDate.Birthdate.addMonths(temp * 3);
      } else if (installmentPeriodSelected.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_YEARLY)) {
        tempORS.Scheduled_Date__c = conStartDate.Birthdate.addYears(temp);
      }       
      lstORS.add ( tempORS );   
    }
    revenue = revenue;
    System.debug('\nOrderLineItem_ScheduleSetupController : saveORS : TESTING ' + lstORS);
    return null;
  }//END of step2ORP
 
  //===========================================================================
  //method to recalculated the revenue amount on Order Revenue Schedule scheduling page
  //===========================================================================
  public PageReference reCalculateRevenue () {
    revenue = 0;
    System.debug('\nOrderLineItem_ScheduleSetupController : saveORS : TESTING ' + lstORS);
    for (Order_Revenue_Schedule__c o : lstORS) {
      if (o.Revenue__c != null) {
        //o.Revenue__c = Decimal.valueOf (String.valueOf(o.Revenue__c));
        revenue = revenue + o.Revenue__c;
      }
    } 
    System.debug('\nOrderLineItem_ScheduleSetupController : saveORS : TESTING ' + lstORS);
    return null;
  }//END of reCalculateRevenue method
 
  //===========================================================================
  //method to add n blank rows of Order Revenue Schedule to the list
  //===========================================================================
  private void addORSRows (Integer addNRows) {
    Order_Revenue_Schedule__c tempORS;
    for ( Integer counter = 0 ; counter < addNRows ; ++counter) {
      tempORS = new Order_Revenue_Schedule__c ();
      tempORS.Order_Line_Item__c = parentOLIId;
      tempORS.Comment__c = '';
      tempORS.Revenue__c = null;
      tempORS.Scheduled_Date__c = null;
      lstORS.add ( tempORS ); 
    }
  }//END of addORSRows method
 
  //===========================================================================
  //validate the Order Schedule data
  //===========================================================================
  private boolean validateSchedulingData () {
    if (/*scheduleTypeSelected.equalsIgnoreCase('none') || */ installmentPeriodSelected.equalsIgnoreCase('none')) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Schedule_Type_And_Installment_Period));
      return false;
    } else  if (numberOfInstallments == null || revenue == null || conStartDate.Birthdate == null) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Required_Data));
      return false;
    } else if (numberOfInstallments < 1) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Positive_Installments));
      return false;
    }
   
    return true;
  }//END of validateSchedulingData method
  
  //===========================================================================
  //validate the Order Revenue Schedule data
  //===========================================================================
  private boolean validateORSData () {
    Boolean scheduleRecordsAdded = true;
    for (Order_Revenue_Schedule__c o : lstORS) {
      if (o !=null && o.Order_Line_Item__c == null) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Required_Data));
        return false;
      }    
      if (! (o != null && o.Revenue__c == null && o.Scheduled_Date__c == null) 
         && (o != null && (o.Revenue__c == null || o.Scheduled_Date__c == null))) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Required_Data));
        return false;
      }
    } 
    for (Order_Revenue_Schedule__c o : lstORS) {
      if (o.Revenue__c != null || o.Scheduled_Date__c != null) {
        scheduleRecordsAdded = false;
      }
    }
    if (scheduleRecordsAdded) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.OLISS_Ensure_Required_Data));
      return false;
    }
    return true;
  }//END of validateORSData method
}