public class SMXSurveyWizardController{
    
   public PageReference redirectToFeedbackDetail()
    {       
        String strSFDCAPIServer = '';
        String strEndPointJSecurityCheck = '';
        String strXPEnterpriseID = '';
        String strXPSecurityToken = '';
        if(!Test.isRunningTest()){
            SMXConfiguration__c smx_config = SMXConfiguration__c.getValues('Configuration');
            strXPEnterpriseID = smx_config.ID_XP_ENTERPRISE__c;
            strSFDCAPIServer=smx_config.URL_SALESFORCE_API_SERVER__c;
            strEndPointJSecurityCheck=smx_config.URL_JSECURITY_CHECK__c;
            strXPSecurityToken = smx_config.XP_SECURITYTOKEN__c;
        }
         System.debug('Debug to create uwl');
        String strProviderID = ApexPages.CurrentPage().getParameters().get('ProvID');
        String strPageURL = ApexPages.CurrentPage().getParameters().get('PURL');
        String strSessionID = UserInfo.getSessionId() ;
        String strUserName = userInfo.getUserName();
        String strUserId = userInfo.getUserId();
        Feedback__c fbkId = [Select Name,Contact__c from Feedback__c where Name =: strProviderID ];
        //Contact FetchAccount = [Select Account.Name,Account.ID,Account.OwnerId from contact where Id=: fbkId.Contact__c];       
        String partnerServerURL = ApexPages.currentPage().getHeaders().get('Host'); 
        System.debug(''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']');             
        return new PageReference (''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']');      
    }    
    
    
    /******** Test Methods ************/
    
     @isTest(SeeAllData=true)  
     static void testRedirectToFeedbackDetail(){
        String strProviderID = prepareTestDataRedirectToFeedbackDetail();
        PageReference pageRef = Page.SMXSurveyDetails;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ProvID', strProviderID );
        
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        
        String nextPage = controller.redirectToFeedbackDetail().getUrl();
        cleanupTestDataRedirectToFeedbackDetail();
     }
     
  static String prepareTestDataRedirectToFeedbackDetail(){     
    List<Contact> contactList = new List<Contact>();
    Contact c = new Contact();
    c.put('FirstName','SMXTestCtctFName');
    c.put('LastName','SMXTestCtctLName');
    contactList.add(c);
    insert contactList;
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Feedback__c feedback = new Feedback__c();
    feedback.Name = 'TEST_CRM_12345';
    feedback.Contact__c = c.Id; //ContactName
    feedback.DataCollectionId__c = '123456';
    feedback.Status__c = 'Test_Nominated';               
    feedback.DataCollectionName__c = 'Test Survey Name';
    feedback.PrimaryScore__c = 9;
    feedback.PrimaryComment__c = 'Test comment';
    feedback.Status__c = 'Test Status';
    feedback.StatusDescription__c = 'Test Description';
    feedback.SurveyDetailsURL__c = '';
    feedbackList.add(feedback);    

    insert feedbackList;    
    
    return feedback.Name;
  }
  
  static void cleanupTestDataRedirectToFeedbackDetail(){
   Contact c = [SELECT Id, Name FROM CONTACT WHERE FirstName = 'SMXTestCtctFName']; 
   delete c;
  }
  
  
}