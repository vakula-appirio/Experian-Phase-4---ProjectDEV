/**=====================================================================
 * Appirio, Inc
 * Name: ContactAddressTriggerHandler
 * Description:
 * Created Date: Nov 19th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified               Modified By              Description of the update
 * Jan 30th, 2014              Jinesh Goyal (Appirio)   T-232760: Homogenize the comments
 * Mar 12th & 14th, 2014       Naresh Kr Ojha (Appirio) T-251968: Contact Addresses on the Account: Contact_Address__c trigger
 * Mar 24th, 2014              Nathalie Le Guay (Appirio) Added try-catch to createNewAccountAddresses()
 * Apr 08th, 2014              Arpita Bose(Appirio)     T-269372: Added addError()in try-catch block
 * May 19th, 2014              Nathalie Le Guay         I-115270: Replace the duplicate check section with code that uses Address__c.Address_Id__c
 *                                                      instead of looping through a large portion of the Contact_Address__c table, for scalability
 =====================================================================*/

public class ContactAddressTriggerHandler {
  //Process beforeInsert Operations.
  public static void beforeInsert(LIST<Contact_Address__c> lstNew) {
    checkForDuplicateContactAddress(lstNew);
  }
  //Process beforeInsert Operations.
  public static void afterInsert(LIST<Contact_Address__c> lstNew) {
    createNewAccountAddresses (lstNew);
  }
  
  //Owner changed, old older was DQ
  public static void checkForDuplicateContactAddress(LIST<Contact_Address__c> lstNew) {
    Map<Id,String> mapContactIdNames = new Map<Id,String>();
    Map<Id,Address__c> mapAddresses = new Map<Id,Address__c>();
    
    //Have Set for each Address Field.
    Set<String> setAddr1 = new Set<String>();
    Set<String> setAddr2 = new Set<String>();
    Set<String> setAddr3 = new Set<String>();
    Set<String> setCity = new Set<String>();
    Set<String> setState = new Set<String>();
    Set<String> setProvince = new Set<String>();
    Set<String> setCountry = new Set<String>();
    Set<String> setPostcode = new Set<String>();
    Set<String> setZip = new Set<String>();
    
    
    Set<String> setContactIds = new Set<String>();
    Set<String> setAddressIds = new Set<String>();
    
    //Retrieve Contact and Address record Ids.
    for (Contact_Address__c trgRec:lstNew) {
      if (trgRec.Contact__c != null && trgRec.Address__c != null) {
        setContactIds.add(trgRec.Contact__c);
        setAddressIds.add(trgRec.Address__c);
      }
    }//END: FOR trgRec
    
    //Retrive ContactNames.
    for (List<Contact> lstCons:[select Id,Name from Contact where Id=:setContactIds]) {
      for (Contact conRec:lstCons) {
        mapContactIdNames.put(conRec.Id,conRec.Name);
      }
    }//END: FOR lstCons


    Datetime meow = Datetime.now();
    // NLG May 19th, 2014
    List<Address__c> addresses = [SELECT Id,Address_1__c,Address_2__c,Address_3__c,Address_4__c,Country__c,State__c,Province__c,City__c,Postcode__c,Zip__c, CEDEX__c,
                                         Codiga_Postal__c, County__c, District__c, Emirate__c, Floor__c, Partofterritory__c, POBox__c, Prefecture__c, SortingCode__c,
                                         Suite__c
                                  FROM Address__c 
                                  WHERE Id=:setAddressIds];
    if (AddressUtility.hasDuplicateAddresses(addresses, mapContactIdNames.keySet(), Constants.SOBJECT_CONTACT)) {
      lstNew.get(0).addError(Label.CSS_Message_Cannot_create_duplicate_address_for_Contact);
    }
    // END OF NLG


/* CODE IN THIS SECTION IS REPLACED WITH LOGIC ABOVE THAT CHECKS ON THE Address_Id__c FIELD - NLG May 19th, 2014
    //Retrive Address details
    for (List<Address__c> lstAddrs:[select Id,Address_1__c,Address_2__c,Address_3__c,Country__c,State__c,Province__c,City__c,Postcode__c,Zip__c from Address__c where Id=:setAddressIds]) {
      for (Address__c addrRec:lstAddrs) {
        //Populate addresses Map.
        mapAddresses.put(addrRec.id,addrRec);

        //Add to respective Sets for any value NOT null.

        if (addrRec.Address_1__c != null) {
          setAddr1.add(addrRec.Address_1__c);
        }
        if (addrRec.Address_2__c != null) {
          setAddr2.add(addrRec.Address_2__c);
        }
        if (addrRec.Address_3__c != null) {
          setAddr3.add(addrRec.Address_3__c); 
        }
        if (addrRec.Country__c != null) {
          setCountry.add(addrRec.Country__c); 
        }
        if (addrRec.State__c != null) {
          setState.add(addrRec.State__c);        
        }
        if (addrRec.Province__c != null) {
          setProvince.add(addrRec.Province__c);   
        } 
        if (addrRec.City__c != null) {
          setCity.add(addrRec.City__c);   
        }
        if (addrRec.Postcode__c != null) {
          setPostcode.add(addrRec.Postcode__c); 
        }
        if (addrRec.Zip__c != null) {
          setZip.add(addrRec.Zip__c);
        }
      }//END: FOR addrRec
    }//END: FOR lstAddrs
    
    system.debug('#########mapAddresses##########'+mapAddresses);
    
    //Build Dynamic query.
    String query = 'select id,Contact__c,Contact__r.Name,address__c,address__r.Address_1__c,address__r.Address_2__c,address__r.Address_3__c,address__r.Country__c,address__r.State__c,address__r.Province__c,address__r.City__c,address__r.Postcode__c,address__r.Zip__c  FROM Contact_Address__c where ';
    
    //Build Dynamic filters.
    String filters;
        if (mapContactIdNames.size() > 0) {
          List<String> lstContactNames = mapContactIdNames.values();
          filters =((filters == null)?'':filters + ' or ')+' Contact__r.Name =:lstContactNames ';
        }   
          
        if (setAddr1.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.Address_1__c =:setAddr1 ';
        }
        if (setAddr2.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.Address_2__c =:setAddr2 ';
        }

        if (setAddr3.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.Address_3__c =:setAddr3 ';
        }

        if (setCountry.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.Country__c =:setCountry ';
        }
        if (setState.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.State__c =:setState ';     
        }
        if (setProvince.size() > 0) {
          filters =((filters == null)?'':filters + ' or ')+' address__r.Province__c =:setProvince ';     
        }
        if (setCity.size() > 0) {
           filters =((filters == null)?'':filters + ' or ')+' address__r.City__c =:setCity ';     
        }
        if (setPostcode.size() > 0) {
           filters =((filters == null)?'':filters + ' or ')+' address__r.Postcode__c =:setPostcode '; 
        }
        if (setZip.size() > 0) {
           filters =((filters == null)?'':filters + ' or ')+' address__r.Zip__c =:setZip ';
        }


    Map<String,List<Contact_Address__c>> mapContactAddress = new Map<String,List<Contact_Address__c>>();

    //Run Dynamic SOQL, if filters found.
    if (filters!=null) {
    
      //Execute the Dynamic SOQL and build the ContactAddress map.
      for (List<Sobject> recordBatch: Database.query(query+filters)) {
        for (SObject rec:recordBatch) {
          Contact_Address__c conAdrRec = (Contact_Address__c) rec;
          if (!mapContactAddress.containsKey(conAdrRec.Contact__r.Name)) {
            mapContactAddress.put(conAdrRec.Contact__r.Name,new List<Contact_Address__c>{conAdrRec});
          } else {
            mapContactAddress.get(conAdrRec.Contact__r.Name).add(conAdrRec);
          }
        }//END: FOR rec
      }//END: FOR recordBatch
    }//END: IF filters

    //Iterate through actual records set to find and addError for duplicate ones.
    for (Contact_Address__c trgRec:lstNew) {
      //Only records lookup to Contact and Address.
      if (trgRec.Contact__c != null && trgRec.Address__c != null) {
        //Check if map has Contact and Address from earlier queries.
        if (mapContactIdNames.containsKey(trgRec.Contact__c) && mapContactAddress.ContainsKey(mapContactIdNames.get(trgRec.Contact__c))
            && mapAddresses.containsKey(trgRec.Address__c)) {
          Address__c addRec = mapAddresses.get(trgRec.Address__c);
          
          //Retrive all Address for an Contact.
          for (Contact_Address__c conAdrRec: mapContactAddress.get(mapContactIdNames.get(trgRec.Contact__c))) {
            
            //If any Address match current then addError.
            if (addRec.Address_1__c == conAdrRec.address__r.Address_1__c && 
              addRec.Address_2__c == conAdrRec.address__r.Address_2__c && 
              addRec.Address_3__c == conAdrRec.address__r.Address_3__c && 
              addRec.Country__c == conAdrRec.address__r.Country__c && 
              addRec.State__c == conAdrRec.address__r.State__c && 
              addRec.Province__c == conAdrRec.address__r.Province__c && 
              addRec.City__c == conAdrRec.address__r.City__c && 
              addRec.Postcode__c == conAdrRec.address__r.Postcode__c && 
              addRec.Zip__c == conAdrRec.address__r.Zip__c) {
              //trgRec.addError('ContactAddressTrigger:Duplicate Contact<=>Address found conId='+conAdrRec.Contact__c+', AddrId='+addRec.id);
              trgRec.addError('\nTADAAAA' + Label.CSS_Message_Cannot_create_duplicate_address_for_Contact);
              break;
            }//END: IF address field compare.
          }//END: FOR conAdrRec
        }//END: IF Ids contains in Maps.
      }//END: IF trgRec
    }//END: FOR trgRec*/
    Datetime meow2 = Datetime.now();
    Integer timeBetween = meow2.millisecond() - meow.millisecond();
    system.debug('\nThe operation took ' + timeBetween + 'ms to complete');
  }//END: Method checkForDuplicateContactAddress
  


  //T-251968: Contact Addresses on the Account: Contact_Address__c trigger
  public static void createNewAccountAddresses (List<Contact_Address__c> newList) {
    Map<String, Contact_Address__c> contactAddressMap = new Map<String, Contact_Address__c>();
    List<Account_Address__c> accountAddressList = new List<Account_Address__c>();
    
    
    Set<String> contactAccountIDs = new Set<String>();
    Set<String> contactAddressIDs = new Set<String>();
    
    //Fetching contact addresses and populating related map and sets.
    for (Contact_Address__c contAddress : [SELECT Contact__r.AccountId, Contact__c, 
                                                  Address__c,
                                                  Address__r.Address_id__c  
                                           FROM Contact_Address__c 
                                           WHERE ID IN : newList]) {
      
      System.debug('[ContactAddressTriggerHandler:createNewAccountAddresses][Debug 1.0:]'+contAddress);
      System.debug('[ContactAddressTriggerHandler:createNewAccountAddresses][Debug 1.1:]'+contAddress.Address__r.Address_id__c);
      System.debug('[ContactAddressTriggerHandler:createNewAccountAddresses][Debug 1.2:]'+contAddress.Contact__r.AccountId);
      
      if (contAddress.Address__r.Address_id__c <> null && contAddress.Contact__r.AccountId <> null && 
          !contactAddressMap.containsKey(contAddress.Contact__r.AccountId + '~~' + contAddress.Address__r.Address_id__c)) {
        
        contactAddressMap.put(contAddress.Contact__r.AccountId + '~~' + contAddress.Address__r.Address_id__c, contAddress);
        
        contactAccountIDs.add(contAddress.Contact__r.AccountId);
        contactAddressIDs.add(contAddress.Address__r.Address_id__c);
      }
    }
    
    System.debug('[ContactAddressTriggerHandler:createNewAccountAddresses][Debug 1.3:]'+contactAddressMap);
    //Checking weather the account addresses created for the contact's related account
    //if created removing those contact addresses from map and than will create for remaining.
    List<Account_Address__c> accAddressList = new List<Account_Address__c>();
    Map<ID, Address__c> allAddressMap = new Map<ID, Address__c>();
    Set<ID> addressIDset = new Set<ID>();
    
    //Querying account address related to Contact's accounts
    for (Account_Address__c accAddress : [SELECT Id, Address__r.Address_id__c, 
                                                 Address__r.Id, Address__c, 
                                                 Account__c 
                                          FROM Account_Address__c 
                                          WHERE Address__r.Address_ID__c IN: contactAddressIDs
                                              AND Account__c IN: contactAccountIDs]) {
      accAddressList.add(accAddress);
      if (accAddress.Address__c <> null) {
        addressIDset.add(accAddress.Address__c);
      }
    }
    
    //Qyery on addresses found on Account Addresses above
    for (Address__c address : [SELECT Zip__c, Validation_Status__c, Suite__c, State__c, 
                                      SortingCode__c, Province__c, Prefecture__c, Postcode__c, 
                                      Partofterritory__c, POBox__c, OwnerId, Name, Last_Validated__c, 
                                      Id, Floor__c, Emirate__c, District__c, CurrencyIsoCode, County__c, 
                                      Country__c, Codiga_Postal__c, City__c, CRMOD_ID__c, CEDEX__c, 
                                      Authenticated_Address__c, Address_id__c, Address__c, Address_4__c, 
                                      Address_3__c, Address_2__c, Address_1__c 
                               FROM Address__c WHERE ID IN : addressIDset]) {
      if (!allAddressMap.containsKey(address.ID)) {
        allAddressMap.put(address.ID, address);
      }
    }
    //Checking with contact address for finding matching
    Contact_Address__c contactAddress;
    for (Account_Address__c accAddress : accAddressList) {
      if (contactAddressMap.containsKey(accAddress.Account__c + '~~' + accAddress.Address__r.Address_id__c)) {
        //getting contact address by key of account and address_id__c
        contactAddress = contactAddressMap.get(accAddress.Account__c + '~~' + accAddress.Address__r.Address_id__c);
        //Calling find matching address from address utility, if found matching, removing contact address for
        //further processing to create account address.
        if (allAddressMap.containsKey(contactAddress.Address__c) && 
                AddressUtility.findMatchingAddress(allAddressMap.get(contactAddress.Address__c), allAddressMap.values()) != null) {
          contactAddressMap.remove(accAddress.Account__c + '~~' + accAddress.Address__r.Address_id__c);
        }
      }
    }
    System.debug('[ContactAddressTriggerHandler:createNewAccountAddresses][Debug 1.4:]'+contactAddressMap);
    Account_Address__c newAccountAddress;
    //Create account address for remaining contacts
    for (Contact_Address__c contAddress : contactAddressMap.values()) {
      newAccountAddress = new Account_Address__c();
      newAccountAddress.Account__c = contAddress.Contact__r.AccountId;
      newAccountAddress.Address__c = contAddress.Address__c;
      accountAddressList.add(newAccountAddress);      
    }
    //If any account address is to be created insert call.
    if (!accountAddressList.isEmpty()) {
      try {
        insert accountAddressList;
      } catch (DMLException e) {
        ApexLogHandler.createLogAndSave('ContactAddressTriggerHandler','createNewAccountAddresses', e.getStackTraceString(), e);
        for (Integer i=0; i < e.getNumDml(); i++) {
        	newList.get(0).addError(e.getDMLMessage(i));
        }
      }
    }
  }
}//END: CLASS