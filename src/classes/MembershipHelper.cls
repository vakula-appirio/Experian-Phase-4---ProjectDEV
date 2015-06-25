/**=====================================================================
 * Appirio, Inc
 * Name: MembershipHelper
 * Description: T-364083: Membership: Custom List Button on Account
 * Created Date: Feb 23th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By           Description of the update
 * 24th, Feb 2015           Noopur                T-364091 : Modified the method
 *                                                createMembership to create the URL
 *                                                when button on Opportunity page is clicked.
 * Feb 25th, 2015           Naresh                T-365688: Membership: Submit button.
 * Mar 24th, 2015           Noopur                uncommented the saveURL portion in the redirectUrl,which was commented earlier.
 * May 5th, 2015            Nathalie              Recomment saveURL - per Angela, user should not be redirected
 * June 5th, 2015            Tyaga                 Added Function to check for presence of attachment or confidential record before record is submitted.
  =====================================================================*/
 global class MembershipHelper {

    //==========================================================================
   // Webservice method to deepCopy of Business_Process_Template__c
   //==========================================================================
   webservice static String createMembership(String recordTypeName,Id accId, String accName,Id oppId) {
    String oppName = '';

    String RecordTypeId = DescribeUtility.getRecordTypeIdByName('Membership__c',recordTypeName);
    // String memberShipObjPrefix = Custom_Object_Prefixes__c.getInstance().Membership__c;
    String redirectUrl = '/'+DescribeUtility.getPrefix('Membership__c')+'/e?RecordType=';

    redirectUrl += RecordTypeId != ''?RecordTypeId:'';

    if ( oppId != null) {
        redirectUrl += '&retURL=/'+oppId;//+'&saveURL=/'+oppId;
    }
    else if ( accId != null) {
        redirectUrl += '&retURL=/'+accId;//+'&saveURL=/'+accId;
    }

    if ( oppId != null) {
        for ( Opportunity opp: [SELECT Id,Name,AccountId,Account.Name
                              FROM Opportunity
                              WHERE Id = :oppId]) {
        if ( opp.AccountId != null) {
          accId = opp.AccountId;
          accName = opp.Account.Name;
        }
        oppName = opp.Name;
      }
    }

    Contact con = new Contact();
    if ( accId != null) {
      for (Contact conObj :[SELECT Id, Name
                              FROM Contact
                              WHERE AccountId = :accId
                              AND Contact_Role__c = 'Primary']) {
        con = conObj;
      }
    }

    redirectUrl += con.Id != null?'&CF' + Custom_Fields_Ids__c.getInstance().Membership_Contact__c+'='+con.Name+'&CF' + Custom_Fields_Ids__c.getInstance().Membership_Contact__c+'_lkid='+con.Id:'';
    redirectUrl += accId != null ? '&CF' + Custom_Fields_Ids__c.getInstance().Membership_Account__c+'='+accName+'&CF' + Custom_Fields_Ids__c.getInstance().Membership_Account__c+'_lkid='+accId :'';
    redirectUrl += oppId != null ? '&CF' + Custom_Fields_Ids__c.getInstance().Membership_Opportunity__c+'='+oppName+'&CF' + Custom_Fields_Ids__c.getInstance().Membership_Opportunity__c+'_lkid='+oppId :'';




    return redirectUrl ;
   }

    //==========================================================================
   // Webservice method to deepCopy of Business_Process_Template__c
   //==========================================================================
   webservice static String submitMembership(String membershipId) {
    
     Membership__c membership = null;
     
     for (Membership__c mShip : [SELECT ID, Submit__c, Bill_Code__c FROM Membership__c WHERE ID =: membershipId]) {
         membership = mShip;
     }
     system.debug('********membership::::::'+membership);
     //If no membership record.
     if (membership == null) {
         return System.Label.MEMBERSHIP_ERR_NORECORD;
     } else if (membership.Submit__c == true) {
         return System.Label.MEMBERSHIP_ERR_ALREADY_SUBMITTED;
     }
     
     try{
       membership.Submit__c = true;
       update membership;
      } catch(DMLException ex) {
           apexLogHandler.createLogAndSave('MembershipHelper','submitMembership', ex.getStackTraceString(), ex);
           String msg = '';
           for (Integer i = 0; i < ex.getNumDml(); i++) {
             msg += ex.getDmlMessage(i); 
           }
          return 'Error: ' + msg;
      }
     return System.Label.MEMBERSHIP_MSG_SUCCESS;
   }

   //==========================================================================
   // Method to check the Count of Attachment or Confidentiality informaiton 
   //   before submitting mem req.
   //==========================================================================

    webservice static String CheckAttachment(String membershipId) {
    

         Boolean IsAttchment= false;
         string returnsuccess ='success';
         string returnfailure ='failure';
         List<Confidential_Information__c> MemConfAttach = [select Id from Confidential_Information__c where Membership__c =:membershipId];
         for(Confidential_Information__c MemConfobj : [select Id from Confidential_Information__c where Membership__c =:membershipId]){
               List<attachment> ConfiAtt = [select Id,Name from attachment where parentid=:MemConfobj.Id];               
                if(ConfiAtt.size()>0)
                 {
                  IsAttchment = true;
                  break;                
                 }         
          }     
         if(IsAttchment == false)
         return returnfailure;
         else 
         return returnsuccess;
    
    
    }//End of class





}