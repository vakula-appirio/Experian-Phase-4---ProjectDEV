/*******************
Created BY : Richard Joseph.
Created Date: Oct 13th 2014.
Desc: Service class takes in parameter as Quote records and calls CPQ perform card action api for Quote status  Update.
*************/
public class SFDCToCPQChangeStatusServiceClass {

Public static HttpResponse responseCPQ;
  @future (callout=true)
  public static void callCPQChangeStatusSerivceAsync(Id quoteId){
  Quote__c quoteRecord  = [Select id,Quote_Id__c,Primary__c,Name,Opportunity__r.StageName,Opportunity__r.id,Opportunity__c From Quote__c u where id = :quoteId];  
     If(quoteRecord  != null){
       String response = callCPQUserAdminSerivce(quoteRecord );
           
          if (response != null){
               quoteRecord.Status_Change_Error_Message__c = response ; 
               update quoteRecord;
                   
               }
   }
  }
  
  //Asyc call invoked with Opty id 
  @future (callout=true)
  public static void callOptyCPQChangeStatusSerivceAsync(id OptyId){
  
  Boolean isError = false;
  list<Quote__c> quoteList  = new List<Quote__c>([Select id,Quote_Id__c,Primary__c,Name,Opportunity__r.StageName,Opportunity__r.id,Opportunity__c From Quote__c u where Opportunity__r.id = :OptyId]);  
   
  if(quoteList.size()   < (Limits.getLimitCallouts() - Limits.getCallouts() ) ) 
   For(Quote__c quoteRecord :quoteList  )
   {
     If(quoteRecord  != null){
       String response = callCPQUserAdminSerivce(quoteRecord );
           
          if (response != null){
               quoteRecord.Status_Change_Error_Message__c = response ; 
               
                   isError=true;
               }
   }
   }
   
   If(quoteList.size()>0)
   {
       Update quoteList  ;
       if(!isError)
       {
           Opportunity quoteOpty = new Opportunity (id =OptyId);
           quoteOpty.SyncCPQ__c= false; 
           Update quoteOpty;
       }
   }
  }
  
  public static string callCPQUserAdminSerivce(Quote__c quoteRecord){
        
  
  String resultString = null;
   
  CPQ_Settings__c CPQSetting = CPQ_Settings__c.getInstance('CPQAlt');
  String quoteChangeStatus = 'Closed/Lost';
  
  if (quoteRecord.Opportunity__c != null && quoteRecord.Opportunity__r.StageName == Constants.OPPTY_STAGE_7 )
          quoteChangeStatus='Closed/Won';
    
  String quoteUpdateDetails= '<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:web=\"http://webcominc.com/\">';
    
  quoteUpdateDetails+= '<soapenv:Header/>';
  quoteUpdateDetails+= '<soapenv:Body>';
  quoteUpdateDetails+= '<web:performCartAction>';
  quoteUpdateDetails+= '<web:username>'+CPQSetting.CPQ_API_UserName__c+'</web:username>';
  quoteUpdateDetails+= '<web:password>'+CPQSetting.CPQ_API_Access_Word__c+'</web:password>';
  quoteUpdateDetails+= '<web:compositeCartId>'+quoteRecord.Name+'</web:compositeCartId>';
  quoteUpdateDetails+= '<web:xDoc>';
  quoteUpdateDetails+= '<ACTION>';  
  quoteUpdateDetails+= '<NAME>Change Status</NAME>'; 
  quoteUpdateDetails+= '<PARAMETER name="NewStatus">'+quoteChangeStatus+'</PARAMETER>'; 
  quoteUpdateDetails+= '</ACTION>'; 
  quoteUpdateDetails+='</web:xDoc>';
  quoteUpdateDetails+= '</web:performCartAction>';
  quoteUpdateDetails+='</soapenv:Body>';
  quoteUpdateDetails+= '</soapenv:Envelope>';


  string elementValue = null;
  Http h = new http();
  HttpRequest req = new HttpRequest();
  //HttpResponse responseCPQ = new HttpResponse ();
  //req.setEndpoint('https://test.webcomcpq.com/wsapi/cpqapi.asmx' ); 
  //req.setEndpoint('https://webcomcpq.com/wsapi/cpqapi.asmx'); PROD END POINT
  req.setEndpoint(CPQSetting.CPQ_API_Endpoint__c);
  req.setMethod('POST');
  req.setHeader('Content-Type', 'text/xml;charset=utf-8'); 
  req.setHeader('SOAPAction', '\"http://webcominc.com/performCartAction"');
  req.setHeader('Host', 'test.webcomcpq.com');
  req.setTimeout(12000);
  req.setBody(quoteUpdateDetails);
        
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
    if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Result') {
      
       while(reader.hasNext()){
         if(reader.hasText() )
        {
           if (elementValue == null && reader.getText() == 'NOK')
           {  
                 elementValue =  reader.getText();
         }
         else if (elementValue != null && reader.getText() != 'NOK')
         {    
             if ( (reader.getText()).trim()=='Action execution fail: No action available for specified end status')
             {    elementValue = null;
                     Break;
                     }
              elementValue = elementValue  + ' ' +reader.getText();
                  
         }
         else if (elementValue == null && reader.getText() == 'OK')     
         Break;
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
    
    
}