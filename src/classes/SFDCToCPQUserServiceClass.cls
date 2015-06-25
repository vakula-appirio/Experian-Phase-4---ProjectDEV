/*******************
Created BY : Richard Joseph.
Created Date: Aug 22nd 2014.
Desc: Service class takes inparameter as User record and calls CPQ User Administration for User Creation or Update.

Sep29th 2014 - Richard Joseph - Added User Region to drive CPQ Company value
April 2nd - 2015- Richard Joseph - added CSDA fields Bill plan user and CSDA Quote User
April 10th 2015 - Added validation to skip null/empty CPQ User Type.
26th May, 2015 - Paul Kissick - Fixed code formatting
June 1st 2015 - Case # 00944115 Added logic to include 'Decision Analytics' BU also to Map it to CS company value.
*************/
public class SFDCToCPQUserServiceClass {
  
  public static HttpResponse responseCPQ;
  
  @future(callout=true)
  public static void callCPQUserAdminSerivceAsync(Id userId){ 
    //RJ - 4/2/15 Added Global_Business_Line__c to the query.
    user userRecord = [Select u.Username, u.Title, u.State, u.PostalCode, u.Phone, u.Name, u.MobilePhone, u.LastName, u.IsActive, u.FirstName, u.Email, u.Country__c, u.CompanyName,u.Country, u.City, u.CPQ_User__c, u.CPQ_User_Type__c,u.street,u.Alias,u.Region__c,u.Global_Business_Line__c,CSDA_Create_Quote_User__c,CSDA_Bill_Plan_User__c  From User u where id = :userId];  
    if(userRecord != null) {
      callCPQUserAdminSerivce(userRecord);
    }
  }
  
  public static void callCPQUserAdminSerivce(User userRecord ){
    
    CPQ_Settings__c CPQSetting = CPQ_Settings__c.getInstance('CPQ');
    system.debug('===========+=====CPQ' + CPQSetting);
    //[RJ]- Added company value to override the default Experian with region spec company values.
    String companyValue = CPQSetting.Company_Code__c;
    //RJ- Added CSDA Credit Services company logic.
    //RJ - Added logic to include 'Decision Analytics' BU also to Map it to CS company value in CPQ Case#00944115
    if (userRecord.Global_Business_Line__c == 'Credit Services' || userRecord.Global_Business_Line__c == 'Decision Analytics') {
      if (userRecord.Region__c == 'UK&I') {
        companyValue = 'CS UK&I';
      }
      else if (userRecord.Region__c == 'North America') {
        companyValue = 'CS NA';   
      }
    }
    else {
      if (userRecord.Region__c == 'UK&I') {
        companyValue = 'EDQ UK&I';
      }
      else if (userRecord.Region__c == 'North America') {
        companyValue = 'EDQ NA';
      }
      else if (userRecord.Region__c == 'APAC') {
        companyValue = 'EDQ APAC';
      }
      else if (userRecord.Region__c == 'EMEA') {
        companyValue = 'EDQ EMEA';
      }
    }
    String userProperties = '<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:web=\"http://webcominc.com/\">';
    userProperties += '<soapenv:Header/>';
    userProperties += '<soapenv:Body>';
    userProperties += '<UserAdministration xmlns="http://webcominc.com/">';
    userProperties += '<userNameAtDomain>'+CPQSetting.CPQ_API_UserName__c+'</userNameAtDomain>';
    userProperties += '<password>'+CPQSetting.CPQ_API_Access_Word__c+'</password>';
    userProperties += '<action>ADDORUPDATE</action>';
    userProperties += '<xDoc>';

    userProperties += '<USERPROPERTIES xmlns=\"\">'; 
    userProperties +='<USERNAME>'+userRecord.Username+'</USERNAME>';
    userProperties +='<PASSWORD>Password'+(Math.round(Math.random()*1000)) +'</PASSWORD>';
    userProperties +='<TITLE>'+ ((userRecord.Title ==null ? '':userRecord.Title )).escapeHtml4()+'</TITLE>';
    userProperties +='<FIRSTNAME>'+(userRecord.FirstName).escapeHtml4()+'</FIRSTNAME>';
    userProperties +='<LASTNAME>'+(userRecord.LastName).escapeHtml4()+'</LASTNAME>';
    if ((userRecord.CPQ_User_Type__c ) != null) {
      userProperties +='<TYPE>'+(userRecord.CPQ_User_Type__c ).escapeHtml4()+'</TYPE>';
    }
    userProperties +='<EMAILADDRESS>'+(userRecord.email).escapeHtml4()+'</EMAILADDRESS>';
    userProperties +='<ADDRESS1>'+((userRecord.Street ==null ? '' :userRecord.Street)).escapeHtml4()+'</ADDRESS1>';
    userProperties +='<ADDRESS2 />'; 
    //[RJ]- Logic to Activate or Inactivate user
    if(!userRecord.IsActive || !userRecord.CPQ_User__c) {
      userProperties +='<ACTIVE>0</ACTIVE>'; 
    }
    else {
      userProperties +='<ACTIVE>1</ACTIVE>';
    }     
    //[RJ]- Ends
    userProperties +='<CITY>'+((userRecord.city ==null ? '':userRecord.city )).escapeHtml4()+'</CITY>';
    userProperties +='<STATE>'+((userRecord.state==null ? '' :userRecord.state)).escapeHtml4()+'</STATE>';
    userProperties +='<ZIPCODE>'+((userRecord.PostalCode == null ? '' :userRecord.PostalCode )).escapeHtml4()+'</ZIPCODE>';
    userProperties +='<COUNTRY>'+((userRecord.country__c == null ? '':userRecord.country__c )).escapeHtml4() +'</COUNTRY>';
    userProperties +='<PHONENUMBER>'+(userRecord.phone == null ? '' :userRecord.phone)+'</PHONENUMBER>';
    userProperties +='<FAXNUMBER />';
    //[RJ] changed to acpt company code value according to User Region 
    userProperties +='<COMPANYCODE>'+(companyValue).escapeHtml4() +'</COMPANYCODE>';
    userProperties +='<MUSTCHANGEPASSWORD>'+'0'+'</MUSTCHANGEPASSWORD>';
    userProperties +='<PASSWORDLOCKED>'+'0'+'</PASSWORDLOCKED>';
    userProperties +='<ORDERINGPARENT></ORDERINGPARENT>';
    userProperties +='<MANGAGINGPARENT></MANGAGINGPARENT>';
    userProperties +='<APPROVINGPARENT></APPROVINGPARENT>';
    userProperties +='<CrmUserId>'+userRecord.id+'</CrmUserId>';
    userProperties +='<CrmName>'+(userRecord.Name).escapeHtml4()+'</CrmName>';
    userProperties +='<CrmUserName>'+(userRecord.Username).escapeHtml4()+'</CrmUserName>';
    userProperties +='<CrmPassword>'+'</CrmPassword>';
    //RJ change for CSDA fields. CSDA_Create_Quote_User__c
    userProperties += '<CUSTOMFIELDS>';
    userProperties +='<CUSTOMFIELD><NAME>Quote_User</NAME>'+'<VALUE>'+((userRecord.CSDA_Create_Quote_User__c)? 'Y' : 'N')+'</VALUE>'+'</CUSTOMFIELD>';
    userProperties +='<CUSTOMFIELD>'+'<NAME>Bill_Plan_User</NAME>'+'<VALUE>'+((userRecord.CSDA_Bill_Plan_User__c)? 'Y' : 'N')+'</VALUE>'+'</CUSTOMFIELD>';
    userProperties +='</CUSTOMFIELDS>';

    //userProperties +='<DefaultMarket>'+'USD'+'</DefaultMarket>';
    userProperties +='</USERPROPERTIES>';
    userProperties +='</xDoc>';
    userProperties += '</UserAdministration>';
    userProperties +='</soapenv:Body>';
    userProperties += '</soapenv:Envelope>';
    
    string elementValue = 'Not Found';
    Http h = new http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(CPQSetting.CPQ_API_Endpoint__c);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'text/xml;charset=utf-8'); 
    req.setHeader('SOAPAction', '\"http://webcominc.com/UserAdministration\"');
    req.setHeader('Host', 'test.webcomcpq.com');
    req.setTimeout(12000);
    req.setBody(userProperties);
    system.debug('Req:  '+ req.getBody());
    try {
      if(!Test.isRunningtest()) {
        responseCPQ = h.send(req);
      }
      
      system.debug('Body was:  '+ responseCPQ);    
      if(responseCPQ != null && responseCPQ.getStatusCode() == 200) {    
        system.debug('Body was:  '+ responseCPQ);
        system.debug('String was:' + responseCPQ.getBody());
        XmlStreamReader reader = responseCPQ.getXmlStreamReader();
        reader.setNamespaceAware(true);
        while(reader.hasNext()) {
          if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Result') {
            reader.next();
            elementValue = reader.getText();
            system.debug('The element value was:  ' + elementValue);
          }
          reader.next();
        }
      }   
    }
    catch(System.CalloutException e) {
      system.debug('Callout error: '+ e);
      system.debug(responseCPQ.toString());
    }
    catch (Exception e) {
      system.debug('Exception error: '+ e);
    }
  } 
}