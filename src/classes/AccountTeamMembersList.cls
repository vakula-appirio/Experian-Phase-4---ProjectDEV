/**=====================================================================
 * Appirio, Inc
 * Name: AccountTeamMembersList
 * Description: T-366039: Confidential Information: Account Team VF Page
 * Created Date: Feb 27th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified         Modified By           Description of the update
 * Mar 3th,2015          Noopur                T-367124 :Added logic for the deletion of 
 *                                             Confidential Information Share records.
 * Mar 5th, 2015         Arpita Bose           T-368099: auto-create Confidential_Information__Share
 *                                             records when ATM is created
 * Mar 11th, 2015        Gaurav Kumar Chadha   T-369312: Added logic to display Sales Team and Sales Sub team 
 * Jun 1st, 2015         Paul Kissick          Case #941536: Added 'with sharing' as everyone could edit everything!
  =====================================================================*/
public with sharing class AccountTeamMembersList {
  
  public List<accountTeamWrapper> accountTeamMembers {get;set;}
  public List<accountTeamWrapper> newAccountTeamMembers {get;set;}
  public Account acc {get;set;}
  public Boolean showAddMemberSection {get;set;}
  public Boolean displayAccess {get;set;}
  public List<selectOption> accountOppAccessLevels {get;set;}
  public List<selectOption> caseAccessLevels {get;set;}
  public Id selectedId {get;set;}
  public Integer listSize {get;set;}
  public List<accountTeamWrapper> accountTeamMembersToShow {get;set;}
  public Integer currentSizeShown {get;set;}
  public Boolean reachedMax {get;set;}
  
  //==========================================================================
  // Constructor
  //==========================================================================
  public AccountTeamMembersList ( ApexPages.Standardcontroller std) {
    showAddMemberSection = false;
    displayAccess = false;
    currentSizeShown = 5;
    reachedMax = false;
    accountTeamMembersToShow = new List<accountTeamWrapper>();
    accountOppAccessLevels = new List<selectOption>();
    accountOppAccessLevels.add(new selectOption(Label.AccountTeamMembersList_Read,Label.AccountTeamMembersList_Read_Only));
    accountOppAccessLevels.add(new selectOption(Label.AccountTeamMembersList_Edit,Label.AccountTeamMembersList_Read_Write));
    caseAccessLevels = new List<selectOption>();
    caseAccessLevels.add(new selectOption(Label.AccountTeamMembersList_None,Label.AccountTeamMembersList_Private));
    caseAccessLevels.add(new selectOption(Label.AccountTeamMembersList_Read,Label.AccountTeamMembersList_Read_Only));
    caseAccessLevels.add(new selectOption(Label.AccountTeamMembersList_Edit,Label.AccountTeamMembersList_Read_Write));
    Id accId = std.getRecord().Id;
    acc = [SELECT Id,Name 
           FROM Account
           WHERE Id = :accId];
    fetchExistingAccountTeamMembers();
    listSize = accountTeamMembers.size();
    if( listSize == 5) {
        reachedMax = true;
    }
    if( ApexPages.currentPage().getParameters().get('showAddMemberSection') != null && 
     ApexPages.currentPage().getParameters().get('showAddMemberSection') != '' ) {
      //showAddMemberSection = true;
      addTeamMembers();
    }
  }
  
  //==========================================================================
  // Method to fetch the existing Account Team Members and their access levels
  //==========================================================================
  public void fetchExistingAccountTeamMembers () {
    accountTeamMembers = new List<accountTeamWrapper> ();
    accountTeamMembersToShow = new List<accountTeamWrapper>();
    integer i = 0;
    map<Id,AccountShare> accShareMap = new map<Id,AccountShare>();
    for ( AccountShare accShare : [SELECT Id,OpportunityAccessLevel, CaseAccessLevel, UserOrGroupId
                                   FROM AccountShare
                                   WHERE AccountId = :acc.Id]) {
      accShareMap.put(accShare.UserOrGroupId,accShare);
    }
    for ( AccountTeamMember atm : [SELECT Id,TeamMemberRole,UserId,AccountId,
                                          AccountAccessLevel ,
                                          User.Sales_Sub_Team__c, 
                                          User.Sales_Team__c,
                                          User.Name
                                   FROM AccountTeamMember 
                                   WHERE AccountId = :acc.Id
                                   order by User.Name ASC]) {
      accountTeamWrapper atWrap = new accountTeamWrapper();
      atWrap.member = atm;
      if(accShareMap != null && accShareMap.containsKey(atm.UserId)) {
        AccountShare accShare = accShareMap.get(atm.UserId);
        atWrap.caseAccess = accShare.CaseAccessLevel;
        atWrap.opportunityAccess = accShare.OpportunityAccessLevel;
      }
      accountTeamMembers.add(atWrap);
      if( i < 5) {
        accountTeamMembersToShow.add(atWrap);
        i++;
      }
      
    }
  }
  
  //==========================================================================
  // Method to create new members list and display the add team members section
  //==========================================================================
  public void addTeamMembers () {
    newAccountTeamMembers = new List<accountTeamWrapper>();
    for ( integer i=0; i<5; i++) {
      accountTeamWrapper atm = new accountTeamWrapper();
      atm.member.AccountId = acc.Id;
      newAccountTeamMembers.add(atm);
    }
    showAddMemberSection = true;
  }
  
  //==========================================================================
  // Method to show the access levels on the list view
  //==========================================================================
  public void showAccess (){
    displayAccess = true;
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.AccountTeamMembersList_Display_Access_Info));
  }
  
  //==========================================================================
  // Method to save the newly created team members
  //==========================================================================
  public pagereference saveNewTeamMembers () {
    List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
    List<AccountShare> accshareToInsert = new List<AccountShare>();
    List<Confidential_Information__Share> confInfoSharesToInsert = new List<Confidential_Information__Share>();
    try {
      for ( accountTeamWrapper atmWrap : newAccountTeamMembers) {
        if ( atmWrap.member.userId != null ) {
          atmToInsert.add(atmWrap.member);
          System.debug('---atmWrap.member.AccountAccessLevel---'+atmWrap.accountAccess);
          if ( atmWrap.accountAccess == Label.AccountTeamMembersList_Edit) {
            AccountShare accshare = new AccountShare();
            accshare.AccountAccessLevel = atmWrap.accountAccess;
            accshare.AccountId = atmWrap.member.AccountId;
            accshare.OpportunityAccessLevel = atmWrap.opportunityAccess;
            accshare.CaseAccessLevel = atmWrap.caseAccess;
            accshare.UserOrGroupId = atmWrap.member.userId;
            accshareToInsert.add(accshare);
          }
        }
      }
      //T-368099 - create Confidential_Information__Share when ATM created
      List<Confidential_Information__c> confInfoList = getConInfoRecords(acc.Id);
      Confidential_Information__Share newConfInfoShare;
      
      for (Confidential_Information__c confInfo : confInfoList) {
        for ( accountTeamWrapper atmWrap : newAccountTeamMembers) {
          if ( atmWrap.member.userId != null ) {
            String accessLevel = Constants.ACCESS_LEVEL_READ; //Default to be set.
  
            // All access level is not on the ConfInfoShare picklist so it will have edit.
            if (accessLevel == Constants.ACCESS_LEVEL_ALL) {
              accessLevel = Constants.ACCESS_LEVEL_EDIT;
            }
            newConfInfoShare = new Confidential_Information__Share();
            newConfInfoShare.AccessLevel    = accessLevel;
            newConfInfoShare.ParentId       = confInfo.Id;
            newConfInfoShare.RowCause       = Constants.ROWCAUSE_ACCOUNT_TEAM;
            newConfInfoShare.UserOrGroupId  = atmWrap.member.userId;
            confInfoSharesToInsert.add(newConfInfoShare);
          }
        }
      }
      if (!atmToInsert.isEmpty()) {
        insert atmToInsert;
      }
      if (!accshareToInsert.isEmpty()) {
        insert accshareToInsert;
      }
      if (!confInfoSharesToInsert.isEmpty()) {
          insert confInfoSharesToInsert;
      }
      return new pagereference('/'+acc.Id);
    }
    catch ( exception ex) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.Error, ex.getMessage()));
      apexLogHandler.createLogAndSave('AccountTeamMembersList','saveNewTeamMembers', ex.getStackTraceString(), ex);
      return null;
    }
  }
  
  //==========================================================================
  // Method to save team members and show the blank list again for the user to enter more records
  //==========================================================================
  public void saveAndMore() {
    saveNewTeamMembers();
    addTeamMembers(); 
  }
  
  //==========================================================================
  // Method to cancel and return back to Account page
  //==========================================================================
  public pagereference doCancel () {
    newAccountTeamMembers = null;
    return new pagereference('/'+acc.Id);
  }
  
  //==========================================================================
  // Method to delete the account team member records
  //==========================================================================
  public PageReference doDelete() {
    try{
      if ( selectedId != null ) {
        integer indexToDel = -1;
        for (accountTeamWrapper atWrap :accountTeamMembers) {
          indexToDel++;
          if ( atWrap.member.Id == selectedId ) {
            break;
          }
        }
        if( indextoDel != -1) {
          accountTeamMembers.remove(indextoDel);
        }
        AccountTeamMember atmToDel = [SELECT Id,UserId,AccountId FROM AccountTeamMember WHERE Id = :selectedId];
        
        // fetch the Confidential_Information__Share records to be deleted.
        List<Confidential_Information__Share> confidentialInfoShares = new List<Confidential_Information__Share>();
        for (Confidential_Information__Share CI_Share : [SELECT c.UserOrGroupId, c.RowCause, c.Parent.Account__c, c.ParentId 
                                                         FROM Confidential_Information__Share c
                                                         WHERE Parent.Account__c = :atmToDel.AccountId 
                                                         AND UserOrGroupId = :atmToDel.UserId
                                                         AND RowCause = :Constants.ROWCAUSE_ACCOUNT_TEAM]) {
          confidentialInfoShares.add(CI_Share);
        }
        
        delete atmToDel;
        
        if (!confidentialInfoShares.isEmpty() ) {
          delete confidentialInfoShares;
        }
        fetchExistingAccountTeamMembers();
      }
    }
    catch ( exception ex) {
      apexLogHandler.createLogAndSave('AccountTeamMembersList','doDelete', ex.getStackTraceString(), ex);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, ex.getMessage()));
    }
    return null;
  }
  
  //==========================================================================
  // Method to show next set of records in the detail page
  //==========================================================================
  public void showMoreRecords() {
    integer loopEndVariable;
    if( currentSizeShown+5 < accountTeamMembers.size() ) {
      loopEndVariable = currentSizeShown+5;
    }
    else {
      loopEndVariable = accountTeamMembers.size();
      reachedMax = true;
    }
    for( integer i=currentSizeShown; i < loopEndVariable; i++) {
      accountTeamMembersToShow.add(accountTeamMembers[i]);
    }
    currentSizeShown = accountTeamMembersToShow.size();
  }
  
  //==========================================================================
  //Method to get Confidential_Information__c records
  //==========================================================================
  public List<Confidential_Information__c> getConInfoRecords (Id accID) {
    List<Confidential_Information__c> lstConInfo = [SELECT Id, Account__c,
                                                      (SELECT Id
                                                         FROM Shares
                                                           WHERE RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM)
                                                     FROM Confidential_Information__c
                                                     WHERE Account__c = :accID
                                                     AND Synch_Account_Team_Members__c = true];
      return lstConInfo;
  }
  
  //==========================================================================
  // Wrapper class to hold the Team Member record as well as their access levels
  //==========================================================================
  public class accountTeamWrapper {
    public AccountTeamMember member {get;set;}
    public String accountAccess {get;set;}
    public String opportunityAccess {get;set;}
    public String caseAccess {get;set;}
    public accountTeamWrapper() {
      member = new AccountTeamMember();
      opportunityAccess = '';
      caseAccess = '';
    }
  }
}