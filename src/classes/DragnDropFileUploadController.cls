/**=====================================================================
 * Appirio, Inc
 * Name: DragnDropFileUploadController
 * Description: T-358314: Controller class for DragnDropFileUploader component
 * Created Date: Feb 03rd, 2015
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Mar 10th, 2015               Noopur Sundriyal             T-368621: Send email on upload error
 * Apr 23rd, 2015               Paul Kissick                 I-156934: Removed the Test.isRunningTest on the sendMailOnFailure method.
  =====================================================================*/
global with sharing class DragnDropFileUploadController{

    public String parentId {get;set;}
    public static boolean isMailSent = false ;
    /* for ie fall back just to upload the file */
    public Attachment attachment {
      get {
        if (attachment == null) {
          attachment = new Attachment();
        }
        return attachment;
      }
      set;
    }

  //================================================================================================
  // Creates an Attachment on the record
  //================================================================================================
  public Pagereference uploadFile() {
    try {
      attachment.ParentId = parentId;
      insert attachment;
    }
    catch(Exception  ex) {
        sendMailOnFailure(ex.getMessage());
    }
    return null;
  }

  //================================================================================================
  // Gets the custom domain name & SFDC pod
  //================================================================================================
  public String domainURL {
    get {
      String domainURL = URL.getCurrentRequestUrl().getHost();
      return domainURL;
    }
    set;
  }

  //================================================================================================
  // Called from the VF Page and will create an Attachment record
  //================================================================================================
  @RemoteAction
  global static String uploadFile(String parentId, String attachmentId, String fileName, String contentType, String base64BlobValue) {
    /*
    parentId: The sfdc object Id this file will be attached to
    attachmentId: The record of the current Attachment file being processed
    fileName: Name of the attachment
    contentTye: Content Type of the file being attached
    base64BlobValue: Base64 encoded string of the file piece currently processing
    */
    try {
        // If recordId is blank this is the first part of a multi piece upload
        if (String.isBlank(attachmentId)) {
          Attachment att = new Attachment(
                ParentId = parentId,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = fileName,
                ContentType = contentType
          );
          insert att;
    
          // Return the new attachment Id
          return att.Id;
        } else {
          for (Attachment atm : [SELECT Id, Body FROM Attachment WHERE Id = :attachmentId]) {
            // Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
            update new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue));
          }
          // Return the Id of the attachment we are currently processing
          return attachmentId;
        }
    }
    catch(Exception  ex) {
      sendMailOnFailure(ex.getMessage());
      return null;
    }
  }
  
  //============================================================
  //Method to send email to the current user in case the file 
  // upload fails.
  //============================================================
  public static void sendMailOnFailure(String errorMessage) {
    if (isMailSent){
      return;
    }
    else {
      isMailSent = true;
    }
    String email_Body = Label.DragnDrop_Email_Body_For_Upload_Fail + '\n' + errorMessage;
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());      
    mail.setSubject('File Upload Failed');
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setPlainTextBody(email_Body);   
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}