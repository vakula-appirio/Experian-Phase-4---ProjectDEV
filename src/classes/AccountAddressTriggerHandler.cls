/**=====================================================================
 * Appirio, Inc
 * Name: AccountAddressTriggerHandler
 * Description: Handler class for AccountAddressTrigger.trigger
 * Created Date: Nov 11th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * May 19th, 2014               Nathalie Le Guay             I-115270: Replace the duplicate check section with code that uses Address__c.Address_Id__c
 *                                                           instead of looping through a large portion of the Account_Address__c table, for scalability
 * Oct 07th, 2014               Arpita Bose(Appirio)         T-324658: Added method syncContactRec_OnDemand() in afterInsert and afterUpdate
 =====================================================================*/

public class AccountAddressTriggerHandler {
  //Process beforeInsert Operations.
  public static void beforeInsert(LIST<Account_Address__c> lstNew) {
      checkForDuplicateAccountAddress(lstNew);
  }

  //===========================================================================
  // T-324658: After Insert
  //===========================================================================
  public static void afterInsert(List<Account_Address__c> newList) {
    syncContactRec_OnDemand(newList, null);
  }

  //===========================================================================
  // T-324658: After Update
  //===========================================================================
  public static void afterUpdate(List<Account_Address__c> newList, Map<ID, Account_Address__c> oldMap) {
    syncContactRec_OnDemand(newList, oldMap);
  }
  
  //Owner changed, old older was DQ
  public static void checkForDuplicateAccountAddress(LIST<Account_Address__c> lstNew) {    
    Map<Id,String> mapAccountIdNames = new Map<Id,String>();
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
      
      
    Set<String> setAccountIds = new Set<String>();
    Set<String> setAddressIds = new Set<String>();
    
    //Retrieve Account and Address record Ids.
    for(Account_Address__c trgRec : lstNew) {
        if(trgRec.Account__c != null && trgRec.Address__c != null) {
            setAccountIds.add(trgRec.Account__c);
            setAddressIds.add(trgRec.Address__c);
        }
    }//END: FOR trgRec
    
    //Retrive Account Names.
    for(List<Account> lstAccs : [SELECT Id, Name FROM Account where Id =: setAccountIds]) {
        for(Account accRec:lstAccs)
        mapAccountIdNames.put(accRec.Id,accRec.Name);
    }//END: FOR lstAccs
    
    system.debug('##########mapAccountIdNames#########'+mapAccountIdNames);
    
    // NLG May 19th, 2014
    List<Address__c> addresses = [SELECT Id,Address_1__c,Address_2__c,Address_3__c,Address_4__c,Country__c,State__c,Province__c,City__c,Postcode__c,Zip__c, CEDEX__c,
                                         Codiga_Postal__c, County__c, District__c, Emirate__c, Floor__c, Partofterritory__c, POBox__c, Prefecture__c, SortingCode__c,
                                         Suite__c
                                  FROM Address__c 
                                  WHERE Id=:setAddressIds];
    if (AddressUtility.hasDuplicateAddresses(addresses, mapAccountIdNames.keySet(), Constants.SOBJECT_ACCOUNT)) {
      lstNew.get(0).addError(Label.ASS_Message_Cannot_create_duplicate_address_for_Account);
    }
    // END OF NLG

      /*//Retrive Address details
      for(List<Address__c> lstAddrs:[SELECT Id,Address_1__c,Address_2__c,Address_3__c,Country__c,State__c,Province__c,City__c,Postcode__c,Zip__c FROM Address__c where Id=:setAddressIds])
      {
          for(Address__c addrRec:lstAddrs)
          {
              //Populate addresses Map.
              mapAddresses.put(addrRec.id,addrRec);
              system.debug('#########addrRec##########'+addrRec);
              
              //Add to respective Sets for any value NOT null.
              
              if(addrRec.Address_1__c!=null)
                  setAddr1.add(addrRec.Address_1__c);
              
              if(addrRec.Address_2__c!=null)
                  setAddr2.add(addrRec.Address_2__c);
                  
              if(addrRec.Address_3__c!=null)
                  setAddr3.add(addrRec.Address_3__c); 
              
              if(addrRec.Country__c!=null)
                  setCountry.add(addrRec.Country__c); 
              
              if(addrRec.State__c!=null)
                  setState.add(addrRec.State__c);                
              
              if(addrRec.Province__c!=null)
                  setProvince.add(addrRec.Province__c);   
                  
             if(addrRec.City__c!=null)
                  setCity.add(addrRec.City__c);   
             
             if(addrRec.Postcode__c!=null)
                  setPostcode.add(addrRec.Postcode__c); 
             
             if(addrRec.Zip__c!=null)
                  setZip.add(addrRec.Zip__c);                      
                  
          }//END: FOR addrRec
      }//END: FOR lstAddrs
      
      system.debug('#########mapAddresses##########'+mapAddresses);
      
      //Build Dynamic query.
      String query = 'SELECT id,Account__c,Account__r.Name,address__c,address__r.Address_1__c,address__r.Address_2__c,address__r.Address_3__c,address__r.Country__c,address__r.State__c,address__r.Province__c,address__r.City__c,address__r.Postcode__c,address__r.Zip__c  FROM Account_Address__c where ';
      
      //Build Dynamic filters.
      String filters;
              if(mapAccountIdNames.size()>0)
              {
                  List<String> lstAccountNames = mapAccountIdNames.values();
                  filters =((filters==null)?'':filters + ' or ')+' Account__r.Name =:lstAccountNames ';
               }   
                  
             if(setAddr1.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.Address_1__c =:setAddr1 ';
                   
              if(setAddr2.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.Address_2__c =:setAddr2 ';
      
                  
              if(setAddr3.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.Address_3__c =:setAddr3 ';
      
              
              if(setCountry.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.Country__c =:setCountry ';
              
              if(setState.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.State__c =:setState ';       
              
              if(setProvince.size()>0)
                  filters =((filters==null)?'':filters + ' or ')+' address__r.Province__c =:setProvince ';       
                  
             if(setCity.size()>0)
                 filters =((filters==null)?'':filters + ' or ')+' address__r.City__c =:setCity ';       
             
             if(setPostcode.size()>0)
                 filters =((filters==null)?'':filters + ' or ')+' address__r.Postcode__c =:setPostcode '; 
             
             if(setZip.size()>0)
                 filters =((filters==null)?'':filters + ' or ')+' address__r.Zip__c =:setZip ';
      
      
      system.debug('#########query#########'+query);
      system.debug('#########filters#########'+filters);
      
      Map<String,List<Account_Address__c>> mapAccountAddress = new Map<String,List<Account_Address__c>>();
      
      //Run Dynamic SOQL, if filters found.
      if(filters!=null)
      {
      system.debug('#########query+filters#########'+query+filters);
      
          //Execute the Dynamic SOQL and build the AccountAddress map.
          for(List<Sobject> recordBatch: Database.query(query+filters))
          {
              for(SObject rec:recordBatch)    
              {
                  Account_Address__c accAdrRec = (Account_Address__c) rec;
                  if(!mapAccountAddress.containsKey(accAdrRec.Account__r.Name))
                      mapAccountAddress.put(accAdrRec.Account__r.Name,new List<Account_Address__c>{accAdrRec});
                  else
                      mapAccountAddress.get(accAdrRec.Account__r.Name).add(accAdrRec);
              }//END: FOR rec
          }//END: FOR recordBatch
      }//END: IF filters
      system.debug('#########mapAccountAddress#########'+mapAccountAddress);
      
      //Iterate through actual records set to find and addError for duplicate ones.
      for(Account_Address__c trgRec : lstNew) {
        //Only records lookup to Account and Address.
        if(trgRec.Account__c!=null && trgRec.Address__c!=null) {
          //Check if map has Account and Address FROM earlier queries.
          if(mapAccountIdNames.containsKey(trgRec.Account__c) && 
                    mapAccountAddress.ContainsKey(mapAccountIdNames.get(trgRec.Account__c)) && 
                    mapAddresses.containsKey(trgRec.Address__c)) {
            Address__c addRec = mapAddresses.get(trgRec.Address__c);
                  
            //Retrive all Address for an Account.
            for(Account_Address__c accAdrRec: mapAccountAddress.get(mapAccountIdNames.get(trgRec.Account__c))) {
                      System.debug('###########accAdrRec##############'+accAdrRec);
                      
                      //If any Address match current then addError.
                      if(addRec.Address_1__c==accAdrRec.address__r.Address_1__c && 
                          addRec.Address_2__c==accAdrRec.address__r.Address_2__c && 
                          addRec.Address_3__c==accAdrRec.address__r.Address_3__c && 
                          addRec.Country__c==accAdrRec.address__r.Country__c && 
                          addRec.State__c==accAdrRec.address__r.State__c && 
                          addRec.Province__c==accAdrRec.address__r.Province__c && 
                          addRec.City__c==accAdrRec.address__r.City__c && 
                          addRec.Postcode__c==accAdrRec.address__r.Postcode__c && 
                          addRec.Zip__c==accAdrRec.address__r.Zip__c)
                      {
                          //trgRec.addError('AccountAddressTrigger:Duplicate Account<=>Address found AccId='+accAdrRec.Account__c+', AddrId='+addRec.id);
                          trgRec.addError(Label.ASS_Message_Cannot_create_duplicate_address_for_Account);
                          break;
                      }//END: IF address field compare.
                  }//END: FOR accAdrRec
              }//END: IF Ids contains in Maps.
          }//END: IF trgRec
      }//END: FOR trgRec*/
  }//END: Method checkForDuplicateAccountAddress


  //===========================================================================
  //T-324658: Method to synch Contact records with On Demand when 
  //Account_Address__c record is created or updated for Address_Type__c = 'Registered'
  //===========================================================================
  private static void syncContactRec_OnDemand (List<Account_Address__c> newList, Map<ID, Account_Address__c> oldMap) {
    Set<ID> setAccountIds = new Set<ID>();
    List<Contact> onDemandContacts = new List<Contact>();
    
    // find all Account_Address__c.Address_Type__c = 'Registered' || updated to have Address_Type__c = 'Registered'
    // store Ids of Account_Address__c.Account__c in a Set
    for (Account_Address__c accAdd : newList) {
      if (accAdd.Address_Type__c != null && accAdd.Account__c != null) {
        if (accAdd.Address_Type__c == Constants.ADDRESS_TYPE_REGISTERED && 
             (oldMap != null ? accAdd.Address_Type__c != oldMap.get(accAdd.ID).Address_Type__c : true )) {
          setAccountIds.add(accAdd.Account__c);
        }
      }  
    }
    
    // Query all Account_Address__c.Account, as well as related Contact where Contact.EDQ_On_Demand__c == true
    // store in a map 
    for (Account acc : [SELECT Id, 
                               (SELECT AccountId, EDQ_On_Demand__c, EDQ_Send_to_On_Demand__c
                                FROM Contacts
                                WHERE EDQ_On_Demand__c = true)
                        FROM Account 
                        WHERE Id IN :setAccountIds]) {
      if (acc.Contacts.size() > 0) {
        Contact con = acc.Contacts.get(0);
        con.EDQ_Send_to_On_Demand__c = true;
        onDemandContacts.add(con);
      }
    }

    if (onDemandContacts.size() > 0) {
      try {
        update onDemandContacts;
      } catch(DMLException e){
          System.debug('\n[AccountAddressTriggerHandler: syncContactRec_OnDemand]: ['+e.getMessage()+']]');
          apexLogHandler.createLogAndSave('AccountAddressTriggerHandler','syncContactRec_OnDemand', e.getStackTraceString(), e);
          for (Integer i = 0; i < e.getNumDml(); i++) {
            newList.get(0).addError(e.getDmlMessage(i)); 
          }
      }
    } 
  }


}//END: CLASS