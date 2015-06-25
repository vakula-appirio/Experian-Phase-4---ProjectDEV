/**=====================================================================
 * Appirio, Inc
 * Name: TestMethodUtilities
 * Description: Utility class
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 16th, 2015               Arpita Bose                  T-370246: Added value for Contract_Renewal_Job_Last_Run__c
 =====================================================================*/
public with sharing class TestMethodUtilities {
  public static Account ultimateParent;
  public static Account childOne;
  public static Account childTwo;

  public static void createTestGlobalSettings() {
    Global_Settings__c lastRun = new Global_Settings__c();
    lastRun.Account_Team_Member_Job_Last_Run__c = system.now().addSeconds(-20);
    lastRun.Account_Team_Member_CI_Job_Last_Run__c =  system.now().addSeconds(-20);
    //lastRun.BUHierarchy_Job_Last_Run__c =  system.now().addSeconds(-80);
    lastRun.Contract_Renewal_Job_Last_Run__c = system.now().addSeconds(-20);
    lastRun.AccSegmentCreationViaATM_Job_Last_Run__c = system.now().addSeconds(-20);
    lastRun.Name = (Constants.GLOBAL_SETTING);
    insert lastRun;
  }
   
  public void createTestUltimateParentAndChildAccounts() {
    ultimateParent = new Account(Name = 'Ultimate Parent', DQ_Status__c = 'Pending', 
                                 Region__c = 'APAC', Type = 'Prospect' , Industry = 'Apparel');
    insert ultimateParent;
    childOne = new Account(Name = 'Child One', DQ_Status__c = 'Pending', Region__c = 'APAC', Type = 'Prospect' , 
                           Industry = 'Apparel', Ultimate_Parent_Account__c = ultimateParent.id);
    insert childOne;                       
    childTwo = new Account(Name = 'Child Two', DQ_Status__c = 'Pending', Region__c = 'APAC', Type = 'Prospect' , 
                           Industry = 'Apparel', Ultimate_Parent_Account__c = ultimateParent.id);
    insert childTwo;
      
  }
   
  public Account getUltimateParent() {
    return ultimateParent;
  }
   
  public Id getUltimateParentId() {
    return ultimateParent.id;
  }
   
  public Id getchildOneId() {
    return childOne.id;
  }
   
  public Id getchildTwoId() {
    return childTwo.id;
  }
}