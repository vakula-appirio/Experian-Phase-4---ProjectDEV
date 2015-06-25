/**=====================================================================
 * Name: MergeHistoryUtility
 * Description: Utility class to build MergeHistory__c records. Case #29746
 * Created Date: Feb 19th, 2015
 * Created By: Paul Kissick
*/
public without sharing class MergeHistoryUtility {
  
  // Take 2 sobjects (only Lead, Contact and Account will be supported here) and create a MergeHistory record.
  public static MergeHistory__c createMergeHistoryRecord(sObject loserRec, sObject winnerRec) {
    
    MergeHistory__c mh = new MergeHistory__c();
    String objectType = loserRec.getSObjectType().getDescribe().getLocalName();
    mh.Object_Type__c = objectType;
    mh.Loser_Record_ID__c = (String)loserRec.get('Id');
    mh.Winner_Record_ID__c = (String)winnerRec.get('Id');
    if (objectType == 'Account') {
      try {
        mh.Loser_CSDA_Integration_ID__c = (String)loserRec.get('CSDA_Integration_ID__c');
        mh.Loser_EDQ_Integration_Id__c = (String)loserRec.get('EDQ_Integration_Id__c');
        mh.Loser_Top_Parent_ID__c = (String)loserRec.get('Ultimate_Parent_Account__c');
        mh.Loser_Global_Unique_ID__c = (String)loserRec.get('Global_Unique_ID__c');
        mh.Loser_Experian_ID__c = (String)loserRec.get('Experian_ID__c');
        mh.Loser_SaaS_Ind__c = (Boolean)loserRec.get('Saas__c');
        mh.Winner_CSDA_Integration_ID__c = (String)winnerRec.get('CSDA_Integration_ID__c');
        mh.Winner_EDQ_Integration_Id__c = (String)winnerRec.get('EDQ_Integration_Id__c');
        mh.Winner_Top_Parent_ID__c = (String)winnerRec.get('Ultimate_Parent_Account__c');
        mh.Winner_Global_Unique_ID__c = (String)winnerRec.get('Global_Unique_ID__c');
        mh.Winner_Experian_ID__c = (String)winnerRec.get('Experian_ID__c');
        mh.Winner_SaaS_Ind__c = (Boolean)winnerRec.get('Saas__c');
      }
      catch (SObjectException soex) {
        system.debug('createMergeHistoryRecord : field missing : '+soex.getMessage());
        apexLogHandler.createLogAndSave('MergeHistoryUtility','createMergeHistoryRecord', soex.getStackTraceString(), soex);
      }
      mh.put('Account__c',(Id)winnerRec.get('Id'));
    }
    if (objectType == 'Contact') {
      try {
        // mh.Loser_CSDA_Integration_ID__c = (String)loserRec.get('CSDA_Integration_ID__c');
        mh.Loser_EDQ_Integration_Id__c = (String)loserRec.get('EDQ_Integration_Id__c');
        mh.Loser_Global_Unique_ID__c = (String)loserRec.get('Global_Unique_ID__c');
        mh.Loser_Experian_ID__c = (String)loserRec.get('Experian_ID__c');
        mh.Loser_SaaS_Ind__c = (Boolean)loserRec.get('Saas__c');
        // mh.Winner_CSDA_Integration_ID__c = (String)winnerRec.get('CSDA_Integration_ID__c');
        mh.Winner_EDQ_Integration_Id__c = (String)winnerRec.get('EDQ_Integration_Id__c');
        mh.Winner_Global_Unique_ID__c = (String)winnerRec.get('Global_Unique_ID__c');
        mh.Winner_Experian_ID__c = (String)winnerRec.get('Experian_ID__c');
        mh.Winner_SaaS_Ind__c = (Boolean)winnerRec.get('Saas__c');
      }
      catch (SObjectException soex) {
        system.debug('createMergeHistoryRecord : field missing : '+soex.getMessage());
        apexLogHandler.createLogAndSave('MergeHistoryUtility','createMergeHistoryRecord', soex.getStackTraceString(), soex);
      }
      mh.put('Contact__c',(Id)winnerRec.get('Id'));
    }
    /*
    // Commenting out as there is no lead merging handling yet 
    if (objectType == 'Lead') {
      mh.put('Lead__c',(Id)winnerRec.get('Id'));
    }
    */
    
    return mh;
  }

}