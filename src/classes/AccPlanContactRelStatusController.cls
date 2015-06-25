/**=====================================================================
 * Appirio, Inc
 * Name        : AccPlanContactRelStatusController
 * Description : Controller class for page AccPlanContactRelStatusPage (for T-289161)
 * Created Date: Jun 24th, 2014
 * Created By  : Sonal Shrivastava (Appirio JDC)
 =====================================================================*/
public class AccPlanContactRelStatusController {
  
  public Map<Integer, List<Account_Plan_Contact__c>> mapLevel_LstContact {get; set;}
  private Map<String, List<Account_Plan_Contact__c>> mapParent_LstContact;
  public Map<String, Integer> mapConName_NoOfCol {get; set;}
  public Map<String, Integer> mapConName_NoOfRow {get; set;}
  public List<Integer> lstLevels {get; set;}
  public String accPlanId {get; set;}  
  public Attachment contactRelationImage {get;set;}
  public Integer maxLevels = 0 ;
  
  //----------------------------------------------------------------------------
  // Constructor
  //----------------------------------------------------------------------------
  
  public AccPlanContactRelStatusController(ApexPages.StandardController stdController) {
  	 accPlanId = ApexPages.currentPage().getParameters().get('id');
     init();
  }
    
  public AccPlanContactRelStatusController(){
    accPlanId = ApexPages.currentPage().getParameters().get('id');   
    init();
  }
  
  //----------------------------------------------------------------------------
  // Method to initialize properties
  //----------------------------------------------------------------------------
  private void init(){
    lstLevels = new List<Integer>();
    mapLevel_LstContact = new Map<Integer, List<Account_Plan_Contact__c>>();
    mapParent_LstContact = new Map<String, List<Account_Plan_Contact__c>>();
    mapConName_NoOfCol = new Map<String, Integer>();
    mapConName_NoOfRow = new Map<String, Integer>();
    
    if(accPlanId != null && accPlanId != ''){
    	 
	    for(Attachment att : [Select Id From Attachment Where ParentId = :accPlanId and Name = 'ContactRelationImage']){
	        ContactRelationImage = att;
	    }        
	    
        List<Account_Plan_Contact__c> lstAccPlanContact = fetchAccPlanContacts(accPlanId);
          if(!lstAccPlanContact.isEmpty()){
            prepareHierarchy(lstAccPlanContact);
            prepareNoOfColMap();
            System.debug('mapConName_NoOfCol --->>> ' + mapConName_NoOfCol);
          }
    }
  }
  
  //----------------------------------------------------------------------------
  // Method to get all account plan contacts related to the account plan
  //----------------------------------------------------------------------------
  private List<Account_Plan_Contact__c> fetchAccPlanContacts(String accPlanId){
    List<Account_Plan_Contact__c> lstAccPlanContact = new List<Account_Plan_Contact__c>();
    for(Account_Plan_Contact__c apc : [SELECT Id, Reports_To__c, Contact__c, Contact_Name__c, 
                                              Contact_Job_Title__c, Account_Plan__c,
                                              Contact__r.ReportsToId, Experian_Relationship__c  
                                       FROM Account_Plan_Contact__c 
                                       WHERE Account_Plan__c =: accPlanId
                                       ORDER BY Contact_Name__c, Contact_Job_Title__c]){
        lstAccPlanContact.add(apc);
    }
    return lstAccPlanContact;
  }
  
  
  //----------------------------------------------------------------------------
  // Method to create a map with key as account plan contact name and value as
  // list of all its subordinates
  //----------------------------------------------------------------------------
  private void prepareHierarchy(List<Account_Plan_Contact__c> lstAccPlanContact){
    
    List<Account_Plan_Contact__c> lstTopContact = new List<Account_Plan_Contact__c>();
    Map<Id,Account_Plan_Contact__c> mapAccPlanContact = new Map<Id,Account_Plan_Contact__c>();
    for(Account_Plan_Contact__c apContact : lstAccPlanContact){
        //If it is top contact, add it in top contact list
        mapAccPlanContact.put(apContact.Contact__c,apContact);
    }  
    for(Account_Plan_Contact__c apContact : lstAccPlanContact){
        //If it is top contact, add it in top contact list
        if(apContact.Contact__r.ReportsToId == null || !mapAccPlanContact.containsKey(apContact.Contact__r.ReportsToId)){
        	apContact.Contact__r.ReportsToId = null; //  to avoid connector lines when report to in not in the list
            lstTopContact.add(apContact);
        }
        //Else, add it in a map with key as its ReportsTo contact name, and value as list of child contacts
        else{
            if(!mapParent_LstContact.containsKey(apContact.Contact__r.ReportsToId)){
                mapParent_LstContact.put(apContact.Contact__r.ReportsToId, new List<Account_Plan_Contact__c>());
            }
            mapParent_LstContact.get(apContact.Contact__r.ReportsToId).add(apContact);
        }
    }       
    prepareLevelContactHierarchy(lstTopContact);    
  }
  
  //----------------------------------------------------------------------------
  // Method to add all top level contacts in the map
  //----------------------------------------------------------------------------
  private void prepareLevelContactHierarchy(List<Account_Plan_Contact__c> lstTopContact){
    Integer topLevel = 1;
    for(Account_Plan_Contact__c topCon : lstTopContact){
        
        //Add the topContact at level 1
        if(!mapLevel_LstContact.containsKey(topLevel)){
            mapLevel_LstContact.put(topLevel, new List<Account_Plan_Contact__c>());
            lstLevels.add(topLevel);
        }
        mapLevel_LstContact.get(topLevel).add(topCon);
        addSubordinatesToHierarchyMap(topLevel, topCon);
    }                     
  }
  
  //----------------------------------------------------------------------------
  // Method to add all subordinates to the hierarchy map
  //----------------------------------------------------------------------------
  private void addSubordinatesToHierarchyMap(Integer level, Account_Plan_Contact__c con){
    if(mapParent_LstContact.containsKey(con.Contact__c)){
      Integer subordinateLevel = level + 1; 
      for(Account_Plan_Contact__c subordinateCon : mapParent_LstContact.get(con.Contact__c)){
          if(!mapLevel_LstContact.containsKey(subordinateLevel)){
            mapLevel_LstContact.put(subordinateLevel, new List<Account_Plan_Contact__c>());
            lstLevels.add(subordinateLevel);
          } 
          mapLevel_LstContact.get(subordinateLevel).add(subordinateCon);
          addSubordinatesToHierarchyMap(subordinateLevel, subordinateCon);
        }      
        maxLevels =  maxLevels > subordinateLevel ? maxLevels : subordinateLevel;
    }
  }
  
  //----------------------------------------------------------------------------
  // Method to prepare a map with key as account plan name and value as the no.
  // of columns it will take as colspan in UI.
  //----------------------------------------------------------------------------
  private void prepareNoOfColMap(){
    for(Integer level : lstLevels){
        //Iterate through first level contacts
        for(Account_Plan_Contact__c apc : mapLevel_LstContact.get(level)){
            findNoOfCol(apc.Contact__c); 
            findNoOfRows(apc.Contact__c,level);
        }
    }
  }
  
  private integer findNoOfCol(String conName){ 
    integer cnt;
    if(mapParent_LstContact.containsKey(conName)){
        cnt = 0;
        for(Account_Plan_Contact__c apc : mapParent_LstContact.get(conName)){
          cnt = cnt + findNoOfCol(apc.Contact__c);
        }
        //cnt = cnt == 0 ? 1 : cnt;
    }else{
        cnt = 1; 
    }
    mapConName_NoOfCol.put(conName, cnt);
    return cnt;
  }
  
  private integer findNoOfRows(String conName, Integer currentLevel){ 
    integer cnt;
    if(mapParent_LstContact.containsKey(conName)){
    	if(mapParent_LstContact.get(conName).size() > 0){
        cnt = 1;
    	}else{
    		cnt = maxLevels > currentLevel ? maxLevels - currentLevel + 1 : 1;
    	}
    }else{
    	cnt = maxLevels > currentLevel ? maxLevels - currentLevel + 1 : 1; 
    }        
    mapConName_NoOfRow.put(conName, cnt);
    return cnt;
  }
  
}