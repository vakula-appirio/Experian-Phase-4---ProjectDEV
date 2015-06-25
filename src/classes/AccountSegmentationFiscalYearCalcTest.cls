/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentationFiscalYearCalcTest
 * Description:  
 *              T-374227: Test Class for AccountSegmentationFiscalYearCalculation
 * Created Date: April 07th, 2015
 * Created By: Nikhil Sharma (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 ======================================================================*/

@isTest
global class AccountSegmentationFiscalYearCalcTest {
  public static Order__c ordr1, ordr2;
  public static List<Account_Segment__c> listAccSegments;
  public static User user;


  //===================================================================
  // Test to verify the Previous_FY_Order_Amount__c populates correctly
  //===================================================================
	static testMethod void basicTest() {
	  createTestData();
	  Test.startTest();
	  AccountSegmentationFiscalYearCalculation bc = new AccountSegmentationFiscalYearCalculation();
	  Database.executeBatch(bc);
	  Test.stopTest(); 
	  for (Account_Segment__c asg: [SELECT Previous_FY_Order_Amount__c FROM Account_Segment__c WHERE Id IN :listAccSegments]) {
	    System.assertEquals(asg.Previous_FY_Order_Amount__c, 3.00);
	  }

    }
    
    //@testSetup
  private static void createTestData() {
    Date oneYearAgo = Date.today().addYears(-1);
    List<FiscalYearSettings> fiscalYears = [SELECT Id, Name, StartDate, EndDate
                                            FROM FiscalYearSettings
                                            WHERE StartDate <= :oneYearAgo and EndDate >= :oneYearAgo];

    Date lastYearDate = fiscalYears.get(0).StartDate.addDays(1);
     // Insert Account
    Account acc = Test_Utils.insertAccount(); 

    //Insert user
    user = Test_Utils.insertUser('System Administrator');

     // Insert Hierarchy
     List<Hierarchy__c> listHierarchies = new List<Hierarchy__c>();
     Hierarchy__c hierarchy_BusinessUnit = Test_Utils.insertHierarchy(false, null, 'test-1', 'Business Unit');
     listHierarchies.add(hierarchy_BusinessUnit);
     Hierarchy__c hierarchy_BusinessLine = Test_Utils.insertHierarchy(false, null, 'test-1', 'Business Line');
     listHierarchies.add(hierarchy_BusinessLine);
     Hierarchy__c hierarchy_Country = Test_Utils.insertHierarchy(false, null, 'test-1', 'Country');
     listHierarchies.add(hierarchy_Country);
     Hierarchy__c hierarchy_GlobalBusinessLine = Test_Utils.insertHierarchy(false, null, 'test-1', 'Global Business Line');
     listHierarchies.add(hierarchy_GlobalBusinessLine);
     Hierarchy__c hierarchy_Region = Test_Utils.insertHierarchy(false, null, 'test-1', 'Region');
     listHierarchies.add(hierarchy_Region);
     insert listHierarchies;
     
     // Insert Account Segment    
    listAccSegments = new List<Account_Segment__c>();
    Account_Segment__c accSegment_BusinessLine = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_BusinessUnit.Id, null);
    listAccSegments.add(accSegment_BusinessLine);
    
    Account_Segment__c accSegment_BusinessUnit = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_BusinessLine.Id, null);
    listAccSegments.add(accSegment_BusinessUnit);
    
    Account_Segment__c accSegment_Country = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_Country.Id, null);
    listAccSegments.add(accSegment_Country);
    
    Account_Segment__c accSegment_GlobalBusinessLine = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_GlobalBusinessLine.Id, null);
    listAccSegments.add(accSegment_GlobalBusinessLine);
    
    Account_Segment__c accSegment_Region = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_Region.Id, null);
    listAccSegments.add(accSegment_Region);
    
    insert listAccSegments;
    
//    System.debug('listAccSegments:::: ' + listAccSegments);

    // Insert Contact
    Contact cnt = Test_Utils.insertContact(acc.Id);
    
    // Insert Opportunity
    Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
    
    // Insert Order
    List<Order__c> listOrder = new List<Order__c>();
    ordr1 = Test_Utils.insertOrder(false, acc.Id, cnt.Id, opp.Id);
    ordr1.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    ordr1.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    ordr1.Segment_Country__c = accSegment_Country.Id;
    ordr1.Segment_Global_Business_Line__c = accSegment_GlobalBusinessLine.Id;
    ordr1.Segment_Region__c = accSegment_Region.Id;
    ordr1.Contract_End_Date__c = lastYearDate;
    ordr1.Contract_Start_Date__c = lastYearDate.addDays(-20);
    ordr1.Amount_Corp__c = 2.00;
    ordr1.RecordTypeID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Read Only').getRecordTypeId();
    listOrder.add(ordr1);
    
    ordr2 = Test_Utils.insertOrder(false, acc.Id, cnt.Id, opp.Id);
    ordr2.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    ordr2.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    ordr2.Segment_Country__c = accSegment_Country.Id;
    ordr2.Segment_Global_Business_Line__c = accSegment_GlobalBusinessLine.Id;
    ordr2.Segment_Region__c = accSegment_Region.Id;
    ordr2.Contract_End_Date__c = lastYearDate;
    ordr2.Contract_Start_Date__c = lastYearDate.addDays(-30);
    ordr2.Amount_Corp__c = 1.00;
    ordr2.RecordTypeID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Read Only').getRecordTypeId();
    listOrder.add(ordr2);
    
    
    insert listOrder;
    
//    System.debug('listOrder:::::: ' + listOrder);
//    System.debug('ordersAmount::::::' + [Select Amount_Corp__c From Order__c]);
    
  }
}