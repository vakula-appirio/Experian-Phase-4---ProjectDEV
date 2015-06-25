public without sharing class LeadSmartSearchExtension {
    
     //Search criteria fields
    public String leadFirstNameToSearch {set;get;}
    public String leadLastNameToSearch {set;get;}
    public String leadEmailToSearch {set;get;}
    public String leadCompanyToSearch {set;get;}
    public String addressline1ToSearch {set;get;}
    public String addressCountryToSearch {set;get;}
    public String addressStateToSearch {set;get;}
    public String addressCityToSearch {set;get;}
    public String addressPostalCodeToSearch {set;get;}
    // userRegion added by James Weatherall. 12Mar14.  
    public String userRegion {set;get;}
     //Added by Richard Joseph 13June 14. Case # 2289
    public String userBU {set;get;}
    
    public integer searchCount{set; get;}
    public string searchStatus{set; get;}
    public string sortField{set;get;}
    private string previousSortField;
    private string sortOrder;
      
    public boolean isAsc{set; get;}
    public Integer showingFrom{get;set;}
    public Integer showingTo{get;set;}
    public string query ;
    
    public boolean showLeadButton{set; get;}
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public String requestedPage {get;set;}
    public String leadPrefix {get;set;}
    public integer totalResults {set; get;}
    
    public Integer totalPage {set; get;}
    
    //MIrfan
    public AccountSmartSearchExtention accSearchController {get;set;}
    public ContactSmartSearchExtention conSearchController {get;set;}
    
    
    /*Commented these constants here and pushed to IConstants.cls file*/
    //private static final Integer DEFAULT_RESULTS_PER_PAGE = 20;  
    //private static final string SEARCH_TYPE = ' and ';
    //private static final string DEFAULT_SORT_ORDER = ' ASC ';
    //private static final string DEFAULT_SORT_FIELD = 'Name';
    
    public ApexPages.StandardSetController leadResults;
    //Constructor
    public LeadSmartSearchExtension(ApexPages.StandardController controller) {
        resetSearchStatus();
        getLeadPrefix();
        getUserRegionAndBU();
        accSearchController = new AccountSmartSearchExtention();
        conSearchController = new ContactSmartSearchExtention();
    }

    //set to default status of page
    public void resetSearchStatus(){
        //Reset Lead fields
        showLeadButton = false;
        leads = new List<Lead>();
        searchCount = 0;
        searchStatus = '';
        sortOrder = IConstants.DEFAULT_SORT_ORDER;
        sortField = IConstants.DEFAULT_SORT_FIELD;
        previousSortField = IConstants.DEFAULT_SORT_FIELD;
        leadFirstNameToSearch = '';
        leadLastNameToSearch = '';
        leadEmailToSearch = '';
        isAsc = true;
        hasPrevious = false;
        hasNext = false;
    }
    
    public List<Lead> leads {
        get{
            return leads;
        }set;
    }
    
    public PageReference cancel(){
        Pagereference pg = null;
        return pg;  
    }
    
    /*@jazzyrocksr : Make a describe call get KeyPrefix for Lead Object to build dynamic URLs*/
    private void getLeadPrefix(){
        Schema.DescribeSObjectResult dsr = Lead.SObjectType.getDescribe();
        leadPrefix=dsr.getKeyPrefix();
    }
    
    /* Added by James Weatherall. 12Mar14. Method to get User Region to use in URL */
    private void getUserRegionAndBU() {
        User u = [select Region__c,Business_Unit__c from User where Id =: UserInfo.getUserId()];
        if(u.Region__c != null)
        {
            userRegion =  EncodingUtil.urlEncode(u.Region__c, 'UTF-8');
        }
         //Added by Richard Joseph - To retrive Business Unit also from User object and pass it on to the Page. Case # 2289
        if(u.Business_Unit__c != null)
        {
            userBU =  EncodingUtil.urlEncode(u.Business_Unit__c , 'UTF-8');
        }
    }
    
    public String findSearchCondition(String query){
     //leadFirstNameToSearch = leadFirstNameToSearch.replace('*','');
     //leadLastNameToSearch = leadLastNameToSearch.replace('*','');
     //leadEmailToSearch = leadEmailToSearch.replace('*','');
     if(leadFirstNameToSearch != null && leadFirstNameToSearch != ''){
         String strFName = String.escapeSingleQuotes(leadFirstNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          if(query.toUpperCase().contains('WHERE')){
            query += ' and FirstName like \'%' + strFName + '%\'';
          }else{
            query += ' where FirstName like \'%' + strFName +  '%\'';
          }
      }
      if(leadLastNameToSearch != null && leadLastNameToSearch != ''){
          String strLName = String.escapeSingleQuotes(leadLastNameToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          if(query.toUpperCase().contains('WHERE')){
            query += ' and LastName like \'%' + strLName + '%\'';
          }else{
            query += ' where LastName like \'%' + strLName +  '%\'';
          }
      }
      if(leadEmailToSearch != null && leadEmailToSearch != ''){
          String strEmail = String.escapeSingleQuotes(leadEmailToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Email like \'%' + strEmail + '%\'';
          }else{
            query += ' where Email like \'%' + strEmail +  '%\'';
          }
      }
      
      //MIrfan
      if(leadCompanyToSearch != null && leadCompanyToSearch != ''){
          String strCompany = String.escapeSingleQuotes(leadCompanyToSearch.Trim().replaceAll('\\*','').replaceAll('%',''));
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Company like \'%' + strCompany + '%\'';
          }else{
            query += ' where Company like \'%' + strCompany +  '%\'';
          }
      }
      
      //MIrfan@191113. Addes IsConverted
      if(query.toUpperCase().contains('WHERE')){
        query += ' and IsConverted=false ';
        /* + 
            ((leadCompany != null && leadCompany != '') ? ' or (isConverted=true and '+
            ' (ConvertedContact.Name like \'%' + leadCompany.Trim() + '%\''+
            ' or ConvertedAccount.Name like \'%' + leadCompany.Trim() + '%\'))' : '');*/
      }else{
        query += ' where IsConverted=false ';
      }

    //mirfan@201113
     if(!query.containsIgnoreCase('and'))
        query += ' and Id=null'; 

      system.debug('##########query###########'+query);
      
      return query;
  }
  
  
    
    
    public void performSearch() {
        searchLead();
        System.debug('Lead list ::::::::::::' + leads);
        
        
        accSearchController.accountNameToSeaarch = leadCompanyToSearch;
        accSearchController.addressline1ToSearch=addressline1ToSearch;
        accSearchController.addressCityToSearch=addressCityToSearch;
        accSearchController.addressStateToSearch=addressStateToSearch;
        accSearchController.addressCountryToSearch=addressCountryToSearch;
        accSearchController.addressPostalCodeToSearch=addressPostalCodeToSearch;
        accSearchController.performSearch();
        
        conSearchController.contactFirstNameToSearch = leadFirstNameToSearch;
        conSearchController.contactLastNameToSearch = leadLastNameToSearch;
        conSearchController.contactEmailToSearch = leadEmailToSearch;
        conSearchController.addressline1ToSearch=addressline1ToSearch;
        conSearchController.addressCityToSearch=addressCityToSearch;
        conSearchController.addressStateToSearch=addressStateToSearch;
        conSearchController.addressCountryToSearch=addressCountryToSearch;
        conSearchController.addressPostalCodeToSearch=addressPostalCodeToSearch;
        conSearchController.performSearch();
        
        system.debug('########showLeadButton##########'+showLeadButton);
        
        showLeadButton = (showLeadButton && leads.size()==0 && conSearchController.contacts.size()==0);// && accSearchController.accounts.size()==0);
        
        for(Account_Address__c rec: accSearchController.accounts)
        {
            if(rec.Account__r.Name.equalsIgnoreCase(leadCompanyToSearch))
                {
                    showLeadButton = false;
                    break;
                }
        }
        
        
    }
    
    //method to search Lead and make list according to pagesize
    private void searchLead(){
        //showLeadButton = true;
        
        //MIrfan, 221113
        leadFirstNameToSearch=leadFirstNameToSearch.trim();
        leadLastNameToSearch=leadLastNameToSearch.trim();
        leadEmailToSearch=leadEmailToSearch.trim();
        leadCompanyToSearch=leadCompanyToSearch.trim();
        addressline1ToSearch=addressline1ToSearch.trim();
        addressCountryToSearch=addressCountryToSearch.trim();
        addressStateToSearch=addressStateToSearch.trim();
        addressCityToSearch=addressCityToSearch.trim();
        addressPostalCodeToSearch=addressPostalCodeToSearch.trim();
        
        
        //Retrive CaseTeamRole name from Custom Setting.
        Global_Settings__c custSettings = Global_Settings__c.getValues('Global');
        
        Integer limitRecords=Integer.valueOf(custSettings.Smart_Search_Query_Limit__c);//250;
        
        //query = 'Select l.Title, l.Phone, l.Owner.Name, l.Name, l.Email, l.company From Lead l ';
        /**************************************************************
         * The code is updated by Jazzy Rock to support fieldsets in 
           Lead for dynamic display of columns*   
         **************************************************************/
         
         List<Schema.FieldSetMember> fsm= Schema.SObjectType.Lead.FieldSets.Lead_Search_Result.getFields();
         String query = 'SELECT ';
         for(Schema.FieldSetMember f : fsm) {
            query += f.getFieldPath() + ', ';
         }
         query += 'Id,Owner.Name FROM Lead';
        
        query = findSearchCondition(query);
        query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
          
        try{
            leads = new List<Lead>();
            leadResults = new ApexPages.StandardSetController(Database.query(query));
            leadResults.setPageSize(IConstants.DEFAULT_RESULTS_PER_PAGE);
            leads = leadResults.getRecords();
            searchCount = leadResults.getResultSize();
            
            // cloudspokes:3087 Added the if condition to check records count touching limitRecords
            if (searchCount >= limitRecords) {
                searchStatus = Label.ASS_Message_Search_returned_more_records.replace('####',limitRecords+'');
            }
            
            
            //MIrfan@Issue I-82762
            if((leadFirstNameToSearch!='' && 
                leadLastNameToSearch!='' &&
                leadEmailToSearch!='' &&
                leadCompanyToSearch!='' ) /*&& 
                (addressline1ToSearch!='' ||
                addressCountryToSearch!='' ||
                addressStateToSearch!='' ||
                addressCityToSearch!='' ||
                addressPostalCodeToSearch!='')*/)
                {
                    showLeadButton=true;
                }
                
                system.debug('########showLeadButton##########'+showLeadButton);
        }catch(Exception e){
            searchCount = 0;
        }  
        if (searchCount  == 0){
            searchStatus = Label.No_matching_results;
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());
        showingFrom = 1;
        totalResults = 0;
        for (List<Sobject> recordBatch:Database.query(query))  {
             totalResults = totalResults + recordBatch.size();
         }
        totalPage = 0;
        totalPage = totalResults / leadResults.getPageSize() ; 
        if (totalPage * leadResults.getPageSize() < totalResults){
          totalPage++;
        }
        
        
        
        if(searchCount < leadResults.getPageSize()) {
            showingTo = searchCount;
        } else {
            showingTo = leadResults.getPageSize();
        }
        if(leadResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        hasPrevious = false;
    }
    
    
    public PageReference nextLeadPage(){
        
        if(leadResults.getHasNext()) {
            leads = new List<Lead>();
            leadResults.next();
            leads = leadResults.getRecords();
            showingFrom = showingFrom + leadResults.getPageSize();
            showingTo =  showingTo + leads.size();
            if(leadResults.getHasNext()) {
                hasNext = true;
            } else {
                hasNext = false;
            }
            hasPrevious = true; 
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());
        return null;
    }
    
   
  
    public PageReference previousLeadPage(){
        if(leadResults.getHasPrevious()) {
            showingTo =  showingTo - leads.size();
            leads = new List<Lead>();
            leadResults.previous();
            leads = leadResults.getRecords();
            showingFrom = showingFrom - leadResults.getPageSize();
            hasNext = true;
            if(leadResults.getHasPrevious()) {
                hasPrevious = true;
            } else {
                hasPrevious = false;
            }
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());  
        return null;
    }
    
   
  
    public PageReference requestedLeadPage(){
        
        boolean check = pattern.matches('[0-9]+',requestedPage); 
        Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
        if(pageNo == 0 || pageNo > totalPage){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Invalid_Page_Number)); 
            return null;       
        }  
        leadResults.setPageNumber(pageNo);
        leads = leadResults.getRecords();
        if(leadResults.getHasPrevious()) {
            hasPrevious = true;
         } else {
            hasPrevious = false;
         }
         if(leadResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        showingFrom  = (pageNo - 1) * leadResults.getPageSize() + 1;
       
        showingTo = showingFrom + leads.size() - 1;
        if(showingTo > totalResults) {
            showingTo = totalResults;
        }
        return null;
    }
    
    
  
    //used to sort
    public void sortData(){
        if (previousSortField.equals(sortField)){
          isAsc = !isAsc;  
        }else{
            isAsc = true;
        }   
        sortOrder = isAsc ? IConstants.SORT_ASC_ORDER : IConstants.SORT_DESC_ORDER;
        previousSortField = sortField;
        searchLead();
    }
    
    
   
    

}