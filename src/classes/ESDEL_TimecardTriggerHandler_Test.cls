/**=====================================================================
 * Appirio, Inc
 * Name: ESDEL_TimecardTriggerHandler_Test
 * Description: Test class for ESDEL_TimecardTriggerHandler.cls (for T-270393 and T-270392)
 * Created Date: April 18th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified                Modified By                  Description of the update
 * Aug 01st, 2014               Arpita Bose(Appirio)         T-286015: Added testdata for Project__c and Delivery_Line__c to fix the failure
  =====================================================================*/
@isTest
private class ESDEL_TimecardTriggerHandler_Test {
    static testMethod void testESDEL_TimecardTriggerHandlerAfterInsert() {
    	Test.startTest();
      // create User
	    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
	    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
	    insert testUser1;			   
	    System.runAs(testUser1){
	    	TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
	      //create 1 account
		    Account acc1 = Test_Utils.insertAccount();
		    //create 3 addresses
		    Address__c address1 = Test_Utils.insertAddress(false);
		    address1.Address_id__c = 'testExternalId1';
		    Address__c address2 = Test_Utils.insertAddress(false);
		    address2.Address_id__c = 'testExternalId2';
		    List<Address__c> listAddresses = new List<Address__c>();
		    listAddresses.add(address1);
		    listAddresses.add(address2);
		    insert listAddresses;
		    //create 1 account address
		    Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
		    //create contact
		    Contact contact1 = Test_Utils.insertContact(acc1.Id);	
		    	    
		    ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
		    Case newCase = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord1');
		    Project__c newProject = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine = Test_Utils.insertDeliveryLine(true, newProject.Id);
        
		    List<ESDEL_Timecard__c> newTimecards = new List<ESDEL_Timecard__c>();
		    integer minutesWorkedOnSingleTimecard = 5;
		    integer noOfTimecardCreation = 50;
		    // insert 50 new timecards for bulk testing
		    for(integer indx = 0; indx < noOfTimecardCreation; indx++){
		    	newTimecards.add(Test_Utils.insertTimecard(false, newCase.id, minutesWorkedOnSingleTimecard, newProject.Id, deliveryLine.Id));		    	
		    }
		    insert newTimecards;
		    
		    // now since new timecards are inserted; the sum of minutues worked should have been updated on parent case record
		    newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
		    // verify that sum of minutes worked is equal to 5 on each time card * 50 number of timecards = 250
		    System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
		    
		    // add one more case to project
		    Case newCase1 = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord41'); 
		    newTimecards = new List<ESDEL_Timecard__c>();
		    // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards.add(Test_Utils.insertTimecard(false, newCase1.id, minutesWorkedOnSingleTimecard, newProject.Id, deliveryLine.Id));         
        }
        insert newTimecards;
        // now since 50 timecards are inserted on the new case; the sum of minutues worked should have been updated on parent case record
        newCase1 = [Select ESDEL_Minutes_Worked__c from case where id =: newCase1.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase1.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
	   	  // verify that delivery project minutes worked is updated based on minutes worked associated to related 2 cases
	   	  deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
	   	  System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) * 2, deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project minutes worked is updated successfully with two new cases');
	    }
	    Test.stopTest();
    }
    
    
    static testMethod void testESDEL_TimecardTriggerHandlerAfterUpdate() {
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;        
      System.runAs(testUser1){
      	TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id); 
              
        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
        Case newCase = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord1');
        Project__c newProject = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine = Test_Utils.insertDeliveryLine(true, newProject.Id);
        Test.startTest();
        List<ESDEL_Timecard__c> newTimecards1 = new List<ESDEL_Timecard__c>();
        integer minutesWorkedOnSingleTimecard = 5;
        integer noOfTimecardCreation = 50;
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards1.add(Test_Utils.insertTimecard(false, newCase.id, minutesWorkedOnSingleTimecard, newProject.Id, deliveryLine.Id));          
        }
        insert newTimecards1;
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        
        // add one more case to project
        Case newCase1 = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord41');
        Project__c newProject1 = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine1 = Test_Utils.insertDeliveryLine(true, newProject.Id);
         
        List<ESDEL_Timecard__c> newTimecards2 = new List<ESDEL_Timecard__c>();
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards2.add(Test_Utils.insertTimecard(false, newCase1.id, minutesWorkedOnSingleTimecard, newProject1.Id, deliveryLine1.Id));         
        }
        insert newTimecards2;
        newCase1 = [Select ESDEL_Minutes_Worked__c from case where id =: newCase1.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase1.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        // verify that delivery project minutes worked is updated based on minutes worked associated to related 2 cases
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) * 2, deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project minutes worked is updated successfully with two new cases');
      
        // now update minutes worked on timecards related to case1;
        integer minutesWorkedOnSingleTimecard_Updated = 10;        
        for(ESDEL_Timecard__c timeCrd : newTimecards1){
        	timeCrd.ESDEL_Minutes_Worked__c = minutesWorkedOnSingleTimecard_Updated;
        }
        update newTimecards1;
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        // verify that minutes worked is updated in case1
        System.assertEquals(minutesWorkedOnSingleTimecard_Updated * noOfTimecardCreation, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        // verify that minutes worked is updated in delievery project because mintues worked is updated on one of the associated case record.
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) + (minutesWorkedOnSingleTimecard_Updated * noOfTimecardCreation), deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project minutes worked is updated successfully with two new cases');
        
      }
      Test.stopTest();
    }
    
    static testMethod void testESDEL_TimecardTriggerHandlerAfterUpdateForCaseAssociationChange() {
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;        
      System.runAs(testUser1){
      	TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id); 
              
        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
        ESDEL_Delivery_Project__c deliveryProject1 = Test_Utils.insertDeliveryProject(true, 'project2', acc1.id, contact1.id, 'bord2');
        
        Case newCase = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord1');
        Project__c newProject = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine = Test_Utils.insertDeliveryLine(true, newProject.Id);
        Test.startTest();
        List<ESDEL_Timecard__c> newTimecards1 = new List<ESDEL_Timecard__c>();
        integer minutesWorkedOnSingleTimecard = 5;
        integer noOfTimecardCreation = 50;
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards1.add(Test_Utils.insertTimecard(false, newCase.id, minutesWorkedOnSingleTimecard, newProject.Id, deliveryLine.Id));          
        }
        insert newTimecards1;
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        
        // add one more case to project
        Case newCase1 = Test_Utils.insertCase (true, deliveryProject1.id, acc1.id, 'bord41');
        Project__c newProject1 = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine1 = Test_Utils.insertDeliveryLine(true, newProject.Id);
         
        List<ESDEL_Timecard__c> newTimecards2 = new List<ESDEL_Timecard__c>();
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards2.add(Test_Utils.insertTimecard(false, newCase1.id, minutesWorkedOnSingleTimecard, newProject1.Id, deliveryLine1.Id));         
        }
        insert newTimecards2;
        newCase1 = [Select ESDEL_Minutes_Worked__c from case where id =: newCase1.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase1.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project1 minutes worked is updated successfully');
        deliveryProject1 = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject1.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, deliveryProject1.ESDEL_Minutes_Worked__c, 'Validate that project2 minutes worked is updated successfully');
        
        // check if we remove the association of all newTimecards2 from newCase1 to newCase; it should update minutes worked on newCase1 to 0 as well as project2 also
        for(ESDEL_Timecard__c timeCard : newTimecards2){ 
          timeCard.ESDEL_Case__c = newCase.id;  	
        }
        update newTimecards2;
        
        // verify that trigger sets the minutes worked on case and related project to 0 as all the timecards 
        // associated to this case are moved to another case.
        newCase1 = [Select ESDEL_Minutes_Worked__c from case where id =: newCase1.id];
        System.assertEquals(0, newCase1.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');        
        deliveryProject1 = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject1.id];
        System.assertEquals(0, deliveryProject1.ESDEL_Minutes_Worked__c, 'Validate that project2 minutes worked is updated successfully');
        
        // verify that trigger sets the minutes worked on case and related project to double as all the timecards 
        // associated to other case are moved to this case.
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) * 2, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');        
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) * 2, deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project1 minutes worked is updated successfully');
        
        
      }
      Test.stopTest();
    }
    
    static testMethod void testESDEL_TimecardTriggerHandlerAfterDelete() {
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;        
      System.runAs(testUser1){
      	TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id); 
              
        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
        Case newCase = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord1');
        
        Project__c newProject = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine = Test_Utils.insertDeliveryLine(true, newProject.Id);
        Test.startTest();
        List<ESDEL_Timecard__c> newTimecards1 = new List<ESDEL_Timecard__c>();
        integer minutesWorkedOnSingleTimecard = 5;
        integer noOfTimecardCreation = 50;
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards1.add(Test_Utils.insertTimecard(false, newCase.id, minutesWorkedOnSingleTimecard, newProject.Id, deliveryLine.Id));          
        }
        insert newTimecards1;
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        
        // add one more case to project
        Case newCase1 = Test_Utils.insertCase (true, deliveryProject.id, acc1.id, 'bord41');
        Project__c newProject1 = Test_Utils.insertProject(true);
        Delivery_Line__c deliveryLine1 = Test_Utils.insertDeliveryLine(true, newProject.Id);
         
        List<ESDEL_Timecard__c> newTimecards2 = new List<ESDEL_Timecard__c>();
        // insert 50 new timecards for bulk testing
        for(integer indx = 0; indx < noOfTimecardCreation; indx++){
          newTimecards2.add(Test_Utils.insertTimecard(false, newCase1.id, minutesWorkedOnSingleTimecard, newProject1.Id, deliveryLine1.Id));         
        }
        insert newTimecards2;
        newCase1 = [Select ESDEL_Minutes_Worked__c from case where id =: newCase1.id];
        System.assertEquals(minutesWorkedOnSingleTimecard * noOfTimecardCreation, newCase1.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        // verify that delivery project minutes worked is updated based on minutes worked associated to related 2 cases
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation) * 2, deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project minutes worked is updated successfully with two new cases');
      
        // now delete timecards associated to case1;
        delete newTimecards1;
        newCase = [Select ESDEL_Minutes_Worked__c from case where id =: newCase.id];
        // verify that minutes worked is updated in case1
        System.assertEquals(0, newCase.ESDEL_Minutes_Worked__c, 'Validate that case minutes worked is updated successfully');
        deliveryProject = [Select ESDEL_Minutes_Worked__c from ESDEL_Delivery_Project__c where id =: deliveryProject.id];
        // verify that minutes worked is updated in delievery project because mintues worked is updated on one of the associated case record.
        System.assertEquals((minutesWorkedOnSingleTimecard * noOfTimecardCreation), deliveryProject.ESDEL_Minutes_Worked__c, 'Validate that project minutes worked is updated successfully with two new cases');
        
      }
      Test.stopTest();
    }
    
    
}