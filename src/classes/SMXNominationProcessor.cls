/*
SMXNominationProcessor class acts a WS client for Satmetrix WS and pushes nomination data into Satmetrix. 
*/
global class SMXNominationProcessor
{
    global static Integer testHttpStatusCode = 200;
    global static String testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>Success</message></status><list><ContactInfo><contactRecordId></contactRecordId><personId></personId><surveyURL>https://nexeosolutions.staging.satmetrix.com</surveyURL></ContactInfo></list></webserviceresponse>';
    
    /*
      Process the survey record. 
      Reads contact mapping information from various mapped Salesforce entities and forms the xml and invokes Satmetrix WS to create a participant
      While creating participant syncs account info as well with Satmetrix
      strFbkId - Name of the survey record to be processed
    */
    global static void processNomination(String strFbkId)
    {
        // read survey record
        Feedback__c fbk = new Feedback__c();
        fbk = [select Feedback__c.Contact__c,Feedback__c.Name,Feedback__c.DataCollectionId__c, Feedback__c.Case__c,Feedback__c.Status__c, Feedback__c.StatusDescription__c, Feedback__c.Opportunity__c, Feedback__c.Order__c from Feedback__c where Feedback__c.Name = :strFbkId];
                        
        String strStatus = '';
        String strXPEnterpriseID = '';
        String strCreateParticipantURL = '';
        String strXPServer = '';
        String strXPSecurityToken = '';
        
        if(!Test.isRunningTest()){
            strXPEnterpriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
            strXPSecurityToken = SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c;
            strXPServer = SMXConfiguration__c.getValues('Configuration').XP_SERVER__c;
            strCreateParticipantURL = SMXConfiguration__c.getValues('Configuration').URL_NOMINATE_CONTACTS__c;
        }
        
        // read account and contact, check contact opt outs etc and sync account to XP
       Contact c = [select Name,Account.Id,Department, Email,FirstName,LastName,Title,HasOptedOutOfEmail, Phone, Salutation from Contact where Id =: fbk.Contact__c];
        
        List<Account> lstAccount = [select Id,Name,Ownerid,NumberOfEmployees,AnnualRevenue,Industry from Account where Id =: c.Account.Id ];      
               
        List<String> lstValidationErrors = validateForScrubRules(fbk, c, lstAccount);      
        
        // process survey record if contact is active and not opted out of email communication
        if(lstValidationErrors.isEmpty())
        {
            Account a = lstAccount.get(0);
            
            // sync the account with Xperience by calling party WS
            SMXAccountProcessor.syncAccount(a.Id);
            
            // prepare participant xml 
            String strParticipantXML = prepareParticipantXML(fbk,c,a,strXPEnterpriseID,strXPSecurityToken);
        
                if(strParticipantXML != '' ){
                            // WS invocation to create participant in Xperience
                HttpRequest req = createHttpRequest(strXPServer,strCreateParticipantURL);    
                
                req.setBody(strParticipantXML);

                Http http = new Http();
                
                try
                {
                    HTTPResponse httpResponse;
                    if(!Test.isRunningTest()){
                     httpResponse = http.send(req);
                     }else{
                     httpResponse = new HttpResponse();
                     httpResponse.setBody(testHttpResponseXML);
                     httpResponse.setStatusCode(testHttpStatusCode);             
                    }
                    if ((httpResponse.getStatusCode()) == 200)
                    {
                        String xmlString = httpResponse.getBody();
                        System.debug('WS response: ' + xmlString);
                        XMLDom doc= new XMLDom(xmlString);
                        XMLDom.Element compDataXML = (XMLDom.Element)doc.getElementByTagName('webserviceresponse');
                        if(compDataXML != null)
                        {
                            String strResultCode, strResultDescription,resultValue;
                            XMLDom.Element code = (XMLDom.Element)compDataXML.getElementByTagName('code');
                            if(code != null)
                            strResultCode= code.nodeValue;
                            XMLDom.Element contactRecordId=(XMLDom.Element)compDataXML.getElementByTagName('contactRecordId');
                            XMLDom.Element description = (XMLDom.Element)compDataXML.getElementByTagName('surveyURL');
                            if(description != null)
                            {
                                strResultDescription= description.nodeValue;
                                Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                                feedback.Status__c = 'Success';
                                if(contactRecordId.nodeValue !=null)
                                    feedback.Name=contactRecordId.nodeValue;
                                if(strResultDescription.contains(strXPServer))
                                    feedback.StatusDescription__c ='Participant Created';
                                else
                                    feedback.StatusDescription__c = strResultDescription;
                                update feedback;
                                strStatus = 'Success';                        
                            }
                            else{
                                if (strResultCode == '0')
                                {
                                    
                                    for(XMLdom.Element ee:compDataXML.getElementsByTagName('message'))
                                    {
                                        resultValue = ee.nodeValue;
                                    }
                                    if (resultValue == 'No Send Rule is applied for the provider')
                                    {
                                        Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                                        feedback.Status__c = 'Skipped';
                                        if(contactRecordId.nodeValue !=null)
                                            feedback.Name=contactRecordId.nodeValue;
                                        feedback.StatusDescription__c = 'No Send Rule Applied';
                                        update feedback;                            
                                        strStatus = 'Failure';
                                        
                                    }
                                    else{
                                        if(!Test.isRunningTest()){
                                        resultValue=resultValue.replace('[','');
                                        resultValue=resultValue.replace(']','');
                                        }
                                        Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                                        feedback.Status__c = 'Skipped';
                                        feedback.StatusDescription__c = resultValue;
                                        update feedback;                            
                                        strStatus = 'Failure';
                                    }
                                    /*if (resultValue != 'No Send Rule is applied for the provider')
                                    {
                                        Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                                        feedback.Status__c = 'Success';
                                        feedback.StatusDescription__c = 'Participant Created';
                                        XMLDom.Element elemRow = (XMLDom.Element)doc.getElementByTagName('row'); 
                                        String strURL = elemRow.getAttribute('value');
                                        feedback.SurveyLink__c = strURL;
                                        update feedback;
                                        strStatus = 'Success';                            
                                    }*/
                                }
                                if (strResultCode <> '0')
                                {
                                    description=(XMLDom.Element)compDataXML.getElementByTagName('description');
                                    strResultDescription= description.nodeValue;
                                    Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                                    
                                    feedback.Status__c = 'Failure';
                                    feedback.StatusDescription__c = strResultDescription;
                                    update feedback;
                                    strStatus = 'Failure';
                                }
                            }
                        }
                    }
                    if ((httpResponse.getStatusCode()) <> 200)
                    {
                        // WS invocation failure
                        String strMessage = httpResponse.getStatus();
                        Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                        
                        feedback.Status__c = 'Failure';
                        feedback.StatusDescription__c = strMessage;
                        update feedback;
                        strStatus = 'Failure';
                        
                    }
                }
                catch(System.CalloutException e)
                {
                    // callout exception
                    String strMessage = e.getMessage();
                    Feedback__c feedback = [select Name, Status__c,StatusDescription__c from Feedback__c where Name = :fbk.Name];
                    
                    feedback.Status__c = 'Failure';
                    feedback.StatusDescription__c = strMessage;
                    update feedback;
                    strStatus = 'Failure';
                    
                }
                
                } else{     
                    fbk.Status__c = 'Failure';
                    //fbk.StatusDescription__c = 'Survey cannot be sent. Unrecognised Survey (not support / relation)';
                    fbk.StatusDescription__c='There is a mapping error occured. Please check the contact mapping.';
                    update fbk;
                }              

        }
    else
        {
            fbk.Status__c = 'Failure';
                     
            if(!lstValidationErrors.isEmpty()){
                String strValidationErrors = '';
                for(String s: lstValidationErrors){
                 strValidationErrors += s;
                }
                fbk.StatusDescription__c = strValidationErrors;
            }
             update fbk;
        }
    }
    
    // utility method to create a http request
    global static HttpRequest createHttpRequest(String strXPServer, String strURL){

        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);

        req.setMethod('POST');
        req.setHeader('Host',strXPServer);
        
        req.setHeader('Connection','keep-alive');
        req.setEndpoint(strURL);
        
        req.setHeader('Content-Type','text/xml');
        req.setHeader('DataEncoding','UTF-8');
        
        return req;
    }
    
    /*
       creates participant xml by reading mapped objects/ attributes
    */
    global static String prepareParticipantXML(Feedback__c fbk, Contact c, Account a, String strXPEnterpriseID, String strXPSecurityToken){      
        
       /* String MailCity = escapeXML(c.MailingCity);
        String MailState = escapeXML(c.MailingState);
        String MailPostalCode = escapeXML(c.MailingPostalCode);
        String MailAddress = MailCity+', '+MailState+', '+MailPostalCode;*/
        
        String strLocaleCode = 'en_US';
        Datetime currentDate = System.now();
        String strCurrentDate = currentDate.format('yyyy-MM-dd') + 'T' + currentDate.format('HH:mm:ss') + '.00';          
        String strPurchaseLevel='';
                 
        String strXML = '';
        String testMode='N';
        
        if(!Test.isRunningTest()){
            if(SMXConfiguration__c.getValues('Configuration').TEST_MODE__c)
                testMode='Y';
        }
        
        strXML = '<?xml version="1.0" encoding="utf-8"?>' +
            '<utilService><enterpriseId>'+
            + strXPEnterpriseID +
            '</enterpriseId>'+        
            '<securityToken>'+
            + strXPSecurityToken +
            '</securityToken>' + 
            '<surveyId>'+
            fbk.DataCollectionId__c+
            '</surveyId>'+
            '<sendMail>Y</sendMail>'+
            '<isTestUpload>'+testMode+'</isTestUpload>'+
            '<contactMap-list>'+
            '<contactMap>' + 
            '<contactMapEntry-list>'+
                '<contactMapEntry key ="Person Identifier" value = "'+fbk.Contact__c+'"/>'+
                '<contactMapEntry key ="First name" value = "'+escapeXML(c.FirstName)+'"/>'+ 
                '<contactMapEntry key ="Person last name" value = "'+escapeXML(c.LastName)+'"/>'+ 
                '<contactMapEntry key ="Email"  value = "'+c.Email+'"/>'+
                '<contactMapEntry key ="Company ID"  value = "'+a.Id+'"/>'+
                '<contactMapEntry key ="Company name"  value = "'+escapeXML(a.Name)+'"/>'+
                '<contactMapEntry key ="Phone"  value = "'+escapeXML(c.Phone)+'"/>'+
                '<contactMapEntry key ="Job Title"  value = "'+escapeXML(c.Title)+'"/>'+
                '<contactMapEntry key ="Person Salutation"  value = "'+escapeXML(c.Salutation)+'"/>'+
                '<contactMapEntry key ="Contact ID"  value = "'+fbk.Contact__c+'"/>'+
                '<contactMapEntry key ="Product"  value = ""/>';
        if(fbk.DataCollectionId__c == 'EXPERIAN_106615'){ // EDQ Support Experience
            List<Case> lstCase=[select id,ClosedDate,ownerid, Description from case where id=:fbk.case__c];
            Case cs;
            user caseOwner;
            List<user> lstcaseOwner;
            String convDate='';
            String strCaseDesc='';
            if(!(lstCase.isEmpty())){
                cs=lstCase.get(0);
                System.debug('Case owner id is '+cs.ownerid);
                if(cs.ownerid!=null){
                    lstcaseOwner=[select Name, email, Country__c, Region__c from user where id=:cs.ownerid];
                    if(!(lstcaseOwner.isEmpty()))
                        caseOwner=lstcaseOwner.get(0);
                }
                
                if(cs.ClosedDate!=null){
                    Datetime newDate=(Datetime)cs.ClosedDate;
                    convDate=newDate.format('yyyy-MM-dd hh:mm:ss');
                }
                strCaseDesc=cs.Description;
                if(String.IsNotBlank(strCaseDesc)){
                    if(strCaseDesc.length()>1650){
                        strCaseDesc=strCaseDesc.substring(0,1650) +'\n <br> ---Case Description truncated to limit the size---</br>\n ';
                    }
                }
            }
            strXML +='<contactMapEntry key ="Initiating event description"  value = "'+escapeXML(strCaseDesc)+'"/>'+
                '<contactMapEntry key ="Initiating event date"  value = "'+convDate+'"/>'+
                '<contactMapEntry key ="Hierarchy 2 node code"  value = "MS"/>';
            if(cs.ownerid!=null){
                strXML +='<contactMapEntry key ="Follow-up Owner 1"  value = "'+caseOwner.email+'"/>'+
                '<contactMapEntry key ="Country"  value = "'+escapeXML(caseOwner.Country__c)+'"/>'+
                '<contactMapEntry key ="Region"  value = "'+escapeXML(caseOwner.Region__c)+'"/>'+
                '<contactMapEntry key ="Account Manager"  value = "'+escapeXML(caseOwner.name)+'"/>';
            }
        }
        else if(fbk.DataCollectionId__c == 'EXPERIAN_106613'){ // EDQ Purchase Experience
            List<Opportunity> lstOpp=[select id,CloseDate,ownerid, Description from Opportunity where id=:fbk.Opportunity__c];
            Opportunity opp;
            List<user> lstoppOwner;
            user oppOwner;
            String convDate;
            if(!(lstOpp.isEmpty())){
                opp=lstOpp.get(0);
                if(opp.ownerid!=null){
                    lstoppOwner=[select Name, email, Country__c, Region__c from user where id=:opp.ownerid];
                    if(!(lstoppOwner.isEmpty()))
                        oppOwner=lstoppOwner.get(0);
                }
                if(opp.CloseDate!=null){
                    Datetime newDate=(Datetime)opp.CloseDate;
                    convDate=newDate.format('yyyy-MM-dd hh:mm:ss');
                }
            }
            strXML +='<contactMapEntry key ="Follow-up Owner 1"  value = "'+oppOwner.email+'"/>'+
                '<contactMapEntry key ="Initiating event description"  value = "Closed Won"/>'+
                '<contactMapEntry key ="Initiating event date"  value = "'+convDate+'"/>'+
                '<contactMapEntry key ="Country"  value = "'+escapeXML(oppOwner.Country__c)+'"/>'+
                '<contactMapEntry key ="Hierarchy 2 node code"  value = "MS"/>'+
                '<contactMapEntry key ="Region"  value = "'+escapeXML(oppOwner.Region__c)+'"/>'+
                '<contactMapEntry key ="Account Manager"  value = "'+escapeXML(oppOwner.name)+'"/>';
        }
        else if(fbk.DataCollectionId__c == 'EXPERIAN_106614'){ // EDQ Contract Renewal
            List<Order__c> lstorder=[select id,Renewal_Survey_Date__c,ownerid, Status__c from Order__c where id=:fbk.Order__c];
            Order__c order;
            List<user> lstorderOwner;
            user orderOwner;
            String convDate;
            if(!(lstorder.isEmpty())){
                order=lstorder.get(0);
                if(order.ownerid!=null){
                    lstorderOwner=[select Name, email, Country__c, Region__c from user where id=:order.ownerid];
                    if(!(lstorderOwner.isEmpty()))
                        orderOwner=lstorderOwner.get(0);
                }
                if(order.Renewal_Survey_Date__c!=null){
                    Datetime newDate=(Datetime)order.Renewal_Survey_Date__c;
                    convDate=newDate.format('yyyy-MM-dd hh:mm:ss');
                }
            }
            strXML +='<contactMapEntry key ="Follow-up Owner 1"  value = "'+orderOwner.email+'"/>'+
                '<contactMapEntry key ="Initiating event description"  value = "'+escapeXML(order.Status__c)+'"/>'+
                '<contactMapEntry key ="Initiating event date"  value = "'+convDate+'"/>'+
                '<contactMapEntry key ="Country"  value = "'+escapeXML(orderOwner.Country__c)+'"/>'+
                '<contactMapEntry key ="Hierarchy 2 node code"  value = "MS"/>'+
                '<contactMapEntry key ="Region"  value = "'+escapeXML(orderOwner.Region__c)+'"/>'+
                '<contactMapEntry key ="Account Manager"  value = "'+escapeXML(orderOwner.name)+'"/>';
        }
        strXML+='</contactMapEntry-list>'+
            '</contactMap>'+
            '</contactMap-list>'+ 
            '</utilService>';
            
        System.debug('>> Result >>'+strXML);     
        return strXML;
    }
    
    global static String escapeXML(String strXML){
        return (strXML == null?'':strXML.escapeXML());
    }    
    
    global static List<String> validateForScrubRules(Feedback__c fbk, Contact c, List<Account> lstAccount){
        List<String> lstErrors = new List<String> ();
            if(lstAccount.isEmpty()){
                lstErrors.add('The contact is not associated with any account\n');
            }
            if(c.HasOptedOutOfEmail){
                lstErrors.add('The contact has opted out of emails\n');
            }
            if(String.isBlank(c.Email)){
              lstErrors.add('There is no email address for the contact\n');        
            }
            if(String.isBlank(c.FirstName)){
              lstErrors.add('Missing first name for the contact\n');        
            }
            if(String.isBlank(c.LastName)){
              lstErrors.add('Missing last name for the contact\n');        
            }  
            
       return lstErrors;
    }
    
}