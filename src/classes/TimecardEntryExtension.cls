/******************************************************************************
 * Appirio, Inc
 * Name: TimecardEntryExtension
 * Description: T-313223: Timecard entry - VF Page LOGIC.
 * Created Date: Aug 17th, 2014
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Date Modified        Modified By             Description 
 * Sep 16th, 2014       Noopur (Appirio)       Page to create the timecard entries for resources and
                                               Delivery Lines.
                                               Added the Methods :-                                               
                                               populateProjectList() - This method populates the 
                                               Project list as per the resource selected.
                                               populateRelatedDeliveryLines() - This method populates
                                               the Delivery Line list as per the project selected.
                                               populateMethodList() - This method populates the methodList
                                                as per the project and DL.
                                               convertStringToDate() - This method is used to format the date 
                                               ( created to resolve the Locale issue).
                                               validateTimesheet() - This method validates the selected time period,
                                               checks if the timesheet is locked for the period or not.
 * Nov 10th, 2014       Nathalie Le Guay       I-138258: add try-catch block for DML operations
 ******************************************************************************/
public without sharing class TimecardEntryExtension {
  
  public Map<String, List<TimecardWrapper>> project_TimecardWrapperMap {get;set;}
  public Map<String, Map<Date, Double>> project_DateHrsMap {get;set;}
  public Map<String, Map<Date, Timecard__c>> project_DateTimecardMap {get;set;}
  public Map<String, Map<Date, String>> project_DateDescriptionMap {get;set;}
  public Map<String, Boolean> project_delSaveMap {get;set;}

  public List<TimecardWrapper> timecardWrapperList {get;set;}

  public Map<String, Timecard__c> projectMap {get;set;}
  public ResourceWrapper resourceInfo {get;set;}
  public List<SelectOption> tcMethod {get;set;}

  public List<Date> currentWeek {get;set;}
  public String selectedWeek {get;set;}
  public String endDateCurrentWeek {get;set;}
  public double totalHours {get;set;}
  public String updatedHr {get;set;} 
  public String currentProjId{get;set;}
  public String currentDateSel {get;set;}
  public Boolean isExistTC {get;set;}
  public String currentLineToDel {get;set;}
  public Date firstDt {get;set;}
  public Date endDate {get;set;}

  public List<SelectOption> projectSelectList {get;set;}
  public String selectedResourceId {get;set;}
  public String projectId {get;set;}
  public Integer selectedIndex {get;set;}
  public String deliveryId {get;set;}
 // public Set<String> existingTCSet{get;set;}
  private Map<String,Timecard__c> existingTCMap {get;set;}
  public Map<String,Boolean> projectStatusMap {get;set;}
  Set<String> alreadyExistingDeliveryLines {get;set;}
  Timecard_Settings__c tcSettings {get;set;}
  public Boolean isTimesheetLocked {get;set;}
  public User currentUser {get;set;}
  public String selectedDeliveryLineId {get;set;}
  public Delivery_Line__c deliveryLine {get;set;}
  public Boolean isManager {get;set;}
  public list<Timecard__c> listToBeDeleted {get;set;}
  public List<String> formattedDateList {get;set;}
  public List<Timecard__c> dummyListForTimecardDates {get;set;}
  public Date lockingDate {get;set;}
  public Boolean isCompleteWeekLocked {get;set;}
  
  //Constructor 
  public TimecardEntryExtension(ApexPages.StandardController std) {
    
    //Populating resource 
    String resID = UserInfo.getUserId();
    if (Apexpages.currentPage().getParameters().get('deliveryLineId') != null) {
      deliveryId = Apexpages.currentPage().getParameters().get('deliveryLineId');
      for ( Delivery_Line__c delLine : [SELECT Id,Name,Project__c,Allow_Timecard_Entry__c
                                        FROM Delivery_Line__c
                                        WHERE Id = :deliveryId ] ) {
        deliveryLine = delLine;
      }
    }
    init();
    populateTimeCardForResource(resID, getCurrentWeekStartDate());
    populateProjectList();
    if ( String.isBlank(currentUser.Business_Unit__c) ) {
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.Timecard_Setting_No_BU_Defined));
    }
  }
  

  //InIt method
  private void init() {
    isManager = false;
    isTimesheetLocked = false;
    currentWeek = new List<Date>();
    fillTimecardWeekList(getCurrentWeekStartDate());
    firstDt = getCurrentWeekStartDate();
    selectedWeek = firstDt.month()+'/'+firstDt.day()+'/'+firstDt.year();
    endDate = firstDt.addDays(6);
    endDateCurrentWeek = firstDt.month()+'/'+firstDt.day()+'/'+firstDt.year();
    totalHours = 0;
    fillNewBlankWrapperList ();
    updatedHr = currentProjId = currentDateSel = currentLineToDel ='';
    isExistTC = false;
    project_delSaveMap = new Map<String, Boolean>();
  //  existingTCSet = new Set<String>();
    projectStatusMap = new Map<String,Boolean>();
    for ( User usr :[SELECT Id, Business_Unit__c,Profile.Name
                     FROM User
                     WHERE Id = :UserInfo.getUserId()] ) {
      currentUser = usr;
    }
    if ( currentUser.profile.Name == Constants.PROFILE_EXP_PROJ_DELIVERY_MANAGER || currentUser.profile.Name == Constants.PROFILE_SYS_ADMIN) {
      isManager = true;
    }
    dummyListForTimecardDates = new List<Timecard__c> ();
    for ( integer i=0; i < 7 ; i++ ) {
      Timecard__c tcDumb = new Timecard__c();
      tcDumb.Date__c = firstDt.addDays(i);
      dummyListForTimecardDates.add(tcDumb);
    }
    validateTimesheet();
    existingTCMap = new Map<String,Timecard__c>();
    listToBeDeleted = new List<Timecard__c>();
  }
  
  //Fill blank timecard line (wrapper)
  public void fillNewBlankWrapperList () {
    
    timecardWrapperList = new List<TimecardWrapper>();
    
    for(Integer i=0; i < 5; i++) {
      TimecardWrapper newTC = new TimecardWrapper();
      for (Date dt : currentWeek) {
        newTC.dateHour.put(dt, 0.00);
        newTC.dateDescription.put(dt,'');
      }
      if ( i == 0 && deliveryLine != null && deliveryLine.Allow_Timecard_Entry__c != null 
      && deliveryLine.Allow_Timecard_Entry__c == true) {
      	String mapDeliveryKey = deliveryLine.Project__c+'~'+ Label.TimecardEntry_Delivery +'~'+ deliveryLine.Id;
      	String mapTravelKey = deliveryLine.Project__c+'~'+ Label.TimecardEntry_Travel +'~'+ deliveryLine.Id;
      	system.debug('====mapDeliveryKey==='+mapDeliveryKey);
      	system.debug('----project_TimecardWrapperMap---'+project_TimecardWrapperMap);
      	if ( project_TimecardWrapperMap != null && !project_TimecardWrapperMap.isEmpty()) {
      		if ( !project_TimecardWrapperMap.containsKey(mapDeliveryKey) ) {
      			newTC.timeCardObj.Project__c = deliveryLine.Project__c;
		        projectId = deliveryLine.Project__c;
		        selectedIndex = 0;
		        //populateRelatedDeliveryLines();
		        newTC.deliveryLines = new list<selectOption>();
		        newTC.deliveryLines.add(new selectOption(deliveryId, deliveryLine.Name));
		        newTC.timeCardObj.Delivery_Line__c = deliveryId;
		        newTC.methodTypes.add(new selectOption('Delivery', Label.TimecardEntry_Delivery));
		        newTC.timeCardObj.Type__c = 'Delivery';
      		}
      		else if ( !project_TimecardWrapperMap.containsKey(mapTravelKey) ) {
      			newTC.timeCardObj.Project__c = deliveryLine.Project__c;
		        projectId = deliveryLine.Project__c;
		        selectedIndex = 0;
		        //populateRelatedDeliveryLines();
		        newTC.deliveryLines = new list<selectOption>();
		        newTC.deliveryLines.add(new selectOption(deliveryId, deliveryLine.Name));
		        newTC.timeCardObj.Delivery_Line__c = deliveryId;
		        newTC.methodTypes.add(new selectOption('Travel', Label.TimecardEntry_Travel));
		        newTC.timeCardObj.Type__c = 'Travel';
      		}
      	}
      	else {
      		newTC.timeCardObj.Project__c = deliveryLine.Project__c;
          projectId = deliveryLine.Project__c;
          selectedIndex = 0;
          newTC.deliveryLines = new list<selectOption>();
          newTC.deliveryLines.add(new selectOption(deliveryId, deliveryLine.Name));
          newTC.timeCardObj.Delivery_Line__c = deliveryId;
          newTC.methodTypes.add(new selectOption('Delivery', Label.TimecardEntry_Delivery));
          newTC.timeCardObj.Type__c = 'Delivery';
      	}
        
      }
      else if ( i == 0 && deliveryLine != null && (deliveryLine.Allow_Timecard_Entry__c == null 
      || deliveryLine.Allow_Timecard_Entry__c == false) ) {
      	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.TimecardEntry_Timecard_Not_Allowed));
      }
      newTC.index = i;
      timecardWrapperList.add(newTC);
    }
  }

  //get Current week's start date (i.e. Sunday)
  private Date getCurrentWeekStartDate () {
    Integer dtNum = Date.newInstance(1900, 1, 7).daysBetween(Date.today());
    Integer currentDay = Math.mod(dtNum, 7);
    Date newDate = Date.today().addDays(-currentDay);
    return newDate;
  }
  
  //===========================================================================
  // Param : resourceId (UserId), startDate (Week start date)
  // Populates map of timecard for the week given as secod parameter 
  //===========================================================================
  public void populateTimeCardForResource (String resourceId, Date startDate) {
    project_DateHrsMap = new Map<String, Map<Date, Double>>();
    project_DateTimecardMap = new Map<String, Map<Date, Timecard__c>> ();
    project_DateDescriptionMap = new Map<String, Map<Date, String>>();
    tcMethod = new List<SelectOption>();
    totalHours = 0;
    tcMethod.add(new Selectoption('Delivery', Label.TimecardEntry_Delivery));
    tcMethod.add(new Selectoption('Travel', Label.TimecardEntry_Travel));

    project_TimecardWrapperMap = new Map<String, List<TimecardWrapper>>();
    projectMap = new Map<String, Timecard__c>();

    List<Timecard__c> timecardList = new List<Timecard__c>();
   
    resourceInfo = new ResourceWrapper();
    resourceInfo.tc.Resource__c = (ID)resourceId;   
    integer i = 0;
    for (Timecard__c tc : [SELECT ID, Resource__r.Name, Resource__c, Project__c, Project__r.Name, 
                                  Hours__c, Description__c, Delivery_Line__c, Date__c, Name ,Type__c
                           FROM Timecard__c
                           WHERE Resource__c =: resourceId AND
                           Date__c >= : startDate AND Date__c < : startDate.addDays(7)
                           Order By Date__c]) { 

        isExistTC = true;
        if( tc.Hours__c == null ) {
        	tc.Hours__c = 0.00;
        }
        //To hand hours for each date of the week
        if (!project_DateHrsMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c)) {
          project_DateHrsMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, new Map<Date, Double>());
        }

        if (!project_DateHrsMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).containsKey(tc.Date__c)) {
          project_DateHrsMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).put(tc.Date__c, tc.Hours__c);
        } else {
          project_DateHrsMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+tc.Delivery_Line__c).put(tc.Date__c, project_DateHrsMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).get(tc.Date__c)+tc.Hours__c);
        }

        // for existing timecards 
        if (!project_DateTimecardMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c)) {
          project_DateTimecardMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, new Map<Date, Timecard__c>());
        }

        //if (!project_DateTimecardMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).containsKey(tc.Date__c)) {
          project_DateTimecardMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).put(tc.Date__c, tc);
       // } else {
        //  project_DateTimecardMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+tc.Delivery_Line__c).put(tc.Date__c, tc);
       // }
        

        if(!project_DateDescriptionMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c)){
          project_DateDescriptionMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, new Map<Date, String>());
        }

        if (!project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).containsKey(tc.Date__c)) {
          if (tc.Description__c != null) {
            project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).put(tc.Date__c, tc.Description__c);
          }
          else {
            project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).put(tc.Date__c, '');
          }
        } else {
          project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+tc.Delivery_Line__c).put(tc.Date__c, project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).get(tc.Date__c)+tc.Description__c);
        }

        //Project and timecard wrapper      
        if (!project_TimecardWrapperMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c)) {
          project_TimecardWrapperMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, new List<TimecardWrapper>());
        }
         
        TimecardWrapper tcWrapObj = new TimecardWrapper();
        tcWrapObj.timeCardObj = tc;
        tcWrapObj.index = i++;
        tcWrapObj.dateHour = project_DateHrsMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c);
        tcWrapObj.dateDescription = project_DateDescriptionMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c);
        project_TimecardWrapperMap.get(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c).add(tcWrapObj);
    
        //Project map to get project name     
        if (!projectMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+tc.Delivery_Line__c)) {
          projectMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, tc);
        }
        //Projects to be deleted or save
        if (!project_delSaveMap.containsKey(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c)) {
          project_delSaveMap.put(tc.Project__c+'~'+ tc.Type__c +'~'+ tc.Delivery_Line__c, true);
        }   
        if ( tc != null && tc.Hours__c != null) {
        totalHours += tc.Hours__c; 
        }
    }
    
    for (String key : project_DateHrsMap.keySet()) {
      for (Date dt : currentWeek) {
        if (!project_DateHrsMap.get(key).containsKey(dt)) {
          project_DateHrsMap.get(key).put(dt, 0.00);
        }
      } 
    }
    for (String key : project_DateDescriptionMap.keySet()) {
      for (Date dt : currentWeek) {
        if(!project_DateDescriptionMap.get(key).containsKey(dt)){
          project_DateDescriptionMap.get(key).put(dt, '');
        }
      }
    }
    
    System.debug('===project_DateDescriptionMap==='+project_DateDescriptionMap);
  }
  
  
  //Generate timecard fetches existing timecard if any for selected period on current resource
  //or creates blank lines.
  public Pagereference generateTimecard () {
    fillTimecardWeekList(convertStringToDate(selectedWeek));
    String resourceId = selectedResourceId != null? selectedResourceId :resourceInfo.tc.Resource__c;
    if(selectedWeek != null && !String.isBlank(selectedWeek) && !String.isBlank(resourceId)) {
      populateTimeCardForResource(resourceId, convertStringToDate(selectedWeek));
    }
    fillNewBlankWrapperList ();
    validateTimesheet();
    return null;
  }
  
  /*
  Method to check if the timesheet is locked for the selected period of time.
  */
  private void validateTimesheet ( ) {
    isCompleteWeekLocked = false;
    isTimesheetLocked = false;
    if ( !String.isBlank(currentUser.Business_Unit__c) ) {
      tcSettings = Timecard_Settings__c.getValues(currentUser.Business_Unit__c);
      if ( tcSettings != null && tcSettings.Locking_End_Date__c != null ) {
        if ( convertStringToDate(selectedWeek) <= tcSettings.Locking_End_Date__c ) {
          isTimesheetLocked = true;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.TimecardEntry_Timecard_Locked_Warning));
        }
        else {
          isTimesheetLocked = false;
        }
        if ( convertStringToDate(selectedWeek).addDays(6) <= tcSettings.Locking_End_Date__c ) {
          isCompleteWeekLocked = true;
        }
        lockingDate = tcSettings.Locking_End_Date__c;
      }
    }
    /*else {
      isTimesheetLocked = false;
    }*/
   /* if (lockingDate == null) {
      lockingDate = Date.today().addYears(-1); // NLG 2014-10-02  moved above where tcSettings is not null
    }*/
  }

  //Fill timecard list from the starting date till next 6 days. 
  private void fillTimecardWeekList (Date stDt) {
    currentWeek = new List<Date>();
    formattedDateList = new List<String> ();
    dummyListForTimecardDates = new List<Timecard__c>();
    for (Integer i = 0; i < 7; i++) {
      Date newDt = stDt.addDays(i);
      currentWeek.add(newDt);
      Timecard__c tcDumb = new Timecard__c();
      tcDumb.Date__c = newDt;
      dummyListForTimecardDates.add(tcDumb);
    }
  }
  
  //Update map for updated information on page. Summing of the hours entered in the timesheet.
  public Pagereference updateMapInfo () {
    totalHours = 0;
    
    if ((currentDateSel == null || currentDateSel == '') && selectedWeek != null && selectedWeek != ''){
      currentDateSel = selectedWeek;
    }
    date newDt = date.newInstance(Integer.valueOf(currentDateSel.split('/')[2]), 
                                  Integer.valueOf(currentDateSel.split('/')[0]), 
                                  Integer.valueOf(currentDateSel.split('/')[1]));
    
    if (timecardWrapperList.size() > 0) {
      for (TimecardWrapper twr : timecardWrapperList) {
        for (Date dt : twr.dateHour.keySet()) {
          totalHours += twr.dateHour.get(dt);
        }
      }
    }
    System.debug('===project_DateHrsMap==='+project_DateHrsMap);
    if (project_DateHrsMap != null && project_DateHrsMap.size() > 0) {
      if (project_DateHrsMap.containsKey(currentProjId) && project_DateHrsMap.get(currentProjId).containsKey(newDt)) {
        project_DateHrsMap.get(currentProjId).put(newDt, Double.valueOf(updatedHr));
      }
      for (String proj : project_DateHrsMap.keySet()) {
        for (Date dt : project_DateHrsMap.get(proj).keySet()) {
          totalHours += project_DateHrsMap.get(proj).get(dt);
        }
      }   
    }
    system.debug('---totalHours---'+totalHours);
    return null;
  }
 
  //Fill blank timecard line (wrapper)
  public Pagereference addNewTimecardLine () {
    for(Integer i=0; i < 1; i++) {
      TimecardWrapper newTC = new TimecardWrapper();
      for (Date dt : currentWeek) {
        newTC.dateHour.put(dt, 0.00);
        newTC.dateDescription.put(dt, '');
      }
      newTC.index = timecardWrapperList.size();
      timecardWrapperList.add(newTC);
    }

    return null;
  }

 //remove wrapper line (wrapper)
  public Pagereference removeTimecardLine () {
    System.debug(currentLineToDel+'--predelete1---'+project_delSaveMap);
    System.debug(currentLineToDel+'--predelete2---'+project_TimecardWrapperMap);
    
    if (currentLineToDel != '' && currentLineToDel.length() > 0 && 
            project_TimecardWrapperMap.containsKey(currentLineToDel) &&
            project_delSaveMap.containsKey(currentLineToDel)) {
      project_delSaveMap.put(currentLineToDel, false);
      for (TimecardWrapper tcw : project_TimecardWrapperMap.get(currentLineToDel)) {
        listToBeDeleted.add(tcw.timeCardObj);
      }
      project_TimecardWrapperMap.remove(currentLineToDel);
    } else {
      Integer sizeOfList = timecardWrapperList.size()-1;
      if (sizeOfList > 0) {
        timecardWrapperList.remove(sizeOfList);
      } else {
        timecardWrapperList.remove(0);
      }
    }

    System.debug(currentLineToDel+'--postdelete1---'+project_delSaveMap);
    System.debug(currentLineToDel+'--postdelete2---'+project_TimecardWrapperMap);

    return null;
  }

  //Saving changes and new timecards
    Public Pagereference saveAndAddTimecards () {
      saveTimecards();
      addNewTimecardLine();
      return null;
    }

  //Saving changes and new timecards
  Public Pagereference saveTimecards () {
    
    List<Timecard__c> tcToDelete = new List<Timecard__c>();
    List<Timecard__c> tcToUpsert = new List<Timecard__c>();
    Boolean hasError = false;
    Set<Timecard__c> timeCardSet = new Set<Timecard__c>();
    Set<Timecard__c> timeCardSetToDel = new Set<Timecard__c>();
    String errorRows = '';
    system.debug('===project_TimecardWrapperMap.keySet()==='+project_TimecardWrapperMap.keySet());
    system.debug('===timecardWrapperList==='+timecardWrapperList);
    system.debug('---lockingDate---'+lockingDate);
    for (String mapKey : project_TimecardWrapperMap.keySet()) {
      if (project_TimecardWrapperMap.get(mapKey).size() < 1) {
        continue;
      }
      for (TimecardWrapper tcw : project_TimecardWrapperMap.get(mapKey)) {
        if (project_delSaveMap.containsKey(mapKey) && project_delSaveMap.get(mapKey) != true) {
          tcToDelete.add(tcw.timeCardObj);
        } else {
          String projDateMapKey = tcw.timeCardObj.Project__c + '~'+ tcw.timeCardObj.Type__c +'~'+ tcw.timeCardObj.Delivery_Line__c;
          if (project_DateHrsMap.containsKey(projDateMapKey) && project_DateHrsMap.get(projDateMapKey) != null &&
            project_DateHrsMap.get(projDateMapKey).containsKey(tcw.timeCardObj.Date__c)){
            tcw.timeCardObj.Hours__c = project_DateHrsMap.get(projDateMapKey).get(tcw.timeCardObj.Date__c);
          }
          if ( (project_DateHrsMap.containsKey(projDateMapKey) && project_DateHrsMap.get(projDateMapKey) != null ) ) {
            Map<Date,Double> timeCardHoursMap = project_DateHrsMap.get(projDateMapKey);
            Map<Date,Timecard__c> timecardDateMap = new Map<Date,Timecard__c>();
            if ( project_DateTimecardMap.containsKey(projDateMapKey)) {
              timecardDateMap = project_DateTimecardMap.get(projDateMapKey);
            }
            for ( Date dt : timeCardHoursMap.keySet() ) {
              if ( dt != tcw.timeCardObj.Date__c && timecardDateMap != null && timecardDateMap.containsKey(dt) &&
                timeCardHoursMap.get(dt) != 0.00 && (lockingDate ==null || dt > lockingDate)) {
                Timecard__c tc = timecardDateMap.get(dt);
                tc.Hours__c = timeCardHoursMap.get(dt);
                if ( !timeCardSet.contains(tc)) {
                  tcToUpsert.add(tc);
                  timeCardSet.add(tc);
                }
              }
              else if ( dt != tcw.timeCardObj.Date__c && timeCardHoursMap.get(dt) != 0.00 && 
                (lockingDate ==null || dt > lockingDate)) {
                Timecard__c tc = new Timecard__c ();
                tc.Hours__c = timeCardHoursMap.get(dt);
                tc.Project__c = tcw.timeCardObj.Project__c;
                tc.Delivery_Line__c = tcw.timeCardObj.Delivery_Line__c;
                tc.Resource__c = tcw.timeCardObj.Resource__c;
                tc.Type__c = tcw.timeCardObj.Type__c;
                tc.Date__c = dt;
                if ( !timeCardSet.contains(tc)) {
                  tcToUpsert.add(tc);
                  timeCardSet.add(tc);
                  project_DateTimecardMap.get(projDateMapKey).put(dt,tc);
                }
              }
              else if ( timeCardHoursMap.get(dt) == 0.00 && timecardDateMap.get(dt) != null && 
                timecardDateMap.get(dt).Hours__c != 0.00 && !timeCardSetToDel.contains(timecardDateMap.get(dt))) {
                tcToDelete.add(timecardDateMap.get(dt));
                timeCardSetToDel.add(timecardDateMap.get(dt));
              }
            }
            }

          }
          if ( !timeCardSet.contains(tcw.timeCardObj)) {
            tcToUpsert.add(tcw.timeCardObj);
            timeCardSet.add(tcw.timeCardObj);
          }
        }
      }
     
    Integer i = project_TimecardWrapperMap.keySet().size();
    for (TimecardWrapper tcw : timecardWrapperList) {
      i++;
      if(tcw.timeCardObj.id == null){
        for (Date dt : tcw.dateHour.keySet()) {
          String existingKey = dt+'-'+ tcw.timeCardObj.Project__c + '-'+tcw.timeCardObj.Delivery_Line__c+
                                  '-'+resourceInfo.tc.Resource__c+'-'+tcw.timeCardObj.Type__c;
          if (tcw.dateHour.get(dt) > 0 && (lockingDate == null || (dt > lockingDate && lockingDate != null))) {
             Timecard__c newTc = new Timecard__c(Project__c = tcw.timeCardObj.Project__c, 
                                                  Delivery_Line__c = tcw.timeCardObj.Delivery_Line__c, 
                                                  Resource__c = resourceInfo.tc.Resource__c,
                                                  Type__c = tcw.timeCardObj.Type__c,
                                                  Description__c = tcw.timeCardObj.Description__c);
             newTc.Date__c = dt;
             newTc.Hours__c = tcw.dateHour.get(dt);
             newTc.Description__c = tcw.dateDescription.get(dt);
             if ( tcw.timeCardObj.Delivery_Line__c == null || tcw.timeCardObj.Project__c == null ||
              tcw.timeCardObj.Type__c == null || tcw.timeCardObj.Type__c == '' ) {
                hasError = true;
                errorRows += i+',';
                continue;
             }
             
             if(!existingTCMap.containsKey(existingKey)){
               tcToUpsert.add(newTc);
               existingTCMap.put(existingKey,newTc);
             }
             else if(existingTCMap.containsKey(existingKey) && tcw.dateHour.get(dt) != tcw.timeCardObj.Hours__c){
               existingTCMap.get(existingKey).Hours__c = tcw.dateHour.get(dt);
               tcToUpsert.add(existingTCMap.get(existingKey));
             }
          }
          if ( tcw.dateHour.get(dt) == 0.00 && !timeCardSetToDel.contains(existingTCMap.get(existingKey)) &&
            existingTCMap.get(existingKey) != null) {
             timeCardSetToDel.add(existingTCMap.get(existingKey));
             tcToDelete.add(existingTCMap.get(existingKey));
             existingTCMap.remove(existingKey);
           }
               
        }
      }
    }
    if (hasError) {
    	errorRows = errorRows.substring(0, errorRows.length()-1);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TimecardEntry_Mandatory_Fields_Missing_Error +errorRows));
      return null;
    }
    System.debug('====tcToUpsert===='+tcToUpsert);
    try {
      if (tcToUpsert.size() > 0) {
        upsert tcToUpsert;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.TimecardEntry_Timecard_Saved_Message));
      }
      System.debug('---=tcToDelete---'+tcToDelete);
      if ( listToBeDeleted != null && listToBeDeleted.size() > 0) {
        tcToDelete.addAll(listToBeDeleted);
        listToBeDeleted = new List<Timecard__c>();
      }

      if (tcToDelete.size() > 0) {
        delete tcToDelete;
      }
    } catch (DMLException e) {
      //save Log for Error 
      apexLogHandler.createLogAndSave('TimecardEntryExtension', 
                                      'saveTimecards', 
                                      e.getStackTraceString(),
                                      e);
      for (Integer eCount = 0; eCount < e.getNumDml(); eCount++) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(eCount)));
      }
    }
    return null;
  }
  
  //Wrapper class for resource information
  public class ResourceWrapper {
    public Timecard__c tc{get;set;}
    public Date startDate{get;set;}
    public Integer totalHrs{get;set;}

    public ResourceWrapper () {
      tc = new Timecard__c();
      startDate = Date.today();
      totalHrs = 0;
    }
  }
  
  //Timecard wrapper class to create timecards.
  public class TimecardWrapper {
    public Timecard__c timeCardObj {get;set;}
    public Map<Date, Double> dateHour {get;set;}
    public Map<Date, String> dateDescription {get;set;}
    public integer index {get;set;}
    public list<selectOption> deliveryLines {get;set;}
    public list<selectOption> methodTypes {get;set;}
   //public Boolean isProjectLocked {get;set;}

    public timecardWrapper() {
      timeCardObj = new Timecard__c(Type__c = 'Delivery',Delivery_Line__c = null,Description__c='');
      dateHour = new Map<Date, Double>();
      deliveryLines = new list<selectOption>();
      methodTypes = new list<selectOption>();
      dateDescription = new Map<Date, String>();
    }
  }

    /*
    Method to populate the Project list as per the resource selected.
    */
    public void populateProjectList(){
      projectSelectList = new list<SelectOption>();
      projectSelectList.add(new selectOption('',Label.TimecardEntry_None));
      if((resourceInfo != null && resourceInfo.tc != null && resourceInfo.tc.Resource__c != null) ||
        !String.isBlank(selectedResourceId)){
        String resourceId = selectedResourceId != null? selectedResourceId :resourceInfo.tc.Resource__c;
        currentUser = [SELECT Id, Business_Unit__c 
                       FROM User
                       WHERE Id = :resourceId];
        populateTimeCardForResource(resourceId, convertStringToDate(selectedWeek));
        validateTimesheet();
        for(Project_Resource__c res :[SELECT p.Resource__c, p.Project__r.Allow_Timecard_Entry__c, p.Project__r.Business_Unit__c, 
                                             p.Project__r.Type__c, p.Project__c,p.Resource__r.Business_Unit__c, p.Project__r.Name,
                                             p.Project__r.Status__c
                                      FROM Project_Resource__c p
                                      WHERE Project__r.Allow_Timecard_Entry__c = true
                                      AND Resource__c = :resourceId ] ){
          projectSelectList.add(new selectOption(res.Project__c,res.Project__r.Name));
          if(res.Project__r.Status__c == 'Locked'){          
            projectStatusMap.put(res.Project__c,true);
          }
          else{
            projectStatusMap.put(res.Project__c,false);
          }
        }
        projectStatusMap.put(null,true);
        
        fillNewBlankWrapperList ();
      }
    }

    /*
    Method to populate the Delivery Lines as per the Project selected.
    */
    public void populateRelatedDeliveryLines(){
      List<SelectOption> deliveryLineList = new list<SelectOption> ();
      
      deliveryLineList.add(new selectOption('',Label.TimecardEntry_None));
      alreadyExistingDeliveryLines = new Set<String>();
      if(!String.isBlank(projectId)){
        String whereClause = ''; 
        for(TimecardWrapper tcWrap:timecardWrapperList){
          if(tcWrap.timeCardObj != null && tcWrap.timeCardObj.Project__c == projectId){
            String existingKey = tcWrap.timeCardObj.Project__c +'-'+ tcWrap.timeCardObj.Type__c +'-'+tcWrap.timeCardObj.Delivery_Line__c;
            alreadyExistingDeliveryLines.add(existingKey);
          }
        }
        if ( project_TimecardWrapperMap != null && !project_TimecardWrapperMap.isEmpty() ) {
          for (String mapKey : project_TimecardWrapperMap.keySet()) {
            if (project_TimecardWrapperMap.get(mapKey).size() < 1) {
              continue;
            }
            for (TimecardWrapper tcWrap : project_TimecardWrapperMap.get(mapKey)) {
              if(tcWrap.timeCardObj != null && tcWrap.timeCardObj.Project__c == projectId){
                String existingKey = tcWrap.timeCardObj.Project__c +'-'+ tcWrap.timeCardObj.Type__c +'-'+tcWrap.timeCardObj.Delivery_Line__c;
                alreadyExistingDeliveryLines.add(existingKey);
              }
            }
          }
        }
              
        for(Delivery_Line__c dl:[SELECT Id,Name
                                 FROM Delivery_Line__c
                                 WHERE Project__c = :projectId
                                 AND Allow_Timecard_Entry__c = true]){
          String existingDelKey = projectId +'-'+ 'Delivery' +'-'+ dl.Id;
          String existingTravelKey = projectId +'-'+ 'Travel' +'-'+ dl.Id;
          if(!alreadyExistingDeliveryLines.contains(existingDelKey) || !alreadyExistingDeliveryLines.contains(existingTravelKey)){
            deliveryLineList.add(new selectOption(dl.Id,dl.Name));
          }
        }
        timecardWrapperList[selectedIndex].deliveryLines = deliveryLineList;
      }
    }

    /*
    Method to populate the Method list as per the project and the Delivery Line combination.
    */
    public void populateMethodList(){
      if ( !String.isBlank(projectId) && !alreadyExistingDeliveryLines.isEmpty() && !String.isblank(selectedDeliveryLineId) ) {
        String DeliveryKey = projectId+'-'+'Delivery'+'-'+selectedDeliveryLineId;
        String TravelKey = projectId+'-'+'Travel'+'-'+selectedDeliveryLineId;
        tcMethod = new List<selectOption>();
        tcMethod.add(new selectOption('',Label.TimecardEntry_None));
        if ( !alreadyExistingDeliveryLines.contains(DeliveryKey) && !alreadyExistingDeliveryLines.contains(TravelKey) ) {
          tcMethod.add(new selectOption('Delivery',Label.TimecardEntry_Delivery));
          tcMethod.add(new selectOption('Travel',Label.TimecardEntry_Travel));
        }
        else if ( !alreadyExistingDeliveryLines.contains(DeliveryKey) && alreadyExistingDeliveryLines.contains(TravelKey) ) {
          tcMethod.add(new selectOption('Delivery',Label.TimecardEntry_Delivery));
        }
        else if ( alreadyExistingDeliveryLines.contains(DeliveryKey) && !alreadyExistingDeliveryLines.contains(TravelKey) ) {
          tcMethod.add(new selectOption('Travel',Label.TimecardEntry_Travel));
        }
        timecardWrapperList[selectedIndex].methodTypes = tcMethod;
      }
    }

    /*
    Method to convert string to date for resolving the locale issue.
    */
    public Date convertStringToDate( String DateInString ){
      Date convertedDate ; 
      String[] dts = DateInString.split('/');
      convertedDate = Date.newInstance(Integer.valueOf(dts[2]), Integer.valueOf(dts[0]), Integer.valueOf(dts[1]));
      return convertedDate;
    }

    /*
    Method to cancel the timecard entry.
    */
    public PageReference doCancel ( ) {

      if ( deliveryId != null && deliveryId != '' ) {
        return new PageReference('/'+deliveryId);
      }
      else{
        return new PageReference('/home/home.jsp');
      }
    }

    /*
    Method to copy the timecards from the previous week .
    */
    public PageReference copyFromPreviousWeek () {
      Boolean isProjectEnded = false;
      String errorString = '';
      Set<String> projectNotToUse = new Set<String>();
      Map<String, Map<Date,Double>> previousMap = new Map<String, Map<Date,Double>>();
      Map<String,String> deliveryMap = new Map<String,String>();
      listToBeDeleted = new list<Timecard__c> ();
      if ( String.isBlank(selectedResourceId) ) {
        selectedResourceId = currentUser.Id;
      }
      Date dtSelectedDate = convertStringToDate(selectedWeek);
      Date previousWeek = dtSelectedDate.addDays(-7);
      timecardWrapperList = new List<TimecardWrapper>();
      //project_DateHrsMap = new Map<String,Map<date,Double>>();
     // project_DateDescriptionMap = new Map<String,Map<date,String>>();
      Set<String> tcDetailsToBeCopied = new Set<String>();
      List<timecardWrapper> previousWeekTimecard = new List<timecardWrapper>();
      for (Timecard__c tc : [SELECT ID, Resource__r.Name, Resource__c, Project__c, Project__r.Name, Project__r.Project_End_Date__c,
                                    Hours__c, Description__c, Delivery_Line__c, Delivery_Line__r.Name, Date__c, Name ,Type__c
                             FROM Timecard__c
                             WHERE Resource__c =: selectedResourceId AND
                             Date__c >= : previousWeek AND Date__c < : dtSelectedDate.addDays(7)
                             Order By Date__c]) {
        deliveryMap.put(tc.Delivery_Line__c,tc.Delivery_Line__r.Name);
        system.debug('tcDate>>'+tc.Date__c+'===='+(tc.Date__c < dtSelectedDate));
        if ( tc.Project__r.Project_End_Date__c <= previousWeek) {
          isProjectEnded = true;
          errorString += tc.Project__r.Name + ',' ;
          projectNotToUse.add(tc.Project__c);
        }
        else if( tc.Date__c < dtSelectedDate ) {
          String key = tc.Project__c + '~'+ tc.Type__c +'~'+ tc.Delivery_Line__c;
          if ( project_TimecardWrapperMap.containsKey(key) ) {
            continue;
          }
          else {
            tcDetailsToBeCopied.add(key);
          }
         /* if ( !previousMap.containsKey(key) ) {
            previousMap.put(key,new Map<Date,Double>());
            previousMap.get(key).put(tc.Date__c.addDays(7), tc.Hours__c);
          }
          else {
            previousMap.get(key).put(tc.Date__c.addDays(7),tc.Hours__c);
          }*/
          if ( !project_DateHrsMap.containsKey(key) ) {
            project_DateHrsMap.put(key,new Map<Date,Double>());
            project_DateHrsMap.get(key).put(tc.Date__c, 0.00);
          }
          else {
            project_DateHrsMap.get(key).put(tc.Date__c, 0.00);
          }
          if ( !project_DateDescriptionMap.containsKey(key) ) {
            project_DateDescriptionMap.put(key,new Map<Date,String>());
            project_DateDescriptionMap.get(key).put(tc.Date__c, '');
          }
          else {
            project_DateDescriptionMap.get(key).put(tc.Date__c, '');
          }
          
        }
        else if( tc.Date__c >= dtSelectedDate ) {
          listToBeDeleted.add(tc);
        }
      }
     // populateTimeCardForResource(selectedResourceId,previousWeek);
      for (String str : tcDetailsToBeCopied) {
        List<String> testList = str.split('~');
        if ( !projectNotToUse.contains(testList[0]) ) {
          TimecardWrapper tcWrap = new TimecardWrapper();
          tcWrap.timeCardObj = new Timecard__c();
          tcWrap.timeCardObj.Project__c = testList[0];
          tcWrap.timeCardObj.Delivery_Line__c = testList[2];
          tcWrap.timeCardObj.Type__c = testList[1];
          tcWrap.timeCardObj.Resource__c = selectedResourceId;
          tcWrap.deliveryLines.add(new selectOption(testList[2],deliveryMap.get(testList[2])));
          tcWrap.methodTypes.add(new selectOption(testList[1],testList[1]));
          //tcWrap.dateHour = project_DateHrsMap.get(str) != null ? project_DateHrsMap.get(str) : new Map<Date,Double>();
          tcWrap.dateDescription = new Map<Date, String>();
          tcWrap.dateHour = new Map<Date, Double>();
          timecardWrapperList.add(tcWrap);
        }
      }
      for (TimecardWrapper tcw :timecardWrapperList) {
        for (Date dt : currentWeek) {
          //if ( !tcw.dateHour.containsKey(dt)) {
            tcw.dateHour.put(dt,0.00);
          //}
          if ( !tcw.dateDescription.containsKey(dt)) {
            tcw.dateDescription.put(dt,'');
          }
        }

      }
     // updateMapInfo();
     // totalHours = 0.0;
     // project_TimecardWrapperMap = new Map<String, List<TimecardWrapper>>();
      if ( errorString != '') {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.TimecardEntry_Previous_Timecard_Locked_Message));
      }
      return null;
    }
}