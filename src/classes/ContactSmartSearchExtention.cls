/**=====================================================================
 * Appirio, Inc
 * Name: ContactSmartSearchExtention
 * Description: 
 * Created Date: Nov 15th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified         Modified By                  Description of the update
 * Jan 30th, 2014        Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014        Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 06th, 2014				 Naresh Ojha(Appirio) 		 		T-256336: added getQueryLimit as per task.
 * Mar 11th, 2014        Arpita Bose(Appirio)         T-256335: Better Debug logging (Removed unnecessary debugs 
 *                                                              and maintained the coding convention)
 * Mar 19th, 2014        Arpita Bose(Appirio)         T-251969: Join button functionality is no longer required so,
 *                                                    showJoinButton and linkRecords method is commented
 * Mar 27th, 2014        Nathalie Le Guay             T-266743: Remove references to Primary_Billing__c & Primary_Shipping__c (unused)
 * Apr 08th, 2014        Arpita Bose(Appirio)         T-269372: Added addError()in try-catch block
 * May 01st, 2014        Arpita Bose                  Updated getDMLMessage to getMessage for catch(Exception)
 * May 07th, 2015        Terri Kellough               I-160915: Added ability to create a limited prospect if user has EDQ SaaS Deployment Manager Permission Set
 =====================================================================*/
//
// Changed to without sharing so that users can see duplicates across the world
//
//public with sharing class SmartcontactsearchExtension {
  public  class ContactSmartSearchExtention {
    //Search criteria fields
    public String contactFirstNameToSearch {set;get;}
    public String contactLastNameToSearch {set;get;}
    public String contactFullNameToSearch {set;get;}
    public String contactEmailToSearch {set;get;}
    public String addressline1ToSearch {set;get;}
    public String addressline2ToSearch {set;get;}
    public String addressline3ToSearch {set;get;}
    public String addressCountryToSearch {set;get;}
    public String addressStateToSearch {set;get;}
    public String addressCityToSearch {set;get;}
    public String addressPostalCodeToSearch {set;get;}

    //MIrfan
    public String accessibleContactIds {set;get;}
    public integer searchCount {set; get;}
    public string searchStatus {set; get;}
    public string sortField {set;get;}
    public integer limitRecords {set; get;} //May25-2012 by sdash@appirio.com: added limit 250 to avoid the query overflow of 50,000 records
    public static Integer queryLimit;//Mar06-2014 by nojha@appirio.com: added against Task T-256336.
   
    private string previousSortField;
    private string sortOrder;
    
    /////////////////MIrfan Address \\\\\\\\\\\\\\\\
    public integer searchAddrCount {set; get;}
    public string searchAddrStatus {set; get;}
    public string sortAddrField {set;get;}
    private string previousAddrSortField;
    private string sortAddrOrder;
    public boolean isAddrAsc {set; get;}
    public Integer showingAddrFrom {get;set;}
    public Integer showingAddrTo {get;set;}
    public boolean hasAddrNext {get;set;}
    public boolean hasAddrPrevious {get;set;}
    public String requestedAddrPage {get;set;}
    public integer totalAddrResults {set; get;}
    public Integer totalAddrPage {set; get;}
    /////////////////MIrfan Address \\\\\\\\\\\\\\\
    
    public String OtherPageCalling {set; get;}
          
    public Boolean isBroaderSearchOn {get;set;}
    public String accountNameToSearch {get;set;}
       
    public boolean isAsc {set; get;}
    public Integer showingFrom {get;set;}
    public Integer showingTo {get;set;}
    public string query;
    
    public boolean showContactButton {set; get;}
    //MIrfan@Issue I-82761
    public boolean showAddContactButton {set; get;}
    public boolean showAddAddressButton {set; get;}
    //public boolean showJoinButton {set; get;}

    
    public boolean hasNext {get;set;}
    public boolean hasPrevious {get;set;}
    public String requestedPage {get;set;}
  
    public integer totalResults {set; get;}
    
    public Integer totalPage {set; get;}
    
    private static final Integer DEFAULT_RESULTS_PER_PAGE = 20;  
    private static final string SEARCH_TYPE = ' and ';
    private static final string DEFAULT_SORT_ORDER = ' ASC ';
    private static final string DEFAULT_SORT_FIELD = 'Name';
    

    public ApexPages.StandardSetController contactResults {get;set;}
    public ApexPages.StandardSetController addressResults {get;set;}
    
    public Id accountId {get; set;}
    
    // Set of Profile names for which the "New Contact" button should be enabled
    public static final set<String> profilesAllowedForNewContact = new set<String>();
    static {
    	profilesAllowedForNewContact.add(Constants.PROFILE_SYS_ADMIN);
    }

    public static final Set<String> permissionSetsAllowedForNewContact = new Set<String>();
      static {
         permissionSetsAllowedForNewContact.add(Constants.PERMISSIONSET_EDQ_SAAS_DEPLOYMENT_MANAGER);
    }
    
    public Boolean showNewContactButton {get;set;}
    
    //Constructor
    public ContactSmartSearchExtention(ApexPages.StandardController controller) {
      //contactSearch= new SmartContactSearchExtension_new();
      Contact c = (Contact)controller.getRecord();
      if (c != null && c.AccountId != null)
         accountId = c.AccountId;
         isBroaderSearchOn = true;   
         resetSearchStatus();
    }

    //Constructor
    public ContactSmartSearchExtention() {
      resetSearchStatus();
    }
    
    //set to default status of page
    public void resetSearchStatus() {
        //Reset Contact fields
      showContactButton = false;
      showAddContactButton = false;
      showAddAddressButton = false;
      //showJoinButton = false;
      contacts = new List<Contact_Address__c>();
        
      searchCount = 0;
      searchAddrCount = 0;
      searchStatus = '';
      sortOrder = DEFAULT_SORT_ORDER;
      sortField = DEFAULT_SORT_FIELD;
      previousSortField = DEFAULT_SORT_FIELD;
      accountNameToSearch = '';
      addressline1ToSearch = '';
      addressline2ToSearch = '';
      addressline3ToSearch = '';
      addressCountryToSearch = '';
      addressStateToSearch = '';
      addressCityToSearch = '';
      addressPostalCodeToSearch = '';
      contactFullNameToSearch = '';
      isAsc = true;
      hasPrevious = false;
      hasNext = false; 

    List<PermissionSet> permissionSetsAllowed = [SELECT Id, Name
                                                 FROM PermissionSet
                                                 WHERE Name in: permissionSetsAllowedForNewContact];      
      User currentUser = [SELECT Id,Profile.Name,
                          (SELECT Id From PermissionSetAssignments WHERE PermissionSetId In: permissionSetsAllowed)
                          FROM User
                          WHERE Id = :userinfo.getUserId()];
      if(profilesAllowedForNewContact.contains(currentUser.Profile.Name) ||
          currentUser.PermissionSetAssignments.size() > 0) {
      	showNewContactButton = true;
      }
      else {
      	showNewContactButton = false;
      }
    }
    
  
    public List<Contact_Address__c  > contacts {
      get{
          return contacts;
      }set;
    }
    
    public List<Contact_Address__c  > addresses {
      get{
          return addresses;
      }set;
    }
 
    public PageReference cancel(){
      Pagereference pg = null;
      return pg;  
    }
      
    public String findSearchCondition(String query, boolean matchContactAddress) {
      String queryOnlyAddress = '';
      //MIrfan
      String queryContactAddress = query;
      queryContactAddress += (queryContactAddress.toUpperCase().contains('WHERE'))?' and ( ' : ' where  ( Contact__r.Id!=null ';

      if (accountNameToSearch != null && accountNameToSearch != '') {
        String strName = String.escapeSingleQuotes(accountNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
          if (queryContactAddress.toUpperCase().contains('WHERE')){
             queryContactAddress += ' and Contact__r.Account.Name like \'%' + strName + '%\'';
          }else {
             queryContactAddress += ' where Contact__r.Account.Name like \'%' + strName +  '%\'';
          }
      } 
     
      if (contactFirstNameToSearch != null && contactFirstNameToSearch != '') {
        String strFName = String.escapeSingleQuotes(contactFirstNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
         
          if (queryContactAddress.toUpperCase().contains('WHERE')){
             queryContactAddress += ' and Contact__r.FirstName like \'%' + strFName + '%\'';
          }else {
            queryContactAddress += ' where Contact__r.FirstName like \'%' + strFName +  '%\'';
          }
      } 
     
     
      if (contactLastNameToSearch != null && contactLastNameToSearch != '') {
        String strLName = String.escapeSingleQuotes(contactLastNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
         
          if (queryContactAddress.toUpperCase().contains('WHERE')) {
             queryContactAddress += ' and Contact__r.LastName like \'%' + strLName + '%\'';
          }else {
             queryContactAddress += ' where Contact__r.LastName like \'%' + strLName +  '%\'';
          }
      } 
     
      if (contactFullNameToSearch != null && contactFullNameToSearch!= '') {
        String strFullName = String.escapeSingleQuotes(contactFullNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
         
          if (queryContactAddress.toUpperCase().contains('WHERE')) {
             queryContactAddress += ' and Contact__r.Name like \'%' + strFullName + '%\'';
          }else {
             queryContactAddress += ' where Contact__r.Name like \'%' + strFullName +  '%\'';
          }
      }
     
     
      if (contactEmailToSearch != null && contactEmailToSearch != '') {
        String strEmail = String.escapeSingleQuotes(contactEmailToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
         
          if (queryContactAddress.toUpperCase().contains('WHERE')) {
             queryContactAddress += ' and Contact__r.Email like \'%' + strEmail + '%\'';
          }else {
             queryContactAddress += ' where Contact__r.Email like \'%' + strEmail +  '%\'';
          }
      } 
     

      if (addressline1ToSearch != null && addressline1ToSearch != '') {
      	//MIrfan
        String strAddr1 = String.escapeSingleQuotes(addressline1ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
          queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_1__c  like \'%' + strAddr1 + '%\'';  
          if (queryContactAddress.toUpperCase().contains('WHERE')){
             queryContactAddress += ' and address__r.Address_1__c  like \'%' + strAddr1 + '%\'';
          }else {
             queryContactAddress += ' where address__r.Address_1__c  like \'%' + strAddr1 +  '%\'';
          }
      }     
      
      if (addressline2ToSearch != null && addressline2ToSearch != '') {
         //MIrfan
         String strAddr2 = String.escapeSingleQuotes(addressline2ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
         queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_2__c  like \'%' + strAddr2 + '%\'';
         if (queryContactAddress.toUpperCase().contains('WHERE')){
            queryContactAddress += ' and address__r.Address_2__c  like \'%' + strAddr2 + '%\'';
         }else {
            queryContactAddress += ' where address__r.Address_2__c  like \'%' + strAddr2 +  '%\'';
         }
      }     
       
      if (addressline3ToSearch != null && addressline3ToSearch != '') {
         //MIrfan
         String strAddr3 = String.escapeSingleQuotes(addressline3ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
         queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_3__c  like \'%' + strAddr3 + '%\'';
         if (queryContactAddress.toUpperCase().contains('WHERE')){
            queryContactAddress += ' and address__r.Address_3__c  like \'%' + strAddr3 + '%\'';
         }else {
            queryContactAddress += ' where address__r.Address_3__c  like \'%' + strAddr3 +  '%\'';
         }
       }   
      
       if (addressCountryToSearch != null && addressCountryToSearch != '') {
         //MIrfan
         String strCountry = String.escapeSingleQuotes(addressCountryToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
         queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Country__c  like \'%' + strCountry + '%\'';
         if (queryContactAddress.toUpperCase().contains('WHERE')){
            queryContactAddress += ' and address__r.Country__c  like \'%' + strCountry + '%\'';
         }else {
            queryContactAddress += ' where address__r.Country__c  like \'%' + strCountry +  '%\'';
         }
       }     
       
       if (addressStateToSearch != null && addressStateToSearch != '') {
         //MIrfan
         String strState = String.escapeSingleQuotes(addressStateToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
         queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') +
                             ' (address__r.State__c like \'%' + strState + 
                             '%\' or address__r.Province__c like \'%' + strState + '%\') ';
         if (queryContactAddress.toUpperCase().contains('WHERE')) {
            queryContactAddress += ' and (address__r.State__c like \'%' + strState +
                                   '%\' or address__r.Province__c like \'%' + strState + '%\') ';
         }else {
            queryContactAddress += ' where (address__r.State__c  like \'%' + strState +  
                                   '%\' or address__r.Province__c like \'%' + strState + '%\') ';
         }
       } 
      
       if (addressCityToSearch != null && addressCityToSearch != '') {
          //MIrfan
          String strCity = String.escapeSingleQuotes(addressCityToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
          queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.City__c  like \'%' + strCity + '%\'';          
          if (queryContactAddress.toUpperCase().contains('WHERE')){
             queryContactAddress += ' and address__r.City__c  like \'%' + strCity + '%\'';
          }else {
             queryContactAddress += ' where address__r.City__c   like \'%' + strCity +  '%\'';
          }
       }     
       
       if (addressPostalCodeToSearch != null && addressPostalCodeToSearch != '') {
          //MIrfan
          String strZip = String.escapeSingleQuotes(addressPostalCodeToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          
          queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + 
                              ' (address__r.Postcode__c  like \'%' + strZip + 
                              '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';         
          if (queryContactAddress.toUpperCase().contains('WHERE')){
             queryContactAddress += ' and (address__r.Postcode__c  like \'%' + strZip + 
                                    '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';
          }else {
             queryContactAddress += ' where address__r.Postcode__c  like \'%' + strZip + 
                                    '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';
          }
       }  
       //MIrfan
       if (matchContactAddress && queryContactAddress.toUpperCase().contains('WHERE')) {
          queryContactAddress +=' ) ';
          query = queryContactAddress;
       }
     

       //MIrfan
       if (!matchContactAddress)
       {
         if (queryOnlyAddress.length()>0)
             query +=' where ( ' +queryOnlyAddress.replace('Contact__r.Id != null','Contact__r.Id = null')+' ) ';
         else
             query +=' where Id=null ';
        }
    
       //mirfan@201113
       if (!query.containsIgnoreCase('and'))
          query = query.replace('Contact__r.Id! = null','Contact__r.Id = null'); 

       return query;
    }

    public void performSearch() {
        System.debug('\n[ContactSmartSearchExtension: performSearch] ::::::::::::' );
        searchContact();
        System.debug('\n[ContactSmartSearchExtension: performSearch] : Contact list ::::::::::::' + contacts);
    }
    
    //method to search contact and make list according to pagesize
    private void searchContact(){
      showContactButton = false;
      showAddContactButton = false;
      showAddAddressButton = false;
      //showJoinButton = false;
    
      contactFirstNameToSearch = contactFirstNameToSearch.trim();
      contactLastNameToSearch = contactLastNameToSearch.trim();
      contactFullNameToSearch = contactFullNameToSearch.trim();
      contactEmailToSearch = contactEmailToSearch.trim();
      addressline1ToSearch = addressline1ToSearch.trim();
      addressline2ToSearch = addressline2ToSearch.trim();
      addressline3ToSearch = addressline3ToSearch.trim();
      addressCountryToSearch = addressCountryToSearch.trim();
      addressStateToSearch = addressStateToSearch.trim();
      addressCityToSearch = addressCityToSearch.trim();
      addressPostalCodeToSearch = addressPostalCodeToSearch.trim();
      accountNameToSearch = accountNameToSearch.trim();
    
     if ( contactFirstNameToSearch !='' || 
        contactLastNameToSearch !='' || 
        //contactFullNameToSearch !='' || 
        contactEmailToSearch !='' || 
        addressline1ToSearch !='' || 
        addressline2ToSearch !='' || 
        addressline3ToSearch !='' || 
        addressCountryToSearch !='' || 
        addressStateToSearch !='' || 
        addressCityToSearch !='' || 
        addressPostalCodeToSearch !='' || 
        accountNameToSearch !='')
        {
          showContactButton = true;
         }
      
      //Retrive Global Custom Setting.
      limitRecords = getQueryLimit();
      /**************************************************************
      * The code is updated by Mohit Batwada for testing purpose   *   
      **************************************************************/
      String queryColumns = 'Select  Name,Contact__r.Name,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,'+
                            ' Contact__r.Title,Contact__r.Phone, '+
                            ' Contact__r.Id ,Contact__r.Owner.Name,Contact__r.Account.Name, '+
                            ' address__r.Name,address__r.Address_1__c,'+
                            ' address__r.Address_2__c,address__r.Address_3__c, address__r.City__c, '+
                            ' address__r.State__c,address__r.Postcode__c,address__r.Province__c,'+
                            ' address__r.zip__c,  address__r.Country__c,'+
                            ' Address_Type__c '+
                            ' FROM Contact_Address__c'; 
   
      query = findSearchCondition(queryColumns, true);
      query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
      System.debug('\n[ContactSmartSearchExtension: searchContact] : QUERY+++++++++:' + query);

      //MIrfan
      string queryAddress = findSearchCondition(queryColumns, false);
      queryAddress += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
      try {
        contacts = new List<Contact_Address__c>();
        system.debug('\n[ContactSmartSearchExtension: searchContact] : #######query#######'+query);
        contacts = Database.query(query);
        Set<Id> setContactIds = new Set<Id>();
        for (Contact_Address__c rec : contacts)
        {
           setContactIds.add(rec.Contact__c);
        }
            
        if (setContactIds.size() > 0) {
           accessibleContactIds = SmartSearchRecordVisibility.getUserAccessibleContacts(setContactIds);
         }
         contactResults = new ApexPages.StandardSetController(contacts);
         contactResults.setPageSize(DEFAULT_RESULTS_PER_PAGE);
         contacts = contactResults.getRecords();
         searchCount = contactResults.getResultSize();
         searchStatus='';
         if (contacts.size() >= limitRecords) {
            searchStatus = Label.ASS_Message_Search_returned_more_records.replace('####', limitRecords+'');
         }
         //MIrfan, 221113, show button only if there is result.
         if (contacts.size() > 0) {
            showAddAddressButton = true;
          }
      }catch(Exception e) {
          searchCount = 0;
          ApexLogHandler.createLogAndSave('ContactSmartSearchExtention','searchContact', e.getStackTraceString(), e);
          contacts.get(0).addError(e.getMessage());
      } 
        
      if (searchCount  == 0){
         searchStatus = Label.ASS_Message_No_matching_results;
      }
      requestedPage = String.valueOf(contactResults.getPageNumber());
      showingFrom = 1;
        
      totalResults = 0;
      for (List<Sobject> recordBatch:Database.query(query))  {
          totalResults = totalResults + recordBatch.size();
      }
        
      totalPage = 0;
      totalPage = totalResults / contactResults.getPageSize() ; 
      if (totalPage * contactResults.getPageSize() < totalResults) {
         totalPage++;
      }

        
     if (searchCount < contactResults.getPageSize()) {
       showingTo = searchCount;
     } else {
      showingTo = contactResults.getPageSize();
     }
     if (contactResults.getHasNext()) {
       hasNext = true;
     } else {
       hasNext = false;
     }
     hasPrevious = false;

     try{
       addresses = new List<Contact_Address__c>();
       System.debug('\n[ContactSmartSearchExtension: searchContact] : ##queryAddress###################'+queryAddress);
       Map<Id,Contact_Address__c> mapConAddr = new Map<Id,Contact_Address__c>();
       for (Contact_Address__c rec : Database.query(queryAddress))
         {
           mapConAddr.put(rec.Address__c,rec);
         }
        
       addressResults = new ApexPages.StandardSetController(mapConAddr.values());
       addressResults.setPageSize(DEFAULT_RESULTS_PER_PAGE);
       addresses = addressResults.getRecords();
     
       searchAddrCount = addressResults.getResultSize();
       searchAddrStatus = '';
       if (mapConAddr.size() >= limitRecords) {
          searchAddrStatus = Label.ASS_Message_Search_returned_more_records.replace('####',limitRecords+'');
       }     
     
       //MIrfan, 221113, show button only if there is result.
       if (addresses.size() > 0){
          showAddContactButton = true;
       }
      }catch(Exception e){
          searchAddrCount = 0;
          ApexLogHandler.createLogAndSave('ContactSmartSearchExtention','searchContact', e.getStackTraceString(), e);
          addresses.get(0).addError(e.getMessage());
      } 
     
      if (searchAddrCount  == 0) {
         searchAddrStatus = Label.ASS_Message_No_matching_results;
      }
    
      requestedAddrPage = (addressResults==null)?'0': String.valueOf(addressResults.getPageNumber());
      showingAddrFrom = 1;
        
      totalAddrResults = 0;
    
      Set<Id> setConAddr = new Set<Id>();
      for (Contact_Address__c rec : Database.query(queryAddress))
        {
          setConAddr.add(rec.Address__c);
         }

      totalAddrResults = totalAddrResults + setConAddr.size();
      totalAddrPage = 0;
      totalAddrPage = totalAddrResults / addressResults.getPageSize() ; 
      if (totalAddrPage * addressResults.getPageSize() < totalAddrResults) {
         totalAddrPage++;
      }

      if (searchAddrCount < addressResults.getPageSize()) {
         showingAddrTo = searchAddrCount;
      } else {
         showingAddrTo = addressResults.getPageSize();
      }
    
      if (addressResults.getHasNext()) {
         hasAddrNext = true;
      }else {
         hasAddrNext = false;
      }
         hasAddrPrevious = false;
        /////////////////////////MIrfan Address Navigation End\\\\\\\\\\\\\\\\\\\\\\\\\\
        //MIrfan, 221113, show button only if there is result.
      /*if (addresses.size() > 0 && contacts.size() > 0) {
         showJoinButton = true;
      }*/
    }

    public PageReference nextContactPage() {
      if (contactResults.getHasNext()) {
         contacts = new List<Contact_Address__c>();
         contactResults.next();
         contacts = contactResults.getRecords();
         showingFrom = showingFrom + contactResults.getPageSize();
         showingTo =  showingTo + contacts.size();
         if (contactResults.getHasNext()) {
            hasNext = true;
         } else {
            hasNext = false;
         }
            hasPrevious = true; 
      }
      requestedPage = String.valueOf(contactResults.getPageNumber());
      return null;
    }

    public PageReference previousContactPage() {
      if (contactResults.getHasPrevious()) {
         showingTo =  showingTo - contacts.size();
         contacts = new List<Contact_Address__c >();
         contactResults.previous();
         contacts = contactResults.getRecords();
         showingFrom = showingFrom - contactResults.getPageSize();
         hasNext = true;
         if (contactResults.getHasPrevious()) {
            hasPrevious = true;
         }else {
            hasPrevious = false;
         }
      }
      requestedPage = String.valueOf(contactResults.getPageNumber());  
      return null;
    }
  
    public void requestedAccountPage() {}
  
    public PageReference requestedContactPage() {
      boolean check = pattern.matches('[0-9]+',requestedPage); 
      Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
      if (pageNo == 0 || pageNo > totalPage){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                 Label.ASS_Message_Invalid_Page_Number)); 
        return null;       
      }   
      contactResults.setPageNumber(pageNo);
      contacts = contactResults.getRecords();
      if (contactResults.getHasPrevious()) {
         hasPrevious = true;
      } else {
         hasPrevious = false;
      }
      if (contactResults.getHasNext()) {
         hasNext = true;
      }else {
         hasNext = false;
      }
      showingFrom  = (pageNo - 1) * contactResults.getPageSize() + 1;
       
      showingTo = showingFrom + contacts.size() - 1;
      if (showingTo > totalResults) {
         showingTo = totalResults;
      }
      return null;
    }
    
  ////////////////////////MIrfan Address \\\\\\\\\\\\\\\\\\\\\\\
    public PageReference nextAddressPage() {
      if (addressResults.getHasNext()) {
         addresses = new List<Contact_Address__c>();
         addressResults.next();
         addresses = addressResults.getRecords();
         showingAddrFrom = showingAddrFrom + addressResults.getPageSize();
         showingAddrTo =  showingAddrTo + addresses.size();
         if (addressResults.getHasNext()) {
            hasAddrNext = true;
         }else {
            hasAddrNext = false;
         }
            hasAddrPrevious = true; 
      }
      requestedAddrPage = String.valueOf(addressResults.getPageNumber());
      return null;
    }

    public PageReference previousAddressPage() {
      if (addressResults.getHasPrevious()) {
         showingAddrTo =  showingAddrTo - addresses.size();
         addresses = new List<Contact_Address__c >();
         addressResults.previous();
         addresses = addressResults.getRecords();
         showingAddrFrom = showingAddrFrom - addressResults.getPageSize();
         hasAddrNext = true;
         if (addressResults.getHasPrevious()) {
            hasAddrPrevious = true;
         }else {
            hasAddrPrevious = false;
         }
      }
      requestedAddrPage = String.valueOf(addressResults.getPageNumber());  
      return null;
    }

    public PageReference requestedAddressPage() {
      boolean check = pattern.matches('[0-9]+',requestedAddrPage); 
      Integer pageAddrNo = check? Integer.valueOf(requestedAddrPage) : 0;
      if (pageAddrNo == 0 || pageAddrNo > totalAddrPage) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                        Label.ASS_Message_Invalid_Page_Number)); 
         return null;       
      }   
      addressResults.setPageNumber(pageAddrNo);
      addresses= addressResults.getRecords();
      if (addressResults.getHasPrevious()) {
         hasAddrPrevious = true;
      }else {
         hasAddrPrevious = false;
      }
      if (addressResults.getHasNext()) {
         hasAddrNext = true;
      }else {
         hasAddrNext = false;
      }
      showingAddrFrom  = (pageAddrNo - 1) * addressResults.getPageSize() + 1;
       
      showingAddrTo = showingAddrFrom + addresses.size() - 1;
      if (showingAddrTo > totalAddrResults) {
         showingAddrTo = totalAddrResults;
      }
      return null;
    }
    /////////////////////// MIrfan Address \\\\\\\\\\\\\\\\\\\\\\\\    
    
     //MIrfan, Linking button handler. 181113
   /* public pagereference linkRecords() {
      String conId = Apexpages.currentPage().getParameters().get('conId'); 
      String addrId = Apexpages.currentPage().getParameters().get('addrId'); 
      addrId = addrId.split(';')[1];
      try {
         Contact_Address__c recToCreate = new Contact_Address__c(Contact__c = conId, Address__c = addrId);
         insert recToCreate;
      } catch(Exception ex) {
         ApexLogHandler.createLogAndSave('ContactSmartSearchExtention', 'linkRecords', ex.getStackTraceString(), ex);
         return null;
      }
      searchContact();
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,Label.ASS_Message_Join_complete));
      return null;
    } */

    //used to sort
    public void sortData(){
      if (previousSortField.equals(sortField)){
         isAsc = !isAsc;  
      }else {
         isAsc = true;
      }   
      sortOrder = isAsc ? ' ASC ' : ' DESC ';
      previousSortField = sortField;
      searchContact();
    }

    //returns default query limit 250 if settings doesn't find.
    public static Integer getQueryLimit () {
      if (queryLimit == null) {
        Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        if (custSettings != null && custSettings.Smart_Search_Query_Limit__c <> null) {
          queryLimit = Integer.valueOf(custSettings.Smart_Search_Query_Limit__c);
        } else {
          queryLimit = 250;
        }
      }
      return queryLimit;
    }   

}