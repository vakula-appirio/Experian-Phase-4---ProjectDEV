/**=====================================================================
 * Experian
 * Name: DrapAndDropRESTAPI
 * Description: I-156934 Attachment uploads fail > 4.5MB
 * Created Date: Apr 23rd, 2015
 * Created By: Paul Kissick
 *
 * Date Modified                Modified By                  Description of the update
  =====================================================================*/
@RestResource(urlMapping='/DragAndDrop/v1/*')
global with sharing class DragAndDropRESTAPI {
  
  @HttpPost
  global static void attachDoc(){
        
    RestRequest req = RestContext.request;
    RestResponse res = Restcontext.response;

    String fName = req.params.get('FileName');
    String parId = req.params.get('parId');
    String contentType = req.params.get('cType');
    Blob postContent = req.requestBody;

    Attachment a = new Attachment(
      ParentId = parId, 
      Body = postContent, 
      Name = fName, 
      ContentType = contentType
    );
    try {
      insert a;
      res.responseBody = Blob.valueOf(a.Id);
    }
    catch(Exception  ex) {
    	res.statuscode = 500;
      DragnDropFileUploadController.sendMailOnFailure(ex.getMessage());
    }
    return;
  }
}