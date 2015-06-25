/**=====================================================================
 * Appirio Inc
 * Name: AddOrCreateNewAccountAddressController.cls
 * Description: 
 * Created Date: Oct 19, 2013
 * Created By: Mohammed Irfan (Appirio)
 *
 * Date Modified         Modified By                   Description of the update
 * January 21st, 2014    Nathalie Le Guay              Adding duplicate check
 * Feb 13th, 2014        Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 * Feb 17th, 2014        Arpita Bose(Appirio)          T-249492: Added Labels for messages and
 *                                                     LoggingLevel.INFO added
 * Mar 04th, 2014        Arpita Bose(Appirio)          T-243282: Added Constants in place of String
 * Apr 07th, 2014        Arpita Bose                   T-269372: Added addError() in try-catch block
 * Apr 28th, 2014        Arpita Bose                   T-275717: Added LIMIT to fix the Force.com Security Scanner Results
 * May 01st, 2014        Naresh kr Ojha (Appirio)      Updated catch(Exception) to catch(DMLException) to use getDMLException
 * Aug 25th, 2014        Richard Joseph                Case - 05230. To validate # registered address for an account , 
                                                       To Validate if the Account and Country of registration already exist.
 * Feb 23th, 2015        Noopur                        T-363964 : added the logic for New Account button to bypass the QAS screen
 * Feb 24th, 2015        Naresh Kr Ojha                T-364971: Added isSaaS option when goes to create new Account. 
 * Mar 16th, 2015        Naresh  Kr Ojha               T-366850: Backing of of the work done by task T-364971. Removed isSaaS references
 =====================================================================*/
public class  AddOrCreateNewAccountAddressController {

    public Account account {get;set;}
    public Address__c address {get;set;}
    public String retURL {get;set;}
    public String action {get;set;}
    private String addressId;
    public boolean enableEditMode{get;set;}
    public boolean enableManualAddressSelection {get;set;}
    public boolean isAddressPopupOnload{get;set;}
    public Account_Address__c accountAddress {get;set;}
    public boolean bypassQAS {get;set;}
    public Map<ID, Account> duplicateAccounts {get;set;}
    
    //MIrfan. TypeDown SessionId Property.
    public String QASTypedownSessionToken {

        get
        {
            for(QAS_NA__QAS_CA_Account__c accountSObject : [SELECT  QAS_NA__ValidationSessionToken__c FROM QAS_NA__QAS_CA_Account__c
                                                            limit 10000 ])
                QASTypedownSessionToken = accountSObject.QAS_NA__ValidationSessionToken__c; 

            return QASTypedownSessionToken;    

        }

     private set;} 

    private String accountId;

    // DUPLICATES
    // Initialize a list to hold any duplicate records
    private List<sObject> duplicateRecords;
    // Define variable that’s true if there are duplicate records
    public boolean hasDuplicateResult{get;set;}

    public AddOrCreateNewAccountAddressController(ApexPages.StandardController controller) {

        // DUPLICATES
        this.duplicateRecords = new List<sObject>();
        this.hasDuplicateResult = false;
        duplicateAccounts = new Map<ID, Account>();    


        addressId = ApexPages.currentPage().getParameters().get('addrId'); 
        String recordType = ApexPages.currentPage().getParameters().get('RecordType');
        //Commented as per T-366850 on 16/03/15. nojha
        //String isSaaS = ApexPages.currentPage().getParameters().get('isSaaS');
        accountId = ApexPages.currentPage().getParameters().get('accId');
        action = Label.ASS_Operation_NewAccountAddress;//ApexPages.currentPage().getParameters().get('action');
        
        bypassQAS = false;
        if (ApexPages.currentPage().getParameters().get('bypassQAS') != '' && ApexPages.currentPage().getParameters().get('bypassQAS') == '1'){
          bypassQAS = true;
        }

        account = new Account();
        address = new Address__c(Authenticated_Address__c=true);
        accountAddress = new Account_Address__c();
        enableEditMode=true;
        isAddressPopupOnload = true;
        enableManualAddressSelection = true;

        User usrRec = [SELECT Country__c,Region__c FROM User WHERE id=:UserInfo.getUserId()];
        if(usrRec.Country__c != null) {
          address.Country__c = usrRec.Country__c;
        }

        //enableManualAddressSelection=false;
        if(ApexPages.currentPage().getParameters().get('action')!=null)
            enableManualAddressSelection = (
                                ApexPages.currentPage().getParameters().get('action').equalsIgnoreCase(Label.ASS_Operation_AddAddress)
                                ||
                                ApexPages.currentPage().getParameters().get('action').equalsIgnoreCase(Label.ASS_Operation_NewAccountAddress));



        if(!String.isBlank(recordType)) {
            account.RecordTypeId = recordType;
        }

        /* Commented as per T-366850 on 16/03/15. nojha
        if(!String.isBlank(isSaaS) && isSaaS == '1') {
            account.SaaS__c = true;
        }*/

        if(accountId != null) {
            //enableEditMode = false;//Commented as per Nathalie's chatter on T-369542. nojha
            String Qry = 'SELECT ' ;
            for(Schema.FieldSetMember f : SObjectType.Account.FieldSets.AccountInfoSectionFieldSet.getFields()) {
                Qry += f.getFieldPath() + ', ';
            }

            for(Schema.FieldSetMember f : SObjectType.Account.FieldSets.AccountAddInfoSectionFieldSet.getFields()) {
                Qry += f.getFieldPath() + ', ';
            }
            
            for(Schema.FieldSetMember f : SObjectType.Account.FieldSets.AccountStrategicInfoSectionFieldSet.getFields()) {
                Qry += f.getFieldPath() + ', ';
            }
            //[RJ] Case 05230 - Added new field to the query Number_of_Registered_Address__c
            Qry += 'Id, Number_of_Registered_Address__c FROM Account  where id=:accountId';
            account = Database.query(Qry );
        }
        else {
            account.name=ApexPages.currentPage().getParameters().get('accName'); 
            account.Region__c = usrRec.Region__c;
        }

        if(addressId != null) {

            String Qry = 'SELECT ' ;
            /*for(Schema.FieldSetMember f : SObjectType.Account__c.FieldSets.Dimensions.getFields()) {
                Qry += f.getFieldPath() + ', ';
            }*/

            String[] strArr = addressId.split(';');
            string addrId = strArr[1];
            
            System.debug(LoggingLevel.INFO, '##############strArr################'+strArr);
            
            accountAddress = [select id,Address_Type__c  from Account_Address__c where Id=:strArr[0] limit 1];
            
            Qry += ' Id, Address_1__c, Address_2__c, Address_3__c, Address_4__c, City__c, Country__c, CEDEX__c, Codiga_Postal__c,'+
                   'County__c, District__c, Emirate__c, Floor__c, Partofterritory__c, POBox__c, Postcode__c, Prefecture__c, '+
                   'Province__c, SortingCode__c, State__c, Suite__c, Zip__c, Last_Validated__c, Validation_Status__c, Address_Id__c'
                + ' FROM Address__c'
                + ' WHERE id=:addrId ';
            address = Database.query(Qry);
            
            
        }



        retURL =  ApexPages.currentPage().getParameters().get(Constants.PARAM_NAME_RETURL); 
        retURL = (retURL==null)?'/001/o':retURL;
    }

   // DUPLICATES
  // Return duplicate records to the Visualforce page for display
    public List<sObject> getDuplicateRecords() {
        return this.duplicateRecords;
    }


    public Pagereference performSave() {
        system.debug('PGB before savepoint');
        Savepoint sp;
        system.debug('PGB after savepoint');
        //Master Try/Catch
        try
        {
            System.debug(LoggingLevel.INFO, '#########address###########'+address);
            isAddressPopupOnload = false;
            
            //validate data before saving.
           
            if (address.Id == null && (address.Validation_Status__c == null || address.Validation_Status__c == '') && bypassQAS == false)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ASS_Message_Address_Blank )); 
                    return null;
            }
            
              //[RJ] case # 05230 - Starts
              
              //To force users to create registered address at the time of Account creation.
              If(account !=null && account.id == null && accountAddress != null && accountAddress.Address_Type__c != 'Registered' && bypassQAS == false )
              {
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Acc_shd_have_Registered_Add )); 
                    return null;
              }
              
              //To validate if the Account and registered address combination exist
            If(accountAddress != null && account.Number_of_Registered_Address__c > 0 && accountAddress.Address_Type__c == 'Registered' && bypassQAS == false)
            {
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Acc_already_has_Registered_Add )); 
                    return null;
                    
                   
            }
              // To validate if the Account has more than one registered address.
            if ((address != null && accountAddress != null && address.Country__c != null && account.Number_of_Registered_Address__c >0 && account!=null&& account.id !=null && account.Country_of_Registration__c != null && account.Country_of_Registration__c.equalsIgnoreCase(address.Country__c) 
            && accountAddress.Address_Type__c == 'Registered'  ) && bypassQAS == false)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Acc_and_Reg_County_exist )); 
                    return null;
            }
            
            
            //To validate if another Account and registered address combination exist
            If(account.name !=null && accountAddress !=null && accountAddress.Address_Type__c == 'Registered' && bypassQAS == false )
            {
                List<Account_Address__c> extAccLst= new list<Account_Address__c> ([Select Account__r.id,Account__r.Name,Account__r.Country_of_Registration__c, account__r.Number_of_Registered_Address__c from Account_Address__c where Account__r.name = :Account.Name and Account__r.Country_of_Registration__c = :address.Country__c limit 1 ]);
                if (extAccLst.size() > 0)
                {
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Duplicate_Acc_and_Cntry )); 
                    return null;
                }
                
            }
            
            
            //[RJ] Case # 05230 ends
            
            

            // Setting save point to roll back in case of error. 
            sp = Database.setSavepoint();
            //Create Account.
            if (action.equalsIgnoreCase(Label.ASS_Operation_AddAccount) || action.equalsIgnoreCase(Label.ASS_Operation_NewAccountAddress)) {
                System.debug(LoggingLevel.INFO, '#########before account###########'+account);
                //insert account;
                // DUPLICATES
                Database.SaveResult saveResult = Database.insert(account, false);

            // DUPLICATES
            if (!saveResult.isSuccess()) {
              for (Database.Error error : saveResult.getErrors()) {
                // If there are duplicates, an error occurs
                // Process only duplicates and not other errors 
                //   (e.g., validation errors)
                if (error instanceof Database.DuplicateError) {
                    // Handle the duplicate error by first casting it as a 
                    //   DuplicateError class
                    // This lets you use methods of that class  
                    //  (e.g., getDuplicateResult())
                    Database.DuplicateError duplicateError = 
                            (Database.DuplicateError)error;
                    Datacloud.DuplicateResult duplicateResult = 
                            duplicateError.getDuplicateResult();
                    
                    // Display duplicate error message as defined in the duplicate rule
                    ApexPages.Message errorMessage = new ApexPages.Message(
                            ApexPages.Severity.ERROR, 'Duplicate Error: ' + 
                            duplicateResult.getErrorMessage());
                    ApexPages.addMessage(errorMessage);
                    
                    // Get duplicate records
                    this.duplicateRecords = new List<sObject>();
 
                    // Return only match results of matching rules that 
                    //  find duplicate records
                    Datacloud.MatchResult[] matchResults = 
                            duplicateResult.getMatchResults();

                    // Just grab first match result (which contains the 
                    //   duplicate record found and other match info)
                    Datacloud.MatchResult matchResult = matchResults[0];

                    Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                    // Add matched record to the duplicate records variable
                    for (Datacloud.MatchRecord matchRecord : matchRecords) {
                        System.debug('MatchRecord: ' + matchRecord.getRecord());
                        //System.debug('[DD] AdditionalInformation : ' + matchRecord.getAdditionalInformation());
                        System.debug('[DD] getFieldDiffs : ' + matchRecord.getFieldDiffs());
                        this.duplicateRecords.add(matchRecord.getRecord());
                        
                        if (!duplicateAccounts.containsKey(matchRecord.getRecord().ID)) {
                          duplicateAccounts.put(matchRecord.getRecord().ID, null);
                        }                        
                    }
                    this.hasDuplicateResult = !this.duplicateRecords.isEmpty();
                  }
              }
            
	            if (duplicateAccounts.size() > 0) {
	              for (Account acc : [SELECT ID, Type, Name, LastModifiedById, LastModifiedDate, OwnerId,
	                                         Owner.Name, BillingStreet, BillingState, BillingPostalCode, BillingCountry, 
	                                         BillingCity, Ultimate_Parent_Account__c, Ultimate_Parent_Account__r.Name, 
	                                         Region__c, ParentId, Parent.Name, Account_Type__c
	                                  FROM Account 
	                                  WHERE ID IN: duplicateAccounts.keySet()]) {
	                if (duplicateAccounts.containsKey(acc.ID)) {
	                  duplicateAccounts.put(acc.ID, acc);
	                }
	              }
	            }
              //If there’s a duplicate record, stay on the page
              return null;
            }
            
             
            

                //Create Address.
            if (action.equalsIgnoreCase(Label.ASS_Operation_AddAddress) || action.equalsIgnoreCase(Label.ASS_Operation_NewAccountAddress)
            && bypassQAS == false)
            {
                address = AddressUtility.checkDuplicateAddress(address); // NLG Jan 21st 2014
                if (String.isEmpty(address.Id)) {
                    insert address;
                }
            }

            System.debug(LoggingLevel.INFO, '#########account###########'+account);
            System.debug(LoggingLevel.INFO, '#########address###########'+address);
            
            if( bypassQAS == false) {
              // Creating a account association with the selected address id.  
              Account_Address__c newAccAdrRec = new Account_Address__c(Address_Type__c=accountAddress.Address_Type__c);
              newAccAdrRec.Account__c = account.Id;
              newAccAdrRec.Address__c = address.Id;
  
              System.debug(LoggingLevel.INFO, '#########newAccAdrRec###########'+newAccAdrRec);
              insert newAccAdrRec;
  
              System.debug(LoggingLevel.INFO, '#########newAccAdrRec###########'+newAccAdrRec);
            }

            retURL='/'+account.id;

            System.debug(LoggingLevel.INFO, '########accountAddress############'+accountAddress);
          }
	
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ASS_Message_Associate_Select_Address + e.getMessage())); 
            // Rollback if is there any error. 
            Database.rollback(sp); 
            ApexLogHandler.createLogAndSave('AddOrCreateNewAccountAddressController','performSave', e.getStackTraceString(), e);
                    
            address.addError(Label.ASS_Message_Associate_Select_Address);
            return null;  
        }
        //Back to where came from.
        return new PageReference(retURL);
    }

    /*
        On cancel return to account tab.
    */
    public Pagereference cancel() {
        return new Pagereference(retURL);
    }

     public pagereference blankCall()
     {
         System.debug(LoggingLevel.INFO, '###########address#############'+address);
         return null;
     }
}