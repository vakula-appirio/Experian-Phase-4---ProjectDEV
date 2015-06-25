/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineChangeStartDateExt_Test
 * Description: T-271252: Test class to test the functionality of Delivery Management: VF Page and 
 *             OrderLineChangeStartDateExt.cls
 * Created Date: Apr 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 22nd, 2014               Arpita Bose                  Added methods for differenct users with different profiles
 =====================================================================*/
@isTest
private class OrderLineChangeStartDateExt_Test {
  
  //test method for 'Experian Finance' User
  static testmethod void testOrderLineChangeStartDateExt_FinUser(){
    ApexPages.StandardController sc;
    OrderLineChangeStartDateExt controller = new OrderLineChangeStartDateExt(sc);  
    //start test
    Test.startTest();
    //create user
    User expFinUser = Test_Utils.insertUser(Constants.PROFILE_EXP_FINANCE);

    //run as 'Experian Finance' User
    System.runAs(expFinUser){
      controller.checkIfUserAllowed();
      List<ApexPages.Message> msgList = ApexPages.getMessages();
      //Asserts to get the errors for PROFILE_EXP_FINANCE
      System.assert(msgList.size() > 0);
    }
    //stop test
    Test.stopTest();
  }

  //test method for 'System Administrator' User
  static testmethod void testOrderLineChangeStartDateExt_SysAdmin(){
    ApexPages.StandardController sc;
    OrderLineChangeStartDateExt controller = new OrderLineChangeStartDateExt(sc);
    controller.haveAccess = true;    
    //start test
    Test.startTest();
    //create user
    User sysAdmin = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    
    //run as System Administrator
    System.runAs(sysAdmin){
      controller.checkIfUserAllowed();
      List<ApexPages.Message> msgList = ApexPages.getMessages();
      //Assert to verify that it should not produce error for PROFILE_SYS_ADMIN
      System.assertEquals(msgList.size(), 0);
    }
    //stop test
    Test.stopTest();
  }

  //test method for 'Experian Sales Effectiveness' User
  static testmethod void testOrderLineChangeStartDateExt_SalesAdmin(){
    ApexPages.StandardController sc;
    OrderLineChangeStartDateExt controller = new OrderLineChangeStartDateExt(sc);
    controller.haveAccess = true;    
    //start test
    Test.startTest();
    //create user
    User salesAdmin = Test_Utils.insertUser(Constants.PROFILE_EXP_SALES_ADMIN);
    //run as 'Experian Sales Effectiveness' user
    System.runAs(salesAdmin){
      controller.checkIfUserAllowed();
      List<ApexPages.Message> msgList = ApexPages.getMessages();
      //Assert to verify that it should not produce error for PROFILE_EXP_SALES_ADMIN
      System.assertEquals(msgList.size(), 0);
    }
    //stop test
    Test.stopTest();
  }

  //test method for a Group Member
  static testmethod void testOrderLineChangeStartDateExt_GroupMember(){
    ApexPages.StandardController sc;
    OrderLineChangeStartDateExt controller = new OrderLineChangeStartDateExt(sc);
    controller.haveAccess = true;    
    //start test
    Test.startTest();
    //create user 
    User grpMember = Test_Utils.insertUser(Constants.PROFILE_EXP_SALES_EXEC);
    //Adding the user to the group
    Group testGroup = new Group(Name = Constants.GROUP_DELIVERY_MANAGEMENT);
    insert testGroup;

    GroupMember grpMem = new GroupMember();
    grpMem.UserOrGroupId = grpMember.Id;
    grpMem.GroupId = testGroup.Id;
    insert grpMem;

    //run as group member
    System.runAs(grpMember){
      controller.checkIfUserAllowed();
      List<ApexPages.Message> msgList = ApexPages.getMessages();
      //Assert to verify that it should not produce error for a user of GROUP_DELIVERY_MANAGEMENT  
      System.assertEquals(msgList.size(), 0);
    }
    //stop test
    Test.stopTest();
  }
}