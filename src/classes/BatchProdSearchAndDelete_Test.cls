/**=====================================================================
 * Appirio, Inc
 * Name: BatchProdSearchAndDelete_Test
 * Description: T-270944: Test class to verify the behaviour of BatchProdCountrySearchAndDelete.cls
 *             and ScheduleProdCountryRegionSearchAndDelete.cls
 * Created Date: Apr 11th, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified         Modified By              Description of the update
 * Feb 18th, 2015        Noopur                   T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
@isTest(SeeAllData=false)
private class BatchProdSearchAndDelete_Test {
    static ID priceBookStandardId;

  //=============================================================================================
  // Test method to test BatchProdCountrySearchAndDelete.cls
  //=============================================================================================
  @isTest
  static void batchTest() {

    Test.StartTest();

    //executing the batch job
    String query = 'SELECT Id FROM Product_Country__c WHERE Product__c = null LIMIT 200';
    BatchProdCountryRegionSearchAndDelete prodSearch = new BatchProdCountryRegionSearchAndDelete(query);
    ID batchprocessid = Database.executeBatch(prodSearch);

    query = 'SELECT Id FROM Product_Region__c WHERE Product__c = null LIMIT 200';
    prodSearch = new BatchProdCountryRegionSearchAndDelete(query);
    batchprocessid = Database.executeBatch(prodSearch);

    Test.StopTest();

    //Asserts
    System.AssertEquals(0, [SELECT count() FROM Product_Country__c WHERE Product__c =:null] );
    System.AssertEquals(50, [SELECT count() FROM Product_Country__c WHERE Product__c != null] );
    System.AssertEquals(0, [SELECT count() FROM Product_Region__c WHERE Product__c =:null] );
    System.AssertEquals(50, [SELECT count() FROM Product_Region__c WHERE Product__c != null] );

  }

  //=============================================================================================
  // Test method to test ScheduleProdCountryRegionSearchAndDelete.cls
  //=============================================================================================
  @isTest
  static void testBatchProdCountrySearchAndDeleteScheduleClass() {
    Test.startTest();
    // Schedule the test job
    String CRON_EXP = '0 0 0 3 9 ? 2022';
    String jobId = System.schedule('ScheduleProdCountryRegionSearchAndDeleteTest', CRON_EXP,
       new ScheduleProdCountryRegionSearchAndDelete());

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                      FROM CronTrigger
                      WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);
    Test.stopTest();
  }

  //=============================================================================================
  // Create Test Data
  //=============================================================================================
  @testSetup
  public static void createBatchTestData() {
    Global_Settings__c gs = new Global_Settings__c();
    gs.Name = 'Global';
    gs.Batch_Failures_Email__c = '';
    insert gs;
        
    // create product
    Product2 product = new Product2(Name = 'Test_Prod1');
    insert product;
    // create Country and Region records
    Country__c c1 = new Country__c(Name = 'Italy');
    insert c1;
    Region__c r1 = new Region__c(Name = 'EMEA');
    insert r1;

    List<Product_Country__c> prodCntryWithNoProd = new List<Product_Country__c>();
    // create Product_Country records with no Product__c
    for (integer i = 0; i<100; i++) {
      Product_Country__c testPC1 = new Product_Country__c(Product__c = null, Country__c = c1.Id);
      prodCntryWithNoProd.add(testPC1);
    }
    insert prodCntryWithNoProd;

    List<Product_Country__c> prodCntryWithProd = new List<Product_Country__c>();
    // create Product_Country records with Product__c
    for (integer i = 0; i<50; i++) {
      Product_Country__c testPC2 = new Product_Country__c(Product__c = product.Id, Country__c = c1.Id);
      prodCntryWithProd.add(testPC2);
    }
    insert prodCntryWithProd;

    List<Product_Region__c> prodRegWithNoProd = new List<Product_Region__c>();
    // create Product_Region records with no Product__c
    for (integer i = 0; i<100; i++) {
      Product_Region__c testPR1 = new Product_Region__c(Product__c = null, Region__c = r1.Id);
      prodRegWithNoProd.add(testPR1);
    }
    insert prodRegWithNoProd;
    List<Product_Region__c> prodRegWithProd = new List<Product_Region__c>();
    // create Product_Region records with Product__c
    for(integer i = 0; i<50; i++){
         Product_Region__c testPR2 = new Product_Region__c(Product__c = product.Id, Region__c = r1.Id);
         prodRegWithProd.add(testPR2);
      }
    insert prodRegWithProd;
  }
}