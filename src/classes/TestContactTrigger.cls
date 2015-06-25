/*
Name: Mohammed Irfan
Date: 12/Dec/2013
Description: Test for Adding Owner to Contact Team.
*/
@isTest
private class TestContactTrigger {

    static testMethod void runTest()
    {
      User usr = [select id from User where IsActive=true limit 1];
      Contact con = new Contact(FirstName='First',LastName='Last',OwnerId=usr.id);
      insert con;
      
    }
}