@IsTest
private class BatchUserLastActivityUpdate_Test {

  static testMethod void testBatch() {
    List<User> listTestUsers = new list<User>();  
    List<User> listUsersToUpdate = new list<User>();  
    
    User testUserforInsert = Test_Utils.createUser('Standard User');
    testUserforInsert.Days_since_Activity__c = 1;
    insert testUserforInsert;     
      
    listTestUsers = [SELECT Id, Days_since_Activity__c FROM User where IsActive = true AND Days_since_Activity__c > 0 order by Name limit 10];
    System.assert(listTestUsers[0].Days_since_Activity__c > 0);
      
    for(User testUser : listTestUsers)
    {
      testUser.Days_since_Activity__c = 0;  
      listUsersToUpdate.add(testUser);  
    }
    update listUsersToUpdate;  
    
    for(User userAssertBefore : [SELECT Id, Days_since_Activity__c FROM User where Id IN: listTestUsers])
    {
      System.assertEquals(userAssertBefore.Days_since_Activity__c, 0);  
    }
      
    Test.startTest();
    
    String query = 'SELECT Id, LastLoginDate, Days_since_Activity__c FROM User WHERE IsActive = true AND LastLoginDate != null order by Name limit 100';
    BatchUserLastActivityUpdate batchToProcess = new BatchUserLastActivityUpdate(query);
    Database.executeBatch(batchToProcess);
      
    Test.stopTest();
      
    for(User userAssertAfter : [SELECT Id, Days_since_Activity__c FROM User where Id IN: listTestUsers AND Days_since_Activity__c != 0])
    {
      System.assert(userAssertAfter.Days_since_Activity__c > 0);  
    }
  }
}