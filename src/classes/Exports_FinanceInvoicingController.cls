/******************************************************************************
 * Appirio, Inc
 * Name: Exports_FinanceInvoicingController.cls
 * Description: T-318077
 * Created Date: Sept 09th, 2014
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Date Modified        Modified By             Description 
 * Sep 2nd, 2014        Naresh Kr Ojha          T-323607: Modified to show status and to reload same records
 * Oct 7th, 2014        Naresh kr Ojha          Modified code to fix saving behavior issue and coding standards
 * Oct 13th, 2014       Naresh Kr Ojha          Updated object name from Batch to Export Batch and updated resource names
 *                                              test class name, class name and page name.
 * Oct 14th, 2014       Naresh kr Ojha          T-325419: Created labels and used in page and controller 
 * Oct 20th, 2014       Pallavi Sharma          T-326948: Update VF Page to Display Shipping/Billing Address 
 *                                              Using Opportunity Contact Address 
 * Nov 3rd, 2014        Nathalie Le Guay        I-137413: adding Order_Number__c to the query
 * Nov 14th, 2014       Arpita Bose             I-139036: Updated query limit to 10,000 and used transient variable to reduce the view state size
 * Dec 2nd, 2014        Terri Kellough          S-274030/T-337168 Added country multi-select picklist
 * Dec 10th, 2014       Naresh Kr Ojha          Fixed I-141971, transient from local Constants.
 * Dec 12th, 2014       Naresh Kr Ojha          T-340042: As per task, implemented User.Business_Unit__c functionality.
 * Jan 2nd, 2014        Nathalie                Updated filtering to remove pre-filter on BU (was filtering on EDQ BUs)
 * Jan 15th, 2015       Naresh Kr Ojha          I-145614: Updated filtering limit on load and manual sharing.
 * Jan 15th, 2015       Nathalie                I-145614: default # of records = 400, option to display 1200
 * Jan 16th, 2015       Nathalie                Commenting code related to Opportunity_Contact_Address__c
 * Feb 11th, 2015       Richard J               Case 542797 - Updating currentUserRegion and removing Transient property.
 * Feb 13th, 2015       Tyaga Pati              00540660 - Making Status Multi Select and Added Created Date for Filtering records
 * Mar 11th, 2015       Richard J               Case # 00562256- Finance Invoice Export - Exclude free trials Orders.  
 * Apr 17th, 2015       Nur Azlini              Case # 00583481- Change filterSet from 'Owner_BU_on_Order_Create_Date__c' to 'Owner_Business_Unit__c'
 * Apr 17th, 2015       Richard Joseph          Case # 00586159- To add a new filter for EMEA to check the Order Product's BL for EDQ Product.
 * Apr 27th, 2015       Richard Joseph          Case # 00607717- To change credit process. Exclude credited order from export page and include Credit Note orders. 
   ******************************************************************************/

public with sharing class Exports_FinanceInvoicingController {
  
    public String BATCH_CONDITION_ORDER_NOT_SELECTED {get;set;}
    public String BATCH_CONDITION_ORDER_PREV_SELECTED  {get;set;}
    public String BATCH_CONDITION_SELECT_BATCH_NO  {get;set;}
    
    //Public Map<ID, orderWrapper> selectedOrderMap {get;set;}
    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    public List<SelectOption> sizeOptions {get;set;}
    public List<SelectOption> regionOptions {get;set;}
    public List<SelectOption> countryOptions {get;set;}
    public List<SelectOption> businessUnitOptions {get;set;}
        
    transient public String selectedRegion {get;set;}
    transient public List<String>  selectedStatus {get;set;}
    transient public List<String> selectedCountries {get;set;}
    transient public List<String> selectedBusinessUnits {get;set;}
    
    public List<SelectOption> batchRecOptions {get;set;}
    transient public String selectedBatchRecLink {get;set;}
    public List<SelectOption> statusOptions {get;set;}
   
    public List<SelectOption> orderDateOptions {get;set;}
    transient public String selectedOrderDate {get;set;}
    transient public String selectedClosedDate {get;set;}
        transient public String selectedCreditedStaDate {get;set;}
    transient public String selectedCreditedEndDate {get;set;}
    //transient public String selectedCreditedDate {get;set;}
    transient public String specificBatchNo {get;set;}
    transient public String dateRange1 {get;set;}
    transient public String dateRange2 {get;set;}
    transient public String queryString;
    public Set<String> selectedOrders {get;set;}
    
    transient public List<orderWrapper> batchList;
    
    public List<string[]> reportDisplayList  {get; set;} // Added by Richard
    public String csvContent  {get; set;} // Added by Richard
    public enum exportFileTypes {RPMFile, SummitFile, RoyaltiesFile,PartnerFile,CustomerFile}    // Added by Richard
    public string currentUserRegion {get; set;}// Added by Richard // Removed Transient on Feb 11th - RJ
    public static Id generatedBatchId {get; set;}// Added by Richard
    public boolean ordersWithEDQProducts {get; set;}//Added by Richard
    
    private Set<String> unusedRegions;
    //Map<Id, Map<String,Opportunity_Contact_Address__c>> mapOppRoleAndAddress; NLG - old functionality prior to creating Order__c.Shipping_Address__c
    //public String filterLimit = '400';  
    //===========================================================================
    //Constructor
    //Tyaga Pati 00540660- Added Status array initialization
    //===========================================================================
    public Exports_FinanceInvoicingController() {
      System.debug('--Constructor called--');
      dateRange1 = dateRange2 = specificBatchNo = selectedClosedDate = selectedRegion = selectedCreditedStaDate = selectedCreditedEndDate = selectedBatchRecLink =  selectedOrderDate = '';
      
      if (selectedCountries == null){
        selectedCountries = new List<String>();
      }

      if (selectedBusinessUnits == null){
        selectedBusinessUnits = new List<String>();
      }
      
      if (selectedStatus== null){
        selectedStatus= new List<String>();
      }
    

      User currentUser = [SELECT Business_Unit__c, Region__c, Country__c, ID FROM User WHERE ID =: UserInfo.getUserId()];
      unusedRegions = new Set<String>{Constants.REGION_LATIN_AMERICA, Constants.REGION_GLOBAL};
     // mapOppRoleAndAddress = new Map<Id, Map<String,Opportunity_Contact_Address__c>>(); NLG - old functionality prior to creating Order__c.Shipping_Address__c
      if (currentUser.Region__c != null && !unusedRegions.contains(currentUser.Region__c)) {
        selectedRegion = currentUser.Region__c; 
        //Added by Richard
        currentUserRegion = currentUser.Region__c;
      }
      if (currentUser.Business_Unit__c != null) {
        selectedBusinessUnits.add(currentUser.Business_Unit__c);
      }
      if (currentUser.Country__c != null) {
        selectedCountries.add(currentUser.Country__c);
      }
      //RJ Case # 00586159- To add a new filter for EMEA to check the Order Product's BL for EDQ Product. 
     ordersWithEDQProducts = false; 
  
      size = 400;
      initPicklists();
      getBatches();
    }
      
      
    //===========================================================================
    // Init method to initialize all the things
    //===========================================================================
    public void initPicklists () {
      BATCH_CONDITION_ORDER_NOT_SELECTED = Label.EXPORT_BATCH_FILTER_ORDER_PREV_NOT_EXPORTED;
      BATCH_CONDITION_ORDER_PREV_SELECTED = Label.EXPORT_BATCH_FILTER_ORDER_PREV_EXPORTED;
      BATCH_CONDITION_SELECT_BATCH_NO = Label.EXPORT_BATCH_FILTER_SELECT_A_BATCH_NO;
      queryString = '';
      selectedOrders = new Set<String>();
      regionOptions = new List<SelectOption>();
      countryOptions = new List<SelectOption>();
      businessUnitOptions = new List<SelectOption>();
      User usr = new User();
      regionOptions.add(new SelectOption('', Label.EXPORT_BATCH_FILTER_ALL));
      for (SelectOption picklistValue: DescribeUtility.getPicklistValues(usr, 'Region__c')) {
        if (!unusedRegions.contains(picklistValue.getValue())) {
          regionOptions.add(picklistValue);
        }
      }
      if (selectedBusinessUnits.isEmpty()) {
        selectedBusinessUnits.add(Label.EXPORT_BATCH_FILTER_ALL);
      }
      countryOptions.add(new SelectOption('', Label.EXPORT_BATCH_FILTER_ALL));
      businessUnitOptions.add(new SelectOption('--All--', Label.EXPORT_BATCH_FILTER_ALL));
       
      for (SelectOption picklistValue: DescribeUtility.getPicklistValues(usr, 'Country__c')) {
        countryOptions.add(picklistValue);
      }
      
      for (SelectOption picklistValue: DescribeUtility.getPicklistValues(usr, 'Business_Unit__c')) {
        businessUnitOptions.add(picklistValue);
      }
      
      statusOptions = new List<SelectOption>();
      statusOptions.add(new SelectOption('', Label.EXPORT_BATCH_FILTER_ALL));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_ACT_REQD, Label.EXPORT_BATCH_FILTER_ACT_REQD));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_PLANNED, Label.EXPORT_BATCH_FILTER_PLANNED));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_LIVE, Label.EXPORT_BATCH_FILTER_LIVE));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_EXPIRED, Label.EXPORT_BATCH_FILTER_EXPIRED));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_CANCELLED, Label.EXPORT_BATCH_FILTER_CANCELLED));
      //RJ- Case # 607717- Changes to credit process -Changed status from Credit to 'Credit Note'
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_CREDITED, Label.EXPORT_BATCH_FILTER_CREDITED));
      statusOptions.add(new SelectOption(Label.EXPORT_BATCH_FILTER_CREDIT_NOTE, Label.EXPORT_BATCH_FILTER_CREDIT_NOTE));
  
      batchRecOptions = new List<SelectOption>();
      batchRecOptions.add(new SelectOption('', Label.EXPORT_BATCH_FILTER_SELECT));
      batchRecOptions.add(new SelectOption(BATCH_CONDITION_ORDER_NOT_SELECTED, BATCH_CONDITION_ORDER_NOT_SELECTED));
      batchRecOptions.add(new SelectOption(BATCH_CONDITION_ORDER_PREV_SELECTED, BATCH_CONDITION_ORDER_PREV_SELECTED));
      batchRecOptions.add(new SelectOption(BATCH_CONDITION_SELECT_BATCH_NO, BATCH_CONDITION_SELECT_BATCH_NO));
  
      orderDateOptions = new List<SelectOption>();
      orderDateOptions.add(new SelectOption('', Label.EXPORT_BATCH_FILTER_SELECT));
      orderDateOptions.add(new SelectOption('Null', Label.EXPORT_BATCH_FILTER_OPEN_ORDERS));
      orderDateOptions.add(new SelectOption('Not Null', Label.EXPORT_BATCH_FILTER_CLOSED_ORDERS));
      orderDateOptions.add(new SelectOption('Specific Date', Label.EXPORT_BATCH_FILTER_SPEC_DATE));
      orderDateOptions.add(new SelectOption('Date Range Include', Label.EXPORT_BATCH_FILTER_DATE_RANGE_INCL));
      orderDateOptions.add(new SelectOption('Date Range Exclude', Label.EXPORT_BATCH_FILTER_DATE_RANGE_EXCL));
  
      sizeOptions = new List<SelectOption>();
      sizeOptions.add(new SelectOption('10', '10'));
      sizeOptions.add(new SelectOption('25', '25'));
      sizeOptions.add(new SelectOption('50', '50'));
      sizeOptions.add(new SelectOption('100', '100'));
      sizeOptions.add(new SelectOption('200', '200'));
      sizeOptions.add(new SelectOption('400', '400'));
      sizeOptions.add(new SelectOption('1000', '1000'));
    }
  
    //===========================================================================
    // Standard Set Controller
    //===========================================================================
    public ApexPages.StandardSetController setCon {
      get {
        if (setCon == null) {
  
          Set<String> filterSet = new Set<String>();
          //Filter with region
          if (!String.isBlank(selectedRegion)) {
            filterSet.add(' Owner_Region__c =: selectedRegion ');
          }
        // Tyaga Pati 00540660 - Made the status multiselectable
        if (!selectedStatus.isEmpty() && selectedStatus[0] != '--All--') {
                     system.debug('selectedBusinessUnits === is not blank:'+selectedBusinessUnits);
                    if (!String.isBlank(selectedStatus[0])) { 
                    filterSet.add(' Status__c In: selectedStatus ');
                    }
                  }
    
         // RJ 00540660 -  Case # 00586159- To add a new filter for EMEA to check the Order Product's BL for EDQ Product.
        if (ordersWithEDQProducts && !String.isBlank(selectedRegion) && selectedRegion=='EMEA' ) {
                     system.debug('ordersWithEDQProducts === is true:'+ordersWithEDQProducts);
                     
                    filterSet.add(' Count_of_EDQ_Products__c > 0 ');
                    
                  }
          //Filter with country
          if (!selectedCountries.isEmpty()){
            system.debug('selected country is not blank');
            if (!String.isBlank(selectedCountries[0])) {
              filterSet.add(' Owner_Country__c In :selectedCountries ');
            }
          }
          
          //Filter with Business_Unit__c
          if (!selectedBusinessUnits.isEmpty() && selectedBusinessUnits[0] != '--All--') {
             system.debug('selectedBusinessUnits === is not blank:'+selectedBusinessUnits);
            if (!String.isBlank(selectedBusinessUnits[0])) {
              filterSet.add('Owner_Business_Unit__c In :selectedBusinessUnits ');
            }
          }
          
          //Filter with date (close date)
          if (!String.isBlank(selectedOrderDate)) {
            if (selectedOrderDate == 'Null') {
              filterSet.add(' Close_Date__c = null ');
            } else if (selectedOrderDate == 'Not Null') {
              filterSet.add(' Close_Date__c != null ');
            } else if (selectedOrderDate == 'Null Or Not Null') {
              filterSet.add(' (Close_Date__c = null OR Close_Date__c != null) ');
            } else if(selectedOrderDate == 'Specific Date') {
              if(!String.isBlank(selectedClosedDate)){
                String startDate = convertStringToDate(selectedClosedDate);
                filterSet.add(' Close_Date__c ='+ startDate + ' ');
              }
            } else if (selectedOrderDate == 'Date Range Include') {
              if (!String.isBlank(dateRange1) && !String.isBlank(dateRange2)) {
                String startDate = convertStringToDate(dateRange1);
                String endDate = convertStringToDate(dateRange2);
                filterSet.add(' Close_Date__c >= '+startDate+' AND Close_Date__c <= '+endDate+' ');
              }
  
            } else if (selectedOrderDate == 'Date Range Exclude') {
               if (!String.isBlank(dateRange1) && !String.isBlank(dateRange2)) {
                 String startDate = convertStringToDate(dateRange1);
                 String endDate = convertStringToDate(dateRange2);
                 filterSet.add(' (Close_Date__c <= '+startDate+' OR Close_Date__c >= '+endDate+') ');
               }
            }
          }
        
 // Added By Tyaga Pati to expose Filter by Credited Date Option:  Only Options are add a date to the filter or not.
          if (!String.isBlank(selectedCreditedStaDate)&&!String.isBlank(selectedCreditedEndDate)) {
          
              String StartDate = convertStringToDate(selectedCreditedStaDate);
              String EndDate = convertStringToDate(selectedCreditedEndDate);
              filterSet.add(' Credited_Date__c >= '+startDate+' AND Credited_Date__c <= '+endDate+' '); 
           
          }
        
        

          //Query for Batch filter
          if (!String.isBlank(selectedBatchRecLink)) {
            if (selectedBatchRecLink == BATCH_CONDITION_ORDER_NOT_SELECTED) {
              filterSet.add(' Finance_Invoice_Export_Batch__c = null ');
            } else if (selectedBatchRecLink == BATCH_CONDITION_ORDER_PREV_SELECTED) {
              filterSet.add(' Finance_Invoice_Export_Batch__c != null ');
            } else if (selectedBatchRecLink == BATCH_CONDITION_SELECT_BATCH_NO && !String.isBlank(specificBatchNo)) {
              String spcBtNo = '%'+specificBatchNo;
              filterSet.add(' Finance_Invoice_Export_Batch__r.Name Like \'%' + specificBatchNo + '\' ');
            } 
          }
          
          //RJ - Case 00562256- Exclude Free trail from export page.
          Set<String> typeToExclude = new Set<String>{Label.EXPORT_BATCH_FILTER_TRIAL,Label.EXPORT_BATCH_FILTER_FREETRIAL};
           If(typeToExclude.size()>0)
                filterSet.add('Type__c NOT IN :typeToExclude ');
           //RJ- Case # 607717- Changes to credit process. Added filter to exclude Credited Orders
          /* Set<String> statusToExclude = new Set<String>{Label.EXPORT_BATCH_FILTER_CREDITED};
           If(statusToExclude.size()>0)
                filterSet.add('status__c NOT IN :statusToExclude '); */
           
           
           
          /*Set<String> bus = getBUs(new Set<String>{Constants.EDQ});  NLG Removed 2015-01-02 because Business_Unit__c filter was added since
          if (bus.size() > 0) {
            String buFilter = ' Owner_BU_on_Order_Create_Date__c in : bus';
            filterSet.add(buFilter);
          }*/
  
          String whereClause = '';
          if (filterSet.size() > 0) {
            Integer i = 0;
            whereClause = ' WHERE ';
            for (String filterString: filterSet) {
              if (i == 0) {
                whereClause += filterString; // filterString would look like ' Close_Date__c > '+startDate+' AND Close_Date__c < '+endDate+' ';
              } else {
                whereClause += ' AND ' + filterString;
              }
              i++;
            }
          }
          //If no query built above //Contact__c, OwnerId,
          if (String.isBlank(queryString)) {
            queryString = 'SELECT ID, Finance_Invoice_Export_Batch__c, Finance_Invoice_Export_Batch__r.Name, Owner.FirstName, Owner.LastName,' //
                               +' Status__c, Account__r.Name, Account__c, Name, Close_Date__c,Credited_Date__c, Total__c, Billing_Account__c,'
                               +' Exported_for_Invoicing__c, Invoice_to_End_User__c, Order_Number__c,' //
                               +' Owner_BU_on_Order_Create_Date__c ,Owner_Business_Unit__c, Opportunity__c, Billing_Address__c, Shipping_Address__c,'
                               +' Billing_Address__r.Name, Shipping_Address__r.Name, PO_Number__c, Contract_Start_Date__c FROM Order__c '
                               + whereClause
                               +' ORDER BY Name LIMIT 2000'; // LIMIT ' + filterLimit;
            system.debug('--rebuild query--- Tyaga'+queryString);
             system.debug('--selectedCountries---'+ selectedCountries);
          } 
          //List<Order__c> allOrders = Database.query(queryString);
          
          System.debug('--queryString--Tyaga'+queryString);
          //setCon = new ApexPages.StandardSetController(getEDQOrders(allOrders));
          setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
          setCon.setPageSize(size);
          noOfRecords = setCon.getResultSize();
        }
        return setCon;
      }set;
    }
  
    /*private static Set<String> getBUs(Set<String> busToQuery) {  NLG Removed 2015-01-02 because Business_Unit__c filter was added since
      Set<String> bus = BusinessUnitUtility.getBUsFromGroupNames(busToQuery);
      return bus;
    }*/

    /*private static List<Order__c> getEDQOrders(List<Order__c> orders) {
      Set<String> BUs = new Set<String>();
      List<Order__c> edqOrders = new List<Order__c>();
      for (Order__c ordr: orders) {
        if (ordr.Owner_BU_on_Order_Create_Date__c != null) {
          BUs.add(ordr.Owner_BU_on_Order_Create_Date__c);
        } 
      }
      Map<String, String> busMapping = BusinessUnitUtility.getGroupNameForBusinessUnits(BUs);
      for (Order__c ordr: orders) {
        if (ordr.Owner_BU_on_Order_Create_Date__c != null && 
            busMapping.get(ordr.Owner_BU_on_Order_Create_Date__c) == 'EDQ') {
          edqOrders.add(ordr);   
        }
      }
      return edqOrders;
    }*/
  
    //===========================================================================
    // Manipulating date for string to date creation
    //===========================================================================  
    private Date setStringToDateFormat(String myDate) {
     String[] strDate = myDate.split('/');
     Integer myIntDate = integer.valueOf(strDate[0]);
     Integer myIntMonth = integer.valueOf(strDate[1]);
     Integer myIntYear = integer.valueOf(strDate[2]);
     Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
     return d;
    }
    
    //===========================================================================
    // Creation date format to be used on page for JS
    //===========================================================================  
    public String convertStringToDate( String DateInString ){
      String[] dts = DateInString.split('/');
      return dts[2]+'-'+dts[0]+'-'+dts[1];
    }
     
    //===========================================================================   
    //Adding selected records to set to keep track on all the pages.
    //===========================================================================    
    public void addSelected () {
      if (batchList ==  null) 
        batchList = new List<orderWrapper>();  
  
      for (orderWrapper ord : batchList) {
        if (ord.selected) {
          selectedOrders.add(ord.order.ID);
        } else if (!ord.selected && selectedOrders.contains(ord.order.ID)) {
          selectedOrders.remove(ord.order.ID);
        }
      }   
    }
    
    //===========================================================================    
    //Fetching batches and adding selected.
    //===========================================================================    
    public List<orderWrapper> getBatches() {
      //selectedOrderMap = new Map<ID, orderWrapper>();
  
      addSelected();
      
      batchList = new List<orderWrapper>();
      
      orderWrapper ordWrapObj;
      Boolean preSelected;
      set<Id> setOpportunityIds = new set<Id>();
      //Check Opportunity Adress in existing map
      /* NLG - old functionality prior to creating Order__c.Shipping_Address__c
      for (Order__c o : (List<Order__c>)setCon.getRecords()) {
        if (!mapOppRoleAndAddress.containsKey(o.Opportunity__c)) {
          setOpportunityIds.add(o.Opportunity__c);  
        }
      }
      Map<String, Map<String, Address__c>> mapShippingTypeToOrderToAddress = new Map<String, Map<String, Address__c>>();
      //Fetch address from Opportunity_Contact_Address__c where Role is Purchase Ledger or Commmercial
      if (!setOpportunityIds.isEmpty()){
        for(Opportunity_Contact_Address__c oppConAddr : [SELECT Role__c, Address__c, Opportunity__c, Contact__r.Name, 
                                                                Address__r.Address_2__c, Address__r.Address_1__c, 
                                                                Address__r.Country__c, Address__r.City__c, 
                                                                Address__r.State__c, Address__r.Zip__c, Address__r.Name
                                                         FROM Opportunity_Contact_Address__c
                                                         WHERE Opportunity__c IN : setOpportunityIds
                                                         AND (Role__c =: Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER 
                                                         OR  Role__c =: Constants.OPPTY_CONTACT_ROLE_COMMERCIAL)]){
          if(!mapOppRoleAndAddress.containsKey(oppConAddr.Opportunity__c)){
            //mapOppRoleAndAddress.put(oppConAddr.Opportunity__c, new Map<String, Opportunity_Contact_Address__c>());
          }
          //mapOppRoleAndAddress.get(oppConAddr.Opportunity__c).put(oppConAddr.Role__c, oppConAddr);
          
        }
      }*/
      Opportunity_Contact_Address__c oppContactAddress;
      for (Order__c o : (List<Order__c>)setCon.getRecords()) {
        preSelected = false;
        if (selectedOrders.contains(o.ID)) {
          preSelected = true;
        }
        if (o.Finance_Invoice_Export_Batch__c != null) {
          ordWrapObj = new orderWrapper(o, preSelected, new Export_Batch__c(ID = o.Finance_Invoice_Export_Batch__c, Name = o.Finance_Invoice_Export_Batch__r.Name));
        } else {
          ordWrapObj = new orderWrapper(o, preSelected, null);
        }
        
        /*if (mapOppRoleAndAddress.containsKey(o.Opportunity__c)) {
          //Populate Billing Address from Purchase Ledger Role
          if(mapOppRoleAndAddress.get(o.Opportunity__c).containsKey(Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER)){
            oppContactAddress = mapOppRoleAndAddress.get(o.Opportunity__c).get(Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER);
            ordWrapObj.billingAddress = oppContactAddress.Address__r.Name; //prepareAddress(oppContactAddress);
            ordWrapObj.billingAddressId = oppContactAddress.Address__c;
          }
          //Populate Shipping Address from Commercial Role
          if(mapOppRoleAndAddress.get(o.Opportunity__c).containsKey(Constants.OPPTY_CONTACT_ROLE_COMMERCIAL)){
            oppContactAddress = mapOppRoleAndAddress.get(o.Opportunity__c).get(Constants.OPPTY_CONTACT_ROLE_COMMERCIAL);
            ordWrapObj.shippingAddress = oppContactAddress.Address__r.Name; //prepareAddress(oppContactAddress);
            ordWrapObj.shippingAddressId = oppContactAddress.Address__c;
          }
        }*/
        
        batchList.add(ordWrapObj);
      }
      return batchList;
    }
    
    //===========================================================================    
    //Refresh country picklist when region changes
    //=========================================================================== 
    public PageReference resetCountry() {
      selectedCountries.clear();
      selectedCountries.add('');
      return null;
    }
    
    
    public PageReference resetBusinessUnit() {
      selectedBusinessUnits.clear();
      selectedBusinessUnits.add('');
      return null;
    }
    //===========================================================================    
    //Refresh works like reset
    //===========================================================================    
    public pageReference refresh() {
      setCon = null;
      selectedOrders = new Set<String>();
      batchList = new List<orderWrapper>();
      getBatches();
      setCon.setPageNumber(1);
      return null;
    }
    
    //===========================================================================    
    //Searching orders
    //===========================================================================    
    public pageReference searchOrders () {
      //filterLimit = '1200';
      setCon = null;
      selectedOrders = new Set<String>();
      batchList = new List<orderWrapper>();
      getBatches();
      setCon.setPageNumber(1);
      return null;    
    }
  
    //===========================================================================  
    //Refresh works like reset
    //===========================================================================    
    public pageReference exportBatchSearch() {
        
      Integer currentPage = Integer.valueOf(setCon.getPageNumber());
      setCon = null;
      batchList = new List<orderWrapper>();
      getBatches();
      setCon.setPageNumber(currentPage);
      return null;
    }
  
    //===========================================================================    
    //Exporting batches
    //===========================================================================    
    public PageReference exportBatches () {
      addSelected();
      System.debug('~~~Batches~~##~'+batchList);
      if (batchList.size() > 0) {
        Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        Integer currentBatchNumber = Integer.valueOf(custSettings.Lastest_Batch_Number__c)+1;
        List<Export_Batch__c> newBatches = new List<Export_Batch__c>();
        Map<String, String> orderId_BatchMap = new Map<String, String>();
        Export_Batch__c currentBatch =  new Export_Batch__c();
        
        //Creating new batches for selected orders
        for (orderWrapper ordWrap : batchList) {
          if(ordWrap.selected) {
              if(!orderId_BatchMap.containsKey(ordWrap.order.ID)) {
                  orderId_BatchMap.put(ordWrap.order.ID, null);
              }
            if (String.isBlank(currentBatch.Name)) {
              currentBatch.Name = 'Batch #'+currentBatchNumber;
            }
          }
        }
  
        //Creating savepoint
        Savepoint sp = Database.setSavepoint();
        try {
          System.debug('####size####'+orderId_BatchMap.keySet().size());
            //Inserting new batches
            if(orderId_BatchMap.keySet().size() > 0) {
              //insert newBatches;
              insert currentBatch;
              List<Order__c> orderToUpdate = new List<Order__c>();
              //for (String ordId : orderId_BatchMap.keySet()) {
              for (String ordId : selectedOrders) {
                  orderToUpdate.add(new Order__c(ID = ordId, Finance_Invoice_Export_Batch__c = currentBatch.ID));
              }
              System.debug('~~~~orders~~~'+orderToUpdate);
              update orderToUpdate;

              custSettings.Lastest_Batch_Number__c = currentBatchNumber;
              update custSettings;
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                        Label.BATCH_ORDER_SELECTION_SUCCESS + 
                                                        '<a href="/'+currentBatch.ID+'" target="_blank">'+currentBatch.Name+'</a>'));
                //Changes by Richard  starts                              
                /*ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                    Label.EXPORT_BATCH_MSG_FILE_GENERATED +' ' + 
                                                        '<a href="/apex/ExportBatchExtractProcess?batchid='+currentBatch.ID+'&ExportFile=CustomerFile'+'" target="_blank">'+'ReportExport'+'</a>'));    
                */
                generatedBatchId =  currentBatch.ID;
                //Changes Ends
              exportBatchSearch();
              return null; 
            }
        } catch (Dmlexception ex) {
          System.debug('Exception:[BatchOrderListController][exportBatches]:' + ex.getMessage());
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
          Database.rollback(sp);
        }
      }
      return null;
    }

    public Boolean hasNext {
      get {
        return setCon.getHasNext();
      }
      set;
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

    //===========================================================================     
    // Wrapper: To hold order and its batch along with selection
    //===========================================================================    
    public class orderWrapper {
      public Order__c order           {get;set;}
      public Boolean selected         {get;set;}
      public Export_Batch__c batch    {get;set;}
      public Boolean isBatch          {get;set;}
      /*public Id billingAddressId {get;set;}
      public Id shippingAddressId{get;set;}
      public String billingAddress    {get;set;}
      public String shippingAddress   {get;set;}*/

      public orderWrapper (Order__c ord, Boolean isSel, Export_Batch__c bat) {
        order = ord;
        if (isSel) {
          selected = true;
        } else {
          selected = false;
        }
        
        if (bat != null) {
          batch = bat;
          isBatch = true;
        } else {
          isBatch = false;
        }
      }
    }
   

}