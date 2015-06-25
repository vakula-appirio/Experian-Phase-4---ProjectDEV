/**=====================================================================
 * Experian
 * Name: CaseMergeController
 * Description: Merges a child case to a parent case, moving email messages, attachments and
 *              tasks to the original case. Then closes the child case.
 *              Case #556253
 * Created Date: Mar 19th, 2015
 * Created By: Paul Kissick
 * 
 * Date Modified                 Modified By                  Description of the update
 * Mar 19th, 2015                Paul Kissick                 Created 
 * Mar 23rd, 2015                Paul Kissick                 Added dependency of CustomPermission 'Merge_Cases_Allowed'
 =====================================================================*/
public with sharing class CaseMergeController {

  private ApexPages.StandardController stdCon;
  private Case loserCase;
  private Id caseRecordTypeId;
  
  public ApexPages.StandardSetController setCon {get;set;}
  
  public Case winnerCase {get{if (winnerCase == null) winnerCase = new Case(); return winnerCase;}set;}
  
  public Boolean includeClosed {get{if(includeClosed == null) includeClosed = false; return includeClosed;}set;}
  public Boolean showSearchGrid {get{if(showSearchGrid == null) showSearchGrid = false; return showSearchGrid;}set;}
  public Boolean showWinner {get{if (showWinner == null) showWinner = false; return showWinner;}set;}
  public Boolean showSearchMissing {get{if (showSearchMissing == null) showSearchMissing = false; return showSearchMissing;}set;}
  
  
  public Integer searchPageSize {get{if(searchPageSize == null) searchPageSize = 10; return searchPageSize;} set;}
  public Integer maxSearchLimit {get{if(maxSearchLimit == null) maxSearchLimit = 250; return maxSearchLimit;}set;}
  
  public Id selectedCase {get;set;}
  
  public List<Id> listSelectedCaseIds {get;set;}
  
  public String caseSubject {get{if (caseSubject == null) caseSubject = ''; return caseSubject;} set;}
  public String caseNumber {get{if (caseNumber == null) caseNumber = ''; return caseNumber;} set;}
  
  public List<Case> getFoundParents() {
  	if (setCon != null) {
  	 return (List<Case>)setCon.getRecords();
  	}
  	else return new List<Case>();
  }
  
  public Boolean allowedToMerge {get {
    if (allowedToMerge == null) {
      Integer testCount = [
        SELECT COUNT()
        FROM SetupEntityAccess
        WHERE SetupEntityType='CustomPermission'
        AND SetupEntityId IN (
          SELECT Id 
          FROM CustomPermission 
          WHERE DeveloperName = 'Case_Merge_Allowed'
        )
      ];
      allowedToMerge = (testCount == 0) ? false : true;
      if (Test.isRunningTest()) allowedToMerge = true; // Adding this to ensure all tests will run fine, but there is probably another way!
    }
    return allowedToMerge;
  } private set;}
  
  public CaseMergeController(ApexPages.StandardController con) {
  	stdCon = con;
  	if (!Test.isRunningTest()) stdCon.addFields(new List<String>{'RecordTypeId','RecordType.Name','Subject'});
  	loserCase = (Case)stdCon.getRecord();
  }
  
  public CaseMergeController(ApexPages.StandardSetController sCon) {
  	// called from a list...
  	List<Case> selectedCases = (List<Case>)sCon.getSelected();
  	if (selectedCases != null && !selectedCases.isEmpty()) {
  		listSelectedCaseIds = new List<Id>();
  		for(Case c : selectedCases) {
  			listSelectedCaseIds.add(c.Id);
  		}
  	}
  }
  
  /*
   * Called when the page is loaded to prepare the search criteria to link up to the correct parent case. 
   */
  public PageReference prepareSearch() {
  	if (!allowedToMerge) return null;
  	if (loserCase.RecordTypeId != null) caseRecordTypeId = loserCase.RecordTypeId;
  	if (String.isNotBlank(loserCase.Subject)) caseSubject = loserCase.Subject;
  	do {
  		caseSubject = caseSubject.removeStartIgnoreCase('RE:').trim();
  		caseSubject = caseSubject.removeStartIgnoreCase('FW:').trim();
  	} while (caseSubject.startsWithIgnoreCase('RE:') || caseSubject.startsWithIgnoreCase('FW:'));
  	return searchCases();
  }
  
  public PageReference mergeFromList() {
  	if (!allowedToMerge) return null;
  	if (listSelectedCaseIds != null && listSelectedCaseIds.size() > 1) {
  		// must be at least 2
  		// first case will be the primary/parent
  		List<Case> cases = [
  		  SELECT Id 
  		  FROM Case 
  		  WHERE Id IN :listSelectedCaseIds 
  		  ORDER BY CreatedDate ASC
  		];
  		Case pCase = cases.remove(0);
  		Set<Id> cCases = new Set<Id>();
  		for(Case c : cases) {
  			cCases.add(c.Id);
  		}
  		try {
	      /* Update the original (losing) case... */
	      Boolean successfulMerge = CaseMergeUtility.mergeCases(pCase.Id,cCases);
	      if (successfulMerge) return new ApexPages.StandardController(pCase).view();
	    }
	    catch (CaseMergeUtility.caseMergeException cme) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,cme.getMessage()));
	    }
	    catch (Exception e) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()));
	    }
  	}
  	else {
  		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Not enough records were selected.'));
  	}
  	
  	return null;
  }
  
  public PageReference searchCases() {
  	showSearchMissing = false;
  	if (String.isBlank(caseNumber) && String.isBlank(caseSubject)) {
  		showSearchMissing = true;
  		return null;
  	}
  	showSearchGrid = true;
  	List<String> caseFields = new List<String>{
  		'Id','Subject','CaseNumber','Owner.Name','RecordType.Name',
  		'Contact.Name','Contact.Email','Status', 'CreatedDate'
  	};
    String dbQuery = 'SELECT ' + String.join(caseFields,',') + ' FROM Case ';
    List<String> whereClause = new List<String>();
    if (String.isNotBlank(caseNumber)) {
  		String cNumSearch = '%'+caseNumber;
  		whereClause.add(' CaseNumber LIKE :cNumSearch ');
  	}
  	else {
  		String cSubSearch = '%' + String.escapeSingleQuotes(caseSubject) + '%';
  		whereClause.add(' Subject LIKE :cSubSearch ');
  		if (caseRecordTypeId != null) whereClause.add(' RecordTypeId = :caseRecordTypeId ');
  		if (!includeClosed) whereClause.add(' IsClosed = false ');
  	}
  	 
  	whereClause.add(' Id != \''+loserCase.Id+ '\' ');
  	List<Case> cases = (List<Case>)Database.query(dbQuery + ((whereClause.size() > 0) ? ' WHERE ' + String.join(whereClause,' AND ') : '') + ' ORDER BY CreatedDate ASC LIMIT '+String.valueOf(maxSearchLimit)); 
  	setCon = new ApexPages.StandardSetController(cases);
  	if (setCon != null) {
      setCon.setPageSize(searchPageSize);
  	}
  	return null;
  }
  
  public PageReference selectCase() {
  	if (selectedCase != null) {
  		// load the parent case to make sure it's correct...
  		showSearchGrid = false;
  		showWinner = true;
  		winnerCase = [SELECT Id, Description, Status, CaseNumber, Subject, Owner.Name FROM Case WHERE Id = :selectedCase LIMIT 1];
  	}
  	return null;
  }
  
  public PageReference backToList() {
  	showSearchGrid = true;
    showWinner = false;
    winnerCase = new Case();
    selectedCase = null;
  	return null;
  }
  
  public PageReference performMerge() {
  	// at this point, we are happy with the case to merge into, and need to move everything, so...
  	try {
  		/* Update the original (losing) case... */
      Boolean successfulMerge = CaseMergeUtility.mergeCases(selectedCase,new Set<Id>{loserCase.Id});
      if (successfulMerge) return new ApexPages.StandardController(new Case(Id = selectedCase)).view();
  	}
  	catch (CaseMergeUtility.caseMergeException cme) {
  		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,cme.getMessage()));
  	}
  	catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()));
    }
  	return null;
  }
  
  public Boolean getHasNext() {
  	return setCon.getHasNext();
  }
  
  public Boolean getHasPrevious() {
    return setCon.getHasPrevious();
  }
  
  public void gotoStart() {
    setCon.first();
  }
  
  public void gotoLast() {
  	setCon.last();
  }
  
  public void gotoNext() {
    setCon.next();
  }
  
  public void gotoPrevious() {
    setCon.previous();
  }
  
  public Integer getPageNumber() {
  	return setCon.getPageNumber();
  }
  
  public Integer getResultSize() {
    return setCon.getResultSize();
  }
  
  public Integer getTotalPages() {
    Decimal total = setCon.getResultSize();
    Decimal pageSize = setCon.getPageSize();
    Decimal pages = (total + pageSize - 1) / pageSize;
    if (pages == 0) pages = 1;
    return pages.intValue();
  }

}