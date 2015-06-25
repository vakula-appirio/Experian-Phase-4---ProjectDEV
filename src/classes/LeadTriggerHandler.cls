/**=====================================================================
 * Appirio, Inc
 * Name: LeadTriggerHandler
 * Description: T-194935, On Lead conversion if billing address is not blank 
                                then create address record and associate that address with 
                                the converted account by creating the AccountAddress record
                                and associate converted contact by creating the ContactAddress record.
 * Created Date: Nov 01st, 2013
 * Created By: Manish Soni ( Appirio )
 * 
 * Date Modified        Modified By                  Description of the update
 * Nov 19th, 2012       Pankaj Mehra(Appirio)        T-213204, Populate Marketing Activity contact lookup on conversion of lead
 * Nov 21st, 2012       Shane Khublall(Appirio)      T-214619, Description : Populate Marketing Activity Account lookup on conversion of lead 
 * Jan 31th, 2014       Naresh Kr Ojha(Appirio)      T-232755: Homogenize triggers 
 * Jan 30th, 2014       Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 03rd, 2014       Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 27th, 2014       Nathalie Le Guay             T-266743: Remove references to Primary_Billing__c & Primary_Shipping__c (unused)
 * May 01st, 2014       Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException Line#63
* July 29th, 2014       Sadar Yacob                  Split the Lead Address based on commas or field length over 50 chars to addr1,addr2, addr3 etc
* Aug 25th, 2014        Sadar Yacob                  Use PostCode__c on Address instead of Zip__c on Lead conversion  
* Aug 27th, 2014        Sadar Yacob                  case 1441 : Split lead Address by Comma 
 =====================================================================*/

public without sharing class LeadTriggerHandler {

  //Before insert call from trigger.
  public static void beforeInsert (Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads) {

  }

  //After Update call from trigger.
  public static void afterUpdate (Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads) {
      // Creating address for converted lead
      LeadTriggerHandler.createAddress(mapNewLeads, mapOldLeads);
      // Populate Maketing Activity contact lookup on conversion of lead
      LeadTriggerHandler.populateMarketingActivityOnContact(mapNewLeads, 
                                                                mapOldLeads);
      // Populate Marketing Activity address lookup on conversion of lead
      LeadTriggerHandler.populateMarketingActivityOnAccount(mapNewLeads, 
                                                                mapOldLeads);    
  }
  // Method for create Address and AddressAccount on Lead coversion
  public static void createAddress(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads){
      
    // Map of Address and Lead Id
    Map<String, Address__c> addressToBeInsert = new Map<String,Address__c>();
    
    // Looping over new leads
    for(Lead newLead : mapNewLeads.values()){
        Lead oldLead = mapOldLeads.get(newLead.id);
        // If lead is converted and have billing address then process further
        if(newLead.IsConverted != oldLead.IsConverted && newLead.IsConverted == true 
            && ( newLead.Street != null || newLead.State != null || newLead.PostalCode != null
            || newLead.Country != null || newLead.City != null )){
                // Adding address in map with associated lead id.
                addressToBeInsert.put(newLead.id, getAddress(newLead)); 
            }
    }
    
    try {
    // If map is not empty then insert the list of address.
    if(!addressToBeInsert.isEmpty()){
        insert addressToBeInsert.values();
        // Create account address
        createAccountAndContactAddress(addressToBeInsert, mapNewLeads);
    }    
    } catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('LeadTriggerHandler','createAddress', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
          mapNewLeads.values().get(0).addError(ex.getDmlMessage(i)); 
      }
    }
  }
  
  // Method for create Address object instance with the account fields values
  private static Address__c getAddress(Lead lead)
{

       string[] leadAddr;
       string addr1='';
       string addr2='';
       string addr3='';
       string addr4='';
       integer addrlen;
       string leadAddress  = lead.Street;
       addrlen = leadAddress.length();
       leadAddr = leadAddress.split(','); //if we had , after each street1
       integer leadAddrLen  = leadAddr.size(); // mod 08.27 
       
       if (addrlen > 50 || leadAddrLen > 0 ) //mod 08.27
       {
             //leadAddr = leadAddress.split(','); //if we had , after each street1
              if ( leadAddr.size() > 0 )
              {
                   addr1 = leadAddr[0];
                   if (addr1.length() > 50 )
                   {
                       addr1= addr1.substring(0,50);
                       if (leadAddress.length() -50 > 0 ) 
                           addr2 =leadAddress.substring(51,leadAddress.length()); //potential issue here, splitting at 50 chars
            
                       if (leadAddress.length() -100 > 0 ) 
                           addr3 =leadAddress.substring(101,leadAddress.length() ); //potential issue here, splitting at 100 chars
                    }
               
              }
              if ( leadAddr.size() > 1 ) //if we had comma, after each street1
               addr2 = leadAddr[1];
    
              if ( leadAddr.size() > 2 ) //if we had comma, after each street2
               addr3 = leadAddr[2];
           
              if ( leadAddr.size() > 3 ) //if we had comma, after each street3
               addr4 = leadAddr[3];    
       }
       else
       {
          addr1 = leadAddress;
       }
      
    Address__c address = new Address__c(
        Address_1__c = addr1 , //lead.Street,
        Address_2__c = addr2,
        Address_3__c = addr3,
        Address_4__c = addr4,
        City__c = lead.City,
        State__c = lead.State, 
        //Zip__c = lead.PostalCode, 
        PostCode__c = lead.PostalCode,
        Country__c = lead.Country, 
        Authenticated_Address__c = false
    );
    return address;
  }
  
  // Method for create AccountAddress And ContactAddress
  private static void createAccountAndContactAddress(Map<String, Address__c> mapAddressWithLeadId, Map<Id, Lead> mapNewLeads){
      
    // AccountAddress List
    List<Account_Address__c> accountAddressToBeInsert = new List<Account_Address__c>();
    // ContactAddress List
    List<Contact_Address__c> contactAddressToBeInsert = new List<Contact_Address__c>();
    
    // Looping over map of Addresses
    for(String leadId : mapAddressWithLeadId.keySet()){
        
        // Geting address for the assoicated lead
        Address__c address = mapAddressWithLeadId.get(leadId);
        // Geting lead 
        Lead lead = mapNewLeads.get(leadId);
        
        // Creating AccountAddress instance
        Account_Address__c accountAddress = new Account_Address__c(
            Account__c = lead.ConvertedAccountId,
            Address__c = address.id,
            /*Primary_Shipping__c = false, 
            Primary_Billing__c = false,NLG Mar27, field to be deleted*/
            Address_Type__c = Constants.ADDRESS_TYPE_REGISTERED
            //Address_Purpose__c = 'Legal' 
        );
        accountAddressToBeInsert.add(accountAddress);
        
        // Creating ContactAddress instance
        Contact_Address__c contactAddress = new Contact_Address__c(
            Contact__c = lead.ConvertedContactId,
            Address__c = address.id,
            /*Primary_Shipping__c = false, 
            Primary_Billing__c = false,  NLG Mar27, field to be deleted*/
            Address_Type__c = Constants.ADDRESS_TYPE_REGISTERED
        );
        contactAddressToBeInsert.add(contactAddress);
    }
    
    // Inserting list of AccountAddress
    insert accountAddressToBeInsert;
    // Inserting list of ContactAddress
    insert contactAddressToBeInsert;  
  }
        
  //Populate Maketing Activity contact lookup on conversion of lead
  public static void populateMarketingActivityOnContact(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads){
    
    Set<Id> leadSet = new Set<Id>(); 
    for(Lead newLead : mapNewLeads.values()){
      Lead oldLead = mapOldLeads.get(newLead.id);
      // If lead is converted 
      if(newLead.IsConverted != oldLead.IsConverted && newLead.IsConverted == true){
        leadSet.add(newLead.id);  
      }
    }
    // Populate Contact field on Marketing activity on Contact
    List<ELQA_Marketing_Activity__c> lstMarketingActivity = new List<ELQA_Marketing_Activity__c>(); 
    for(Lead lead : [SELECT ConvertedContactId ,(Select Id From R00N30000001wa2CEAQ__r) FROM Lead WHERE Id in:leadSet]) {
      for(ELQA_Marketing_Activity__c marketingActivity : lead.R00N30000001wa2CEAQ__r) {
        lstMarketingActivity.add(new ELQA_Marketing_Activity__c(Id = marketingActivity.Id , 
                                     Contact__c = lead.ConvertedContactId));
      }
    }
    
    if(lstMarketingActivity.size() > 0) {
      update lstMarketingActivity;
    }
  }
  
  //Populate Maketing Activity account lookup on conversion of lead
  public static void populateMarketingActivityOnAccount(Map<Id, Lead> mapNewLeads, Map<Id, Lead> mapOldLeads){
    
    Set<Id> leadSet = new Set<Id>(); 
    for(Lead newLead : mapNewLeads.values()){
      Lead oldLead = mapOldLeads.get(newLead.id);
      // If lead is converted 
      if(newLead.IsConverted != oldLead.IsConverted && newLead.IsConverted == true){
        leadSet.add(newLead.id);  
      }
    }
    // Populate Account field on Marketing activity on Account
    List<ELQA_Marketing_Activity__c> lstMarketingActivity = new List<ELQA_Marketing_Activity__c>(); 
    for(Lead lead : [SELECT ConvertedAccountId ,(Select Id From R00N30000001wa2CEAQ__r) FROM Lead WHERE Id in:leadSet]) {
      for(ELQA_Marketing_Activity__c marketingActivity : lead.R00N30000001wa2CEAQ__r) {
        lstMarketingActivity.add(new ELQA_Marketing_Activity__c(Id = marketingActivity.Id , 
                                     Account__c = lead.ConvertedAccountId));
      }
    }
    
    if(lstMarketingActivity.size() > 0) {
      update lstMarketingActivity;
    }
  }  
  
  
    
}