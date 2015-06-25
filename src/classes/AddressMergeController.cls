/**===================================================================================================
 * Appirio Inc
 * Name: AddressMergeController.cls
 * Description: Controller for AddressMergePage.page
 * Created Date: Mar 4, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified            Modified By                   Description of the update
 * March 06, 2014           Nathalie Le Guay (Appirio)    Updated page name from ManualAddressMerge to AddressMerge
 * March 09, 2014                       Naresh Kr Ojha (Appirio)          Added page size select list.
 * March 26, 2014           Nathalie Le Guay              Added Used_on_Aria_Billing_Account__c to the Address__c query
 * March 27, 2014           Nathalie Le Guay              Added limit of 10000 records in the query
 * Oct 25th, 2014           Nathalie Le Guay (Appirio)    Removing functionality
 ===================================================================================================*/
public with sharing class AddressMergeController {
/*
  //Address list to hold initial and selected records
  public Map<String, AddressResult> addressMap {get;set;}
  public Map<ID, AddressResult> addressMergeMap {get;set;}
  public String selectedMaster {get;set;}
  public Set<String> selectedAddressIDs {get;set;}
    public Map<String, AddressResult> selectedAddressResultMap {get;set;}
    
  //Total records available to be redcnered
  public Integer noOfRecords {get; set;}
  public Integer size {get;set;}
*/
  public AddressMergeController(ApexPages.StandardController controller) {
    /*selectedAddressIDs = new Set<String>();
    selectedAddressResultMap = new Map<String, AddressResult>();
    size = 10;
    
    populateAddresses ();
    selectedMaster = '';*/
  }
/*
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('10', '10'));
        options.add(new SelectOption('25', '25'));
        options.add(new SelectOption('50', '50'));
        options.add(new SelectOption('100', '100'));
        return options;
    }     
  //Constructor
  //public AddressMergeController () {
    //selectedAddressIDs = new Set<String>();
    //selectedAddressResultMap = new Map<String, AddressResult>();
    
    //populateAddresses ();
    //selectedMaster = '';
  //} 
  //Standard controller set
  public ApexPages.StandardSetController setCon {
    get{
       if(setCon == null){
        string queryString = 'SELECT ID, Name, County__c, Country__c, Last_Validated__c, Validation_Status__c, Address_1__c, Used_on_Aria_Billing_Account__c'
                           + ' FROM Address__c Order by Name LIMIT 10000';
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
            setCon.setPageSize(size);
            noOfRecords = setCon.getResultSize();
      }
        return setCon;
    }set;
  }

  //Populates records to addressMap to render on page
  public void populateAddresses(){
    List<AddressResult> accList = new List<AddressResult>();
        addressMap = new Map<String, AddressResult>();
        AddressResult addResult;
    for(Address__c a : (List<Address__c>)setCon.getRecords()) {
        addResult = new AddressResult(a);
        if (selectedAddressIDs.contains(a.ID)) {
            addResult.isSelected = true;
        } 
        addressMap.put(a.ID, addResult);
    }
    //return accList;
  }

  //set current page size
  public Pagereference resizePage () {
    refresh();
    //populateAddresses ();
    return null;
  }
    
    //Proceed to second page where master record is to defined
  public Pagereference mergeAddresses () {
    addressMergeMap = new Map<ID, AddressResult>();
    Pagereference pr;
    try {
        for (AddressResult addrs : selectedAddressResultMap.values()) {
          if (addrs.isSelected) {
            addressMergeMap.put(addrs.address_o.ID, addrs);
          }
        }

        if (addressMergeMap.values().size() < 2) {
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.Address_Merge_SELECT_TWO_OR_MORE);
          ApexPages.addMessage(myMsg);  
          pr = new Pagereference('/apex/AddressMerge');
    
        } else {
          pr = new Pagereference('/apex/AddressMergeStep2');
        }
    } catch (Exception ex) {
      System.debug('\n[AddressMergeController: mergeAddresses]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMergeController','mergeAddresses', ex.getStackTraceString(), ex);
            
    }
    return pr;
  }
      
  //Total selected records
  public Integer getTotalSelectedAddresses () {
    Integer selectedResult = 0;
    
    if (selectedAddressResultMap.size() > 0) {
        selectedResult = selectedAddressResultMap.size();
    }
    return selectedResult;
  }
  
  //Call webservice to create address merge request
  public Pagereference processMerge () {
    Pagereference pr;
    System.debug('[AddressMergeController:processMerge]:[---'+String.isBlank(selectedMaster)+'----]');
    try {
        if (addressMergeMap == null || addressMergeMap.keySet().size() < 1) {
          pr = new Pagereference('/apex/AddressMerge');
          pr.setRedirect(true);
          return pr;            
        }
        
        if (String.isBlank(selectedMaster)) {
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.Address_Merge_SELECT_ONE_RECORD);
          ApexPages.addMessage(myMsg);  
          pr = new Pagereference('/apex/AddressMergeStep2');
          return pr;
        } else {
            String masterId = selectedMaster;
            addressMergeMap.remove(selectedMaster);
            List<String> slaveIDs = new List<String>();
            String mergeType = Constants.MANUAL;
            for (String slaveId : addressMergeMap.keySet()) {
                slaveIDs.add(slaveId);
            }
            
            if (AddressMerge.mergeAddressWebserviceManual(masterId, slaveIDs, mergeType)) {
              ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, Label.ACC_MERGE_REQ_SUCCESS);
              ApexPages.addMessage(myMsg);
              refresh();
              pr = new Pagereference('/apex/AddressMergeStep2?merged=1');
              //pr.setRedirect(true);
              return pr;
            }
        }
    } catch (Exception ex) {
      System.debug('\n[AddressMergeController: processMerge]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMergeController','processMerge', ex.getStackTraceString(), ex);       
    }
    return null;
  }
  
  //Add selected records to set
  public Pagereference addSelectedToSet () {
        String addressId = ApexPages.CurrentPage().getParameters().get('addressId');
        String event = ApexPages.CurrentPage().getParameters().get('event');
        System.debug('\n[AddressMergeController: processMerge]: [addressId:'+addressId+', event:'+event+']]');
        if (event == 'Add') {
          selectedAddressIDs.add(addressId);
          selectedAddressResultMap.put(addressId, addressMap.get(addressId));
        } else if (event == 'Remove' && selectedAddressIDs.contains(addressId)) {
            selectedAddressIDs.remove(addressId);
            selectedAddressResultMap.remove(addressId);
        }
    return null;
  }
  
  //Wrapper class with address object & booelan flag to indicate whether 
  //the record is selected or not 
  public class AddressResult {
    public Address__c address_o{get; set;}
    public Boolean isSelected {get; set;}
            
    public AddressResult(Address__c addrs) {
      address_o = addrs;
      isSelected = false; //initially the record is not selected
    }  
  }
  
 
  //Resets the values of the page and reinitiate properties
  public void refresh() {
    setCon = null;
    setCon.setPageNumber(1);
    selectedMaster = '';
    addressMap = new Map<String, AddressResult>();
    addressMergeMap = new Map<ID, AddressResult>();
    selectedAddressIDs = new Set<String>();
    selectedAddressResultMap = new Map<String, AddressResult>();
        populateAddresses();
  }

  //Resets the values of the page and reinitiate properties
  public Pagereference cancelProcess() {
    system.debug('\nThere are : '+ getTotalSelectedAddresses() + ' addresses selected');
    Pagereference pr = new Pagereference('/apex/AddressMerge');
    pr.setRedirect(true);
    return pr;
  }  
  //Check Next page available
  public Boolean hasNext {
    get {
      return setCon.getHasNext();
    }
    set;
  }
  //Check Previous page available
  public Boolean hasPrevious {
    get {
      return setCon.getHasPrevious();
    }
    set;
  }
  //Current page number
  public Integer pageNumber {
    get {
      return setCon.getPageNumber();
    }
    set;
  }
  //Move to first page
  public void first() {
    setCon.first();
    populateAddresses();
  }
  //Move to last page
  public void last() {
    setCon.last();
    populateAddresses();
  }
  //Move to previous page
  public void previous() {
    setCon.previous();
    populateAddresses();
  }
  //Move to next page
  public void next() {
    setCon.next();
    populateAddresses();
  }
*/
}