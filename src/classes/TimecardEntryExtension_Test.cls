@isTest
private class TimecardEntryExtension_Test {
    
  static Timecard__c tcObject;
  static Delivery_Line__c delLine;
  
  static testmethod void testTimecardEntry () {
  	createData ();
    ApexPages.StandardController std = new ApexPages.StandardController(tcObject);
    ApexPages.currentPage().getParameters().put('deliveryLineId',delLine.Id);
    TimecardEntryExtension con = new TimecardEntryExtension(std);
    con.projectId = delLine.Project__c;
    con.populateRelatedDeliveryLines();
    con.selectedDeliveryLineId = delLine.Id;
    con.populateMethodList();
    con.generateTimecard();
    con.updateMapInfo();
    con.removeTimecardLine();
    con.copyFromPreviousWeek();
    con.saveAndAddTimecards();
    con.doCancel();
  }

  static void createData () {
  	tcObject = new Timecard__c();
  	Project__c testProject = new Project__c ();
  	testProject.Name = 'testProject';
  	insert testProject;
  	delLine = new Delivery_Line__c();
  	delLine.Project__c = testProject.Id;
  	delLine.Name = 'testDelivey';
  	insert delLine;
  	List<Timecard__c> tcList = new List<Timecard__c>();
  	for (integer i = 0; i < 5; i++) {
  	  Timecard__c tc = new Timecard__c();
  	  tc.Project__c = testProject.Id;
  	  tc.Delivery_Line__c = delLine.Id;
  	  tc.Type__c = 'Travel';
  	  tc.Hours__c = 4.0;
  	  tc.Date__c = Date.today().addDays(i-5);
  	  tc.Resource__c = userinfo.getUserId();
  	  tcList.add(tc);
  	}
  	for (integer i = 0; i < 5; i++) {
  	  Timecard__c tc = new Timecard__c();
  	  tc.Project__c = testProject.Id;
  	  tc.Delivery_Line__c = delLine.Id;
  	  tc.Type__c = 'Travel';
  	  tc.Hours__c = 4.0;
  	  tc.Date__c = Date.today().addDays(i-12);
  	  tc.Resource__c = userinfo.getUserId();
  	  tcList.add(tc);
  	}
  	insert tcList;
  }
}