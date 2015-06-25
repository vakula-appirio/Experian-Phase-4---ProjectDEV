/***************************************************************************
    Name : WebToCaseRestService_Test
    Created By : Vaibhav Goel ( Appirio)
    Created Date : April 30, 2015
    Description : Class to test the workings of the WebToCaseRestService class
              
***************************************************************************/
@isTest
private class WebToCaseRestService_Test {
  
  
    static String firstName = 'John';
    static String lastName = 'Doe';
    static String phone = '00441212851';
    static String email = 'john.doe@test.com';
    static String caseType = 'Concern';
    static String isAbout = 'IsAbout1';
    static String description = 'Details';
  

    /*
    * Description: Test where email parameters are passed in.
    * Expected Result: Case eillnot be created as Email should be provided for contact record.
    */
    static testMethod void noEmailPassed(){
    
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/v1/cases';
            req.httpMethod = 'POST';

        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();
        supportCase.contact = new Contact(FirstName=firstName,LastName=lastName);
        supportCase.supportCase = new Case(Type=caseType, Description=description);

        // Call Apex REST
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);

        // Assert that all is working as expected
        System.assertEquals(false, result.success);
        System.assert(result.message.startsWith('No email')); // Assert that a Case Id is returned. 
      
           
    }
  
    /*
    * Description: Test where all contact details match a contact in the system and all contact details match.
    * Expected Result: Case is created with appropriate Record Type and attached to existing Contact.
    */
    static testMethod void matchingAllContactDetails(){

        // Create a contact that will match all of the request's contact details
        Contact existingContact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone, Email=email);
        insert existingContact;

        // Create Global settings
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/v1/cases';
            req.httpMethod = 'POST';

        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();
        supportCase.contact = new Contact(FirstName=firstName,LastName=lastName,Phone=phone,Email=email);
        supportCase.supportCase = new Case(Type=caseType, Description=description);

        // Call Apex REST
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);
        system.debug('---result.message----' + result.message);
        // Assert that all is working as expected
        System.assertEquals(true, result.success);
        System.assert(result.message.startsWith('500')); // Assert that a Case Id is returned. 
      
        if(result.success){

            Case c = [Select RecordType.Name, ContactId, Type, Description from Case where Id=:result.message];
            System.assertEquals('EMS',c.RecordType.Name);
            System.assertEquals(caseType,c.Type);
            System.assertEquals(description,c.Description);

            Contact contact = [Select FirstName, LastName, Phone, Email from Contact where Id=:c.ContactId];
            System.assertEquals(existingContact.Id,contact.Id);
            System.assertEquals(firstName,contact.FirstName);
            System.assertEquals(lastName,contact.LastName);
            System.assertEquals(phone,contact.Phone);
            System.assertEquals(email,contact.Email);
        
        
        }
    }
  
    /*
    * Description: Test where Email doesn't matches a contact in the system and all of the other contact details match.
    * Expected Result: Case is created with appropriate Record Type and attached to new Contact. 
    */
    static testMethod void matchingAllButEmail(){
    
        // Create a contact that will match the request's contact phone details but nothing else
        Contact existingContact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone, Email='johnny.does@test.com');
        insert existingContact;
        
        // Create Global settings
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
  
        req.requestURI = '/services/apexrest/v1/cases';
        req.httpMethod = 'POST';
      
        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();
        supportCase.contact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone,Email=email);
        supportCase.supportCase = new Case(Type=caseType, Description=description);

        // Call Apex REST
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);
      
        // Assert that all is working as expected
        System.assertEquals(true, result.success);
        System.assert(result.message.startsWith('500')); // Assert that a Case Id is returned. 
      
        if(result.success){

            Case c = [Select RecordType.Name, ContactId, Type, Description from Case where Id=:result.message];
            System.assertEquals('EMS',c.RecordType.Name);
            System.assertEquals(caseType,c.Type);
            System.assertEquals(description,c.Description);

            Contact dumContact;
            for(Contact con : [Select FirstName, LastName, Phone, Email from Contact where Id=:c.ContactId] ) {
                dumContact = con;
            }
            if(dumContact!=null) {
                System.assertNotEquals(firstName,dumContact.FirstName);
                System.assertNotEquals(lastName,dumContact.LastName);
                System.assertNotEquals(email,dumContact.Email);
            }
        }
    }
  
    /*
    * Description: Test where phone matches 2 contacts in the system and all other contact details match.
    * Expected Result: Case is created with appropriate Record Type and attached to oldest existing Contact. The custom Webform Contact details are also not filled in.
    */
    static testMethod void matchingTwoContacts(){
    
        // Create 2 Contacts that will match the details of the incoming request's contact details.
        Contact existingContactOne = new Contact(FirstName=firstName,LastName=lastName, Phone=phone, Email=email);
        insert existingContactOne;
        
        Contact existingContactTwo = new Contact(FirstName=firstName,LastName=lastName, Phone=phone, Email=email);
        insert existingContactTwo;
        
        // Create Global settings
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
      
            req.requestURI = '/services/apexrest/v1/cases';
            req.httpMethod = 'POST';
          
        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();

        supportCase.contact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone,Email=email);
        supportCase.supportCase = new Case(Type=caseType, Description=description );

        // Call Apex REST
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);

        // Assert that all is working as expected
        System.assertEquals(true, result.success);
        System.assert(result.message.startsWith('500')); // Assert that a Case Id is returned.
          
        if(result.success){
        
            Case c = [Select RecordType.Name, ContactId, Type, Description from Case where Id=:result.message];
            System.assertEquals(caseType,c.Type);
            System.assertEquals(description,c.Description);
            
            Contact contact = [Select FirstName, LastName, Phone, Email from Contact where Id=:c.ContactId];
            System.assertEquals(existingContactOne.Id,contact.Id);
            System.assertEquals(firstName,contact.FirstName);
            System.assertEquals(lastName,contact.LastName);
            System.assertEquals(phone,contact.Phone);
            System.assertEquals(email,contact.Email);
        }
    }
  
  
  
    /*
    * Description: Test successful match of Contact where there is also an Attachment to be added to the Case.
    * Expected Result: Case is created with appropriate Record Type and attached to existing Contact. An Attachment is also added to the Case.
    */
    static testMethod void addAttachment(){
    
        // Create a contact that will match all of the request's contact details
        Contact existingContact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone, Email=email);
        insert existingContact;

        // Create Global settings
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        // Set up the file attachment as a base64 string
        String text = 'This is the contents of the file.';
        Blob testFile = Blob.valueof(text);
        String base64EncodedString = Encodingutil.base64Encode(testFile);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/v1/cases';
        req.httpMethod = 'POST';
          
        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();
        supportCase.contact = new Contact(FirstName=firstName,LastName=lastName, Phone=phone,Email=email);
        supportCase.supportCase = new Case(Type=caseType, Description=description);
        //supportCase.lstJSONAttachment[0].fileBodyAsBase64 = base64EncodedString;
        //supportCase.lstJSONAttachment[0].fileName = 'testfile.txt';
          
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);
          
        // Assert that all is working as expected
        System.assertEquals(true, result.success);
        System.assert(result.message.startsWith('500')); // Assert that a Case Id is returned. 
          
        if(result.success){
            
            Case c = [Select RecordType.Name, ContactId, Type, Description from Case where Id=:result.message];
            System.assertEquals('EMS',c.RecordType.Name);
            System.assertEquals(caseType,c.Type);
            System.assertEquals(description,c.Description);
            
            Contact contact = [Select FirstName, LastName, Phone, Email from Contact where Id=:c.ContactId];
            System.assertEquals(existingContact.Id,contact.Id);
            System.assertEquals(firstName,contact.FirstName);
            System.assertEquals(lastName,contact.LastName);
            System.assertEquals(phone,contact.Phone);
            System.assertEquals(email,contact.Email);
            
            
            //List<Attachment> caseAttachment = [Select Id, OwnerId, ParentId, Name from Attachment where ParentId=:c.Id];
            //System.assertEquals(1,caseAttachment.size());
            //System.assertEquals('testfile.txt',caseAttachment.get(0).Name);
        
        }
    }
  
    /*
    * Description: Test where required parameters for the Objects being created are not passed in (e.g. LastName for Contact)
    * Expected Result: An appropriate error message is returned with details of the offending parameter.
    */
    static testMethod void requiredFieldMissing(){
        
        // Create Global settings
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
      
        req.requestURI = '/services/apexrest/v1/cases';
        req.httpMethod = 'POST';

        // Create request payload
        WebToCaseRestService.SupportCase supportCase = new WebToCaseRestService.SupportCase();
        supportCase.contact = new Contact(FirstName=firstName);
        supportCase.supportCase = new Case(Type=caseType, Description=description);

        // Call Apex REST
        WebToCaseRestService.ReturnClass result = WebToCaseRestService.doPost(supportCase);

        // Assert that all is working as expected
        System.assertEquals(false, result.success);
        system.debug('---result.message----' + result.message);
        //System.assert(result.message.contains('REQUIRED_FIELD_MISSING'));
        //System.assert(result.message.contains('LastName'));
    }
}