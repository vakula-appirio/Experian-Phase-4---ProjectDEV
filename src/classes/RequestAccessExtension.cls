/**=====================================================================
 * Appirio, Inc
 * Name: RequestAccessExtension
 * Description: Request Account Access
 * Created Date: Oct 17th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014								Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * May 01st, 2014               Arpita Bose                  Updated catch(Exception)to catch(DMLException)
 =====================================================================*/

public  class RequestAccessExtension{

public SObject rec{get;set;}
public String name{get;set;}
public String objName{get;set;}
public String strMessage{get;set;}
public Case newCase {get;set;}
public String retURL {get;set;}

    //Constructor
    public RequestAccessExtension()
    {
        Id recId = (Id)ApexPages.currentPage().getParameters().get('id');
        
        objName = recId.getSObjectType().getDescribe().getName();
        
        //Build Dynamic Query
        String queryString = 'SELECT Id,Name FROM ' + objName + ' WHERE Id=\'' + recId+ '\'';
        
        //Execute query.
        rec = Database.query(queryString);
        
        name = (String)rec.get('Name');
        
        //Create new instance of Case.
        newCase = new Case();
        newCase.Requestor__c = UserInfo.getUserId();
        
        //Populate correct field with Id.
        newCase.put((objName.contains('__')?objName:(objName.equalsIgnoreCase('Account')?'Account__c':objName+'Id')),recId);
            
        //Add default Info message.
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Label.ASS_Message_dont_have_access_to_record)); 
        
        
        //Populate RecordTypeId from Custom setting.
        Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        

        if(custSettings!=null && custSettings.Case_Access_Request_RecordtypeId__c!=null)
            newCase.RecordTypeId = custSettings.Case_Access_Request_RecordtypeId__c;

        
        //Return URL
        retURL =  ApexPages.currentPage().getParameters().get(Constants.PARAM_NAME_RETURL); 
        retURL = (retURL == null) ? String.valueOf(Page.ASS_AccountSmartSearch) : retURL;
    }//END: Constructor
    
   
    //Submit request
    public pagereference submitCase()
    {
         try
         {
             //Let the Case Assignment Rule run.
             Database.DMLOptions dmo = new Database.DMLOptions();
             dmo.assignmentRuleHeader.useDefaultRule = true;
             newCase.setOptions(dmo);
            
             newCase.subject=Label.ASS_Case_Access_Request_Subject + ' ' + Name;
             //Insert Case
             insert newCase;
             
             //Retrive CaseTeamRole name from Custom Setting.
             Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
             
             //Retrive CaseTeamRole recordId by name
             CaseTeamRole ctrRec = [SELECT Id,Name,AccessLevel FROM CaseTeamRole where Name=:custSettings.Case_Access_Request_TeamRole__c];
             
             
             //Create CaseTeamMember record and populate fields.
             CaseTeamMember ctmRec = new CaseTeamMember();
             ctmRec.ParentId=newCase.id;
             ctmRec.MemberId=UserInfo.getUserId();
             ctmRec.TeamRoleId=ctrRec.id;
             
             //Create CaseTeamMember record to share to the creator of Case.
             insert ctmRec;
             
             //Query CaseNumber.
             newCase = [Select CaseNumber,Description from case where id=:newCase.id];
             
             //Show as Info message the Case Number to user.
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Label.ASS_Message_Thank_you_request_being_processed+ + '<b><a href="/'+newCase.Id+'">'+newCase.CaseNumber+'</a></b>'));
         }catch(DMLException ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage())); 
            apexLogHandler.createLogAndSave('RequestAccessExtension','submitCase', ex.getStackTraceString(), ex);
			      for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
			        newCase.addError(ex.getDMLMessage(indx));
			      }             
         }
         
         return null;
   }//END: Method submitCase
}