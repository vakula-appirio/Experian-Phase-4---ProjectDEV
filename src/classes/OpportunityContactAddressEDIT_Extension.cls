/**======================================================================================================
 * Appirio, Inc
 * Name             : OpportunityContactAddressEDIT_Extension
 * Description      : T-325893: EDQ Opportunity Contact Addresses Javascript button
 * Created Date     : Oct 14th, 2014
 * Created By       : Naresh Kr Ojha(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 =======================================================================================================*/ 
 public with sharing class OpportunityContactAddressEDIT_Extension {
    
  public Opportunity_Contact_Address__c currentOpptyContactAddress{get;set;}
  public Integer size {get;set;}
  public Integer noOfRecords {get;set;}
  public String selectedRec {get;set;}
  public String currentAddressOnOppty {get;set;}
    
  //Constructor
  public OpportunityContactAddressEDIT_Extension(ApexPages.StandardController controller) {
    System.debug('==recordID===>'+controller.getId());
    System.debug('==getRecord===>'+controller.getRecord());
    for (Opportunity_Contact_Address__c opptyContAdd : [SELECT Contact__c, Contact__r.Name, ID, Address__c, Opportunity__c
                                                        FROM Opportunity_Contact_Address__c 
                                                        WHERE ID =: controller.getId()]) {
        currentOpptyContactAddress = opptyContAdd;
        currentAddressOnOppty = opptyContAdd.Address__c;
    } 
    
    if (currentOpptyContactAddress == null || currentOpptyContactAddress.Contact__c == null) {
        Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, Label.OPPTY_CONT_ADD_INVALID);
      Apexpages.addmessage(msg);
    }
    size = 25;
  }
  
  //Standard controller to get records by soql
  public ApexPages.StandardSetController setCon {
    get{
      if(setCon == null){
        string queryString = 'Select Id, Address__c, Contact__r.Name, Contact__c, Contact_Address_City__c, Contact_Address2__c, Contact_Address1__c, ' + 
                             ' Address_Type__c From Contact_Address__c ' +
                             ' WHERE Contact__c = \'' + currentOpptyContactAddress.Contact__c + '\'';
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
        setCon.setPageSize(size);
        noOfRecords = setCon.getResultSize();
      }
      return setCon;
    }set;
  }
  
  //Getting fetched Contact Addresses
  public List<ContactAddressWrapper> getContactAddressList() {
    List<ContactAddressWrapper> contactAddresses = new List<ContactAddressWrapper>();
    for(Contact_Address__c ca : (List<Contact_Address__c>)setCon.getRecords()) {
        contactAddresses.add(new ContactAddressWrapper(ca, false));
    }
    return contactAddresses;
  }
  
  //Update OpptyContactAddress with new selected address.
  public Pagereference saveOpptyContact () {
    //currentOpptyContactAddress.Address__c = selectedRec;
    //update currentOpptyContactAddress;
    Contact_Address__c selectedContAddress = [SELECT Address__c, ID FROM Contact_Address__c WHERE ID =: selectedRec];
    if (selectedContAddress != null) {
      currentOpptyContactAddress.Address__c = selectedContAddress.Address__c;
      update currentOpptyContactAddress;
      currentAddressOnOppty = selectedContAddress.Address__c;
      
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.OPPTY_CONT_ADD_SAVED));
        
    }
    return null;
  }

  //Update OpptyContactAddress with new selected address.
  public Pagereference saveOpptyContactAndReturn () {
    saveOpptyContact ();
    Pagereference pg = new Pagereference('/'+currentOpptyContactAddress.Opportunity__c);    
    return pg;
  }

  //Update OpptyContactAddress with new selected address.
  public Pagereference noAction () {
    Pagereference pg = new Pagereference('/'+currentOpptyContactAddress.ID);    
    return pg;
  }
  
  public pageReference refresh() {
        setCon = null;
        getContactAddressList();
        setCon.setPageNumber(1);
        return null;
  }  
  
  public Boolean hasNext {
    get {
      return setCon.getHasNext();
    }set;
  }

    public Boolean hasPrevious {
      get {
        return setCon.getHasPrevious();
      }
      set;
    }

    public Integer pageNumber {
      get {
        return setCon.getPageNumber();
      }
      set;
    }

    public void first() {
      setCon.first();
    }

    public void last() {
      setCon.last();
    }

    public void previous() {
      setCon.previous();
    }

    public void next() {
      setCon.next();
    }

   public class ContactAddressWrapper {
      public Contact_Address__c contactAddress {get;set;}
      public Boolean selected {get;set;}
      public ContactAddressWrapper (Contact_Address__c contAdd, Boolean isSel) {
        contactAddress = contAdd;
        if (isSel) {
          selected = true;
        } else {
          selected = false;
        }
      }
    }
   
}