/**=====================================================================
 * Appirio, Inc
 * Name: AccountSmartSearchExtention
 * Description: 
 * Created Date: Jul 19th, 2013
 * Created By: Peter Babalis (Appirio)
 * 
 * Date Modified        Modified By              Description of the update
 * May 25th, 2012       sdash(Appirio)
 * Nov 22st, 2013       MIrfan(Appirio)
 * Jan 30th, 2014       Jinesh Goyal(Appirio)    T-232760: Homogenize the comments
 * Feb 13th, 2014       Jinesh Goyal(Appirio)    T-232763: Added Exception Logging
 * Feb 15th, 2014       Naresh Ojha(Appirio)     T-249364: AKA__c field filter
 * Feb 27th, 2014       Naresh Ojha(Appirio)     T-249488: updated getQueryLimit as per chatter.
 * Mar 04th, 2014       Arpita Bose(Appirio)     T-243282: Added Constants in place of String
 * Mar 11th, 2014       Arpita Bose(Appirio)     T-256335: Better Debug logging (Removed unnecessary debugs 
 *                                                         and maintained the coding convention)
 * Mar 19th, 2014       Arpita Bose(Appirio)     T-251969: Join button functionality is no longer required so,
 *                                               showJoinButton and linkRecords method is commented
 * Mar 27th, 2014       Nathalie Le Guay         T-266743: Remove references to Primary_Billing__c & Primary_Shipping__c (unused)
 * Apr 07th, 2014       Arpita Bose              T-269372: Added addError() in try-catch block
 * Apr 24, 2014         Nathalie Le Guay         Replacing reference to Account.Type__c to Account.Account_Type__c
 * Jul 4, 2014          James Weatherall         Case # 2658 Modify searchAccount and findSearchCondition to include OR search 
 * Feb 23th, 2014       Noopur                   T-363964: added the logic to show "New Account" button on the Account Search page for particular profiles 
 * Feb 19th, 2015       Paul Kissick             Case #22017 - Fix for totalResults being incorrectly totaled
 * Apr 1st, 2015        Nathalie Le Guay         T-367528: allow users having specific permission set to view extra button
  =====================================================================*/
//
// Changed to without sharing so that users can see duplicates across the world
//
// public with sharing class AccountSmartSearchExtention {
public  class AccountSmartSearchExtention {
  
  //Search criteria fields
  public String accountNameToSeaarch {set;get;}
  public String addressline1ToSearch {set;get;}
  public String addressline2ToSearch {set;get;}
  public String addressline3ToSearch {set;get;}
  public String addressCountryToSearch {set;get;}
  public String addressStateToSearch {set;get;}
  public String addressCityToSearch {set;get;}
  public String addressPostalCodeToSearch {set;get;}
    
  //MIrfan
  public String accessibleAccountIds {set;get;}  
  public integer searchCount {set; get;}
  public string searchStatus {set; get;}
  public string sortField {set;get;}
  public integer limitRecords {set; get;} //May25-2012 by sdash@appirio.com: added limit 250 to avoid the query overflow of 50,000 records
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
    
  public boolean showAccountButton {set; get;}
    
  //MIrfan@Issue I-82761
  public boolean showAddAccountButton {set; get;}
  public boolean showAddAddressButton {set; get;}
  //public boolean showJoinButton {set; get;}
    
  public boolean hasNext {get;set;}
  public boolean hasPrevious {get;set;}
  public String requestedPage {get;set;}
  public static Integer queryLimit;

  public integer totalResults {set; get;}   
  public Integer totalPage {set; get;}
    
  private static final Integer DEFAULT_RESULTS_PER_PAGE = 20;  
  private static final string SEARCH_TYPE = ' and ';
  private static final string DEFAULT_SORT_ORDER = ' ASC ';
  private static final string DEFAULT_SORT_FIELD = 'Name';
    
  public ApexPages.StandardSetController accountResults {get;set;}
  public ApexPages.StandardSetController addressResults {get;set;}
  
  public boolean showNewAccountButton {get;set;}
  
  // Set of Profile names for which the "New Contact" button should be enabled
  public static final set<String> profilesAllowedForNewAccount = new set<String>();
  static {
    profilesAllowedForNewAccount.add(Constants.PROFILE_SYS_ADMIN);
  }
  
  public static final Set<String> permissionSetsAllowedForNewAccount = new Set<String>();
  static {
    permissionSetsAllowedForNewAccount.add(Constants.PERMISSIONSET_EDQ_SAAS_DEPLOYMENT_MANAGER);
  }
  
  //Constructor
  public AccountSmartSearchExtention(ApexPages.StandardController controller) {
    isBroaderSearchOn = true;   
    resetSearchStatus();
    }

  //Constructor
  public AccountSmartSearchExtention() {
    resetSearchStatus();
    }
    
  //set to default status of page
  public void resetSearchStatus() {
    //Reset account fields
    showAccountButton = false;
    accounts = new List<Account_Address__c>();   
    searchCount = 0;
    searchAddrCount = 0;
    searchStatus = '';
    sortOrder = DEFAULT_SORT_ORDER;
    sortField = DEFAULT_SORT_FIELD;
    previousSortField = DEFAULT_SORT_FIELD;
    accountNameToSeaarch = '';
    addressline1ToSearch = '';
    addressline2ToSearch = '';
    addressline3ToSearch = '';
    addressCountryToSearch = '';
    addressStateToSearch = '';
    addressCityToSearch = '';
    addressPostalCodeToSearch = '';
    isAsc = true;
    hasPrevious = false;
    hasNext = false;
    
    List<PermissionSet> permissionSetsAllowed = [SELECT Id, Name
                                                 FROM PermissionSet
                                                 WHERE Name in: permissionSetsAllowedForNewAccount];

    User currentUser = [SELECT Id,Profile.Name,
                               (SELECT Id FROM PermissionSetAssignments WHERE PermissionSetId in: permissionSetsAllowed)
                          FROM User
                          WHERE Id = :userinfo.getUserId()];
      
      if (profilesAllowedForNewAccount.contains(currentUser.Profile.Name) ||
          currentUser.PermissionSetAssignments.size() > 0) {
        showNewAccountButton = true;
      }
      else {
        showNewAccountButton = false;
      } 
    }
    
  public List<Account_Address__c  > accounts {
    get{
      return accounts;
        }set;
    }
    
  public List<Account_Address__c  > addresses {
    get{
      return addresses;
        }set;
    }
    
  public PageReference cancel() {
    Pagereference pg = null;
    return pg;  
    }
      
  public String findSearchCondition(String query, boolean matchAccountOr, boolean matchAccountAddress) {
    String queryOnlyAddress = '';   
     //MIrfan
    String queryAccountAddress = query;
    queryAccountAddress += (queryAccountAddress.toUpperCase().contains('WHERE'))?' and ( ' : ' where  ( Account__r.Id!=null ';
     
    if (accountNameToSeaarch != null && accountNameToSeaarch != '') {
      String strName = String.escapeSingleQuotes(accountNameToSeaarch.Trim().replaceAll('\\*','').replaceAll('%',''));
         
      if (queryAccountAddress.toUpperCase().contains('WHERE')) {
        if(!matchAccountOr)
        {
          queryAccountAddress += ' AND (Account__r.Name like \'%' + strName + '%\' OR Account__r.AKA__c like \'%' + strName + '%\') ';
        } else {
          queryAccountAddress += ' AND ((Account__r.Name like \'%' + strName + '%\' OR Account__r.AKA__c like \'%' + strName + '%\') ';
        }
      } else{
         queryAccountAddress += ' WHERE (Account__r.Name like \'%' + strName +  '%\' OR Account__r.AKA__c like \'%' + strName + '%\') ';
      }
    } 
    if (addressline1ToSearch != null && addressline1ToSearch != '') {
      //MIrfan
      String strAddr1 = String.escapeSingleQuotes(addressline1ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_1__c  like \'%' + strAddr1 + '%\'';  
      if (queryAccountAddress.toUpperCase().contains('WHERE')){
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and address__r.Address_1__c  like \'%' + strAddr1 + '%\'';
        } else {
          queryAccountAddress += ' or address__r.Address_1__c  like \'%' + strAddr1 + '%\'';
        }
      } else{
        queryAccountAddress += ' where address__r.Address_1__c  like \'%' + strAddr1 +  '%\'';
      }
    }     
      
    if (addressline2ToSearch != null && addressline2ToSearch != '') {
      //MIrfan
      String strAddr2 = String.escapeSingleQuotes(addressline2ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_2__c  like \'%' + strAddr2 + '%\'';
      if (queryAccountAddress.toUpperCase().contains('WHERE')) {
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and address__r.Address_2__c  like \'%' + strAddr2 + '%\'';
        } else {
          queryAccountAddress += ' or address__r.Address_2__c  like \'%' + strAddr2 + '%\'';
        }
      }else {
        queryAccountAddress += ' where address__r.Address_2__c  like \'%' + strAddr2 +  '%\'';
      }
    }     
       
    if (addressline3ToSearch != null && addressline3ToSearch != '') {
      //MIrfan
      String strAddr3 = String.escapeSingleQuotes(addressline3ToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Address_3__c  like \'%' + strAddr3 + '%\'';
      if (queryAccountAddress.toUpperCase().contains('WHERE')){
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and address__r.Address_3__c  like \'%' + strAddr3 + '%\'';
        } else {
          queryAccountAddress += ' or address__r.Address_3__c  like \'%' + strAddr3 + '%\'';
        }
      } else{
        queryAccountAddress += ' where address__r.Address_3__c  like \'%' + strAddr3 +  '%\'';
      }
    }   

    if (addressCountryToSearch != null && addressCountryToSearch != '') {
      //MIrfan
      String strCountry = String.escapeSingleQuotes(addressCountryToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.Country__c  like \'%' + strCountry + '%\'';
      if (queryAccountAddress.toUpperCase().contains('WHERE')){
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and address__r.Country__c  like \'%' + strCountry + '%\'';
        } else {
          queryAccountAddress += ' or address__r.Country__c  like \'%' + strCountry + '%\'';
        }
      } else{
        queryAccountAddress += ' where address__r.Country__c  like \'%' + strCountry +  '%\'';
      }
    }     
       
    if (addressStateToSearch != null && addressStateToSearch != '') {
      //MIrfan
      String strState = String.escapeSingleQuotes(addressStateToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));  
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' (address__r.State__c like \'%' + strState + '%\' or '+
                           'address__r.Province__c like \'%' + strState + '%\') ';
      if (queryAccountAddress.toUpperCase().contains('WHERE')) {
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and (address__r.State__c like \'%' + strState + '%\' or address__r.Province__c like \'%' + strState + '%\') ';
        } else {
          queryAccountAddress += ' or (address__r.State__c like \'%' + strState + '%\' or address__r.Province__c like \'%' + strState + '%\') ';
        }
      } else{
         queryAccountAddress += ' where (address__r.State__c  like \'%' + strState +  '%\' or address__r.Province__c like \'%' + strState + '%\') ';
      }
    }
      
    if (addressCityToSearch != null && addressCityToSearch != '') {
          //MIrfan
      String strCity = String.escapeSingleQuotes(addressCityToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' address__r.City__c  like \'%' + strCity + '%\'';          
      if(queryAccountAddress.toUpperCase().contains('WHERE')){
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and address__r.City__c  like \'%' + strCity + '%\'';
        } else {
          queryAccountAddress += ' or address__r.City__c  like \'%' + strCity + '%\'';
        }       
      } else{
         queryAccountAddress += ' where address__r.City__c   like \'%' + strCity +  '%\'';
      }
    }     
      
    if (addressPostalCodeToSearch != null && addressPostalCodeToSearch != '') {
          //MIrfan
      String strZip = String.escapeSingleQuotes(addressPostalCodeToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
      queryOnlyAddress += (queryOnlyAddress.length()>0?' and ' : '') + ' (address__r.Postcode__c  like \'%' + strZip + '%\' or '+
                           'address__r.Zip__c  like \'%' + strZip + '%\') ';         
      if (queryAccountAddress.toUpperCase().contains('WHERE')){
        if(!matchAccountOr)
        {
          queryAccountAddress += ' and (address__r.Postcode__c  like \'%' + strZip + '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';
        } else {
          queryAccountAddress += ' or (address__r.Postcode__c  like \'%' + strZip + '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';
        }
      }else {
         queryAccountAddress += ' where address__r.Postcode__c  like \'%' + strZip +  '%\' or address__r.Zip__c  like \'%' + strZip + '%\') ';
      }
    }
    System.debug('\n[AccountSmartSearch: findSearchCondition]: search query: '+queryAccountAddress); 
      //MIrfan
    if (matchAccountAddress && queryAccountAddress.toUpperCase().contains('WHERE')){
       if(matchAccountOr && accountNameToSeaarch != null && accountNameToSeaarch != '')
       {
        queryAccountAddress +=' )) ';
       } else {
        queryAccountAddress +=' ) ';
       }
       query = queryAccountAddress;
    }     

     //MIrfan
    if (!matchAccountAddress) {
       if(queryOnlyAddress.length()>0)
          query +=' where ( ' +queryOnlyAddress.replace('Account__r.Id! = null','Account__r.Id == null')+' ) ';
       else
          query +=' where Id = null ';
    }

     //mirfan@201113
    if (!query.containsIgnoreCase('and'))
       query = query.replace('Account__r.Id!=null', 'Account__r.Id=null');   
       system.debug('\n[AccountSmartSearch: findSearchCondition]: Query is ' + query);
       return query;
  }

  public void performSearch() {
    searchAccount();
  }
    
  //method to search account and make list according to pagesize
  private void searchAccount() {        
    //MIrfan, 221113
    showAccountButton = false;
    showAddAccountButton = false;
    showAddAddressButton = false;
    //showJoinButton = false;
    
    addressline1ToSearch = addressline1ToSearch.trim();
    addressline2ToSearch = addressline2ToSearch.trim();
    addressline3ToSearch = addressline3ToSearch.trim();
    addressCountryToSearch = addressCountryToSearch.trim();
    addressStateToSearch = addressStateToSearch.trim();
    addressCityToSearch = addressCityToSearch.trim();
    addressPostalCodeToSearch = addressPostalCodeToSearch.trim();
    accountNameToSeaarch = accountNameToSeaarch.trim();
            
    if (accountNameToSeaarch !='' || 
        addressline1ToSearch !='' || 
        addressline2ToSearch !='' || 
        addressline3ToSearch !='' || 
        addressCountryToSearch !='' || 
        addressStateToSearch !='' || 
        addressCityToSearch !='' || 
        addressPostalCodeToSearch !='') {
        showAccountButton = true;
        }
                
    limitRecords = getQueryLimit();
    /**************************************************************
     * The code is updated by Mohit Batwada for testing purpose   *   
     **************************************************************/
    String queryColumns = 'Select  Name, Account__r.Phone, Account__r.Parent.Name, Account__r.Ultimate_Parent_Account__r.Name,'+
                          'Account__r.Region__c, Account__r.Active__c, Account__r.Name,Account__r.Id,'+
                          'Account__r.Owner.Name,address__r.Name, address__r.Address_1__c, address__r.Address_2__c,'+
                          'address__r.Address_3__c, address__r.City__c, address__r.State__c, address__r.Postcode__c,'+
                          'address__r.Province__c, address__r.zip__c, address__r.Country__c,'+
                          'Address_Type__c, account__r.Type, account__r.Account_Type__c FROM Account_Address__c'; 
       
       
    query = findSearchCondition(queryColumns, false, true);
    query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
    System.debug('\n[AccountSmartSearch: searchAccount]: Query is: ' + query);
    //JWeatherall 7/4/2014
    string queryOr = findSearchCondition(queryColumns, true, true);
    queryOr += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
    //MIrfan
    string queryAddress = findSearchCondition(queryColumns, false, false);
    queryAddress += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;

    try{
      accounts = new List<Account_Address__c>();
      accounts = Database.query(query);
      System.debug('accounts.size() = ' + accounts.size());
        
      Set<Id> setAccountIds = new Set<Id>();
      for (Account_Address__c rec : accounts) {
        setAccountIds.add(rec.Account__c);
      }
      
      List<Account_Address__c> accountsOr = new List<Account_Address__c>();
      System.debug('queryOr = ' + queryOr);
      accountsOr = Database.query(queryOr);
      //System.debug('accountsOr.size() = ' + accountsOr.size());
          
      for (Account_Address__c AO : accountsOr) {
        if(!setAccountIds.contains(AO.Account__c))
        {
          accounts.add(AO);
          setAccountIds.add(AO.Account__c);
        }
      }
      
      if (setAccountIds.size() > 0)
         accessibleAccountIds = SmartSearchRecordVisibility.getUserAccessibleAccounts(setAccountIds);
         accountResults = new ApexPages.StandardSetController(accounts);
         accountResults.setPageSize(DEFAULT_RESULTS_PER_PAGE);
         accounts = accountResults.getRecords();   
         searchCount = accountResults.getResultSize();

         //May25-2012 by sdash@appirio.com: Added the if condition to check records count touching limitRecords

         searchStatus = '';
      if (accounts.size() >= limitRecords) {
         searchStatus = Label.ASS_Message_Search_returned_more_records.replace('####', limitRecords+'');
         system.debug('\n[AccountSmartSearch: SearchAccount]: searchStatus #######'+searchStatus ); 
      }
           
         //MIrfan, 221113, show button only if there is result.
      if (accounts.size() > 0) {
         showAddAddressButton = true;
      }
    }catch(Exception e){
         searchCount = 0;
         System.debug('e.getStackTraceString() = ' + e.getStackTraceString());
         ApexLogHandler.createLogAndSave('AccountSmartSearchExtention', 'searchAccount', e.getStackTraceString(), e);
         accounts.get(0).addError(Label.ASS_Message_No_matching_results);
    } 
        
    if (searchCount == 0){
      searchStatus = Label.ASS_Message_No_matching_results;
    }
    //requestedPage = (accountResults == null)? '0' : String.valueOf(accountResults.getPageNumber());
    requestedPage = String.valueOf(accountResults.getPageNumber());
    showingFrom = 1;
    // PK Case #22017 - Changed below as this was skewing results.
    totalResults = accountResults.getResultSize();
    
    /*     
    for (List<Sobject> recordBatch:Database.query(query))  {
      totalResults = totalResults + recordBatch.size();
    }
    for (List<Sobject> recordBatch:Database.query(queryOr))  {
      totalResults = totalResults + recordBatch.size();
    }
    */

    totalPage = 0;
    totalPage = totalResults / accountResults.getPageSize() ; 
    if (totalPage * accountResults.getPageSize() < totalResults){
      totalPage++;
    }

    if (searchCount < accountResults.getPageSize()) {
      showingTo = searchCount;
    } else{
      showingTo = accountResults.getPageSize();
    }
         
    if (accountResults.getHasNext()) {
      hasNext = true;
    } else{
      hasNext = false;
    }
      hasPrevious = false;
    ////////////////////MIrfan Address Navigation \\\\\\\\\\\\\\\\\\\\\\
    try {
      addresses = new List<Account_Address__c>();
      system.debug('\n[AccountSmartSearch: AccountSearch]: queryAddress #######'+queryAddress);
      Map<Id,Account_Address__c> mapAccAddr = new Map<Id,Account_Address__c>();
      for(Account_Address__c rec : Database.query(queryAddress))
        {
          mapAccAddr.put(rec.Address__c,rec);
          }
      addressResults = new ApexPages.StandardSetController(mapAccAddr.values());
      addressResults.setPageSize(DEFAULT_RESULTS_PER_PAGE);
      addresses = addressResults.getRecords();      
      searchAddrCount = addressResults.getResultSize();
      //May25-2012 by sdash@appirio.com: Added the if condition to check records count touching limitRecords
      searchAddrStatus = '';
      if (mapAccAddr.size() >= limitRecords) {
         searchAddrStatus = Label.ASS_Message_Search_returned_more_records.replace('####', limitRecords+'');
      }     
      system.debug('\n[AccountSmartSearch: AccountSearch]: searchAddrStatus #######: '+searchAddrStatus );
            //MIrfan, 221113, show button only if there is result.
      if (addresses.size() > 0) {
         showAddAccountButton = true;
      }
    }catch (Exception e){
        searchAddrCount = 0;
        ApexLogHandler.createLogAndSave('AccountSmartSearchExtention', 'searchAccount', e.getStackTraceString(), e);
        addresses.get(0).addError(Label.ASS_Message_No_matching_results);
    } 
     
    if (searchAddrCount == 0) {
       searchAddrStatus = Label.ASS_Message_No_matching_results;
    }
    requestedAddrPage = (addressResults == null)? '0' : String.valueOf(addressResults.getPageNumber());
    showingAddrFrom = 1;
        
    totalAddrResults = 0;
    Set<Id> setAccAddr = new Set<Id>();
    for (Account_Address__c rec : Database.query(queryAddress))
    {
      setAccAddr.add(rec.Address__c);
    }
    totalAddrResults = totalAddrResults + setAccAddr.size();
         
    totalAddrPage = 0;

    totalAddrPage = totalAddrResults / addressResults.getPageSize() ; 
    if (totalAddrPage * addressResults.getPageSize() < totalAddrResults) {
      totalAddrPage++;
    }
        
    if (searchAddrCount < addressResults.getPageSize()) {
      showingAddrTo = searchAddrCount;
    } else{
      showingAddrTo = addressResults.getPageSize();
    }
    
    if (addressResults.getHasNext()) {
      hasAddrNext = true;
    } else{
      hasAddrNext = false;
    }
    hasAddrPrevious = false;
    /////////////////////////MIrfan Address Navigation End\\\\\\\\\\\\\\\\\\\\\\\\\\
    //MIrfan, 221113, show button only if there is result.
    /*if (addresses.size() > 0 && accounts.size() > 0)
    {
      showJoinButton = true;
    }*/
  }
    
  public PageReference nextAccountPage() {     
    if (accountResults.getHasNext()) {
       accounts = new List<Account_Address__c>();
       accountResults.next();
       accounts = accountResults.getRecords();
       showingFrom = showingFrom + accountResults.getPageSize();
       showingTo = showingTo + accounts.size();
       if (accountResults.getHasNext()) {
          hasNext = true;
       } else{
          hasNext = false;
       }
          hasPrevious = true; 
    }
    requestedPage = String.valueOf(accountResults.getPageNumber());
    return null;
  }

  public PageReference previousAccountPage() {
    if (accountResults.getHasPrevious()) {
      showingTo =  showingTo - accounts.size();
      accounts = new List<Account_Address__c >();
      accountResults.previous();
      accounts = accountResults.getRecords();
      showingFrom = showingFrom - accountResults.getPageSize();
      hasNext = true;
      if (accountResults.getHasPrevious()) {
         hasPrevious = true;
      } else{
         hasPrevious = false;
      }
    }
    requestedPage = String.valueOf(accountResults.getPageNumber());  
    return null;
  }

  public PageReference requestedAccountPage() {
    boolean check = pattern.matches('[0-9]+', requestedPage); 
    Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
    if (pageNo == 0 || pageNo > totalPage){
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ASS_Message_Invalid_Page_Number)); 
       return null;       
    }   
    accountResults.setPageNumber(pageNo);
    accounts = accountResults.getRecords();
    if (accountResults.getHasPrevious()) {
       hasPrevious = true;
    } else{
       hasPrevious = false;
    }
    if (accountResults.getHasNext()) {
       hasNext = true;
    } else{
       hasNext = false;
    }
    showingFrom  = (pageNo - 1) * accountResults.getPageSize() + 1;
    showingTo = showingFrom + accounts.size() - 1;
    if (showingTo > totalResults) {
      showingTo = totalResults;
    }
    return null;
  }
    
  ////////////////////////MIrfan Address \\\\\\\\\\\\\\\\\\\\\\\
  public PageReference nextAddressPage() {
    if (addressResults.getHasNext()) {
      addresses = new List<Account_Address__c>();
      addressResults.next();
      addresses = addressResults.getRecords();
      showingAddrFrom = showingAddrFrom + addressResults.getPageSize();
      showingAddrTo =  showingAddrTo + addresses.size();
      if (addressResults.getHasNext()) {
         hasAddrNext = true;
      } else{
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
       addresses = new List<Account_Address__c >();
       addressResults.previous();
       addresses = addressResults.getRecords();
       showingAddrFrom = showingAddrFrom - addressResults.getPageSize();
       hasAddrNext = true;
       if (addressResults.getHasPrevious()) {
          hasAddrPrevious = true;
       } else{
          hasAddrPrevious = false;
       }
    }
    requestedAddrPage = String.valueOf(addressResults.getPageNumber());  
    return null;
  }
    
  public PageReference requestedAddressPage() {
    boolean check = pattern.matches('[0-9]+', requestedAddrPage); 
    Integer pageAddrNo = check? Integer.valueOf(requestedAddrPage) : 0;
    if (pageAddrNo == 0 || pageAddrNo > totalAddrPage){
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ASS_Message_Invalid_Page_Number)); 
       return null;       
    }   
    addressResults.setPageNumber(pageAddrNo);
    addresses = addressResults.getRecords();
    if (addressResults.getHasPrevious()) {
       hasAddrPrevious = true;
    } else{
       hasAddrPrevious = false;
    }
    if (addressResults.getHasNext()) {
       hasAddrNext = true;
    } else{
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
  /*public pagereference linkRecords() {     
    String accId = Apexpages.currentPage().getParameters().get('accId'); 
    String addrId = Apexpages.currentPage().getParameters().get('addrId'); 
    addrId = addrId.split(';')[1];
        
    try{
      Account_Address__c recToCreate = new Account_Address__c(Account__c = accId, Address__c = addrId);
      insert recToCreate;
    }catch(Exception ex){ 
      ApexLogHandler.createLogAndSave('AccountSmartSearchExtention','linkRecords', ex.getStackTraceString(), ex);
      return null;
    }
    searchAccount();
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Label.ASS_Message_Join_complete));
    return null;
  }*/
  
  //used to sort
  public void sortData() {
    if (previousSortField.equals(sortField)) {
      isAsc = !isAsc;  
    } else{
      isAsc = true;
    }   
    sortOrder = isAsc ? ' ASC ' : ' DESC ';
    previousSortField = sortField;
    searchAccount();
  }
  //returns default query limit 250 if settings doesn't find.
  public static Integer getQueryLimit () {
    if (queryLimit == null) {
      Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
      if (custSettings != null && custSettings.Smart_Search_Query_Limit__c <> null) {
        queryLimit = Integer.valueOf(custSettings.Smart_Search_Query_Limit__c);
      } else{
        queryLimit = 250;
      }
    }
    return queryLimit;
  }
}