/*******************
Created BY : Richard Joseph.
Created Date: Oct 25th 2014.
Desc: Service class to Insert/Update ProductMaster table in CPQ.
Change Log:
March 11th 2015 Richard Joseph - Phase 3 CSDA fields to be added. CMC # S-299092
March 18th 2015 Richard Joseph - Phase 3 -Change to use Product_Name__c instead of Name field.CMC # S-302522
Apr   24th 2015 Richard Joseph - Phase 3 - Truncated the field to 200.
*************/
public class SFDCToCPQProductMasterSyncServiceClass {

Public static HttpResponse responseCPQ;
  
 
  @future (callout=true)
  public static void callCPQProductMasterAsync(Id productMasterId){
  
String objName = 'product_Master__c';

Map<String,Schema.SObjectType> globalDescMap = Schema.getGlobalDescribe(); 
Schema.SObjectType sobjType = globalDescMap.get(objName ); 
Schema.DescribeSObjectResult describeResult = sobjType.getDescribe(); 
Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap(); 

String queryFields= null;
For (Schema.SObjectField fieldName:fieldsMap.Values() ){
    If (queryFields == null)
        queryFields=String.valueof(fieldName);
    else    
    queryFields=queryFields+','+fieldName ;    
}

 String queryString = 'Select ' +queryFields + ' From product_Master__c where Id = '+ '\'' +productMasterId +'\'';
 system.debug(queryString );
  Product_Master__c prodMasterRecord  = Database.query(queryString );
     If(prodMasterRecord  != null){
       String response = callCPQProductMasterService(prodMasterRecord  );
           
          if (response != null && prodMasterRecord  .CpqTableEntryId__c == null){
               prodMasterRecord  .CpqTableEntryId__c = response ; 
               //To By-Pass the trigger and control rescursion
               ProductMasterTriggerHandler.aSyncRRecursiveRUN= true;
               update prodMasterRecord  ;
                   
               }
   }
  }
  
  public static string callCPQProductMasterService(Product_Master__c productMaster){
        
  
  String resultString = null;
  Boolean isUpdate = (productMaster.CpqTableEntryId__c != null ? True : False);
  Boolean respStatus = false;
  String productRegionStr = null;
  String productCntryStr = null;
  String productFinBUNameStr =null;
  String productFinBUStr = null;
  string revSchdRuleStr =null;
  Set<String> deDupeStr = new set<String>();
  set<String> deDupeFinBUStr = new set<String> ();
  
  
  For(Product_Region__c productRegion :[Select Region__r.Name, Region__c, Product_Master__c, Name, Id From Product_Region__c  where Product_Master__r.Id = :productMaster.id ]){
    
     if(deDupeStr!= null && deDupeStr.size() >0 && ! deDupeStr.contains(productRegion.Region__r.Name))
        {
                deDupeStr.add(productRegion.Region__r.Name);
                productRegionStr=productRegionStr+';'+productRegion.Region__r.Name;
        }else if(deDupeStr!= null && deDupeStr.size() == 0)
        {
            deDupeStr.add(productRegion.Region__r.Name);
            productRegionStr=productRegion.Region__r.Name;  
        }
  }
  
  
  deDupeStr = new set<String>();
  
  For(Product_Country__c productCountry :[Select Product_Master__c,Id,Product_Finance_BU__c, Product_Finance_BU__r.Finance_BU_Name__c, Product_Finance_BU__r.Finance_BU_Code__c, Product_Finance_BU__r.Name, Finance_BU_Name__c, Country__r.Name, Country__c From Product_Country__c where Product_Master__r.Id = :productMaster.id ]){
    
     if(deDupeStr!= null &&  deDupeStr.size() >0 && ! deDupeStr.contains(productCountry.Country__r.Name))
        {
                deDupeStr.add(productCountry.Country__r.Name);
                productCntryStr=productCntryStr+';'+productCountry.Country__r.Name;
        }else if(deDupeStr!= null && deDupeStr.size() == 0)
        {
            deDupeStr.add(productCountry.Country__r.Name);
            productCntryStr=productCountry.Country__r.Name;
            
        }
    
    //Case # 374838 - Made changes to bypass Null if the Product FInance lookup is null
    if(deDupeFinBUStr!= null  && deDupeFinBUStr.size() >0 && productCountry.Product_Finance_BU__c !=null && ! deDupeFinBUStr.contains(productCountry.Product_Finance_BU__r.name))
        {
                deDupeFinBUStr.add(productCountry.Product_Finance_BU__r.name);
            productFinBUNameStr=productFinBUNameStr+productCountry.Finance_BU_Name__c;
                productFinBUStr=productFinBUStr+';'+productCountry.Product_Finance_BU__r.name;
        }else if(deDupeFinBUStr!= null && deDupeFinBUStr.size() == 0 )
        {
            deDupeFinBUStr.add(productCountry.Product_Finance_BU__r.name);
            productFinBUNameStr=productCountry.Finance_BU_Name__c;
                productFinBUStr=productCountry.Product_Finance_BU__r.name;
            
        }
    
            
            
  }  
  

  
  deDupeStr = new set<String>();
  
  For(Billing_Product__c  billingProduct :[Select Type_of_Sale__c, Revenue_Schedule_Rule__c,Revenue_Schedule_Rule__r.name, Product_Master__c, Name From Billing_Product__c  where Product_Master__r.Id = :productMaster.id ]){
    
     if(deDupeStr!= null && deDupeStr.size() >0 && ! deDupeStr.contains(billingProduct.Revenue_Schedule_Rule__r.name))
        {
                deDupeStr.add(billingProduct.Revenue_Schedule_Rule__r.name);
                revSchdRuleStr=revSchdRuleStr+';'+billingProduct.Revenue_Schedule_Rule__r.name;
        }else if(deDupeStr!= null && deDupeStr.size() == 0)
        {
            deDupeStr.add(billingProduct.Revenue_Schedule_Rule__r.name);
            revSchdRuleStr=billingProduct.Revenue_Schedule_Rule__r.name;
            
        }
    
    
    
            
            
  } 
  
  
   
  CPQ_Settings__c CPQSetting = CPQ_Settings__c.getInstance('CPQ');
  
    
  String userProperties = '<?xml version=\"1.0\" encoding=\"utf-8\"?><soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\">';
    
  userProperties += '<soapenv:Header/>';
  userProperties += '<soapenv:Body>';
  userProperties += '<AUXTableAdministration xmlns="http://webcominc.com/">';
  userProperties += '<userName>'+CPQSetting.CPQ_API_UserName__c+'</userName>';
  userProperties += '<password>'+CPQSetting.CPQ_API_Access_Word__c+'</password>';
  If (isUpdate )
  userProperties += '<action>UPDATEROWS</action>';
  else
  userProperties += '<action>INSERTROWS</action>';
  userProperties += '<tableName>Product_Master</tableName>';
  userProperties += '<xDoc>';

  userProperties += '<Root xmlns=\"\">'; 
  userProperties +='<Columns>';
    If (isUpdate )
  userProperties +='<Column>CpqTableEntryId</Column>' ;  
 userProperties +='<Column>ProductName</Column>';
userProperties +='<Column>ProductMasterName</Column>';
userProperties +='<Column>ProductDescription</Column>';
userProperties +='<Column>TypesOfSale</Column>';
userProperties +='<Column>RevenueProjectionrulesLinkToSalesType</Column>';
userProperties +='<Column>SimpleComplex</Column>';
userProperties +='<Column>DEcapability</Column>';
userProperties +='<Column>DEproductfamily</Column>';
userProperties +='<Column>DEproductgroup</Column>';
userProperties +='<Column>CustomerJourney</Column>';
userProperties +='<Column>AssetType</Column>';
userProperties +='<Column>ProvidesInsightInto</Column>';
userProperties +='<Column>ProductGlobalBusinessLine</Column>';
userProperties +='<Column>BusinessLine</Column>';
userProperties +='<Column>BusinessUnit</Column>';
userProperties +='<Column>BusinessUnitName</Column>';
userProperties +='<Column>SectorCode</Column>';
userProperties +='<Column>Region</Column>';
userProperties +='<Column>Country</Column>';
userProperties +='<Column>ChartOfAccountsSubanalysisPDCode</Column>';
userProperties +='<Column>ChartOfAccountsProductDescription</Column>';
userProperties +='<Column>ProductMasterID</Column>';
//RJ - Adding fo Phase 3 - CMC # S-299092
userProperties +='<Column>CSDAProductGroup</Column>';
userProperties +='<Column>CSDAProductOrg</Column>';
userProperties +='<Column>CSDAProductSuite</Column>';
userProperties +='</Columns>';

userProperties +='<Rows>';
userProperties +='<Row>';
  If (isUpdate )
  userProperties +='<Value>'+productMaster.CpqTableEntryId__c+'</Value>';
  //RJ - CMC #S 302522 - Change Product_Name__c instead of Name field
//userProperties +='<Value>'+(productMaster.Name != null ? productMaster.Name : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Product_Name__c != null ? productMaster.Product_Name__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Product_master_name__c != null ? productMaster.Product_master_name__c : '').escapeHtml4()+'</Value>';
//RJ - changed to Truncate the field to 200. TruncateString200
userProperties +='<Value>'+(productMaster.Product_description__c != null ? TruncateString200(productMaster.Product_description__c) : '').escapeHtml4()+'</Value>';
/*If(productMaster.Product_description__c != null && productMaster.Product_description__c.length() > 200)
userProperties +='<Value>'+(productMaster.Product_description__c != null ? (productMaster.Product_description__c).substring(0,200) : '').escapeHtml4()+'</Value>';
else
userProperties +='<Value>'+(productMaster.Product_description__c != null ? productMaster.Product_description__c : '').escapeHtml4()+'</Value>';*/
userProperties +='<Value>'+(productMaster.Type_of_sale__c != null ? productMaster.Type_of_sale__c: '').escapeHtml4()+'</Value>';
//userProperties +='<Value>RevenueProjectionrulesLinkToSalesType</Value>';
//RJ - changed to Truncate the field to 200. TruncateString200
userProperties +='<Value>'+(revSchdRuleStr != null ? TruncateString200(revSchdRuleStr): '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Simple_or_complex__c != null ? productMaster.Simple_or_complex__c: '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Capability__c != null ? productMaster.Capability__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Product_family__c != null ? productMaster.Product_family__c: '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Product_group__c != null ? productMaster.Product_group__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Customer_journey__c != null ? productMaster.Customer_journey__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Asset_type__c != null ? productMaster.Asset_type__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Provides_insight_into__c!= null ? productMaster.Provides_insight_into__c: '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Product_Global_Business_Line__c != null ? productMaster.Product_Global_Business_Line__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Line_of_business__c!= null ? productMaster.Line_of_business__c: '').escapeHtml4()+'</Value>';
//userProperties +='<Value>'+(productMaster.Finance_Business_Unit_c__c != null ? productMaster.Finance_Business_Unit_c__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productFinBUStr != null ? TruncateString200(productFinBUStr) : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productFinBUNameStr != null ? TruncateString200(productFinBUNameStr) : '').escapeHtml4()+'</Value>';
//userProperties +='<Value>'+'BusinessUnitName'+'</Value>';
userProperties +='<Value>'+(productMaster.Name != null ? productMaster.Name : '').escapeHtml4()+'</Value>';
//userProperties +='<Value>'+(productMaster.Region__c!= null ? productMaster.Region__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productRegionStr!= null ? TruncateString200(productRegionStr) : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productCntryStr != null ? TruncateString200(productCntryStr) : '').escapeHtml4()+'</Value>';
//userProperties +='<Value>'+(productMaster.Country__c != null ? productMaster.Country__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Chart_of_Accounts_Subanaysis_PD_code__c != null ? productMaster.Chart_of_Accounts_Subanaysis_PD_code__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.Chart_of_Accounts_product_description__c != null ? productMaster.Chart_of_Accounts_product_description__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+String.valueof((productMaster.ID != null ? productMaster.Id: '')).escapeHtml4()+'</Value>';
//RJ - Adding phase 3 CSDA fields  CMC # S-299092
userProperties +='<Value>'+(productMaster.CSDA_Product_Group__c != null ? productMaster.CSDA_Product_Group__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.CSDA_Product_Org__c != null ? productMaster.CSDA_Product_Org__c : '').escapeHtml4()+'</Value>';
userProperties +='<Value>'+(productMaster.CSDA_Product_Suite__c != null ? productMaster.CSDA_Product_Suite__c : '').escapeHtml4()+'</Value>';


 userProperties +='</Row>';
userProperties +='</Rows>';

  userProperties +='</Root>';
  userProperties +='</xDoc>';
  userProperties += '</AUXTableAdministration>';
  userProperties +='</soapenv:Body>';
  userProperties += '</soapenv:Envelope>';



  string elementValue = null;
  Http h = new http();
  HttpRequest req = new HttpRequest();
  //HttpResponse responseCPQ = new HttpResponse ();
  //req.setEndpoint('https://test.webcomcpq.com/wsapi/cpqapi.asmx' ); 
  //req.setEndpoint('https://webcomcpq.com/wsapi/cpqapi.asmx'); PROD END POINT
  req.setEndpoint(CPQSetting.CPQ_API_Endpoint__c);
  req.setMethod('POST');
  req.setHeader('Content-Type', 'text/xml;charset=utf-8'); 
  req.setHeader('SOAPAction', '\"http://webcominc.com/AUXTableAdministration"');
  req.setHeader('Host', 'test.webcomcpq.com');
  req.setTimeout(12000);
  req.setBody(userProperties );
        
  system.debug('Req:  '+ req.getBody());
  
  Try{
  if(!Test.isRunningtest())
      responseCPQ = h.send(req);
   //else
      // responseCPQ=responseCPQTest;
      
  system.debug('Body was:  '+ responseCPQ);    
  If(responseCPQ != null && responseCPQ.getStatusCode() == 200)
  {    
  system.debug('Body was:  '+ responseCPQ);
  system.debug('String was:' + responseCPQ.getBody());
  XmlStreamReader reader = responseCPQ.getXmlStreamReader();
  reader.setNamespaceAware(true);  
  while(reader.hasNext()) {
    if (reader.getEventType() == XmlTag.START_ELEMENT && (reader.getLocalName() == 'CpqTableEntryId' || reader.getLocalName() == 'Status') ) {
      
       while(reader.hasNext()){
         if(reader.hasText() )
        {
            
            If(respStatus){
                elementValue= reader.getText();  
                break;
                } 
            
             if (reader.getText() == 'OK')             
             respStatus= true;
              
                        
                        break;
        }   
        reader.next();
            
      }
      }
       reader.next();
   }
   system.debug('The element value was:  ' + elementValue);
   resultString =elementValue;
   }   
    }
    catch(System.CalloutException e) {
        System.debug('Callout error: '+ e);
        If (responseCPQ != null){
        System.debug(responseCPQ.toString());
            resultString = 'Service Response : '+responseCPQ.toString();
            }else
            resultString= 'Error calling the Service';
    }
    catch (Exception e)
    {
        System.debug('Exception error: '+ e);
        resultString = 'Exception Deatils: '+ e.getLineNumber() + ' Stack:' +e.getStackTraceString();
    }

        return resultString ;

   } 
  
  //RJ - To Truncate the field to 200 
   private static string TruncateString200 (String inStreamStr)
   {
       if (inStreamStr != null && inStreamStr.length() > 225)
           return inStreamStr.substring(0,225);
        
        return inStreamStr;   
   }
    
    
}