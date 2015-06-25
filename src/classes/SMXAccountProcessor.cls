/*
SMXAccountProcessor acts as WS client for sync party WS and syncs accounts into Xperince.
*/

global class SMXAccountProcessor
{
    global static Integer testHttpStatusCode = 200;
    global static String testHttpResponseXML = '';
    
    /*
      sync an account given an account id
      
      strAccountId - account id      
    */
    global static boolean syncAccount(String strAccountId)
    {   

        Account acc = [select Id,Name,AccountNumber from Account where Id =: strAccountId];
        
        String strXPCreatePartyURL = '';
        String strXPServer = '';
        String strXPSecurityToken = '';
        String strXPEnterpriseID = '';
        
        String strStatus = '';
                
        if(!Test.isRunningTest()){
            strXPCreatePartyURL = SMXConfiguration__c.getValues('Configuration').URL_CREATEPARTY_SERVICE__c;
            strXPServer = SMXConfiguration__c.getValues('Configuration').XP_SERVER__c;
            strXPSecurityToken = SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c;
            strXPEnterpriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
        }
        
        Datetime currentDate = System.now();        
        String strCurrentDate = currentDate.format('yyyy-MM-dd') + 'T' + currentDate.format('HH:mm:ss') + '.00';
        
        // prepare party xml - account equivalent xml
        String strPartyXml = preparePartyXML(strXPEnterpriseID, strXPSecurityToken, acc);
        
        System.debug(strPartyXml); 
        
        HttpRequest req = prepareRequestWithXMLBody(strXPServer,strXPCreatePartyURL, strPartyXml);
        
        return fireHttpRequest(req);        
    }   
    
    // prepare party xml to sync an account
    public static String preparePartyXML(String strXPEnterpriseID, String strXPSecurityToken, Account acc){
        Datetime currentDate = System.now();        
        String strCurrentDate = currentDate.format('yyyy-MM-dd') + 'T' + currentDate.format('HH:mm:ss') + '.00';
        String strXML = '<?xml version="1.0" encoding="utf-8"?>' +   
                  '<utilService><companyIdfier>'+
                  + strXPEnterpriseID +
                  '</companyIdfier>'+               
                  '<securityToken>'+
                  + strXPSecurityToken +
                  '</securityToken>' + 
                  '<party enterprisePartyYN="N" primaryIdfier="'+escapeXml(acc.Id + '')+'" partyTypeCode="ORG" primaryEmailAddressIdfier="company@'+escapeXML(acc.Id)+'.com" enabledYN="Y" updateYN="Y"><partyT-list><partyT nameT="'+escapeXml(acc.Name)+'" descriptionT="'+escapeXml(acc.Id + '')+'" localeCode="en_US" sourceLocaleCode="en_US" translatedTimestamp="'+ strCurrentDate +'"/>'+
                  '</partyT-list></party></utilService>';
        return strXML;
    }
    
    /*
     Prepare an HttpRequest with given strXML 
     strXML - party xml    
    */
    
    public static HttpRequest prepareRequestWithXMLBody(String strXPServer, String strURL, String strXML){
        //construct an HTTP request
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setMethod('POST');
        req.setHeader('Host',strXPServer);
        
        req.setHeader('Connection','keep-alive');
        req.setEndpoint(strURL);
        req.setHeader('Content-Type','text/xml');
        req.setHeader('DataEncoding','UTF-8');
        req.setBody(strXML);
        return req;
    }
    
    /*
      Call SyncParty Xperience WS and sync the account
    */
    public static boolean fireHttpRequest(HttpRequest req){         
            try
            {
                HTTPResponse httpResponse;
                
                if(!Test.isRunningTest()){
                      Http http = new Http();
                      httpResponse = http.send(req); 
                    }
                else{
                      httpResponse = new HttpResponse();
                      httpResponse.setBody(testHttpResponseXML);
                      httpResponse.setStatusCode(testHttpStatusCode); 
                  }
               
               if((httpResponse.getStatusCode()) == 200)
                {
                    String xmlString = httpResponse.getBody();
                    System.debug(xmlString);
                    XMLDom doc= new XMLDom(xmlString);
                    XMLDom.Element compDataXML = (XMLDom.Element)doc.getElementByTagName('webserviceresponse');
                    if(compDataXML != null)
                    {
                        String strResultCode, strResultDescription;
                        XMLDom.Element code = (XMLDom.Element)compDataXML.getElementByTagName('code');
                        if(code != null)
                        strResultCode= code.nodeValue;
                        XMLDom.Element description = (XMLDom.Element)compDataXML.getElementByTagName('message');
                        if(description != null)
                        strResultDescription= description.nodeValue;
                        if (strResultCode == '0')
                        {
                            return true;
                        }
                        if (strResultCode <> '0')
                        {
                            return false;
                        }
                    }
                }
                else if ((httpResponse.getStatusCode()) <> 200)
                {
                    return false;              
                } 
            }
            catch(System.CalloutException e)
            {
                String strMessage = e.getMessage();
                System.debug(strMessage);
                return false;
            } 
            return false;      
    }     

     global static String escapeXML(String strXML){
     return (strXML == null?'':strXML.escapeXML());
     }    
}