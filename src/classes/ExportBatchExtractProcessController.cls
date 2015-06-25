/******************************************************************************
 * Name: ExportBatchExtractProcessController 
 * Description: S-254156
 * Created Date: Oct 20th, 2014
 * Created By: Richard
 * Description : Class to Query , Extract and Format all Oracle finance report extract CSV files.
 * Change Log- 
 * Feb 11th 2015 Richard Joseph  Case # 00553884- This is to derive customer site value based on billing EDQ Integration ID for UK.
 * Feb 12th 2015 Richard Joseph Case # 00554006- To change the process to refer Global_Unique_ID__c if the Experian_ID__c is SFDC ID. If its EDQ ID then will pass the same.
 * Feb 18th 2015 Richard Jospeph Case # 00562967 
 * Mar 12th 2015 Richard Joseph  Case 00584024- To change Experian id to all upper case for APAC/EMEA .
 * Apr 16th 2015 Richard Joseph  Remove logic on credited order. Case # 00607717
 * Apr 16th 2015 Richard Joseph   Case # 568901- Changes to RPM file
 * Apr 20th 2015 Richard Joseph   Case # 607717- Changed to credit process -Changed status from Credit to 'Credit Note'
 ******/
public class ExportBatchExtractProcessController {
    public List<string[]> reportDisplayList  {get; set;} // Added by Richard
    public String csvContent  {get; set;} // Added by Richard
    public enum exportFileTypes {RPMFile, SummitFile, RoyaltiesFile,PartnerFile,CustomerFile}    // Added by Richard
    public static Id generatedBatchId {get; set;} 
    public Boolean isComplete {get; set;}
    private set<string> memoLnTypeOfSaleLSet{ get; set;}
    private set<string> memoLnTypeOfSaleISet{ get; set;}
    private string userRegion {get; set;}   
    private boolean isUSRegion {get; set;}
    public String operatingUnitName='';
   
    Public string getfileName() {
      
      User currentUser = [SELECT Region__c,Country__c, ID FROM User WHERE ID =: UserInfo.getUserId()];
       
          
       
     if (currentUser!= null) 
     {
          
        userRegion=(currentUser.Region__c != null ? currentUser.Region__c:'' ); 
       if(currentUser.Country__c!= null) {
        
          if (currentUser.Country__c == 'USA' || currentUser.Country__c == 'United States of America' || currentUser.Country__c == 'United States' || currentUser.Country__c == 'US') {
                 
            operatingUnitName = 'EXP_US_EHI_OU';
            }
            else if (currentUser.Country__c == 'UK' || currentUser.Country__c == 'United Kingdom' ) {
                     
                operatingUnitName='EXP_UK_ELI_OU';

            }
            else if (currentUser.Country__c == 'FR' || currentUser.Country__c == 'France' ) {
            operatingUnitName='EXP_FR_ECS_OU';
               
            }
            else if (currentUser.Country__c == 'NZ' || currentUser.Country__c == 'New Zealand' ) {
                operatingUnitName='EXP_NZ_EAP_OU'; 
            }
            else if (currentUser.Country__c == 'SGP' || currentUser.Country__c == 'Singapore' ) {
                operatingUnitName='EXP_SG_EAP_OU';
                 
            }
            else if (currentUser.Country__c == 'AU' || currentUser.Country__c == 'Australia' ) {
                operatingUnitName='EXP_AU_EAP_OU';
                 
            }
            else if (currentUser.Country__c == 'NL' || currentUser.Country__c == 'Netherlands' ) {
                operatingUnitName='EXP_NL_ENL_OU';
                
                
            }
            
      } 
          //getOperatingUnitValue();
         
      } 
      
        String currentFileType = ApexPages.currentPage().getParameters().get('ExportFile');
            If(currentFileType==exportFileTypes.CustomerFile.name())
            {   
                      
                     return 'EXP_UN_CUSTOMERS_QAS_'+operatingUnitName+Datetime.now().format('ddMMYYYYHHMMSS');
             }
            else if (currentFileType==exportFileTypes.PartnerFile.name()){
                     return 'EXP_UN_PARTNER_COMMISSION_QAS_'+operatingUnitName+Datetime.now().format('ddMMYYYYHHMMSS');
            }
            else if (currentFileType==exportFileTypes.RoyaltiesFile.name()){
                 return 'EXP_UN_ROYALTIES_QAS_'+operatingUnitName+Datetime.now().format('ddMMYYYYHHMMSS');
            }
            else if (currentFileType==exportFileTypes.SummitFile.name()){
                    return 'EXP_UN_TRANSACTION_QAS_'+operatingUnitName+Datetime.now().format('ddMMYYYYHHMMSS');
            }
            else if (currentFileType==exportFileTypes.RPMFile.name()){
                 return 'EXP_RPM_'+Datetime.now().format('ddMMYYYYHHMMSS');
            }
    
        return Datetime.now().format('ddMMYYYYHHMMSS');
    
    }
    
    public PageReference exportFileProcess() {
        
            isComplete=false;
            
            getfileName();
  
            if (userRegion == 'APAC'  || userRegion == 'EMEA' )
                  isUSRegion= false;
             else        
                    isUSRegion= true;
            
            String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
            String currentFileType = ApexPages.currentPage().getParameters().get('ExportFile');
           if(currentBatchId!=null && currentBatchId!= ''){
            If(currentFileType==exportFileTypes.CustomerFile.name())
            {   
                      
                     exportCustFile();   
                     // ApexPages.currentPage().getParameters().put('ExportFile', 'PartnerFile'); 
                     return  null;
            }
            else if (currentFileType==exportFileTypes.PartnerFile.name()){
                      exportPartnerFile();
                     //ApexPages.currentPage().getParameters().put('ExportFile', 'RoyaltiesFile'); 
                     return  null;
            }
            else if (currentFileType==exportFileTypes.RoyaltiesFile.name()){
                 exportRoyaltyFile();
                 //ApexPages.currentPage().getParameters().put('ExportFile', 'SummitFile'); 
                     return  null;
            }
            else if (currentFileType==exportFileTypes.SummitFile.name()){
                     exportSummitFile();
                     //ApexPages.currentPage().getParameters().put('ExportFile', 'RPMFile'); 
                     return  null;
            }
            else if (currentFileType==exportFileTypes.RPMFile.name()){
                 exportRPMFile();
               isComplete=true;
                //ApexPages.currentPage().getParameters().put('ExportFile', 'PartnerFile'); 
                     //return  null;
            }
    
           }
        return null;
    }
   
  //===========================================================================
    // Method to generate EDQ Customer File - Richard Joseph
    //=========================================================================== 
   public PageReference exportCustFile () {

    Report_Extract_Templates__c reportExtractTemplateRec= Report_Extract_Templates__c.getValues('Oracle Customer File');

    Integer fieldCount = 1;
    String queryFieldsStr = '';
    String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
    //Richard TestData 
    //currentBatchId=generatedBatchId;
    
    reportDisplayList = new list<string[]>();
    String fieldValue ='';

    while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
      if (String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) !=null && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('Transform')
      && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('HC--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('DT--') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SQ--') 
       ) 
         queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
     
      fieldCount++;
    }
  
    system.debug('Fields to Retrieve: ' +queryFieldsStr );
  
    String filterStr = 'where Finance_Invoice_Export_Batch__c = \''+currentBatchId +'\'';

    String soqlStr = 'Select '+queryFieldsStr +' ID,Owner_Region__c,Ownerid,Owner_Country__c,Billing_Address__r.Country__c,Billing_Address__r.State__c,Billing_Address__r.EDQ_Integration_Id__c,Account__r.Global_Unique_ID__c   From Order__c '+filterStr ;

    system.debug('SOQL to Fetch: ' +sOQLStr );
    
    generateCSVFile(exportFileTypes.CustomerFile,sOQLStr,reportExtractTemplateRec );
 
        PageReference reDirected = new PageReference('/apex/ExportBatchExtractProcess?BatchID='+currentBatchId+'&ExportFile=RPMFile');
        return reDirected;
    //return null;
   
  } 
  
   //===========================================================================
    // Method to generate EDQ RPM file - Richard Joseph
    //=========================================================================== 
  public PageReference exportRPMFile () {

    Report_Extract_Templates__c reportExtractTemplateRec= Report_Extract_Templates__c.getValues('RPM File');

    Integer fieldCount = 1;
    String queryFieldsStr = '';
    String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
    Integer seqNumber = 0; 
    String todayDate= Datetime.now().format('ddMMYYYY'); 
    //Richard TestData 
    //currentBatchId=generatedBatchId;
    
    reportDisplayList = new list<string[]>();
    String fieldValue ='';
    Set<String> fieldSet = new Set<String>();
    while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
      if (String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) !=null && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('Transform') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('HC--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('DT--') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SQ--') 
                    ) 
                    {
                    String fieldName = String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ));
          
          if( !fieldSet.Contains(fieldName ))      
          {      
         queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
         fieldSet.add(fieldName );
         }
         }
         //queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
     
      fieldCount++;
    }
  
    system.debug('Fields to Retrieve: ' +queryFieldsStr );
  
    String filterStr = 'where Order__r.Finance_Invoice_Export_Batch__c = \''+currentBatchId +'\'';
    //RJ - Case # 568901 changes
    String soqlStr = 'Select '+queryFieldsStr +' ID,Order__r.Billing_Address__r.Country__c,Order__r.Account__r.Name,End_Date__c,Users_From__c,Users_To__c,Quantity_Type__c,Start_Date__c From Order_Line_Item__c '+filterStr ;

    system.debug('SOQL to Fetch: ' +sOQLStr );
    
    generateCSVFile(exportFileTypes.RPMFile,sOQLStr,reportExtractTemplateRec );
  
  //System.debug(reportDisplayList);
    
        PageReference reDirected = new PageReference('/apex/ExportBatchExtractProcess?BatchID='+currentBatchId+'&ExportFile=RoyaltiesFile');
        return reDirected;
    //return null;
    //return page.BatchOrderList;
    
  }
   //===========================================================================
    // Method to generate EDQ Royalties File - Richard Joseph
    //=========================================================================== 
  public PageReference exportRoyaltyFile () {

    Report_Extract_Templates__c reportExtractTemplateRec= Report_Extract_Templates__c.getValues('Oracle Royalties File');

    Integer fieldCount = 1;
    String queryFieldsStr = '';
    String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
    Integer seqNumber = 0; 
    String todayDate= Datetime.now().format('ddMMYYYY');
    //Richard TestData 
    //currentBatchId=generatedBatchId;
    
    reportDisplayList = new list<string[]>();
    String fieldValue ='';
    Set<String> fieldSet = new Set<String>();
    while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
      if (String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) !=null && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('Transform') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('HC--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('DT--') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SQ--') 
                    ) 
                    {
          String fieldName = String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ));
          
          if( !fieldSet.Contains(fieldName ))      
          {      
         queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
         fieldSet.add(fieldName );
         }
         }
      fieldCount++;
    }
  
    system.debug('Fields to Retrieve: ' +queryFieldsStr );
  
    String filterStr = 'where Amount__c != 0 AND Order_line_Item__r.Order__r.Finance_Invoice_Export_Batch__c = \''+currentBatchId +'\'';

    String soqlStr = 'Select '+queryFieldsStr +' ID,Order_line_Item__r.Product__r.Types_of_Sale__c,Order_line_Item__r.Type_of_Sale__c, Order_line_Item__r.Product__r.Family,Order_line_Item__r.Order__r.Type__c,Order_line_Item__r.EDQ_Memo_Line__c,Royalty_Group_Reference__c,Order_line_Item__r.Order__r.Status__c From Royalty__c '+filterStr ;

    system.debug('SOQL to Fetch: ' +sOQLStr );
    
    generateCSVFile(exportFileTypes.RoyaltiesFile,sOQLStr,reportExtractTemplateRec );   
    
  
  //System.debug(reportDisplayList);
    
        PageReference reDirected = new PageReference('/apex/ExportBatchExtractProcess?BatchID='+currentBatchId+'&ExportFile=PartnerFile');
        return reDirected;
    //return null;
    //return page.BatchOrderList;
  }


  //===========================================================================
    // Method to generate EDQ Patner File - Richard Joseph
    //=========================================================================== 
  public PageReference exportPartnerFile () {

    Report_Extract_Templates__c reportExtractTemplateRec= Report_Extract_Templates__c.getValues('Oracle Partner File');

    Integer fieldCount = 1;
    String queryFieldsStr = '';
    String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
    Integer seqNumber = 0; 
    String todayDate= Datetime.now().format('ddMMYYYY');
    //Richard TestData 
    //currentBatchId=generatedBatchId;
    
    reportDisplayList = new list<string[]>();
    String fieldValue ='';
    Set<String> fieldSet = new Set<String>();
    while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
      if (String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) !=null && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('Transform') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('HC--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('DT--') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SQ--') 
                    ) 
                    {
          String fieldName = String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ));
          
          if( !fieldSet.Contains(fieldName ))      
          {      
         queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
         fieldSet.add(fieldName );
         }
         }
      fieldCount++;
    }
  
    system.debug('Fields to Retrieve: ' +queryFieldsStr );
  
    String filterStr = 'where Partner_Amount__c >0 AND Order__r.Finance_Invoice_Export_Batch__c = \''+currentBatchId +'\'';

    String soqlStr = 'Select '+queryFieldsStr +'name,Order__r.Account__r.BillingCountry,Product__r.Types_of_Sale__c, Product__r.Family,'+
                        'Order__r.Type__c,Type_of_Sale__c,EDQ_Memo_Line__c,Order__r.Partner__r.Experian_ID__c,Order__r.Status__c From Order_Line_Item__c '+filterStr ;

    system.debug('SOQL to Fetch: ' +sOQLStr );
    
    
    generateCSVFile(exportFileTypes.PartnerFile,sOQLStr,reportExtractTemplateRec );
  //System.debug(reportDisplayList);

        PageReference reDirected = new PageReference('/apex/ExportBatchExtractProcess?BatchID='+currentBatchId+'&ExportFile=SummitFile');
        return reDirected;
    //return null;
    //return page.BatchOrderList;
  }

 //===========================================================================
    // Method to generate EDQ Summit File - Richard Joseph
    //=========================================================================== 
  public PageReference exportSummitFile () {
  
    Report_Extract_Templates__c reportExtractTemplateRec;
  if(isUSRegion)  
     reportExtractTemplateRec= Report_Extract_Templates__c.getValues('Oracle Transaction (Summit) File');
  else
   reportExtractTemplateRec= Report_Extract_Templates__c.getValues('Oracle Trans (Summit) NON US');
    Integer fieldCount = 1;
    String queryFieldsStr = '';
    String currentBatchId = ApexPages.currentPage().getParameters().get('BatchID');
    Integer seqNumber = 0; 
    String todayDate= Datetime.now().format('ddMMYYYY');
    //Richard TestData 
    //currentBatchId=generatedBatchId;
    
    reportDisplayList = new list<string[]>();
    String fieldValue ='';
    Set<String> fieldSet = new Set<String>();
    while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
      if (String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) !=null && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('Transform') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('HC--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('DT--') 
                  && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SQ--') && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('SF--') 
                    && !String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')).contains('GQ--')) 
                    {
          String fieldName = String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ));
          
          if( !fieldSet.Contains(fieldName ))      
          {      
         queryFieldsStr=queryFieldsStr +String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c' ))+',';
         fieldSet.add(fieldName );
         }
         }
      fieldCount++;
    }
  
    system.debug('Fields to Retrieve: ' +queryFieldsStr );
  
    String filterStr = 'where Order__r.Finance_Invoice_Export_Batch__c = \''+currentBatchId +'\'';

    String soqlStr = 'Select '+queryFieldsStr +'name,id ,Order__r.id, Operating_System__c,Product__r.Types_of_Sale__c, Product__r.Family,Order__r.Type__c,Order__r.Shipping_Contact__c,'+
                        'Type_of_Sale__c,Users_To__c, Users_From__c, End_Date__c,Quantity_Type__c,Order__r.Owner_Country__c,Order__r.Contact__r.email,Order__r.Billing_Contact__r.email,'+
                        'Order__r.Billing_Address__c, Order__r.Shipping_Address__c,Order__r.Account__r.Global_Unique_ID__c,Order__r.Shipping_Address__r.State__c,'+
                        'Order__r.Billing_Address__r.EDQ_Integration_Id__c From Order_Line_Item__c '+filterStr + ' Order by Order__r.Name , Name' ;

    system.debug('SOQL to Fetch: ' +sOQLStr );
        
    generateCSVFile(exportFileTypes.SummitFile,sOQLStr,reportExtractTemplateRec );
  //System.debug(reportDisplayList);

        PageReference reDirected = new PageReference('/'+currentBatchId);
        return reDirected;
    //return null;
    
  }
    
    
//===========================================================================
    // Method to generate CSV File - Richard Joseph
    //=========================================================================== 
  public PageReference generateCSVFile (exportFileTypes fileType , string queryString, Report_Extract_Templates__c reportExtractTemplateRec) {

      system.debug('SOQL to Fetch: ' +queryString );


    Integer fieldCount = 1;
    Integer seqNumber = 0; 
    String todayDate= Datetime.now().format('ddMMYYYY');
    reportDisplayList = new list<string[]>();
    String fieldValue ='';
    Set<String> fieldSet = new Set<String>();
    Integer orderGroupNumber = 1;
    String runningOrderId =null;
    String prevOrderId= null;
  Map<String,String> countryCodeMap = new Map<String,String>();
  Map<String,String> stateCodeMap = new Map<String,String>();
  //getfileName();
    
    List<sObject> sobjList = Database.query(queryString );
    csvContent = '';
  //prerequisite
  //to get OU 
  getOperatingUnitValue();
  // to populate memoLnTypeOfSaleISet and memoLnTypeOfSaleLSet  
       Report_Extract_Templates__c MemoLnTypeOfSale= Report_Extract_Templates__c.getValues('MemoLnTypeOfSaleI');
  //To Populate Country Code from Custom Setting.
    List<Country_Codes__c> countryCodesList = Country_Codes__c.getall().values();
    For(Country_Codes__c countryCodesRec:countryCodesList ) 
    {
      If(countryCodesRec.Name!= null && countryCodesRec.Country_Code__c != null )
        countryCodeMap.put(countryCodesRec.Name,countryCodesRec.Country_Code__c);
      
    }  
    
   //To Populate State Code from Custom Setting.
    List<State_Codes__c> stateCodesList = State_Codes__c.getall().values();
    For(state_Codes__c stateCodesRec:stateCodesList ) 
    {
      If(stateCodesRec.Name!= null && stateCodesRec.state_Code__c != null )
        stateCodeMap.put(stateCodesRec.Name,stateCodesRec.state_Code__c);
      
    }   
       memoLnTypeOfSaleISet = new Set<string>();
       while (fieldCount < 100  && String.valueOf(MemoLnTypeOfSale.get('Col'+fieldCount+'__c')) != 'EOF' ) {
     
                    
          String saleTypeValue = String.valueOf(MemoLnTypeOfSale.get('Col'+fieldCount+'__c' ));
          
          if(memoLnTypeOfSaleISet != null &&  !memoLnTypeOfSaleISet.Contains(saleTypeValue ) && saleTypeValue != null)      
          {      
         
            memoLnTypeOfSaleISet.add(saleTypeValue);
         }
         
      fieldCount++;
    }
    
    fieldCount = 1;
      MemoLnTypeOfSale= Report_Extract_Templates__c.getValues('MemoLnTypeOfSaleL');
       memoLnTypeOfSaleLSet = new Set<string>();
       while (fieldCount < 100  && String.valueOf(MemoLnTypeOfSale.get('Col'+fieldCount+'__c')) != 'EOF' ) {
     
                    
          String saleTypeValue = String.valueOf(MemoLnTypeOfSale.get('Col'+fieldCount+'__c' ));
          
          if(memoLnTypeOfSaleLSet != null &&  !memoLnTypeOfSaleLSet.Contains(saleTypeValue ) && saleTypeValue != null)      
          {      
         
            memoLnTypeOfSaleLSet.add(saleTypeValue);
         }
         
      fieldCount++;
    }
     
     
//Extract all RPM codes
Map<String, RPM_Product_Code__c> rpmCodes= RPM_Product_Code__c.getAll();      

  
 // Content Generation  
    for (sObject sObjectRec:sobjList)
    {
      List<string> displayLine = new List<String>();
      fieldCount = 1;
      String cloneCSVRowContent = '';
      String fieldName= '';
      fieldValue='';
      while (fieldCount < 100  && String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c')) != 'EOF' ) {
  
        fieldName = String.valueOf(reportExtractTemplateRec.get('Col'+fieldCount+'__c'));
        if (fieldName!=null && !fieldName.contains('Transform') && !fieldName.contains('HC--') && !fieldName.contains('DT--') && !fieldName.contains('SQ--') && !fieldName.contains('DT--') && !fieldName.contains('SF--') && !fieldName.contains('GQ--') ) {
          if (!fieldName.contains('.')) {
            fieldValue = (String.valueOf(sObjectRec.get (fieldName)) != null ? String.valueOf(sObjectRec.get (fieldName)) : ''  );
            
             if( fieldName != null && fieldName.contains('_Date_') ) 
            {
                displayLine.add(datetime.valueof(fieldValue).format('ddMMYYYY') );
            csvContent =csvContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            }
             else if( fieldName == 'Total__c')
             {
             displayLine.add(String.valueOf(sObjectRec.get (fieldName)));
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
            
            
            }
            else if ((fileType == exportFileTypes.SummitFile) && (fieldName  == 'CRM_Product_Name__c') ){
              
              if(fieldValue != null )
                  fieldValue = fieldValue  + ' '+  (String.valueOf(sObjectRec.get ('Operating_System__c')) != null ? String.valueOf(sObjectRec.get ('Operating_System__c')) : ''  );
              
              String licStr = 'License Period to:';
              if (!isUSRegion )
              {
                fieldValue =fieldValue+ '|'+ 'License Period to:';
                fieldValue =fieldValue+(String.valueOf(sObjectRec.get ('End_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('End_Date__c'))).format('MM/dd/YYYY') : ''  ); 
                fieldValue =fieldValue+'|';
                fieldValue =fieldValue+(String.valueOf(sObjectRec.get ('Users_From__c')) != null ? String.valueOf(sObjectRec.get ('Users_From__c')) : ''  );
                fieldValue =fieldValue+ ' to ';
                fieldValue =fieldValue+ (String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + ' ';
                fieldValue =fieldValue+ (String.valueOf(sObjectRec.get ('Quantity_Type__c')) != null ? String.valueOf(sObjectRec.get ('Quantity_Type__c')) : ''  ) ;
              }
              
               licStr=licStr+(String.valueOf(sObjectRec.get ('End_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('End_Date__c'))).format('MM/dd/YYYY') : ''  ) + ' , ';
               
               licStr=licStr+(String.valueOf(sObjectRec.get ('Users_From__c')) != null ? String.valueOf(sObjectRec.get ('Users_From__c')) : ''  ) + ' to ';
               
               licStr=licStr+(String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + ' ';
              
              licStr=licStr+(String.valueOf(sObjectRec.get ('Quantity_Type__c')) != null ? String.valueOf(sObjectRec.get ('Quantity_Type__c')) : ''  ) + ' ';
              
             
                  displayLine.add(fieldValue );
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+licStr +'\",';
                  
                  
              }  
            else if(( fieldName == 'Delivery_Method__c') && (fileType == exportFileTypes.SummitFile))
             {
              String delvryMethod = '';
              //RJ - Made change to male Electronic as the default value
                //If(fieldValue!=null && fieldValue!='')
                //{
                  if (fieldValue==null || fieldValue==''|| fieldValue =='E - Mail' || fieldValue =='FTP Download'  ||fieldValue.contains('Electronic') || fieldValue=='Not Required')
                     fieldValue='ELECTRONIC';
                     else
                      fieldValue='TANGIBLE';
                //} 
             displayLine.add(fieldValue);
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
            
            
            }
            else if( (fieldName == 'Sales_Price__c') && (fileType == exportFileTypes.SummitFile) )
            {
            //RJ- Case 00607717
            //if(sObjectRec.getSobject('Order__r')!= null && sObjectRec.getSobject('Order__r').get('status__c') == 'Credited' )
                if(sObjectRec.getSobject('Order__r')!= null && sObjectRec.getSobject('Order__r').get('status__c') == 'Credit Note' )
                {
                    displayLine.add(fieldValue);
                 //RJ -Case # 00607717 Changed Credited process to behave the same way as normal order
                 //csvContent =csvContent +'\"-'+fieldValue +'\",';
                //cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
                csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }else
                {
                    displayLine.add(fieldValue);
                 csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }
            }
            else if(( fieldName == 'Partner_Amount__c') && (fileType == exportFileTypes.PartnerFile))
            {
                //RJ- Case 00607717
                //if(sObjectRec.getSobject('Order__r')!= null && sObjectRec.getSobject('Order__r').get('status__c') == 'Credited' ){
                if(sObjectRec.getSobject('Order__r')!= null && sObjectRec.getSobject('Order__r').get('status__c') == 'Credit Note' ){
                displayLine.add(fieldValue);
                // //RJ -Case # 00607717 Changed Credited process to behave the same way as normal order
                 //csvContent =csvContent +'\"-'+fieldValue +'\",';
                 //cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                 csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
                }
            else
            {
                 displayLine.add(fieldValue);
                 csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
                }
            }
            else if( (fieldName == 'Amount__c') && (fileType == exportFileTypes.RoyaltiesFile))
            {
                    
                //RJ- Case 00607717
                //if(sObjectRec.getSobject('Order_Line_item__r')!= null && sObjectRec.getSobject('Order_Line_item__r').getSobject('Order__r')!= null&& sObjectRec.getSobject('Order_Line_item__r').getSobject('Order__r').get('status__c') == 'Credited' )
                if(sObjectRec.getSobject('Order_Line_item__r')!= null && sObjectRec.getSobject('Order_Line_item__r').getSobject('Order__r')!= null&& sObjectRec.getSobject('Order_Line_item__r').getSobject('Order__r').get('status__c') == 'Credit Note' )
                {
                
                displayLine.add(fieldValue);
                //RJ -Case # 00607717 Changed Credited process to behave the same way as normal order
                 //csvContent =csvContent +'\"-'+fieldValue +'\",';
                //cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
                }
            else
            {
                 displayLine.add(fieldValue);
                 csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"-'+fieldValue +'\",';
                }
            }else if ((fileType == exportFileTypes.RPMFile) && (fieldName  == 'CRM_Product_Name__c') ){
                  
                  String licStr='';
                 
              if(fieldValue != null )                 
              licStr = fieldValue+',  ' ;
              
              licStr=licStr+(String.valueOf(sObjectRec.get ('Users_From__c')) != null ? String.valueOf(sObjectRec.get ('Users_From__c')) : ''  ) + ' to ';
              
              //RJ - Case # 00568901- Took off the ","  and replaced it with SPACE
              //licStr=licStr+(String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + ',  ';             
              licStr=licStr+(String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + '  ';             
              
              licStr=licStr+(String.valueOf(sObjectRec.get ('Quantity_Type__c')) != null ? String.valueOf(sObjectRec.get ('Quantity_Type__c')) : ''  ) + ',  ';
              //RJ - Case # 568901 changes 
              licStr =licStr + 'License Period From '; 
              licStr=licStr+(String.valueOf(sObjectRec.get ('Start_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('Start_Date__c'))).format('dd/MM/YYYY') : ''  ) + ' ';
              licStr =licStr + 'to ';  
              licStr=licStr+(String.valueOf(sObjectRec.get ('End_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('End_Date__c'))).format('dd/MM/YYYY') : ''  ) + ',  ';
               
                if ( (sObjectRec.getSobject('Order__r')!= null && sObjectRec.getSobject('Order__r').getSobject('Account__r')!= null && sObjectRec.getSobject('Order__r').getSobject('Account__r').get('Name')!= null) )
                  licStr=licStr + String.valueof(sObjectRec.getSobject('Order__r').getSobject('Account__r').get('Name'));
                
              
             
                  displayLine.add(licStr);
            csvContent =csvContent +'\"'+licStr+'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+licStr +'\",';
                  
                  
                  
              }
            else
            {
            displayLine.add(String.valueOf(sObjectRec.get (fieldName)));
            csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }
          }
          else {
           // System.debug(fieldName);
            //system.debug(String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).get (fieldName.split('\\.')[1])));

            if (fieldName.contains('.') && sObjectRec.getSObject ((fieldName.split('\\.')[0])) != null)
            {
             //upto 3 related objects 
              if (((fieldName.split('\\.')[1]).contains('.') || (fieldName.split('\\.').size() > 3)) ){
                  if(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])) != null && sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])).getSObject ((fieldName.split('\\.')[2])) != null )  {  
                  fieldValue =((String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])).getSObject ((fieldName.split('\\.')[2])).get (fieldName.split('\\.')[3]))) != null ? (String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])).getSObject(fieldName.split('\\.')[2]).get(fieldName.split('\\.')[3]))) : '' );
                  
               if( fieldName != null && fieldName.contains('_Date_') ) 
            {
                displayLine.add(datetime.valueof(fieldValue).format('ddMMYYYY') );
            csvContent =csvContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            }
            else
            {
            displayLine.add(fieldValue );
            csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }
              }              
              else {
              csvContent =csvContent +'\"\",';
               cloneCSVRowContent =cloneCSVRowContent +'\"\",';
              }
              }
             //upto 2 related objects
            else if (((fieldName.split('\\.')[1]).contains('.') || (fieldName.split('\\.').size() > 2)) ){    
                if(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])) != null ){
                  fieldValue =((String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])).get (fieldName.split('\\.')[2]))) != null ? (String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).getSObject ((fieldName.split('\\.')[1])).get(fieldName.split('\\.')[2]))) : '' );
                 
             if ((fieldName  == 'Order__r.Account__r.Experian_ID__c') && (fileType == exportFileTypes.SummitFile)){
                  //RJ - Case # 00554006- To change the process to refer Global_Unique_ID__c if the Experian_ID__c is SFDC ID. If its EDQ ID then will pass the same.
                     String processedFieldValue =fieldValue;
                     if (isUSRegion){
                  
                   
                        if(fieldValue != null && fieldValue != '' && fieldValue.Length()> 14 && sObjectRec.getSObject ('Order__r')!= null && sObjectRec.getSObject('Order__r').getSObject ('Account__r') != null){
                            processedFieldValue='QAS-'+ (String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Account__r').get ('Global_Unique_ID__c')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Account__r').get ('Global_Unique_ID__c')) );
                  
                        }
                    else{
                         processedFieldValue = 'QAS-' + fieldValue ;
                    }
                  }
                  else{
                      //RJ - Case 00584024- To change Experian id to all upper case for APAC/EMEA .
                      If (processedFieldValue !=null && processedFieldValue !='')
                      processedFieldValue = processedFieldValue.toUpperCase();
                  }
              
                  displayLine.add(processedFieldValue  );
            csvContent =csvContent +'\"'+processedFieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+processedFieldValue +'\",';
                  
                  
              }
             else     
                    if( fieldName != null && fieldName.contains('_Date_') ) 
            {
                displayLine.add(datetime.valueof(fieldValue).format('ddMMYYYY') );
            csvContent =csvContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            } else if( fieldName != null && fieldName.contains('Shipping_Address__r') && isUSregion ) {
                
                if(sObjectRec.getSObject ('Order__r')!= null && sObjectRec.getSObject ('Order__r').get ('Shipping_Address__c') != null &&
                        sObjectRec.getSObject ('Order__r').get ('Billing_Address__c') != null && 
                     String.valueOf(sObjectRec.getSObject ('Order__r').get('Billing_Address__c')) ==  String.valueOf(sObjectRec.getSObject ('Order__r').get ('Shipping_Address__c')) )
                     {
                         
                        
                        displayLine.add('' );
                   csvContent =csvContent +'\"\",';
                   cloneCSVRowContent =cloneCSVRowContent +'\"\",';
                }
                else
                {
                       if( fieldName == 'Order__r.Shipping_Address__r.PostCode__c' && sObjectRec.getSObject('Order__r') != null && sObjectRec.getSObject('Order__r').getSObject ('Shipping_Address__r')!= null && (fileType == exportFileTypes.SummitFile) )
                       {
                       
                            string stateValue =(String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Shipping_Address__r').get ('State__c')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Shipping_Address__r').get ('State__c')) );
                  
                  String stateCodeStr = stateValue ;
                   if(stateCodeMap.size()>0 && stateValue != '' && stateCodeMap.containsKey(stateValue )  )
                 stateCodeStr =stateCodeMap.get(stateValue );
                     
                     stateCodeStr = stateCodeStr +' '+ fieldValue ;
                 
                 
                 displayLine.add(stateCodeStr ); 
            csvContent =csvContent +'\"'+stateCodeStr +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+stateCodeStr +'\",';
                       
                       }
                       else
                       {
                   displayLine.add(fieldValue );
                        csvContent =csvContent +'\"'+fieldValue +'\",';
                        cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                        }
                }
                
            
            }
            else
            {
            displayLine.add(fieldValue );
            csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }
            }
            else {
              csvContent =csvContent +'\"\",';
               cloneCSVRowContent =cloneCSVRowContent +'\"\",';
            }
              }
              //1 related object
              else if (sObjectRec.getSObject ((fieldName.split('\\.')[0])) != null){
              fieldValue =((String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).get (fieldName.split('\\.')[1]))) != null ? (String.valueOf(sObjectRec.getSObject ((fieldName.split('\\.')[0])).get (fieldName.split('\\.')[1]))) : '' );
              
              
               if (fieldName  == 'Order__r.Status__c'){
              
              //RJ- Case 00607717
              //if(fieldValue != null &&  fieldValue  =='Credited')
              if(fieldValue != null &&  fieldValue  =='Credit Note')
                  fieldValue = 'CREDIT MEMO';
              else
                  fieldValue  = 'INVOICE';
              
                  displayLine.add(fieldValue  );
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                  
                  
              }
              //RJ - Case # 00554006- To change the process to refer Global_Unique_ID__c if the Experian_ID__c is SFDC ID. If its EDQ ID then will pass the same.
                   
              else if (fieldName  == 'Account__r.Experian_ID__c' && isUSRegion){
              
              if(fieldValue != null &&  fieldValue  !=''&& (fileType == exportFileTypes.CustomerFile ) && sObjectRec.getSObject ('Account__r') != null && fieldValue.length()>14)
                 fieldValue  = (String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) == null ? '': String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) );
                  
              
                  displayLine.add(fieldValue  );
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                  
                  
              }
              //RJ - Changes for case  # 00562967 
              else if ((fileType == exportFileTypes.SummitFile) && (fieldName  == 'Product__r.Name') ){
              
              if(fieldValue != null )
                  fieldValue = fieldValue  + ' '+  (String.valueOf(sObjectRec.get ('Operating_System__c')) != null ? String.valueOf(sObjectRec.get ('Operating_System__c')) : ''  );
              
              String licStr = 'License Period to:';
              if (!isUSRegion )
              {
                fieldValue =fieldValue+ '|'+ 'License Period to:';
                fieldValue =fieldValue+(String.valueOf(sObjectRec.get ('End_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('End_Date__c'))).format('MM/dd/YYYY') : ''  ); 
                fieldValue =fieldValue+'|';
                fieldValue =fieldValue+(String.valueOf(sObjectRec.get ('Users_From__c')) != null ? String.valueOf(sObjectRec.get ('Users_From__c')) : ''  );
                fieldValue =fieldValue+ ' to ';
                fieldValue =fieldValue+ (String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + ' ';
                fieldValue =fieldValue+ (String.valueOf(sObjectRec.get ('Quantity_Type__c')) != null ? String.valueOf(sObjectRec.get ('Quantity_Type__c')) : ''  ) ;
              }
              
               licStr=licStr+(String.valueOf(sObjectRec.get ('End_Date__c')) != null ? datetime.valueof(String.valueOf(sObjectRec.get ('End_Date__c'))).format('MM/dd/YYYY') : ''  ) + ' , ';
               
               licStr=licStr+(String.valueOf(sObjectRec.get ('Users_From__c')) != null ? String.valueOf(sObjectRec.get ('Users_From__c')) : ''  ) + ' to ';
               
               licStr=licStr+(String.valueOf(sObjectRec.get ('Users_To__c')) != null ? String.valueOf(sObjectRec.get ('Users_To__c')) : ''  ) + ' ';
              
              licStr=licStr+(String.valueOf(sObjectRec.get ('Quantity_Type__c')) != null ? String.valueOf(sObjectRec.get ('Quantity_Type__c')) : ''  ) + ' ';
              
             
                  displayLine.add(fieldValue );
            csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+licStr +'\",';
                  
                  
              }
              /*else if ((fileType == exportFileTypes.CustomerFile) && (fieldName  == 'Billing_Address__r.Country__c') ){
                  
                  String countryCodeStr = fieldValue;
                   if(countryCodeMap.size()>0 && fieldValue != '' && countryCodeMap.containsKey(fieldValue) )
                 countryCodeStr=countryCodeMap.get(fieldValue);
                 
                 displayLine.add(countryCodeStr  ); 
            csvContent =csvContent +'\"'+countryCodeStr +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+countryCodeStr +'\",';
                  
                  
              }*/
              //RJ - Included change for case # 568901 to limit PO number by 20 char
              else if ( (fileType == exportFileTypes.RPMFile) && (fieldName  =='Order__r.PO_Number__c')){
               string pNumberStr = '';
               Integer index = 20;
                   if (fieldValue!= null && fieldValue != '')
                   { 
                     // Case #629393 : 042914 James Weatherall : Added check to see if FieldValue is > 20 chars
                     index = fieldValue.length() > 20 ? index : fieldValue.length();
                     pNumberStr = fieldValue.substring(0,index);
                   }
                       
                    displayLine.add(pNumberStr );
            csvContent =csvContent +'\"'+pNumberStr +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+pNumberStr +'\",';
              
              }
               //RJ - Commented this to refer Descrption instead of Chart_of_Accounts_Product_Description__c field          
              //else if ((fileType == exportFileTypes.RPMFile) && (fieldName  == 'Product__r.Chart_of_Accounts_Product_Description__c') ){
              else if ((fileType == exportFileTypes.RPMFile) && (fieldName  == 'Product__r.Description') ){
              
              String RPMCode = '';
                        if(fieldValue != null &&  rpmCodes.containsKey(fieldValue ))
                            RPMCode = rpmCodes.get(fieldValue ).RPM_Code__c;
            
            displayLine.add(RPMCode );
            csvContent =csvContent +'\"'+RPMCode +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+RPMCode +'\",';
                 
            
                  
              }
             else if( fieldName != null && fieldName.contains('_Date_') && !( fileType == exportFileTypes.SummitFile && fieldName == 'Order__r.Close_Date__c')) 
            {
                displayLine.add(datetime.valueof(fieldValue).format('ddMMYYYY') );
            csvContent =csvContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+datetime.valueof(fieldValue).format('ddMMYYYY')+'\",';
            }
            else
            {
            displayLine.add(fieldValue );
            csvContent =csvContent +'\"'+fieldValue +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
                }
              }
               else {
              csvContent =csvContent +'\"\",';
               cloneCSVRowContent =cloneCSVRowContent +'\"\",';
            }
            }
            else {
              csvContent =csvContent +'\"\",';
               cloneCSVRowContent =cloneCSVRowContent +'\"\",';
            }
          }
        }
        else if (fieldName!= null && (fieldName.contains('Transform') ))
        {
         if (fieldName == 'Transform--CustomerSiteReferenceNumber' && (fileType == exportFileTypes.CustomerFile  ||  fileType == exportFileTypes.SummitFile )) {
          string transValue = '';
          if ( (fileType == exportFileTypes.CustomerFile ) && sObjectRec.get ('Owner_Country__c') != null  ){
            transValue =((String.valueOf(sObjectRec.get ('Owner_Country__c')) != null ? (String.valueOf(sObjectRec.get ('Owner_Country__c'))) : '' ));
          } else 
          if ((fileType == exportFileTypes.SummitFile ) && sObjectRec.getSObject ('Order__r') != null && sObjectRec.getSObject ('Order__r').get ('Owner_Country__c') != null  ){
            transValue =((String.valueOf(sObjectRec.getSObject ('Order__r').get ('Owner_Country__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Order__r').get ('Owner_Country__c'))) : '' ));
          }
            /*if (transValue == 'USA' || transValue == 'United States of America' || transValue == 'United States' || transValue == 'US') {
                transValue='US';
            }
            else if (transValue == 'UK' || transValue == 'United Kingdom' ) {
                     
               transValue='UK';

            }
            else if (transValue == 'FR' || transValue == 'France' ) {
           transValue='FR';
            }
            else if (transValue == 'NZ' || transValue == 'New Zealand' ) {
                transValue='NZ';
            }
            else if (transValue == 'SGP' || transValue == 'Singapore' ) {
                transValue='SGP';
            }
            else if (transValue == 'AU' || transValue == 'Australia' ) {
               transValue='AU';
            }
            else if (transValue == 'NL' || transValue == 'Netherlands' ) {
                transValue='NL';
            }*/
             if(countryCodeMap.size()>0 && transValue != '' && countryCodeMap.containsKey(transValue) )
                 transValue=countryCodeMap.get(transValue);
            
              
          
          If (isUSRegion){
          //RJ - Case # 00554006- To change the process to refer Global_Unique_ID__c if the Experian_ID__c is SFDC ID. If its EDQ ID then will pass the same.
                   
               string experianIdStr= '';
                if((fileType == exportFileTypes.CustomerFile ) && sObjectRec.getSObject ('Account__r') != null){
               //transValue=transValue+'-'+((String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c'))) : '' ));
               experianIdStr=((String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c'))) : '' ));
                   If(experianIdStr != null && experianIdStr !='' && experianIdStr.length() >14)
                       experianIdStr=(String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) == null ? '': String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) );
                  
                       
                       transValue=transValue+'-'+experianIdStr;
               
               }else if ((fileType == exportFileTypes.SummitFile ) && sObjectRec.getSObject ('Order__r') != null && sObjectRec.getSObject ('Order__r').getSObject ('Account__r') != null)
                 {
                  //transValue=transValue+'-'+((String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Experian_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Experian_ID__c'))) : '' ));
                  experianIdStr=((String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Experian_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Experian_ID__c'))) : '' ));
                   If(experianIdStr != null && experianIdStr !='' && experianIdStr.length() >14)
                       experianIdStr=((String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Global_Unique_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Account__r').get ('Global_Unique_ID__c'))) : '' ));
                  
                       
                       transValue=transValue+'-'+experianIdStr;
                 } 
             } 
            else{
                //RJ - Included this change as per case 00553884. This is to derive customer site value based on billing EDQ Integration ID for UK.
                  
                  if((fileType == exportFileTypes.CustomerFile ) && sObjectRec.getSObject ('Billing_Address__r') != null)
               transValue=transValue+'-'+((String.valueOf(sObjectRec.getSObject ('Billing_Address__r').get ('EDQ_Integration_Id__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Billing_Address__r').get ('EDQ_Integration_Id__c'))) : '' ));
               else if ((fileType == exportFileTypes.SummitFile ) && sObjectRec.getSObject ('Order__r') != null && sObjectRec.getSObject ('Order__r').getSObject ('Billing_Address__r') != null)
                  transValue=transValue+'-'+((String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Billing_Address__r').get ('EDQ_Integration_Id__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Order__r').getSObject ('Billing_Address__r').get ('EDQ_Integration_Id__c'))) : '' ));
          
              
            }      
              
                
                
          displayLine.add('transValue');
            csvContent =csvContent +'\"'+transValue+'\",';
             cloneCSVRowContent =cloneCSVRowContent +'\"'+transValue+'\",';
          
         }  
         else if((fieldName=='Transform--Shipping_Address__r.Country__c' && (fileType == exportFileTypes.CustomerFile)) ||
              ((fileType == exportFileTypes.PartnerFile && FieldName== 'Transform--Order__r.Account__r.BillingCountry'))  ){
            if (fileType == exportFileTypes.CustomerFile)
                     fieldValue =((String.valueOf(sObjectRec.getSObject (('Shipping_Address__r'))) != null ? (String.valueOf(sObjectRec.getSObject (('Shipping_Address__r')).get ('Country__c'))) : '' ));
            else if (fileType == exportFileTypes.PartnerFile && sObjectRec.getSObject (('Order__r')) != null && sObjectRec.getSObject('Order__r').getSObject ('Account__r') != null)
                fieldValue =((String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Account__r').get ('BillingCountry')) != null ?String.valueOf(sObjectRec.getSObject('Order__r').getSObject ('Account__r').get ('BillingCountry'))  : '' ));
            
            if (fieldValue == 'USA' || fieldValue == 'United States of America' || fieldValue == 'United States' || fieldValue == 'US') {
                displayLine.add('EXP_US_EHI_OU');
            csvContent =csvContent + '\"EXP_US_EHI_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_US_EHI_OU\",';
            }
            else if (fieldValue == 'UK' || fieldValue == 'United Kingdom' ) {
                     
                displayLine.add('EXP_UK_ELI_OU');
            csvContent =csvContent + '\"EXP_UK_ELI_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_UK_ELI_OU\",';

            }
            else if (fieldValue == 'FR' || fieldValue == 'France' ) {
            displayLine.add('EXP_FR_ECS_OU');
            csvContent =csvContent + '\"EXP_FR_ECS_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_FR_ECS_OU\",';
            }
            else if (fieldValue == 'NZ' || fieldValue == 'New Zealand' ) {
                displayLine.add('EXP_NZ_EAP_OU');
            csvContent =csvContent + '\"EXP_NZ_EAP_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_NZ_EAP_OU\",';
            }
            else if (fieldValue == 'SGP' || fieldValue == 'Singapore' ) {
                displayLine.add('EXP_SG_EAP_OU');
            csvContent =csvContent + '\"EXP_SG_EAP_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_SG_EAP_OU\",';
            }
            else if (fieldValue == 'UK' || fieldValue == 'United Kingdom' ) {
                displayLine.add('EXP_AU_EAP_OU');
            csvContent =csvContent + '\"EXP_AU_EAP_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_AU_EAP_OU\",';
            }
            else if (fieldValue == 'NL' || fieldValue == 'Netherlands' ) {
                displayLine.add('EXP_NL_ENL_OU');
            csvContent =csvContent + '\"EXP_NL_ENL_OU\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"EXP_NL_ENL_OU\",';
            }
            else
            {
              csvContent =csvContent +'\"'+fieldValue +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldValue +'\",';
            }
            
               }
          else if (fieldName == 'Transform--Trans') {
            
            displayLine.add('TRANS');
            csvContent =csvContent +'\"'+'TRANS'+'\",';
             cloneCSVRowContent =cloneCSVRowContent +'\"'+'DESCRIPTOR'+'\",';
          }
          else if ((fieldName == 'Transform--TotalAmount') && (fileType == exportFileTypes.SummitFile)) {
            
            double transSalesValue = 0;
            double transQntyValue = 0;
          if (sObjectRec.get ('Sales_Price__c') != null ){
            transSalesValue =(double.valueOf((String.valueOf(sObjectRec.get ('Sales_Price__c')) != null ? (String.valueOf(sObjectRec.get ('Sales_Price__c'))) : '0' )));
          }
          if (sObjectRec.get ('CPQ_Quantity__c') != null ){
            transQntyValue =(double.valueOf((String.valueOf(sObjectRec.get ('CPQ_Quantity__c')) != null ? (String.valueOf(sObjectRec.get ('CPQ_Quantity__c'))) : '0' )));
          }
          
          displayLine.add(String.valueof(transSalesValue*transQntyValue));
            csvContent =csvContent +'\"'+(transSalesValue*transQntyValue)+'\",';
             cloneCSVRowContent =cloneCSVRowContent +'\"'+(transSalesValue*transQntyValue)+'\",';
              
            
          }
          else if(fieldName == 'Transform--MemoLn'){
          
              If ((fileType == exportFileTypes.PartnerFile))
              {
                  String memoLnValue= (String.valueOf(sObjectRec.get ('EDQ_Memo_Line__c')) == null ? '': String.valueOf(sObjectRec.get ('EDQ_Memo_Line__c')) );
                  String partnerAccRefValue='';
                  if(sObjectRec.getSObject('Order__r') != null && sObjectRec.getSObject('Order__r').getSObject('Partner__r') != null )
                  partnerAccRefValue= (String.valueof(sObjectRec.getSObject('Order__r').getSObject('Partner__r').get ('Experian_ID__c')) == null ? '':String.valueof(sObjectRec.getSObject('Order__r').getSObject('Partner__r').get ('Experian_ID__c'))  );
                  
                  displayLine.add(String.valueof(memoLnValue ));
                  csvContent =csvContent +'\"'+memoLnValue +'\",';
                  cloneCSVRowContent =cloneCSVRowContent +'\"'+partnerAccRefValue+'\",';
                  
              } else if (fileType == exportFileTypes.RoyaltiesFile){
                  String memoLnValue='';
                  If (sObjectRec.getSObject (('Order_Line_Item__r')) != null )
                  memoLnValue=String.valueof(sObjectRec.getSObject('Order_Line_Item__r').get('EDQ_Memo_Line__c')== null ?'':sObjectRec.getSObject('Order_Line_Item__r').get('EDQ_Memo_Line__c'));
                  String royaltyGrpRefValue='';
                  royaltyGrpRefValue=(String.valueOf(sObjectRec.get ('Royalty_Group_Reference__c')) == null ? '': String.valueOf(sObjectRec.get ('Royalty_Group_Reference__c')) );
                  
                  displayLine.add(String.valueof(memoLnValue ));
                  csvContent =csvContent +'\"'+memoLnValue +'\",';
                  cloneCSVRowContent =cloneCSVRowContent +'\"'+royaltyGrpRefValue+'\",';
              }
              
              
          
          // This below logic is altered and moved into orderLine trigger handler  
              /*String memoLnValue= ''; 
              String memoDupString='';
              If ((fileType == exportFileTypes.PartnerFile)||(fileType == exportFileTypes.SummitFile)){
              If(sObjectRec.getSObject (('Order__r')) != null && sObjectRec.getSObject (('Product__r')) != null  ){
                  //string productSaleType =String.valueOf(sObjectRec.getSObject('Product__r').get ('Types_of_Sale__c'));
                  string productSaleType =(String.valueOf(sObjectRec.get ('Type_of_Sale__c')) == null ? '': String.valueOf(sObjectRec.get ('Type_of_Sale__c')) );
                  string orderType =String.valueOf(sObjectRec.getSObject('Order__r').get ('Type__c'));
                  string productFamily=String.valueOf(sObjectRec.getSObject('Product__r').get ('Family'));
                  //Order__r.Account__r.BillingCountry,Order__r.Product__r.Types_of_Sale__c, Order__r.Product__r.Family,Order__r.Type__c
                  memoLnValue= generateMemoLn( productSaleType,  orderType, productFamily);
                  if(fileType == exportFileTypes.PartnerFile)
                  memoDupString = (String.valueof(sObjectRec.getSObject('Order__r').getSObject('Account__r').get ('Experian_ID__c')) == null ? '':String.valueof(sObjectRec.getSObject('Order__r').getSObject('Account__r').get ('Experian_ID__c'))  );
              }
              }
              else if (fileType == exportFileTypes.RoyaltiesFile){
                If(fileType == exportFileTypes.RoyaltiesFile &&sObjectRec.getSObject (('Order_Line_Item__r')) != null && sObjectRec.getSObject (('Order_Line_Item__r')) .getSObject (('Order__r')) != null && sObjectRec.getSObject (('Order_Line_Item__r')) .getSObject (('Product__r')) != null  ){
                  //string productSaleType =String.valueOf(sObjectRec.getSObject ('Order_Line_Item__r').getSObject('Product__r').get ('Types_of_Sale__c'));
                  string productSaleType =(String.valueOf(sObjectRec.getSObject ('Order_Line_Item__r').get ('Type_of_Sale__c')) == null ? '':String.valueOf(sObjectRec.getSObject ('Order_Line_Item__r').get ('Type_of_Sale__c'))  );
                  string orderType =String.valueOf(sObjectRec.getSObject ('Order_Line_Item__r').getSObject('Order__r').get ('Type__c'));
                  string productFamily=String.valueOf(sObjectRec.getSObject ('Order_Line_Item__r').getSObject('Product__r').get ('Family'));
                  //Order__r.Account__r.BillingCountry,Order__r.Product__r.Types_of_Sale__c, Order__r.Product__r.Family,Order__r.Type__c
                  memoLnValue= generateMemoLn( productSaleType,  orderType, productFamily);
                  memoDupString = (String.valueof(sObjectRec.getSObject('Order_line_item__r').getSObject('Order__r').getSObject('Account__r').get ('Experian_ID__c')) == null ? '':String.valueof(sObjectRec.getSObject('Order_line_item__r').getSObject('Order__r').getSObject('Account__r').get ('Experian_ID__c'))  );
              } 
              } 
                 
                csvContent =csvContent +'\"'+memoLnValue +'\",';
                If(fileType == exportFileTypes.SummitFile)
                cloneCSVRowContent =cloneCSVRowContent +'\"'+memoLnValue +'\",';
                else
                {
                  cloneCSVRowContent =cloneCSVRowContent +'\"'+memoDupString +'\",';
                  
                } */
          }
          else if (fieldName == 'Transform--OperatingUnit'){
              
              displayLine.add(operatingUnitName);
              csvContent =csvContent +'\"'+operatingUnitName+'\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"'+operatingUnitName+'\",';
          }
          else if (fieldName == 'Transform--StateCode'){
              
              if ((fileType == exportFileTypes.CustomerFile) && sObjectRec.getSObject (('Billing_Address__r')) != null ){
                  
                  string stateValue =(String.valueOf(sObjectRec.getSObject (('Billing_Address__r')).get ('State__c')) == null ? '': String.valueOf(sObjectRec.getSObject (('Billing_Address__r')).get ('State__c')) );
                  
                  String stateCodeStr = stateValue ;
                   if(stateCodeMap.size()>0 && stateValue != '' && stateCodeMap.containsKey(stateValue )  )
                 stateCodeStr =stateCodeMap.get(stateValue );
                 
                 displayLine.add(stateCodeStr ); 
            csvContent =csvContent +'\"'+stateCodeStr +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+stateCodeStr +'\",';
                  
                  
              }
              else
              {
              
              displayLine.add('');
              csvContent =csvContent +'\"\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"\",';
              
              }
          }
          else if (fieldName == 'Transform--CountryCode'){
               
               If(fileType == exportFileTypes.RPMFile && sObjectRec.getSObject (('Order__r')) != null && sObjectRec.getSObject('Order__r').getSObject (('Billing_Address__r')) != null  ){
                  
                  string countryCode='';
                  string countryValue =(String.valueOf(sObjectRec.getSObject('Order__r').getSObject (('Billing_Address__r')).get ('Country__c')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').getSObject (('Billing_Address__r')).get ('Country__c')) );
                  if(countryCodeMap.size()>0 && countryValue != '' && countryCodeMap.containsKey(countryValue ) )
                     countryCode=countryCodeMap.get(countryValue );    
                  
                  displayLine.add(countryCode);
              csvContent =csvContent +'\"'+countryCode+'\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"'+countryCode+'\",';
                  
              }
              else if ((fileType == exportFileTypes.CustomerFile) && sObjectRec.getSObject (('Billing_Address__r')) != null ){
                  
                  string countryValue =(String.valueOf(sObjectRec.getSObject (('Billing_Address__r')).get ('Country__c')) == null ? '': String.valueOf(sObjectRec.getSObject (('Billing_Address__r')).get ('Country__c')) );
                  
                  String countryCodeStr = countryValue ;
                   if(countryCodeMap.size()>0 && countryValue != '' && countryCodeMap.containsKey(countryValue ) )
                 countryCodeStr=countryCodeMap.get(countryValue );
                 
                 displayLine.add(countryCodeStr  ); 
            csvContent =csvContent +'\"'+countryCodeStr +'\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"'+countryCodeStr +'\",';
                  
                  
              }
              else
              {
              
              displayLine.add('');
              csvContent =csvContent +'\"\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"\",';
              
              }
               
                  
          }
          //RJ - Case # 00554006- To change the process to refer Global_Unique_ID__c if the Experian_ID__c is SFDC ID. If its EDQ ID then will pass the same.
                   
          else if( fieldName =='Transform-USExperianID'){
          if(IsUSRegion && (fileType == exportFileTypes.CustomerFile))
          {
              string experianIDValue='';
              if((fileType == exportFileTypes.CustomerFile ) && sObjectRec.getSObject ('Account__r') != null)
               experianIDValue=((String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c')) != null ? (String.valueOf(sObjectRec.getSObject ('Account__r').get ('Experian_ID__c'))) : '' ));
               
               /*If(experianIDValue != null && experianIDValue !='' && experianIDValue.length() >14)
                   experianIDValue=(String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) == null ? '': String.valueOf(sObjectRec.getSObject ('Account__r').get ('Global_Unique_ID__c')) );
                  */
                  
               displayLine.add(experianIDValue);
              csvContent =csvContent +'\"'+experianIDValue+'\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"'+experianIDValue+'\",';
          }
          else
          {
              
              displayLine.add('');
              csvContent =csvContent +'\"\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"\",';
              
              }
          
          
          }
           else if (fieldName == 'Transform--Email' || fieldName == 'Transform--ContactEmail'  ){
               
               If(fileType == exportFileTypes.SummitFile && sObjectRec.getSObject (('Order__r')) != null   ){
                  
                   string emailHC='EMAIL';
                   string contactEmail='';
               
              //RJ- Case 00607717
              //if( (String.valueOf(sObjectRec.getSObject('Order__r').get ('Status__c')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').get ('Status__c')))  =='Credited')
              if( (String.valueOf(sObjectRec.getSObject('Order__r').get ('Status__c')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').get ('Status__c')))  =='Credit Note')
              {
                  emailHC= 'NFD';
               
                  }
                  else
                  {
                      If( sObjectRec.getSObject (('Order__r')).getSObject (('Billing_Contact__r')) != null )
                      contactEmail=(String.valueOf(sObjectRec.getSObject('Order__r').getSObject('Billing_Contact__r').get ('email')) == null ? '': String.valueOf(sObjectRec.getSObject('Order__r').getSObject('Billing_Contact__r').get ('email')));
                     
                     if (contactEmail=='' )
                            emailHC='PRINT';
                  }
                  
                  if (fieldName == 'Transform--Email')
                  {
                      displayLine.add(emailHC);
              csvContent =csvContent +'\"'+emailHC+'\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"'+emailHC+'\",';
                  }
                   if (fieldName == 'Transform--ContactEmail')
                  {
                      displayLine.add(contactEmail);
              csvContent =csvContent +'\"'+contactEmail+'\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"'+contactEmail+'\",';
                  }
                  
                  
                  
              }
              else
              {
              
              displayLine.add('');
              csvContent =csvContent +'\"\",';
              cloneCSVRowContent =cloneCSVRowContent +'\"\",';
              
              }
               
             }     
          
          else {
            displayLine.add('');
            csvContent =csvContent +'\"\",';
            cloneCSVRowContent =cloneCSVRowContent +'\"\",';
          }
          
          
        }
        else if (fieldName!= null && (fieldName.contains('HC--') )){
                displayLine.add(fieldName.split('HC--')[1]);
          csvContent =csvContent +'\"'+fieldName.split('HC--')[1]+'\",';
              If ( fieldName != 'HC--F')
           cloneCSVRowContent =cloneCSVRowContent +'\"'+fieldName.split('HC--')[1]+'\",';
           else
           cloneCSVRowContent =cloneCSVRowContent +'\"'+''+'\",';
        }
        else if (fieldName!= null && (fieldName.contains('SQ--') ))
        {    
            seqNumber++;
            displayLine.add(string.valueof(seqNumber) );
               csvContent =csvContent +'\"' +seqNumber +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"' +seqNumber +'\",';
               
        
        }
        else if (fieldName!= null && (fieldName.contains('DT--TODAY') ))
        {    
             
            displayLine.add(todayDate);
               csvContent =csvContent +'\"'+ todayDate +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+ todayDate +'\",';
                
        
        }
        else if(fieldName!= null && (fieldName.contains('GQ--Order') )&& (fileType == exportFileTypes.SummitFile) )
        { 
          
          
            
          if (runningOrderId == null && prevOrderId == null && sObjectRec.getSObject (('Order__r')) != null ) 
          {           
              runningOrderId=prevOrderId=String.Valueof(sObjectRec.getSObject (('Order__r')).get('id'));
              orderGroupNumber=1;
          
          }else 
          {
            If(sObjectRec.getSObject (('Order__r')) != null )
            runningOrderId=String.Valueof(sObjectRec.getSObject (('Order__r')).get('id'));
            
          if (runningOrderId==prevOrderId)
          {
            orderGroupNumber++;
          }
            else
            {
            orderGroupNumber=1;
            prevOrderId=runningOrderId;
            
            
            }
          }
              
           displayLine.add(todayDate);
               csvContent =csvContent +'\"'+ orderGroupNumber +'\",';
                cloneCSVRowContent =cloneCSVRowContent +'\"'+ orderGroupNumber +'\",';
        }
        else {
          displayLine.add('');
          csvContent =csvContent +'\"\",';
           cloneCSVRowContent =cloneCSVRowContent +'\"\",';
        }
        fieldCount++;
      }

      reportDisplayList.add (displayLine);
      if(fileType != exportFileTypes.CustomerFile && fileType != exportFileTypes.RPMFile && !(fileType == exportFileTypes.SummitFile && (isUSRegion== false)))
      csvContent =csvContent +'\n'+cloneCSVRowContent +'\n' ;
      else
        csvContent =csvContent +'\n' ;

  } 

  //RPM File Header Generation
    if(fileType == exportFileTypes.RPMFile  ) 
    {
      Integer runningSeq= 0;
      Report_Extract_Templates__c RPMHDRTLRRec= Report_Extract_Templates__c.getValues('RPM HDRTLR');
      try{
       runningSeq= Integer.valueof(string.valueof((RPMHDRTLRRec.col5__c)).split('RunningSeq--')[1]);
      }
      catch(exception ex)
      {
        runningSeq=0;
        
      }
       runningSeq++;
  String header =  '\"HDR\",'+'\"'+seqNumber+'\",'+'\"1484\",\"'+todayDate+'\",\"'+runningSeq+'\"';
  //csvContent = header + '\n';
  String trailer = '\"TLR\",'+'\"'+seqNumber+'\",'+'\"1484\",\"'+todayDate+'\",\"'+runningSeq+'\"';
  csvContent = header + '\n'+csvContent + Trailer + '\n';
  RPMHDRTLRRec.col5__c = 'RunningSeq--'+runningSeq;
  update RPMHDRTLRRec;
    }
  //System.debug(reportDisplayList);

    return null;
    //return page.BatchOrderList;
  }
  //Method to generate Operating Unit value from  User
  private void getOperatingUnitValue(){
  
  User currentUser = [SELECT Region__c,Country__c, ID FROM User WHERE ID =: UserInfo.getUserId()];
       
  
  if(currentUser.Country__c!= null) {
        
          if (currentUser.Country__c == 'USA' || currentUser.Country__c == 'United States of America' || currentUser.Country__c == 'United States' || currentUser.Country__c == 'US') {
                 
            operatingUnitName = 'EXP_US_EHI_OU';
            }
            else if (currentUser.Country__c == 'UK' || currentUser.Country__c == 'United Kingdom' ) {
                     
                operatingUnitName='EXP_UK_ELI_OU';

            }
            else if (currentUser.Country__c == 'FR' || currentUser.Country__c == 'France' ) {
            operatingUnitName='EXP_FR_ECS_OU';
               
            }
            else if (currentUser.Country__c == 'NZ' || currentUser.Country__c == 'New Zealand' ) {
                operatingUnitName='EXP_NZ_EAP_OU'; 
            }
            else if (currentUser.Country__c == 'SGP' || currentUser.Country__c == 'Singapore' ) {
                operatingUnitName='EXP_SG_EAP_OU';
                 
            }
            else if (currentUser.Country__c == 'AU' || currentUser.Country__c == 'Australia' ) {
                operatingUnitName='EXP_AU_EAP_OU';
                 
            }
            else if (currentUser.Country__c == 'NL' || currentUser.Country__c == 'Netherlands' ) {
                operatingUnitName='EXP_FR_ECS_OU';
                
            }
            
      } 
  
  
  }
  
  //Memo Line generation code - Move to Order Line trigger
  public string generateMemoLn (string productSaleType, string orderType,string productFamily){
    string memoLnTxt = '';
    memoLnTxt= 'QAS';
    if (orderType== 'Renewal')
      memoLnTxt=memoLnTxt+'R';
    else 
      memoLnTxt=memoLnTxt+'N';
      //if (orderType== 'N')
    
      memoLnTxt= memoLnTxt+(productFamily == null ? '' : productFamily);
      
      if(productSaleType != null && !productSaleType.contains(';') )
      {
      if(memoLnTypeOfSaleLSet.contains(productSaleType))
        memoLnTxt=memoLnTxt+'L';
      else if (memoLnTypeOfSaleISet.contains(productSaleType))  
        memoLnTxt=memoLnTxt+'I';
      }
      else if (productSaleType != null && productSaleType.contains(';') )
      {
          List<string> saleTypeList = new list<string>();
          saleTypeList= productSaleType.split(';');
          for(string saleTypeValue : saleTypeList)
          {
            if(memoLnTypeOfSaleLSet.contains(saleTypeValue))
            {
              memoLnTxt=memoLnTxt+'L';
              break;
            }
            else if (memoLnTypeOfSaleISet.contains(saleTypeValue))
            { 
              memoLnTxt=memoLnTxt+'I';
              break;
            }
            
          }
          
      }
    
    
    return memoLnTxt;
  }
}