/**=====================================================================
 * Appirio, Inc
 * Name: SmartSearchRecordVisibility
 * Description: 
 * Created Date: Oct 16th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 =====================================================================*/
public with sharing class SmartSearchRecordVisibility {

public static string getUserAccessibleAccounts(Set<Id> setAccountIds)
    {
        String returnValue='';
        for(Account rec: [select id from Account where id=:setAccountIds])
        {
            returnValue+=rec.Id+',';
        }
        
        return returnValue;
    }

public static string getUserAccessibleContacts(Set<Id> setContactIds)
    {
        String returnValue='';
        for(Contact rec: [select id from Contact where id=:setContactIds])
        {
            returnValue+=rec.Id+',';
        }
        
        return returnValue;
    }    
    
}