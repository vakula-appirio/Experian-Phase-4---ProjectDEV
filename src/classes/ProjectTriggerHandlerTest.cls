/**=====================================================================
 * Appirio, Inc
 * Name: ProjectTriggerHandlerTest 
 * Description: To Test functionality of main class ProjectTriggerHandler and its trigger
 * Created Date: Aug 02, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Aug 11th, 2014               Naresh Kr Ojha               T-310542: removed method "test_copyDeliveryTemplatesToProjDeliveryLines( )"
 =====================================================================*/
@isTest
private class ProjectTriggerHandlerTest {

  //Creates project resources on project insertion
  static testMethod void test_createProjectResources() {
    User adminUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert adminUser;
    User newOwner = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert newOwner;

    System.runAs(adminUser) {
      Project__c project = Test_Utils.insertProject(true);
      //On insert case
      System.assert([SELECT ID, Project__c FROM Project_Resource__c WHERE Project__c =: project.ID].size() == 1);

      project.OwnerId = newOwner.ID;
      update project;

      System.assertEquals([SELECT ID, Project__c FROM Project_Resource__c WHERE Project__c =: project.ID].size(), 2);
    }
  }

  //deleting project should remove associated delivery lines
  static testMethod void test_deleteDeliveryLines() {
    User adminUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert adminUser;

    System.runAs(adminUser) {
      Project__c project = Test_Utils.insertProject(true);
      Delivery_Line__c delLine = Test_Utils.insertDeliveryLine(true, project.ID);

      Test.startTest();
      //Inserted delivery line
      System.assertEquals([SELECT ID, Project__c FROM Delivery_Line__c WHERE Project__c =: project.ID].size(), 1);    

      //deleting project should delete delivery line too.
      delete project;
      Test.stopTest();      
      System.assertEquals([SELECT ID, Project__c FROM Delivery_Line__c WHERE Project__c =: project.ID].size(), 0);
    }
  }
  
  //Creating delivery lines for template populated in project (In insert case)
  static testMethod void test_copyDelTempToProjDelLines_InsertCase() {
    User adminUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert adminUser;

    System.runAs(adminUser) {
      List<Delivery_Template_Line__c> delTLines = new List<Delivery_Template_Line__c>();
      Project__c project = Test_Utils.insertProject(false);
      Delivery_Template_Header__c delTempHeader = Test_Utils.insertDeliveryTemplateHeader(true);
      Delivery_Template_Line__c dtl = Test_Utils.insertDeliveryTemplateLine(false, delTempHeader.ID);
      delTLines.add(dtl);
      dtl = Test_Utils.insertDeliveryTemplateLine(false, delTempHeader.ID);
      delTLines.add(dtl);
      insert delTLines;
      
      project.Template__c = delTempHeader.ID;
      insert project;
      
      System.assertEquals(2, [SELECT ID FROM Delivery_Line__c WHERE Project__c =: project.ID].size());
    }
  }
  
  //Creating delivery lines for template populated in project (In update case)
  static testMethod void test_copyDelTempToProjDelLines_UpdateCase() {
    User adminUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert adminUser;

    System.runAs(adminUser) {
      List<Delivery_Template_Line__c> delTLines = new List<Delivery_Template_Line__c>();
      Project__c project = Test_Utils.insertProject(true);
      Delivery_Template_Header__c delTempHeader = Test_Utils.insertDeliveryTemplateHeader(true);
      Delivery_Template_Line__c dtl = Test_Utils.insertDeliveryTemplateLine(false, delTempHeader.ID);
      delTLines.add(dtl);
      dtl = Test_Utils.insertDeliveryTemplateLine(false, delTempHeader.ID);
      delTLines.add(dtl);
      insert delTLines;
      
      project.Template__c = delTempHeader.ID;
      update project;
      
      System.assertEquals(2, [SELECT ID FROM Delivery_Line__c WHERE Project__c =: project.ID].size());
    }
  }
  
}