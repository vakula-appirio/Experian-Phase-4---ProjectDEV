/**=====================================================================
 * Appirio Inc
 * Name: AddOrCreateNewContactAddressController.cls
 * Description: 
 * Created Date: Nov 15, 2013
 * Created By: Mohammed Irfan (Appirio)
 *
 * Date Modified         Modified By                   Description of the update
 * January 21st, 2014    Nathalie Le Guay              Adding duplicate check
 * Feb 13th, 2014        Jinesh Goyal(Appirio)         T-232763: Added Exception Logging 
 * Mar 04th, 2014        Arpita Bose(Appirio)          T-243282: Added Constants in place of String
 * Mar 06th, 2014        Naresh Kr Ojha(Appirio)       T-256339: Use of Labels for messages and used keyPrefix to get
 *                                                     Account's keyPrefix.
 * Mar 19th, 2014        Jinesh Goyal(Appirio)         T-251967
 * Apr 07th, 2014        Arpita Bose                   T-269372: Added addError() in try-catch block
 * Apr 10th, 2014        Jinesh Goyal(Appirio)         I-109889: Added accountUpdateId()
 * Apr 28th, 2014        Arpita Bose                   T-275717: Added LIMIT to fix the Force.com Security Scanner Results
 * May 1st, 2014         Arpita Bose                   Updated catch(Exception) to catch(DMLException) to use getDMLException
 * Feb 19, 2015          Noopur                        T-363891: added the logic to retrive the bypassQAS parameter from the URL 
 *                                                     to check if the user has clicked on "New Contact" button.
 * Feb 24th, 2015        Naresh Kr Ojha                T-364970: Added isSaaS option when goes to create new Contact.
 =====================================================================*/

public class AddOrCreateNewContactAddressController {
    
    //public Account account {get;set;}
    public Contact Contact {get;set;}
    public Address__c address {get;set;}
    public String retURL {get;set;}
    public String action {get;set;}
    public boolean enableEditMode{get;set;}
    public boolean enableManualAddressSelection {get;set;}
    public boolean isAddressPopupOnload{get;set;}
    public Account_Address__c accountAddress {get;set;}
    public Contact_Address__c contactAddress {get;set;}
    public boolean bypassQAS {get;set;}

    private String contactId;
    private String addressId;
    
    //MIrfan. TypeDown SessionId Property.
    public String QASTypedownSessionToken {
      get {
        for(QAS_NA__QAS_CA_Account__c accountSObject : [SELECT  QAS_NA__ValidationSessionToken__c FROM QAS_NA__QAS_CA_Account__c 
                                                        limit 10000]) {
           QASTypedownSessionToken = accountSObject.QAS_NA__ValidationSessionToken__c; 
        }
        return QASTypedownSessionToken;    
      }
      private set;
    } 
    //added by JG for T-251967
    public String addressIdFrmComponent {get;set;}
    public String accountName {get;set;}
    public String accountId {get;set;}
    //Constructor   
    public AddOrCreateNewContactAddressController() {
      addressId = ApexPages.currentPage().getParameters().get('addrId'); 
      String recordType = ApexPages.currentPage().getParameters().get('RecordType');
      String isSaaS = ApexPages.currentPage().getParameters().get('isSaaS');
      
      contactId = ApexPages.currentPage().getParameters().get('conId');
      action = ApexPages.currentPage().getParameters().get('action');
      bypassQAS = false;
      if (ApexPages.currentPage().getParameters().get('bypassQAS') != '' && ApexPages.currentPage().getParameters().get('bypassQAS') == '1'){
      	bypassQAS = true;
      }
      //account = new Account();
      contact = new Contact();
      address = new Address__c(Authenticated_Address__c=true);
      contactAddress = new Contact_Address__c();
      enableEditMode = true;
      isAddressPopupOnload = true; //Set false as per T-251967 : nojha
      
      User usrRec = [Select Country__c from User where id=:UserInfo.getUserId()];
      if (usrRec.Country__c != null) {
       address.Country__c = usrRec.Country__c;
      }
      
      enableManualAddressSelection = false;
      if (ApexPages.currentPage().getParameters().get('action') != null) {
          enableManualAddressSelection = (
                        ApexPages.currentPage().getParameters().get('action').equalsIgnoreCase(Label.CSS_Operation_AddAddress)
                        ||
                        ApexPages.currentPage().getParameters().get('action').equalsIgnoreCase(Label.CSS_Operation_NewContactAddress));
      }
      
      
      if (!String.isBlank(recordType)) {
        //contact.RecordTypeId = recordType;
      }
      
      if (!String.isBlank(isSaaS) && isSaaS == '1') {
        contact.SaaS__c = true;
      }
      
      if (contactId != null) {
          enableEditMode=false;
          String Qry = 'SELECT ';
          for (Schema.FieldSetMember f : SObjectType.Contact.FieldSets.ContactInfoSectionFieldSet.getFields()) {
            Qry += f.getFieldPath() + ', ';
          }
          
          Qry += 'Id FROM Contact  where id=:contactId';
          contact = Database.query(Qry );
      } else {
          contact.FirstName=ApexPages.currentPage().getParameters().get('conFName'); 
          contact.LastName=ApexPages.currentPage().getParameters().get('conLName'); 
          contact.Email=ApexPages.currentPage().getParameters().get('conEmail');
          if(ApexPages.currentPage().getParameters().containsKey('accId') && ApexPages.currentPage().getParameters().get('accId') != null && ApexPages.currentPage().getParameters().get('accId') != ''){
            contact.AccountId=ApexPages.currentPage().getParameters().get('accId'); 
          }
      }
      
      
      if (addressId != null) {
          
        String Qry = 'SELECT ';
        /*for(Schema.FieldSetMember f : SObjectType.Account__c.FieldSets.Dimensions.getFields()) {
          Qry += f.getFieldPath() + ', ';
        }*/
        
        String[] strArr = addressId.split(';');
        string addrId = strArr[1];
        
        contactAddress = [select id,Address_Type__c  from Contact_Address__c where Id=:strArr[0] limit 1];
        
        Qry += 'id, Address_1__c,Address_2__c,Address_3__c,Address_4__c,City__c,Country__c ,CEDEX__c,Codiga_Postal__c,County__c,District__c,Emirate__c,Floor__c,Partofterritory__c,POBox__c,Postcode__c,Prefecture__c,Province__c,SortingCode__c,State__c,Suite__c,Zip__c,Last_Validated__c,Validation_Status__c FROM Address__c where id=:addrId ';
        address = Database.query(Qry);
      }
      
      //Added getkeyprefix to remove hardcoded /001/o from below code.
      Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
      String AccountKeyPrefix = dsr.getKeyPrefix();
       
      retURL =  ApexPages.currentPage().getParameters().get(Constants.PARAM_NAME_RETURL); 
      //retURL = (retURL==null)?'/001/o':retURL;
      retURL = (retURL==null)?'/'+AccountKeyPrefix+'/o':retURL;
      addressIdFrmComponent = accountName = '';
      accountId = ApexPages.currentPage().getParameters().get('accId');
    }
    
    //Save method to save records    
    public Pagereference performSave() {
      System.debug('XXXX inside performSave');
      Savepoint sp;
      //Master Try/Catch
      try {
        isAddressPopupOnload=false;
        //validate data before saving.
        if (address.Id == null && (address.Validation_Status__c == null || address.Validation_Status__c == '') && bypassQAS == false) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_ADDRESS_IS_BLANK)); 
          return null;
        }
            
        // Setting save point to roll back in case of error. 
        sp = Database.setSavepoint();
        //Create Contact.
        if (action.equalsIgnoreCase(Label.CSS_Operation_AddContact) || action.equalsIgnoreCase(Label.CSS_Operation_NewContactAddress)) {
          insert contact;
        }
            
        //Create Address.
        if (action.equalsIgnoreCase(Label.CSS_Operation_AddAddress) || action.equalsIgnoreCase(Label.CSS_Operation_NewContactAddress) && bypassQAS == false) {
          address = AddressUtility.checkDuplicateAddress(address); // NLG Jan 21st 2014
          if (address.Id == null) {
            insert address;
          }
        }
                
        if (address.Id != null && bypassQAS == false) {
        	// Creating a Contact association with the selected address id.  
	        Contact_Address__c newConAdrRec = new Contact_Address__c(Address_Type__c=contactAddress.Address_Type__c);
	        newConAdrRec.Contact__c = contact.Id;
	        newConAdrRec.Address__c = address.Id;
	        
	        insert newConAdrRec;
        }        
        
        retURL='/'+contact.id;

      } catch(DMLException e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  e.getMessage())); 
        ApexLogHandler.createLogAndSave('AddOrCreateNewContactAddressController','performSave', e.getStackTraceString(), e);
        return null;
        for (Integer i = 0; i < e.getNumDml(); i++) {
        	address.addError(e.getDmlMessage(i));
        }
            
      }//END: Master Try/Catch
       catch(Exception e) { 
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EXCEPTION_WHILE_SAVING_REC + e.getMessage())); 
         // Rollback if is there any error. 
         Database.rollback(sp); 
         ApexLogHandler.createLogAndSave('AddOrCreateNewContactAddressController','performSave', e.getStackTraceString(), e);
         
         address.addError(Label.EXCEPTION_WHILE_SAVING_REC);
         return null;
      }
      
      //Back to where came from.
      return new PageReference(retURL);
    }
    

  //On cancel return to Contact tab.
  public Pagereference cancel() {
    return new Pagereference(retURL);
  }
  
  //Blank call method  
  public pagereference blankCall() {
    return null;
  }
  
  //added by JG for T-251967
  //method to update the address Id (for the address selected) coming from the address component on the page
  public void updateAddress () {
    if (addressIdFrmComponent == '' || addressIdFrmComponent == null) {
      address.Id = null;
    } else if (addressIdFrmComponent != null) {
      address.Id = addressIdFrmComponent;
    }
  }//END OF METHOD 'updateAddress'
  
  //Get Account Id for the latest account selected on Contact creation page
  public void accountUpdateId() {
    Boolean resultFound = false;
    Account tempAcc = new Account();
    for(Account acc : [SELECT Id FROM Account
                       WHERE Name = :accountName 
                       LIMIT 1]) {
        resultFound = true;      
        tempAcc = acc;
    }
    //update values to be used on page
    if (!resultFound) {
      accountId = null;
    }else {
      accountId = tempAcc.Id;
    }
  } 
}