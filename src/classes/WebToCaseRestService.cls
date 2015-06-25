//
// (c) 2014 Appirio, Inc.
//
// An Apex REST service that supports the following operation:
// POST /cases; Creates a new Support Case record and Contact & Attachment if necessary.
//
// April 30, 2015   Vaibhav Goel        Original (Ref. T-381861)
// May 7, 2015      Sidhant Agarwal     Modified (Ref. PR-002241)
// May 9, 2015      Sidhant Agarwal     Case added; if no Contact record is sent from Zendesk
// May 14, 2015     Sidhant Agarwal     Logic added for multiple attachments
//

@RestResource(urlMapping='/v1/cases/*')
global with sharing class WebToCaseRestService {
    
    // Error Messages
    public static String errMsg = '';
    public static final String No_Email_Provided = 'No email was provided for this request, please fix this before resubmitting.';
    public static final String EMS = 'EMS';
    /**
    * @author Vaibhav Goel ( Appirio)
    * @date 30/04/2015
    * @description POST method that supports the creation of new cases
            Delegates responsibility to the createSupportCase() method.
    * @return The ReturnClass giving detail about the success or failure of the operation
    */
    @HttpPost
    global static ReturnClass doPost(SupportCase supportCase){
        
        // Call the logic to create the Chatter Message
        ReturnClass returnClass = createSupportCase(supportCase);
        return returnClass;
        
    }
    
    //
    // @author Vaibhav Goel ( Appirio)
    // @date 30/04/2015
    // @modified by Sidhant (Appirio)
    // @description Handles the business logic of inserting the Support Case and related objects.
    // @return The custom ReturnClass object which contains if the operation was a success or not.
    //        If successful, the newly created Case Id will be shown, else an informative error 
    //        will be presented. 
    
    private static ReturnClass createSupportCase(SupportCase supportCase){
        
        ReturnClass returnClass = new ReturnClass();
        
        // The Case Record Type Id to be used when creating the Support Case
        // Currently 'EMS' is the default record type for the cases from Zendesk
        String caseRecordTypeId;
        
        // If a brand has been passed in, make sure that it matches a Case Record Type
        caseRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_EMS );
        //caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(EMS).getRecordTypeId();
        
        // Check if Contact exists
        List<Contact> existingContacts = new List<Contact>();
        if(supportCase.contact != null){
            String email = supportCase.contact.email;
            // Only one of the following queries could get executed 
            if(supportCase.contact.email != null){
                existingContacts = [Select FirstName, LastName, Email, Phone from Contact where Email=:email order by CreatedDate asc limit 1];
            }else{
                returnClass.success = false;
                returnClass.message = No_Email_Provided;
                return returnClass;
                
            }
        }
        
        // Set savepoint to roll back to if there are any errors.
        // If anything goes wrong, we will roll back and present to the user to fix the issue
        Savepoint sp = Database.setSavepoint();
        
        try{
            Case newCase = new Case();
            if(existingContacts.size() == 0){ // If no matching Contact exists
                
                // Create new Support Case without contact
                newCase = supportCase.supportCase;
                newCase.Origin = 'Web';
                newCase.Status = 'New';
                newCase.RecordTypeId = caseRecordTypeId;
                insert newCase;
                
            }else if (existingContacts.size() == 1){ // If a matching Contact exists
                
                Contact existingContact = existingContacts.get(0);
                // Create new Support Case for the existing Contact
                newCase = supportCase.supportCase;
                newCase.Origin = 'Web';
                newCase.Status = 'New';
                newCase.RecordTypeId = caseRecordTypeId;
                newCase.ContactId = existingContact.Id;
                insert newCase;
            }
            // Now add attachment if one has been passed in
            Attachment caseAttachment;
            list<Attachment> lstAttachment = new list<Attachment>();
            if(supportCase!=null && supportCase.lstJSONAttachment!=null && supportCase.lstJSONAttachment.size()>0) {
                for(Integer i=0; i<supportCase.lstJSONAttachment.size(); i++) {
                    caseAttachment = new Attachment();
                    caseAttachment.Body = Encodingutil.base64Decode(supportCase.lstJSONAttachment[i].fileBodyAsBase64);
                    caseAttachment.ParentId = newCase.Id;
                    caseAttachment.Name = supportCase.lstJSONAttachment[i].fileName;
                    lstAttachment.add(caseAttachment);
                }
            }
            if(lstAttachment.size()>0) {
                try {
                   insert lstAttachment;
                }catch(Exception e) {
                    errMsg = e.getMessage();
                    system.debug('Error Message'+errMsg);
                }
            }
            
            returnClass.success = true;
            returnClass.message = newCase.Id;
            return returnClass;
            
        }catch(Exception e){
            
            // If any errors occur
            // Rollback any dmls
            Database.rollback(sp);
            
            // Set up the failure return object
            returnClass.success = false;
            returnClass.message = e.getMessage();
            
            // Exit and return to user
            return returnClass;
            
        }
    }
    
    //
    // @author Vaibhav Goel ( Appirio)
    // @date 30/04/2015
    // @modified by Sidhant (Appirio)
    // @description Class that models the incoming Support Case and related objects request.
    // supportCase: The Support Case details
    // contact: The contact information
    // fileAsBase64: file as Base64 type to be parsed and used to create an Attachment for the Support Case.
    // fileName: The File Name to use when creating the Attachment record.
    //
    global class SupportCase{
        
        public Case supportCase;
        public Contact contact;
        public List<MultipleAttachment> lstJSONAttachment;
    }
    // @author: Sidhant Agarwal
    // @date 14/05/2015
    // @description: Class for storing the Attachments; if attached
    // 
    global class MultipleAttachment{
        
        public String fileBodyAsBase64;
        public String fileName;
    }
    
    // @author Vaibhav Goel ( Appirio)
    // @date 30/04/2015
    // @description Class that models the response to the request to create a Support Case
    //
    global class ReturnClass {
        
        global boolean success = false;
        global String message;
        
    }
}